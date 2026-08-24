defmodule LiveShadcnTools.Gen.Progress do
  @moduledoc """
  The progress recipe.

  Base UI writes the indicator width from the root value. The value is server
  data in LiveView, so the root writes one CSS variable and each indicator
  reads it. The remaining parts are ordinary presentational markup.
  """

  alias LiveShadcnTools.Gen.Presentational

  @doc "The module source for one progress component."
  def module(spec, opts) do
    spec
    |> Presentational.module(opts)
    |> String.replace(
      " value={@value}",
      " style={\"--progress-value: \#{@value}\"}",
      global: false
    )
    |> String.replace(
      "data-slot={@rest[:\"data-slot\"] || \"progress-indicator\"} class",
      "data-slot={@rest[:\"data-slot\"] || \"progress-indicator\"} style=\"width: calc(var(--progress-value) * 1%)\" class",
      global: false
    )
  end
end
