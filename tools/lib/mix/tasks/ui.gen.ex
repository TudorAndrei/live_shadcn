defmodule Mix.Tasks.Ui.Gen do
  @shortdoc "Generate HEEx components from registry/spec"

  @moduledoc """
  Stage 3 of the codegen pipeline.

  Turns each committed spec into a component module under
  `packages/live_shadcn/priv/registry/`, which is the registry `mix ui.add`
  copies from.

      mix ui.gen                 # every spec whose recipe exists
      mix ui.gen accordion       # one component
      mix ui.gen --check         # exit 1 if any generated file is stale

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

  @namespace LiveShadcn.UI

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")
    {opts, names, _} = OptionParser.parse(argv, strict: [check: :boolean])
    check? = Keyword.get(opts, :check, false)

    results = names |> specs() |> Enum.map(&one(&1, check?))

    for {:no_recipe, name, recipe} <- results,
        do: Mix.shell().info("  skip #{name}: no `#{recipe}` recipe yet")

    report(results, check?)
  end

  defp specs([]) do
    registry_path("spec")
    |> Path.join("*.json")
    |> Path.wildcard()
    |> Enum.sort()
  end

  defp specs(names), do: Enum.map(names, &registry_path(["spec", "#{&1}.json"]))

  # One component the generator cannot produce is a gap in a recipe, not a
  # reason to leave the rest ungenerated. It is reported by name and the run
  # continues.
  defp one(spec_path, check?) do
    spec = read_json!(spec_path)
    name = spec["name"]

    case Gen.module(spec, module: Gen.module_name(@namespace, name)) do
      {:error, recipe} ->
        {:no_recipe, name, recipe}

      {:ok, source} ->
        write_or_check(name, source, check?)
    end
  rescue
    error -> {:failed, spec_path |> Path.basename(".json"), first_line(error)}
  end

  defp first_line(error),
    do: error |> Exception.message() |> String.split("\n") |> Enum.find(&(String.trim(&1) != ""))

  defp write_or_check(name, source, check?) do
    path = destination(name)

    cond do
      not check? ->
        write!(path, source)
        {:wrote, name}

      File.exists?(path) and File.read!(path) == source ->
        {:current, name}

      true ->
        {:outdated, name}
    end
  end

  defp destination(name) do
    Path.join([
      repo_root(),
      "packages",
      "live_shadcn",
      "priv",
      "registry",
      "#{String.replace(name, "-", "_")}.ex"
    ])
  end

  defp report(results, check?) do
    outdated = for {:outdated, name} <- results, do: name
    wrote = for {:wrote, name} <- results, do: name
    failed = for {:failed, name, why} <- results, do: "#{name}: #{why}"

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
