defmodule LiveShadcnTools.Gen.Separator do
  @moduledoc """
  The separator recipe.

  Base UI writes `data-orientation`. The stylesheet reads that attribute, so a
  presentational element that writes only `orientation` cannot receive its
  horizontal or vertical dimensions.
  """

  alias LiveShadcnTools.Gen.Presentational
  alias LiveShadcnTools.Gen.Tree

  @doc "The module source for one separator component."
  def module(spec, opts) do
    spec
    |> Tree.rename_attr_at_slot("separator", "orientation", "data-orientation")
    |> Presentational.module(opts)
  end
end
