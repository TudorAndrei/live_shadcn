defmodule Mix.Tasks.Ui.Spec do
  @shortdoc "Synchronize safe upstream facts into reviewed component ports"

  @moduledoc """
  Stage 2 of the maintainer pipeline.

  Every component must have a version-2 contract and a reviewed Elixir port.
  The task uses Oxc facts to update class and CVA data. It stops when upstream
  structure or behavior needs manual review.

      mix ui.spec
      mix ui.spec accordion
      mix ui.spec shadcn/message
      mix ui.spec --check
      mix ui.spec --check --source shadcn
      mix ui.spec --check --offline

  An online run reads the pinned files from `registry/upstream/`. It computes
  every result before it writes any port or contract. Thus one manual drift
  stops all writes in that run.

  `--check --offline` reads only committed contracts and ports. It checks fact
  values, canonical fact blocks, port-body digests, and canonical JSON bytes.
  It does not need `registry/UPSTREAM.json` or `registry/upstream/`.
  """
  use Mix.Task

  import LiveShadcnTools

  alias LiveShadcnTools.Converter
  alias LiveShadcnTools.Style

  @switches [check: :boolean, source: :string, offline: :boolean]

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")
    {opts, names, invalid} = OptionParser.parse(argv, strict: @switches)
    valid_options!(invalid)

    check? = Keyword.get(opts, :check, false)
    offline? = Keyword.get(opts, :offline, false)
    source = Keyword.get(opts, :source)

    if offline? and not check? do
      Mix.raise("`--offline` is valid only with `--check`.")
    end

    components = components(names, source)

    results =
      if offline? do
        Enum.map(components, &offline_result/1)
      else
        manifest = read_json!(registry_path("UPSTREAM.json"))
        styles = styles!(manifest)
        Enum.map(components, &online_result(&1, manifest, styles))
      end

    finish(results, check?)
  end

  defp valid_options!([]), do: :ok

  defp valid_options!(invalid) do
    options = Enum.map_join(invalid, ", ", fn {option, _value} -> option end)
    Mix.raise("invalid option(s): #{options}")
  end

  defp components([], source) do
    registry_path(["spec", "*", "*.json"])
    |> Path.wildcard()
    |> Enum.map(&component_from_path/1)
    |> only(source)
    |> Enum.sort()
  end

  defp components(names, source) do
    names
    |> Enum.map(&resolve/1)
    |> Enum.map(fn {component_source, name} = component ->
      if source != nil and source != component_source do
        Mix.raise("#{ref(component_source, name)} does not belong to source #{source}.")
      end

      unless File.exists?(spec_path(component_source, name)) do
        Mix.raise("#{ref(component_source, name)} has no version-2 contract.")
      end

      component
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp component_from_path(path) do
    source = path |> Path.dirname() |> Path.basename()
    name = Path.basename(path, ".json")
    {source, name}
  end

  defp only(components, nil), do: components
  defp only(components, source), do: Enum.filter(components, &(elem(&1, 0) == source))

  defp offline_result({source, name}) do
    with {:ok, contract, contract_bytes, port} <- inputs(source, name),
         {:ok, artifact} <- offline_sync(contract, port),
         :ok <- byte_current(contract_bytes, port, artifact) do
      {:current, ref(source, name), artifact}
    else
      {:updated, artifact} -> {:updated, ref(source, name), artifact, []}
      {:error, reason} -> {:error, ref(source, name), reason}
    end
  rescue
    error -> {:error, ref(source, name), Exception.message(error)}
  end

  defp online_result({source, name}, manifest, styles) do
    with {:ok, contract, contract_bytes, port} <- inputs(source, name),
         {:ok, files} <- upstream_files(contract, manifest),
         {:ok, base_ui} <- base_ui_files(contract, manifest),
         result <-
           Converter.sync(%{
             source: source,
             name: name,
             files: files,
             styles: styles,
             base_ui: base_ui,
             contract: contract,
             port: port
           }) do
      normalize(result, source, name, contract_bytes, port)
    else
      {:error, reason} -> {:error, ref(source, name), reason}
    end
  rescue
    error -> {:error, ref(source, name), Exception.message(error)}
  end

  defp inputs(source, name) do
    contract_path = spec_path(source, name)
    port_path = module_path(source, name)
    contract_bytes = File.read!(contract_path)
    contract = Jason.decode!(contract_bytes)

    if contract["schema_version"] != 2 do
      {:error, "the contract is not schema version 2"}
    else
      {:ok, contract, contract_bytes, File.read!(port_path)}
    end
  end

  defp offline_sync(contract, port) do
    case Converter.sync(%{mode: :offline, contract: contract, port: port}) do
      {:current, artifact} -> {:ok, artifact}
      {:error, diagnostics} -> {:error, diagnostics_message(diagnostics)}
    end
  end

  defp byte_current(contract_bytes, port, artifact) do
    if contract_bytes == artifact.contract_json and port == artifact.port,
      do: :ok,
      else: {:updated, artifact}
  end

  defp upstream_files(contract, manifest) do
    {:ok,
     contract["upstream"]
     |> Map.keys()
     |> Enum.sort()
     |> Map.new(&{&1, source!(manifest, &1)})}
  rescue
    error -> {:error, Exception.message(error)}
  end

  defp base_ui_files(contract, manifest) do
    {:ok,
     contract
     |> Map.get("base_ui", %{})
     |> Map.keys()
     |> Enum.sort()
     |> Map.new(fn name -> {name, source!(manifest, "base_ui/#{name}.md")} end)}
  rescue
    error -> {:error, Exception.message(error)}
  end

  defp normalize({:current, artifact}, source, name, contract_bytes, port) do
    case byte_current(contract_bytes, port, artifact) do
      :ok -> {:current, ref(source, name), artifact}
      {:updated, artifact} -> {:updated, ref(source, name), artifact, []}
    end
  end

  defp normalize({:updated, artifact, changes}, source, name, _contract_bytes, _port),
    do: {:updated, ref(source, name), artifact, changes}

  defp normalize({:manual, drift}, source, name, _contract_bytes, _port),
    do: {:manual, ref(source, name), drift}

  defp normalize({:error, diagnostics}, source, name, _contract_bytes, _port),
    do: {:error, ref(source, name), diagnostics_message(diagnostics)}

  defp source!(manifest, file) do
    entry = get_in(manifest, ["files", file]) || raise "#{file} is not in registry/UPSTREAM.json"
    path = registry_path(["upstream", file])
    body = File.read!(path)

    if entry["sha256"] != digest(body) do
      raise "#{file} does not match its digest; run `mix ui.fetch`"
    end

    body
  end

  defp styles!(manifest) do
    manifest
    |> Map.get("files", %{})
    |> Map.keys()
    |> Enum.filter(&String.starts_with?(&1, "shadcn/styles/"))
    |> Enum.sort()
    |> Map.new(fn file ->
      {Path.basename(file, ".css"), manifest |> source!(file) |> Style.rules()}
    end)
  end

  defp finish(results, check?) do
    problems = Enum.filter(results, &match?({kind, _, _} when kind in [:manual, :error], &1))
    updates = Enum.filter(results, &match?({:updated, _, _, _}, &1))

    cond do
      problems != [] ->
        Mix.raise(problem_message(problems))

      check? and updates != [] ->
        names = Enum.map_join(updates, ", ", fn {:updated, name, _, _} -> name end)
        Mix.raise("stale ports: #{names}. Run `mix ui.spec`.")

      check? ->
        Mix.shell().info("every port is current (#{length(results)})")

      true ->
        Enum.each(updates, &write_update/1)
        Mix.shell().info("synchronized #{length(updates)} port(s)")
    end
  end

  defp problem_message(problems) do
    Enum.map_join(problems, "\n", fn
      {:manual, name, drift} -> "#{name}: manual upstream drift: #{inspect(drift)}"
      {:error, name, reason} -> "#{name}: #{reason}"
    end)
  end

  defp write_update({:updated, name, artifact, _changes}) do
    {source, component} = parse_ref(name)
    write!(module_path(source, component), artifact.port)
    write!(spec_path(source, component), artifact.contract_json)
  end

  defp diagnostics_message(diagnostics) do
    Enum.map_join(diagnostics, "\n", fn
      %{message: message} -> message
      %{"message" => message} -> message
      diagnostic -> inspect(diagnostic)
    end)
  end
end
