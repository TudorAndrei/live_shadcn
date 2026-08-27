defmodule Mix.Tasks.Ui.SpecTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias LiveShadcnTools.Converter

  @initial_alpha ~S'''
  function Alpha() {
    return <div className="alpha-old" />
  }

  export { Alpha }
  '''

  @initial_beta ~S'''
  function Beta() {
    return <div className="beta-old" />
  }

  export { Beta }
  '''

  setup do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "live-shadcn-ui-spec-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp_dir)
    on_exit(fn -> File.rm_rf!(tmp_dir) end)
    {:ok, tmp_dir: tmp_dir}
  end

  test "the offline check needs no fetched source directory", %{tmp_dir: tmp_dir} do
    root = prepare_repo(tmp_dir)
    write_initial_port!(root, "alpha", @initial_alpha)
    File.rm_rf!(Path.join(root, "registry/upstream"))
    File.rm!(Path.join(root, "registry/UPSTREAM.json"))

    refute File.exists?(Path.join(root, "registry/upstream"))

    output = run_task(root, ["--check", "--offline"])

    assert output =~ "every port is current (1)"
  end

  test "manual drift prevents every safe write in the same full run", %{tmp_dir: tmp_dir} do
    root = prepare_repo(tmp_dir)
    write_initial_port!(root, "alpha", @initial_alpha)
    write_initial_port!(root, "beta", @initial_beta)

    alpha_contract = contract_path(root, "alpha") |> File.read!()
    alpha_port = port_path(root, "alpha") |> File.read!()

    changed_alpha = String.replace(@initial_alpha, "alpha-old", "alpha-new")

    changed_beta =
      String.replace(
        @initial_beta,
        ~s|return <div className="beta-old" />|,
        ~s|return <div className="beta-old"><span /></div>|
      )

    write_sources!(root, %{"alpha" => changed_alpha, "beta" => changed_beta})

    assert_raise Mix.Error, ~r/manual upstream drift/, fn ->
      run_task(root, [])
    end

    assert File.read!(contract_path(root, "alpha")) == alpha_contract
    assert File.read!(port_path(root, "alpha")) == alpha_port
  end

  defp prepare_repo(tmp_dir) do
    root = Path.join(tmp_dir, "repo")
    File.mkdir_p!(Path.join(root, "registry/spec/shadcn"))
    File.mkdir_p!(Path.join(root, "packages/live_shadcn/priv/registry"))
    File.mkdir_p!(Path.join(root, "packages/live_ai_elements"))
    File.mkdir_p!(Path.join(root, "tools"))

    File.write!(
      Path.join(root, "tools/package.json"),
      Jason.encode!(%{"dependencies" => %{"oxc-parser" => "0.74.0"}})
    )

    root
  end

  defp write_initial_port!(root, name, source) do
    source_path = "shadcn/ui/#{name}.tsx"
    port = port(name, source)

    artifact =
      File.cd!(root, fn ->
        assert {:updated, artifact, _changes} =
                 Converter.sync(%{
                   source: "shadcn",
                   name: name,
                   files: %{source_path => source},
                   styles: %{},
                   base_ui: %{},
                   contract: nil,
                   port: port
                 })

        artifact
      end)

    File.write!(contract_path(root, name), artifact.contract_json)
    File.write!(port_path(root, name), artifact.port)

    sources = current_sources(root) |> Map.put(name, source)
    write_sources!(root, sources)
  end

  defp write_sources!(root, sources) do
    upstream = Path.join(root, "registry/upstream/shadcn/ui")
    File.mkdir_p!(upstream)

    files =
      Map.new(sources, fn {name, source} ->
        path = "shadcn/ui/#{name}.tsx"
        File.write!(Path.join(root, "registry/upstream/#{path}"), source)

        {path,
         %{
           "bytes" => byte_size(source),
           "sha256" => LiveShadcnTools.digest(source),
           "url" => "https://example.test/#{name}.tsx"
         }}
      end)

    manifest = %{"files" => files, "sources" => %{}}
    File.write!(Path.join(root, "registry/UPSTREAM.json"), Jason.encode!(manifest))

    inventory =
      sources
      |> Map.keys()
      |> Enum.sort()
      |> Enum.map(&%{"source" => "shadcn", "name" => &1, "recipe" => "presentational"})

    File.write!(
      Path.join(root, "registry/INVENTORY.json"),
      Jason.encode!(%{"components" => inventory})
    )
  end

  defp current_sources(root) do
    root
    |> Path.join("registry/upstream/shadcn/ui/*.tsx")
    |> Path.wildcard()
    |> Map.new(fn path -> {Path.basename(path, ".tsx"), File.read!(path)} end)
  end

  defp run_task(root, arguments) do
    capture_io(fn ->
      File.cd!(root, fn ->
        Mix.Task.reenable("ui.spec")
        Mix.Tasks.Ui.Spec.run(arguments)
      end)
    end)
  end

  defp port(name, source) do
    module = name |> Macro.camelize()
    class = Regex.run(~r/className="([^"]+)"/, source, capture: :all_but_first) |> hd()

    """
    defmodule LiveShadcn.UI.#{module} do
      # live-shadcn: upstream facts start
      @upstream_facts %{
        "jsx/#{module}/class/0" => #{inspect(class)}
      }
      # live-shadcn: upstream facts end

      def #{name}(), do: @upstream_facts
    end
    """
  end

  defp contract_path(root, name),
    do: Path.join(root, "registry/spec/shadcn/#{name}.json")

  defp port_path(root, name),
    do: Path.join(root, "packages/live_shadcn/priv/registry/#{name}.ex")
end
