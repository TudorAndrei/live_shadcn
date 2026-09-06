defmodule LiveShadcnTools.PlaywrightReport do
  @moduledoc """
  Maps a Playwright JSON report to the component that each test checks.

  A full browser run contains component tests and repository-wide checks. A
  component result must include only its own tests. An unmatched failure stays
  visible as a suite failure instead of changing every component status.
  """

  @type check :: map()
  @type result :: %{components: %{String.t() => check()}, global_failures: [String.t()]}

  alias LiveShadcnTools.BrowserVerification

  @spec results(map(), [String.t()]) :: result()
  def results(report, component_names) do
    components = MapSet.new(component_names)

    report
    |> Map.get("suites", [])
    |> specs([])
    |> Enum.reduce(%{components: %{}, global_failures: []}, fn {parents, spec}, result ->
      check = check(spec)

      case {component(spec, parents, components), check} do
        {nil, %{"pass" => true}} ->
          result

        {nil, _failed} ->
          Map.update!(result, :global_failures, &(&1 ++ [check["detail"]]))

        {name, _check} ->
          update_in(result, [:components], fn current ->
            Map.update(current, name, check, &BrowserVerification.merge_checks([&1, check]))
          end)
      end
    end)
  end

  @doc false
  @spec example_results(map(), [String.t()]) :: result()
  def example_results(report, example_names) do
    examples = MapSet.new(example_names)

    report
    |> Map.get("suites", [])
    |> specs([])
    |> Enum.reduce(%{components: %{}, global_failures: []}, fn {_parents, spec}, result ->
      check = check(spec)

      case {example(spec, examples), check["pass"]} do
        {nil, true} ->
          result

        {nil, false} ->
          Map.update!(result, :global_failures, &(&1 ++ [check["detail"]]))

        {name, _pass} ->
          update_in(result, [:components], fn current ->
            Map.update(current, name, check, &BrowserVerification.merge_checks([&1, check]))
          end)
      end
    end)
  end

  @doc "Maps a completed small-batch report to its selected example evidence."
  @spec incremental_example_results(map(), String.t(), [String.t()]) :: result()
  def incremental_example_results(report, layer, example_names)

  def incremental_example_results(report, "interaction", example_names) do
    examples = MapSet.new(example_names)

    report
    |> Map.get("suites", [])
    |> specs([])
    |> Enum.reduce(%{components: %{}, global_failures: []}, fn {_parents, spec}, result ->
      check = check(spec)

      case interaction_example(spec, examples) do
        nil ->
          if check["pass"] do
            result
          else
            Map.update!(result, :global_failures, &(&1 ++ [check["detail"]]))
          end

        name ->
          update_in(result, [:components], fn current ->
            Map.update(current, name, check, &BrowserVerification.merge_checks([&1, check]))
          end)
      end
    end)
  end

  def incremental_example_results(report, layer, example_names)
      when layer in ["accessibility", "parity", "pixel"],
      do: example_results(report, example_names)

  def incremental_example_results(report, "behavior", [example]) do
    checks =
      report
      |> Map.get("suites", [])
      |> specs([])
      |> Enum.map(fn {_parents, spec} -> check(spec) end)

    case checks do
      [] ->
        %{
          components: %{
            example => %{"pass" => false, "detail" => "behavior report has no test result"}
          },
          global_failures: []
        }

      _ ->
        %{components: %{example => BrowserVerification.merge_checks(checks)}, global_failures: []}
    end
  end

  def incremental_example_results(_report, "behavior", _example_names) do
    raise ArgumentError,
          "named behavior evidence must name exactly one example; import one direct test report at a time"
  end

  def incremental_example_results(_report, layer, _example_names) do
    raise ArgumentError, "unknown incremental verification layer: #{layer}"
  end

  defp specs(suites, parents) do
    Enum.flat_map(suites, fn suite ->
      path = parents ++ [suite["title"]]

      Enum.map(suite["specs"] || [], &{path, &1}) ++
        specs(suite["suites"] || [], path)
    end)
  end

  defp check(spec) do
    tests = spec["tests"] || []
    pass? = tests != [] and Enum.all?(tests, &(&1["status"] == "expected"))

    if pass? do
      %{"pass" => true}
    else
      messages =
        tests
        |> Enum.reject(&(&1["status"] == "expected"))
        |> Enum.flat_map(&(&1["results"] || []))
        |> Enum.flat_map(&(&1["errors"] || []))
        |> Enum.map(& &1["message"])
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()

      %{"pass" => false, "detail" => Enum.join([spec["title"] | messages], "\n")}
    end
  end

  defp component(spec, parents, components) do
    title = spec["title"] || ""

    with nil <- title_component(title),
         nil <- shared_file_component(spec, parents) do
      file_component(spec, components)
    end
  end

  defp title_component(title) do
    cond do
      match = Regex.run(~r/^(.+?) \/ /, title, capture: :all_but_first) ->
        hd(match)

      match =
          Regex.run(
            ~r/^(.+?) unslotted text has React geometry$/,
            title,
            capture: :all_but_first
          ) ->
        hd(match)

      true ->
        nil
    end
  end

  defp example(spec, examples) do
    with [component, example] <-
           Regex.run(
             ~r/^(.+?) \/ (.+?) (?:draws what React draws|paints what React paints|has the .+ contract)$/,
             spec["title"] || "",
             capture: :all_but_first
           ),
         name = "#{component}.#{example}",
         true <- MapSet.member?(examples, name) do
      name
    else
      _ -> nil
    end
  end

  defp interaction_example(spec, examples) do
    with [component, example] <-
           Regex.run(
             ~r/^(.+?) \/ (.+?) keeps inferred interaction semantics$/,
             spec["title"] || "",
             capture: :all_but_first
           ),
         name = "#{component}.#{example}",
         true <- MapSet.member?(examples, name) do
      name
    else
      _ -> nil
    end
  end

  defp shared_file_component(spec, parents) do
    case file_name(spec) do
      "checkbox" ->
        cond do
          "a switch" in parents -> "switch"
          "a radio group" in parents -> "radio-group"
          "a toggle" in parents -> "toggle"
          true -> "checkbox"
        end

      "popover" ->
        if "a tooltip" in parents, do: "tooltip", else: "popover"

      "menu" ->
        "dropdown-menu"

      _other ->
        nil
    end
  end

  defp file_component(spec, components) do
    name = file_name(spec)
    if MapSet.member?(components, name), do: name
  end

  defp file_name(spec) do
    spec
    |> Map.get("file", "")
    |> Path.basename(".spec.mjs")
  end
end
