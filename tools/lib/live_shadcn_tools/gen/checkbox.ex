defmodule LiveShadcnTools.Gen.Checkbox do
  @moduledoc """
  The checkbox recipe.

  Base UI unmounts the indicator of a checkbox that is not checked. Here it is
  in the DOM and `hidden`, because the client owns this control's state: a click
  flips the attributes without asking the server, and an element that only
  exists when the *server* says checked would never appear. `LiveBase.FormControl`
  flips `hidden` with the rest.
  """

  alias LiveShadcnTools.Gen.FormControl
  alias LiveShadcnTools.Gen.Tree

  @doc "The module source for one checkbox component."
  def module(spec, opts) do
    spec
    |> Tree.put_attrs_at_slot("checkbox-indicator", [{"hidden", :code, "not @checked"}])
    |> FormControl.module(opts)
  end
end
