defmodule LiveShadcnTools.Gen.RadioGroup do
  @moduledoc """
  The radio group recipe.

  Base UI unmounts the indicator of every radio but the selected one. Here each
  is in the DOM and `hidden`, for the reason the checkbox recipe gives: the
  client owns which radio is on, and `LiveBase.FormControl.select/2` moves
  `hidden` with the rest of the state.
  """

  alias LiveShadcnTools.Gen.FormControl
  alias LiveShadcnTools.Gen.Tree

  @doc "The module source for one radio group component."
  def module(spec, opts) do
    spec
    |> Tree.put_attrs_at_slot("radio-group-indicator", [{"hidden", :code, "not @checked"}])
    |> FormControl.module(opts)
  end
end
