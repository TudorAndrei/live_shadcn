defmodule LiveBase.Listbox do
  @moduledoc """
  The behavior behind choosing one value from a list: select, combobox,
  native select.

  ## What it adds to a menu

  A listbox opens beside its trigger the way a menu does, and walks its options
  the way a menu walks its items. Two things are its own, and both follow from
  the fact that a listbox *holds a value* where a menu only offers actions:

  **Choosing sets, not just closes.** The chosen option is marked
  `data-selected`, every other option is unmarked, the trigger shows the new
  label, and the hidden input a form submits follows. A menu item that has been
  clicked leaves no trace; a select that has been used has an answer in it.

  **It is a form field.** `LiveBase.FormControl` already knows how to read one
  out of a `Phoenix.HTML.FormField`, and this reuses it rather than growing a
  second way to say the same thing.

  ## The attribute contract

  | Element | Attribute | When |
  |---|---|---|
  | trigger | `data-popup-open` | while open |
  | option | `data-selected` | on the chosen one |
  | option | `data-highlighted` | while the arrow keys are on it |
  | option | `data-disabled` | when it refuses to be chosen |
  """

  alias LiveBase.Popover
  alias Phoenix.LiveView.JS

  @doc "The id of the option at a given value."
  def option_id(listbox, value), do: "#{listbox}-option-#{value}"

  @doc "The id of the hidden input a form submits."
  def input_id(listbox), do: "#{listbox}-input"

  @doc "The id of the element that shows the chosen label."
  def value_id(listbox), do: "#{listbox}-value"

  @doc """
  Chooses an option: marks it, shows it, submits it, and closes the list.

  ## Options

    * `:listbox` — required, the id of the listbox
    * `:value` — required, the value of the option being chosen
    * `:label` — what the trigger should read afterwards. Defaults to the value.
  """
  def choose(js \\ %JS{}, opts) do
    listbox = Keyword.fetch!(opts, :listbox)
    value = Keyword.fetch!(opts, :value)
    option = "##{option_id(listbox, value)}"
    others = "##{Popover.popup_id(listbox)} [role='option']:not(#{option})"

    js
    |> JS.remove_attribute("data-selected", to: others)
    |> JS.set_attribute({"aria-selected", "false"}, to: others)
    |> JS.set_attribute({"data-selected", ""}, to: option)
    |> JS.set_attribute({"aria-selected", "true"}, to: option)
    |> JS.set_attribute({"value", value}, to: "##{input_id(listbox)}")
    |> JS.set_attribute({"data-value", value}, to: "##{Popover.trigger_id(listbox)}")
    |> label(listbox, Keyword.get(opts, :label, value))
    |> JS.dispatch("change", to: "##{input_id(listbox)}", bubbles: true)
    |> Popover.close(listbox)
  end

  # The trigger has to read the chosen label, and there is no attribute for
  # "the text of this element". Two elements — one per label — and only the
  # chosen one shown is what a class string can express.
  defp label(js, listbox, label) do
    JS.set_attribute(js, {"data-label", label}, to: "##{value_id(listbox)}")
  end

  @doc "Marks the attributes the client owns so a server render does not undo a choice."
  def owned_attributes(js \\ %JS{}, part)

  def owned_attributes(js, :option),
    do: JS.ignore_attributes(js, ["data-selected", "aria-selected", "data-highlighted"], [])

  def owned_attributes(js, :value),
    do: JS.ignore_attributes(js, ["data-label"], [])

  def owned_attributes(js, :input),
    do: JS.ignore_attributes(js, ["value"], [])

  def owned_attributes(js, part), do: Popover.owned_attributes(js, part)
end
