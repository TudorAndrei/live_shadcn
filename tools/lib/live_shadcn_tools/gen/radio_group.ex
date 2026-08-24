defmodule LiveShadcnTools.Gen.RadioGroup do
  @moduledoc """
  The radio group recipe.

  Base UI mounts each radio indicator only for the selected item.
  """

  alias LiveShadcnTools.Gen.FormControl
  alias LiveShadcnTools.Gen.Tree

  @doc "The module source for one radio group component."
  def module(spec, opts) do
    spec
    |> Tree.put_attrs_at_slot("radio-group-indicator", [{":if", :code, "@checked"}])
    |> FormControl.module(opts)
  end
end
