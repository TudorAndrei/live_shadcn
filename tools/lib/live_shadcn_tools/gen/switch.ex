defmodule LiveShadcnTools.Gen.Switch do
  @moduledoc """
  The switch recipe.

  Base UI writes checked state on both the switch and its thumb. The stylesheet
  reads the thumb state to translate it.
  """

  alias LiveShadcnTools.Gen.FormControl

  @doc "The module source for one switch component."
  def module(spec, opts) do
    spec
    |> FormControl.module(opts)
    |> String.replace(
      "data-slot=\"switch-thumb\"",
      "data-slot=\"switch-thumb\" data-checked={flag(@checked)} data-unchecked={flag(not @checked)}",
      global: false
    )
  end
end
