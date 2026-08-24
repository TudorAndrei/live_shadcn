defmodule LiveShadcnTools.Gen.Switch do
  @moduledoc """
  The switch recipe.

  Base UI writes checked state on both the switch and its thumb. The stylesheet
  reads the thumb state to translate it.
  """

  alias LiveShadcnTools.Gen.FormControl
  alias LiveShadcnTools.Gen.Tree

  @doc "The module source for one switch component."
  def module(spec, opts) do
    spec
    |> Tree.put_attrs_at_slot("switch-thumb", [
      {"data-checked", :code, "flag(@checked)"},
      {"data-unchecked", :code, "flag(not @checked)"}
    ])
    |> FormControl.module(opts)
  end
end
