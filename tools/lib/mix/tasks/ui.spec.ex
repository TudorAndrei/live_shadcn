defmodule Mix.Tasks.Ui.Spec do
  @shortdoc "Turn the fetched upstream sources into registry/spec/<name>.json"

  @moduledoc """
  Stage 2 of the codegen pipeline.

  Reads the shadcn `.tsx` and the Base UI `.md` that `mix ui.fetch` downloaded
  and writes one JSON document per component into `registry/spec/`.

      mix ui.spec                  # every component that has both sources
      mix ui.spec accordion        # one component
      mix ui.spec --check          # exit 1 if any spec on disk is stale

  The spec is committed and the upstream sources are not, so the spec is the
  reviewable record of what upstream says. Each spec carries the SHA-256 of the
  two files it was built from: if a digest in the spec and the digest in
  `registry/UPSTREAM.json` disagree, the spec is stale and `--check` fails.

  A component with no Base UI page is skipped, not guessed at. The Base UI page
  is where the data-attribute contract comes from, and a component generated
  without it would emit attributes nobody promised.
  """
  use Mix.Task

  import LiveShadcnTools

  alias LiveShadcnTools.Spec
  alias LiveShadcnTools.Style

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")
    {opts, names, _} = OptionParser.parse(argv, strict: [check: :boolean])
    check? = Keyword.get(opts, :check, false)

    manifest = read_json!(registry_path("UPSTREAM.json"))
    inventory = read_json!(registry_path("INVENTORY.json"))
    recipes = Map.new(inventory["components"], &{&1["name"], &1["recipe"]})
    styles = styles(manifest)

    components = if names == [], do: fetched(manifest), else: names
    results = Enum.map(components, &one(&1, manifest, recipes, styles, check?))

    report(results, check?)
  end

  # The `cn-` rules, one map per shadcn style. A missing sheet is reported once
  # here rather than per component.
  defp styles(manifest) do
    manifest
    |> Map.get("files", %{})
    |> Map.keys()
    |> Enum.filter(&String.starts_with?(&1, "shadcn/styles/"))
    |> Enum.sort()
    |> Enum.flat_map(fn file ->
      path = registry_path(["upstream", file])

      if File.exists?(path) do
        [{Path.basename(file, ".css"), path |> File.read!() |> Style.rules()}]
      else
        Mix.shell().error("  skip #{file}: not fetched. Run `mix ui.fetch`.")
        []
      end
    end)
    |> Map.new()
  end

  defp fetched(manifest) do
    files = Map.keys(manifest["files"] || %{})
    Enum.sort(for "shadcn/ui/" <> file <- files, do: Path.basename(file, ".tsx"))
  end

  # One component that the reader cannot understand is a gap in the reader, not
  # a reason to leave the other sixty unspecced. It is reported by name and the
  # run continues, so the gaps are a list somebody can work through.
  defp one(name, manifest, recipes, styles, check?) do
    tsx_file = "shadcn/ui/#{name}.tsx"
    md_file = "base_ui/#{name}.md"

    with {:ok, tsx} <- source(manifest, tsx_file),
         {:ok, pages} <- extra_pages(tsx, manifest, name) do
      # A component with no Base UI page is a component with no behaviour: a
      # card is a `<div>` with a class string. It specs from the `.tsx` alone.
      pages =
        case source(manifest, md_file) do
          {:ok, markdown} -> Map.put(pages, name, markdown)
          _absent -> pages
        end

      spec =
        Spec.build(name,
          tsx: tsx,
          module: name,
          markdown: pages,
          styles: styles,
          recipe: Map.get(recipes, name, "unassigned"),
          upstream: %{
            "shadcn" => %{"file" => tsx_file, "sha256" => digest(tsx)},
            "base_ui" => Map.new(pages, fn {mod, md} -> {mod, digest(md)} end)
          }
        )

      write_or_check(name, spec, check?)
    end
  rescue
    error -> {:unreadable, name, Exception.message(error) |> String.split("\n") |> hd()}
  end

  # menubar is built from `@base-ui/react/menubar` and `@base-ui/react/menu`.
  # Both pages are its contract, so both are read.
  defp extra_pages(tsx, manifest, name) do
    ~r|from "@base-ui/react/([a-z0-9-]+)"|
    |> Regex.scan(tsx, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.reject(&(&1 == name))
    |> Enum.reduce_while({:ok, %{}}, fn module, {:ok, pages} ->
      case source(manifest, "base_ui/#{module}.md") do
        {:ok, markdown} -> {:cont, {:ok, Map.put(pages, module, markdown)}}
        # A module with no page of its own is not a component module: Base UI
        # publishes utilities under the same namespace.
        _missing -> {:cont, {:ok, pages}}
      end
    end)
  end

  defp source(manifest, file) do
    path = registry_path(["upstream", file])

    cond do
      not File.exists?(path) ->
        {:missing, file}

      manifest["files"][file]["sha256"] != digest(File.read!(path)) ->
        {:stale, file}

      true ->
        {:ok, File.read!(path)}
    end
  end

  defp write_or_check(name, spec, check?) do
    path = registry_path(["spec", "#{name}.json"])
    rendered = json(spec)

    cond do
      not check? ->
        write!(path, rendered)
        {:wrote, name}

      File.exists?(path) and File.read!(path) == rendered ->
        {:current, name}

      true ->
        {:outdated, name}
    end
  end

  defp json(spec),
    do: (spec |> Jason.encode_to_iodata!(pretty: true) |> IO.iodata_to_binary()) <> "\n"

  defp report(results, check?) do
    for {:missing, file} <- results,
        do: Mix.shell().error("  skip: #{file} is not fetched. Run `mix ui.fetch`.")

    for {:stale, file} <- results,
        do: Mix.shell().error("  skip: #{file} does not match its digest. Run `mix ui.fetch`.")

    unreadable = for {:unreadable, name, why} <- results, do: "#{name}: #{why}"
    outdated = for {:outdated, name} <- results, do: name
    wrote = for {:wrote, name} <- results, do: name

    if unreadable != [] do
      Mix.shell().error("""

      #{length(unreadable)} component(s) the reader cannot understand yet:

        #{Enum.join(unreadable, "\n  ")}
      """)
    end

    cond do
      check? and outdated != [] ->
        Mix.raise("stale specs: #{Enum.join(outdated, ", ")}. Run `mix ui.spec`.")

      check? ->
        Mix.shell().info("every spec is current (#{length(results) - length(unreadable)})")

      true ->
        Mix.shell().info("wrote #{length(wrote)} spec(s)")
    end
  end
end
