defmodule LiveBase.Combobox do
  @moduledoc """
  The client behavior for a filterable, selectable combobox.

  `LiveShadcn.UI.Combobox` owns markup and styles. This module gives the
  markup one stable hook name, so copied registry components do not need a
  JavaScript implementation of their own.
  """

  @hook "LiveBase.Combobox"

  @doc "The hook name used by the Combobox visible controller anchor."
  def hook, do: @hook

  @doc "Marks state that the client hook owns between LiveView patches."
  def owned_attributes(js \\ %Phoenix.LiveView.JS{}, part)

  def owned_attributes(js, :root),
    do:
      Phoenix.LiveView.JS.ignore_attributes(
        js,
        ["aria-controls", "data-combobox-value", "data-filled", "data-open", "data-closed"],
        []
      )

  def owned_attributes(js, :input),
    do:
      Phoenix.LiveView.JS.ignore_attributes(
        js,
        ["value", "aria-controls", "aria-expanded", "aria-activedescendant", "data-popup-open"],
        []
      )

  def owned_attributes(js, :trigger),
    do:
      Phoenix.LiveView.JS.ignore_attributes(
        js,
        ["aria-controls", "aria-expanded", "data-popup-open", "data-pressed"],
        []
      )

  def owned_attributes(js, :addon),
    do: Phoenix.LiveView.JS.ignore_attributes(js, ["aria-hidden"], [])

  def owned_attributes(js, :label),
    do: Phoenix.LiveView.JS.ignore_attributes(js, ["aria-hidden"], [])

  def owned_attributes(js, :chip),
    do: Phoenix.LiveView.JS.ignore_attributes(js, ["aria-hidden"], [])

  def owned_attributes(js, :chip_remove),
    do: Phoenix.LiveView.JS.ignore_attributes(js, ["tabindex"], [])

  def owned_attributes(js, :clear),
    do: Phoenix.LiveView.JS.ignore_attributes(js, ["data-visible", "hidden", "tabindex"], [])

  def owned_attributes(js, :item),
    do:
      Phoenix.LiveView.JS.ignore_attributes(
        js,
        ["aria-selected", "data-selected", "data-highlighted", "hidden"],
        []
      )

  def owned_attributes(js, :hidden_input),
    do: Phoenix.LiveView.JS.ignore_attributes(js, ["value"], [])
end
