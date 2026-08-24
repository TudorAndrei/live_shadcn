defmodule LiveShadcnTools.Gen.Checkbox do
  @moduledoc """
  The checkbox recipe.

  Base UI mounts the indicator only for a checked checkbox. This keeps an
  unchecked control empty and prevents its icon from taking layout space.
  """

  alias LiveShadcnTools.Gen.FormControl
  alias LiveShadcnTools.Gen.Tree

  @doc "The module source for one checkbox component."
  def module(spec, opts) do
    spec
    |> Tree.put_attrs_at_slot("checkbox-indicator", [{":if", :code, "@checked"}])
    |> FormControl.module(opts)
  end
end
