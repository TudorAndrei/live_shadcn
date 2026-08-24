defmodule LiveShadcnTools.Gen.Checkbox do
  @moduledoc """
  The checkbox recipe.

  Base UI mounts the indicator only for a checked checkbox. This keeps an
  unchecked control empty and prevents its icon from taking layout space.
  """

  alias LiveShadcnTools.Gen.FormControl

  @doc "The module source for one checkbox component."
  def module(spec, opts) do
    spec
    |> FormControl.module(opts)
    |> String.replace(
      "data-slot=\"checkbox-indicator\"",
      ":if={@checked} data-slot=\"checkbox-indicator\"",
      global: false
    )
  end
end
