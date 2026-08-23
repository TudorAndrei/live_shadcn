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

  alias LiveShadcnTools.Gen

  @namespaces %{"shadcn" => LiveShadcn.UI, "ai_elements" => LiveAiElements.Components}

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")
    {opts, names, _} = OptionParser.parse(argv, strict: [check: :boolean])
    check? = Keyword.get(opts, :check, false)

    results = names |> specs() |> Enum.map(&one(&1, check?))

    for {:no_recipe, reference, recipe} <- results,
        do: Mix.shell().info("  skip #{reference}: no `#{recipe}` recipe yet")

    report(results, check?)
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
    namespace = Map.fetch!(@namespaces, source)

    case Gen.module(spec, module: Gen.module_name(namespace, name)) do
      {:error, recipe} ->
        {:no_recipe, ref(source, name), recipe}

      {:ok, rendered} ->
        write_or_check(source, name, rendered, check?)
    end
  rescue
    error -> {:failed, spec_reference(path), first_line(error)}
  end

  # A spec that cannot even be read has no source to name it by, so the path is
  # what identifies it.
  defp spec_reference(path),
    do: ref(Path.basename(Path.dirname(path)), Path.basename(path, ".json"))

  defp first_line(error),
    do: error |> Exception.message() |> String.split("\n") |> Enum.find(&(String.trim(&1) != ""))

  defp write_or_check(source, name, rendered, check?) do
    path = module_path(source, name)

    cond do
      not check? ->
        write!(path, rendered)
        {:wrote, ref(source, name)}

      File.exists?(path) and File.read!(path) == rendered ->
        {:current, ref(source, name)}

      true ->
        {:outdated, ref(source, name)}
    end
  end

  defp report(results, check?) do
    outdated = for {:outdated, reference} <- results, do: reference
    wrote = for {:wrote, reference} <- results, do: reference
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
