defmodule LiveShadcnTools.Gen.Separator do
  @moduledoc """
  The separator recipe.

  Base UI writes `data-orientation`. The stylesheet reads that attribute, so a
  presentational element that writes only `orientation` cannot receive its
  horizontal or vertical dimensions.
  """

  alias LiveShadcnTools.Gen.Presentational

  @doc "The module source for one separator component."
  def module(spec, opts) do
    spec
    |> Presentational.module(opts)
    |> String.replace(
      " orientation={@orientation}",
      " data-orientation={@orientation}",
      global: false
    )
  end
end
