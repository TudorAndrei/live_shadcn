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
  def module(spec, opts), do: spec |> decorate() |> Presentational.module(opts)

  @doc """
  What this recipe writes, over any markup that draws a separator.

  A component that folds `shadcn/separator` takes the markup and not this, and
  the markup alone is a `<div>` with an attribute the style sheet does not read.
  `checkpoint` drew a separator zero pixels wide until the fold carried it.
  """
  def decorate(spec),
    do: Tree.rename_attr_at_slot(spec, "separator", "orientation", "data-orientation")
end
