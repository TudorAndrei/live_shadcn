defmodule LiveShadcnTools.PlaywrightReport do
  @moduledoc """
  Maps a Playwright JSON report to the component that each test checks.

  A full browser run contains component tests and repository-wide checks. A
  component result must include only its own tests. An unmatched failure stays
  visible as a suite failure instead of changing every component status.
  """

  @type check :: map()
  @type result :: %{components: %{String.t() => check()}, global_failures: [String.t()]}

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
            Map.update(current, name, check, &merge(&1, check))
          end)
      end
    end)
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

  defp merge(%{"pass" => true}, next), do: next
  defp merge(current, %{"pass" => true}), do: current

  defp merge(current, next) do
    detail =
      [current["detail"], next["detail"]]
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.join("\n")

    %{"pass" => false, "detail" => detail}
  end
end
