defmodule Mix.Tasks.Ui.Gen do
  @shortdoc "Generate HEEx components from registry/spec"

  @moduledoc """
  Stage 3 of the codegen pipeline.

  Turns each committed spec into a component module in the package that ships
  it. A shadcn component lands in `packages/live_shadcn/priv/registry/`, which
  is the registry `mix ui.add` copies from; an AI Elements component lands in
  `packages/live_ai_elements/lib/`, because that package is an ordinary
  dependency rather than a copy-in.

      mix ui.gen                    # every spec whose recipe exists
      mix ui.gen accordion          # one component
      mix ui.gen shadcn/message     # one component, said unambiguously
      mix ui.gen --check            # exit 1 if any generated file is stale

  A spec whose recipe has not been written yet is reported and skipped. That is
  the normal state between milestones: the spec is data and lands as soon as
  upstream has it, the recipe is a decision and lands when somebody makes it.

  Nothing in the output is edited by hand. `--check` in CI is what keeps that
  true: an edited file no longer matches what the spec produces, and the build
  says so.
  """
  use Mix.Task

  import LiveShadcnTools

  alias LiveShadcnTools.Converter
  alias LiveShadcnTools.Gen

  @namespaces %{"shadcn" => LiveShadcn.UI, "ai_elements" => LiveAiElements.Components}

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")
    {opts, names, _} = OptionParser.parse(argv, strict: [check: :boolean])
    check? = Keyword.get(opts, :check, false)

    results =
      names
      |> specs()
      |> Enum.flat_map(&List.wrap(one(&1, check?)))
      |> without_missing_siblings(check?)

    for {:no_recipe, reference, recipe} <- results,
        do: Mix.shell().info("  skip #{reference}: no `#{recipe}` recipe yet")

    for {:removed, reference} <- results,
        do: Mix.shell().info("  removed #{reference}: its recipe no longer generates it")

    report(results, check?)
  end

  # A recipe that draws one component out of another component's anatomy needs
  # that other spec. `sonner` is the case: it renders a stack whose parts are
  # the toast's, because sonner itself exposes only a manager and the server
  # owns the list. Committed specs are what it reads, the same as everything
  # else in this stage — the generator still never reads a `.tsx`.
  defp resolve_spec(source, name) do
    path = spec_path(source, name)
    if File.exists?(path), do: read_json!(path)
  end

  defp specs([]) do
    registry_path("spec")
    |> Path.join("*/*.json")
    |> Path.wildcard()
    |> Enum.sort()
  end

  defp specs(names) do
    for argument <- names, {source, name} = resolve(argument), do: spec_path(source, name)
  end

  # One component the generator cannot produce is a gap in a recipe, not a
  # reason to leave the rest ungenerated. It is reported by name and the run
  # continues.
  defp one(path, check?) do
    spec = read_json!(path)
    %{"name" => name, "source" => source} = spec

    if spec["schema_version"] == 2 do
      port = module_path(source, name) |> File.read!()

      case Converter.sync(%{mode: :offline, contract: spec, port: port}) do
        {:current, artifact} -> write_or_check(source, name, artifact.port, check?)
        {:error, diagnostics} -> raise diagnostics_message(diagnostics)
      end
    else
      namespace = Map.fetch!(@namespaces, source)

      case Gen.module(spec, module: Gen.module_name(namespace, name), resolve: &resolve_spec/2) do
        {:error, recipe} ->
          {:no_recipe, ref(source, name), recipe}

        {:ok, rendered} ->
          write_or_check(source, name, rendered, check?)
      end
    end
  rescue
    error ->
      reference = spec_reference(path)
      stale(reference, check?) ++ [{:failed, reference, first_line(error)}]
  end

  # A component that calls a sibling which did not generate.
  #
  # `reachable!/1` refuses a call into another package. This refuses the other
  # half: `agent` renders `code-block`, they ship in the same package, and while
  # `code-block` has no recipe the `agent` that generated named a module nothing
  # defines. The package stopped compiling, which is a late and confusing way to
  # learn that one component is missing.
  #
  # It settles rather than passing once, because dropping `code-block` drops
  # `tool` with it and dropping `tool` drops `sandbox`.
  defp without_missing_siblings(results, check?) do
    tried = MapSet.new(Enum.map(results, &named/1))

    calls =
      for {state, reference, rendered} <- results,
          state in [:wrote, :current, :outdated],
          into: %{},
          do: {reference, calls_of(reference, rendered)}

    kept = settled(calls |> Map.keys() |> MapSet.new(), calls, tried)

    Enum.flat_map(results, fn result ->
      reference = made(result)

      if reference && not MapSet.member?(kept, reference) do
        missing = Enum.reject(Map.fetch!(calls, reference), &satisfied?(&1, kept, tried))

        stale(reference, check?) ++
          [
            {:failed, reference,
             "it renders #{Enum.join(missing, ", ")}, which does not generate."}
          ]
      else
        [result]
      end
    end)
  end

  defp made({state, reference, _rendered}) when state in [:wrote, :current, :outdated],
    do: reference

  defp made(_result), do: nil

  defp named({_state, reference}), do: reference
  defp named({_state, reference, _more}), do: reference

  # What the module names, read off the module this run produced rather than off
  # the spec. A recipe that folds decides for itself which of a spec's
  # references it draws and which it leaves to the caller to compose — `plan`
  # has a `shimmer` in its spec and no `Shimmer` in its markup — so the spec
  # says what upstream renders and only the written module says what it calls.
  @calls ~r/\b(LiveAiElements\.Components|LiveShadcn\.UI)\.([A-Z][A-Za-z0-9]*)\./

  defp calls_of(reference, rendered) do
    @calls
    |> Regex.scan(rendered, capture: :all_but_first)
    |> Enum.map(fn [namespace, module] -> ref(package(namespace), dashed(module)) end)
    |> Enum.uniq()
    |> List.delete(reference)
  end

  defp package("LiveAiElements.Components"), do: "ai_elements"
  defp package(_namespace), do: "shadcn"

  defp dashed(module), do: module |> Macro.underscore() |> String.replace("_", "-")

  defp settled(kept, calls, tried) do
    smaller =
      for {reference, called} <- calls,
          Enum.all?(called, &satisfied?(&1, kept, tried)),
          into: MapSet.new(),
          do: reference

    if MapSet.size(smaller) == MapSet.size(kept),
      do: kept,
      else: settled(smaller, calls, tried)
  end

  # A call this run generated, or one this run never looked at whose module is
  # on disk from a run before it: `mix ui.gen accordion` generates one component
  # and the rest of the package is still there.
  #
  # A component this run *did* look at is judged by `kept` alone. Its file is on
  # disk either way at this point — the run wrote it before this pass decided
  # whether to take it back — so asking the file system would answer yes about a
  # module that is one line below from being deleted.
  defp satisfied?(reference, kept, tried) do
    {source, name} = parse_ref(reference)

    MapSet.member?(kept, reference) or
      (not MapSet.member?(tried, reference) and File.exists?(module_path(source, name)))
  end

  # A module left over from a run that could still generate it. Nothing else
  # would remove it: the file compiles into a package, so a stale one breaks the
  # build or, worse, keeps working while the spec it claims to come from has
  # moved on. The generator owns these files, so it takes this one back.
  defp stale(reference, check?) do
    {source, name} = parse_ref(reference)
    path = module_path(source, name)

    cond do
      not File.exists?(path) ->
        []

      check? ->
        [{:leftover, reference}]

      true ->
        File.rm!(path)
        [{:removed, reference}]
    end
  end

  # A spec that cannot even be read has no source to name it by, so the path is
  # what identifies it.
  defp spec_reference(path),
    do: ref(Path.basename(Path.dirname(path)), Path.basename(path, ".json"))

  defp first_line(error),
    do: error |> Exception.message() |> String.split("\n") |> Enum.find(&(String.trim(&1) != ""))

  defp diagnostics_message(diagnostics) do
    Enum.map_join(diagnostics, "\n", &diagnostic_message/1)
  end

  defp diagnostic_message(%{message: message}), do: message
  defp diagnostic_message(%{"message" => message}), do: message
  defp diagnostic_message(diagnostic), do: inspect(diagnostic)

  # The rendered source travels with the result, because the pass that refuses a
  # component calling a sibling that did not generate has to read what this run
  # produced. Under `--check` nothing is written, so the file on disk is either
  # the previous run's answer or not there at all — and a component that is
  # absent because it cannot generate would have looked like one that calls
  # nothing.
  defp write_or_check(source, name, rendered, check?) do
    path = module_path(source, name)

    cond do
      not check? ->
        write!(path, rendered)
        {:wrote, ref(source, name), rendered}

      File.exists?(path) and File.read!(path) == rendered ->
        {:current, ref(source, name), rendered}

      true ->
        {:outdated, ref(source, name), rendered}
    end
  end

  defp report(results, check?) do
    # A module whose bytes no longer match its spec, and a module still on disk
    # for a component that no longer generates. Both are the same answer under
    # `--check`: what is committed is not what this pipeline produces.
    outdated =
      for({:outdated, reference, _rendered} <- results, do: reference) ++
        for {:leftover, reference} <- results, do: reference

    wrote = for {:wrote, reference, _rendered} <- results, do: reference
    failed = for {:failed, reference, why} <- results, do: "#{reference}: #{why}"

    if failed != [] do
      Mix.shell().error("""

      #{length(failed)} component(s) the recipe cannot generate yet:

        #{Enum.join(failed, "\n  ")}
      """)
    end

    cond do
      check? and outdated != [] ->
        Mix.raise("""
        generated components do not match their spec: #{Enum.join(outdated, ", ")}

        Either the spec changed and `mix ui.gen` has not run, or the file was
        edited by hand. Generated files are not edited by hand.
        """)

      check? ->
        Mix.shell().info("every generated component matches its spec")

      true ->
        Mix.shell().info("generated #{length(wrote)} component(s): #{Enum.join(wrote, ", ")}")
    end
  end
end
