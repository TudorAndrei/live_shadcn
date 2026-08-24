defmodule LiveShadcnTools.Gen.RadioGroup do
  @moduledoc """
  The radio group recipe.

  Base UI mounts each radio indicator only for the selected item.
  """

  alias LiveShadcnTools.Gen.FormControl

  @doc "The module source for one radio group component."
  def module(spec, opts) do
    spec
    |> FormControl.module(opts)
    |> String.replace(
      ~s|data-slot="radio-group-indicator"|,
      ~s|:if={@checked} data-slot="radio-group-indicator"|,
      global: false
    )
  end
end
