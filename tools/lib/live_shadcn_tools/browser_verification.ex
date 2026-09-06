defmodule LiveShadcnTools.BrowserVerification do
  @moduledoc """
  Small, lossless operations for browser verification results.

  A component can have more than one preview. Every result must count: a
  failure from one preview cannot be hidden by a later passing preview.
  """

  @doc "Returns the local preview IDs for one Storybook component."
  def examples(previews, key) when is_map(previews) and is_binary(key),
    do: Map.get(previews, key, [])

  @doc "Splits example IDs into sequential browser batches."
  def batches(examples, size) when is_list(examples) and is_integer(size) and size > 0,
    do: Enum.chunk_every(examples, size)

  @doc "Adds a stable check label to a failed result."
  def label(%{"pass" => false} = result, label) do
    detail = Map.get(result, "detail", "failed")
    Map.put(result, "detail", "#{label}: #{detail}")
  end

  def label(result, _label), do: result

  @doc "Combines checks with logical AND and retains all failed details."
  def merge_checks([]), do: %{"pass" => false, "detail" => "no local preview examples"}

  def merge_checks([first | rest]),
    do: Enum.reduce(rest, first, fn next, current -> merge_check(current, next) end)

  @doc "Records the verification meaning after a pixel example was measured."
  def finalize_pixel(result, name, {:skipped, why}) do
    merge_checks([
      result,
      %{"pass" => false, "gated" => false, "detail" => "#{name} is not compared: #{why}"}
    ])
  end

  def finalize_pixel(result, name, :pending) do
    merge_checks([result, %{"pass" => false, "detail" => "measured, not yet gated: #{name}"}])
  end

  def finalize_pixel(result, _name, :compared), do: result

  # Elixir treats `0` as true. A zero entry in pixel-budget.json therefore
  # reaches this function as a budgeted result, but it is the strict comparison
  # mode, not an allowed divergence.
  def finalize_pixel(result, _name, {:budgeted, 0}), do: result

  def finalize_pixel(result, name, {:budgeted, pixels}) when is_integer(pixels) and pixels > 0 do
    merge_checks([
      result,
      %{
        "pass" => false,
        "gated" => false,
        "detail" => "#{name} has a nonzero pixel budget (#{pixels} px)"
      }
    ])
  end

  @doc "Combines Playwright reports without dropping component or global failures."
  def merge_reports(reports) do
    Enum.reduce(reports, %{components: %{}, global_failures: []}, fn report, combined ->
      %{
        components:
          Map.merge(combined.components, report.components, fn _component, left, right ->
            merge_checks([left, right])
          end),
        global_failures: Enum.uniq(combined.global_failures ++ report.global_failures)
      }
    end)
  end

  defp merge_check(%{"pass" => true}, next), do: next
  defp merge_check(current, %{"pass" => true}), do: current

  defp merge_check(current, next) do
    details =
      [current["detail"], next["detail"]]
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.join("\n")

    result = %{"pass" => false, "detail" => details}

    case Enum.find([current["exit"], next["exit"]], &(is_integer(&1) and &1 != 0)) do
      nil -> result
      exit -> Map.put(result, "exit", exit)
    end
  end
end
