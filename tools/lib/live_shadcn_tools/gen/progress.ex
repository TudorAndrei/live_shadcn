defmodule LiveShadcnTools.Gen.Progress do
  @moduledoc """
  The progress recipe.

  Base UI writes the indicator width from the root value. The value is server
  data in LiveView, so the root writes one CSS variable and each indicator
  reads it. The remaining parts are ordinary presentational markup.
  """

  alias LiveShadcnTools.Gen.Presentational
  alias LiveShadcnTools.Gen.Tree
  alias LiveShadcnTools.Spec

  @doc "The module source for one progress component."
  def module(spec, opts) do
    root = part!(spec, "progress")
    indicator = part!(spec, "progress_indicator")

    spec
    |> Tree.drop_attr_at_slot("progress", "value")
    |> Presentational.module(
      Keyword.put(opts, :attrs, %{
        Spec.key(root["tree"]) => [{"style", :code, "\"--progress-value: \#{@value}\""}],
        Spec.key(indicator["tree"]) => [
          {"style", :text, "width: calc(var(--progress-value) * 1%)"}
        ]
      })
    )
  end

  defp part!(spec, name), do: Enum.find(spec["parts"], &(&1["name"] == name))
end
