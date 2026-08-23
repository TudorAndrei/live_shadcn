defmodule LiveBase.FormControl do
  @moduledoc """
  The behavior behind a control that holds a value: checkbox, switch, radio,
  toggle, and the plain inputs beside them.

  ## What the recipe owns

  A form control is a value plus what a form knows about it. Base UI documents
  that as one set of attributes, shared by every control it publishes:

  | Attribute | When |
  |---|---|
  | `data-checked` / `data-unchecked` | the value, for a control that has two |
  | `data-disabled`, `data-readonly`, `data-required` | how it may be used |
  | `data-valid` / `data-invalid` | whether the form accepted it |
  | `data-filled` | whether it holds anything |
  | `data-dirty`, `data-touched`, `data-focused` | what the reader has done to it |

  The first five come from the server: they are the form's own state, and
  `Phoenix.HTML.FormField` already carries every one of them. The last three are
  the reader's own history with the control, which the server never sees, so
  they are set on the client and only there.

  ## The control and the input

  Base UI's checkbox renders a `<button role="checkbox">` and a hidden
  `<input>`. That is not decoration: a `<button>` is what the class strings
  style and what a screen reader announces, and the `<input>` is what a form
  submits. `live_shadcn` renders both, and keeps them in step.

  Flipping the button's own attributes is a `JS` command. So is flipping the
  input, because the reader never touches it directly: its `checked` property
  still follows its attribute, and the `change` event the command dispatches is
  what makes `phx-change` fire.
  """

  import Phoenix.Component, only: [assign: 3]

  alias Phoenix.LiveView.JS

  @doc """
  Fills a control's assigns in from `:field`.

  A `Phoenix.HTML.FormField` already carries the id, the name, the value and the
  errors. Anything the caller set explicitly wins, so a control can still be
  used without a form at all.

  Errors are only shown once the form has been used. An untouched form is not a
  form with mistakes in it, and marking it `data-invalid` on first paint says
  otherwise.
  """
  def from_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> identity(field)
    |> assign(:value, assigns[:value] || Phoenix.HTML.Form.normalize_value("text", field.value))
  end

  def from_field(assigns), do: assign(assigns, :id, assigns[:id] || assigns[:name])

  @doc """
  Fills a checkable control's assigns in from `:field`.

  The same as `from_field/1`, except that `:value` is what the form submits when
  the control is on — `"true"`, usually — rather than the field's current value.
  What the field holds decides `:checked` instead.
  """
  def from_checkable(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> identity(field)
    |> assign(:checked, checked(assigns[:checked], field.value))
  end

  def from_checkable(assigns) do
    assigns
    |> assign(:checked, assigns[:checked] == true)
    |> assign(:id, assigns[:id] || assigns[:name])
  end

  defp identity(assigns, field) do
    assigns
    |> assign(:id, assigns[:id] || field.id)
    |> assign(:name, assigns[:name] || field.name)
    |> assign(:errors, assigns[:errors] ++ errors(field))
    |> assign(:field, nil)
  end

  defp checked(nil, value), do: value in [true, "true", "on", 1, "1"]
  defp checked(checked, _value), do: checked == true

  defp errors(%{errors: errors} = field) do
    if Phoenix.Component.used_input?(field), do: Enum.map(errors, &message/1), else: []
  end

  defp message({message, options}) do
    Regex.replace(~r/%\{(\w+)\}/, message, fn _whole, key ->
      options |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
    end)
  end

  defp message(message) when is_binary(message), do: message

  @doc "The id of the hidden input that carries a control's value."
  def input_id(control), do: "#{control}-input"

  @doc """
  Flips a two-state control: the button a reader sees and the input a form
  submits.

  ## Options

    * `:control` — required, the id of the control element
    * `:state` — `:checked` for a checkbox or switch, `:pressed` for a toggle.
      Defaults to `:checked`.
    * `:input` — whether there is a hidden input beside the control. Base UI
      documents which controls have one, and a toggle does not.
    * `:change` — whether to tell the form. Defaults to `true`, which is what
      makes `phx-change` fire and the server learn the new value.
  """
  def toggle(js \\ %JS{}, opts) do
    control = Keyword.fetch!(opts, :control)
    input = "##{input_id(control)}"
    to = "##{control}"

    js
    |> state(to, Keyword.get(opts, :state, :checked))
    |> JS.toggle_attribute({"data-filled", ""}, to: to)
    |> then(&if Keyword.get(opts, :input, true), do: submit(&1, input, opts), else: &1)
    # Whatever the reader does to a control, they have touched it and changed
    # it.
    |> JS.set_attribute({"data-dirty", ""}, to: to)
    |> JS.set_attribute({"data-touched", ""}, to: to)
  end

  @doc """
  Selects one control in a group and unselects the rest.

  A radio is not a checkbox that happens to look round: choosing one is choosing
  *instead of* the others, and a radio that only checked itself would let a
  reader submit two answers to one question.

  ## Options

    * `:control` — required, the id of the radio
    * `:group` — required, the id of the element that groups them

  The others are found by their role rather than by a list of ids, so a group
  the caller built with a comprehension needs no bookkeeping.
  """
  def select(js \\ %JS{}, opts) do
    control = Keyword.fetch!(opts, :control)
    group = Keyword.fetch!(opts, :group)
    to = "##{control}"
    others = "##{group} [role='radio']:not(#{to})"

    js
    |> JS.set_attribute({"aria-checked", "false"}, to: others)
    |> JS.remove_attribute("data-checked", to: others)
    |> JS.remove_attribute("data-filled", to: others)
    |> JS.set_attribute({"data-unchecked", ""}, to: others)
    |> JS.remove_attribute("checked", to: "##{group} input[type='radio']")
    |> JS.set_attribute({"aria-checked", "true"}, to: to)
    |> JS.set_attribute({"data-checked", ""}, to: to)
    |> JS.set_attribute({"data-filled", ""}, to: to)
    |> JS.remove_attribute("data-unchecked", to: to)
    |> JS.set_attribute({"checked", ""}, to: "##{input_id(control)}")
    |> notify("##{input_id(control)}")
    |> JS.set_attribute({"data-dirty", ""}, to: to)
    |> JS.set_attribute({"data-touched", ""}, to: to)
  end

  # A checkbox is checked or unchecked; a toggle is pressed or not. Base UI
  # names them differently because a screen reader announces them differently,
  # and a control that claimed both would be announced twice.
  defp state(js, to, :checked) do
    js
    |> JS.toggle_attribute({"aria-checked", "true", "false"}, to: to)
    |> JS.toggle_attribute({"data-checked", ""}, to: to)
    |> JS.toggle_attribute({"data-unchecked", ""}, to: to)
  end

  defp state(js, to, :pressed) do
    js
    |> JS.toggle_attribute({"aria-pressed", "true", "false"}, to: to)
    |> JS.toggle_attribute({"data-pressed", ""}, to: to)
  end

  # The reader never touches the hidden input, so its `checked` property still
  # follows its attribute. The `change` event is what makes `phx-change` fire.
  defp submit(js, input, opts) do
    js = JS.toggle_attribute(js, {"checked", ""}, to: input)
    if Keyword.get(opts, :change, true), do: notify(js, input), else: js
  end

  defp notify(js, input), do: JS.dispatch(js, "change", to: input, bubbles: true)

  @doc """
  Marks the attributes the client owns so a server render does not undo a click.

  Only the three the server cannot know. `data-checked` and the validity
  attributes are the form's, and a re-render is exactly when they should be
  corrected.
  """
  def owned_attributes(js \\ %JS{}) do
    JS.ignore_attributes(js, ["data-dirty", "data-touched", "data-focused"], [])
  end

  @doc "Marks a control focused, which Base UI documents and CSS cannot express."
  def focused(js \\ %JS{}, opts) do
    JS.set_attribute(js, {"data-focused", ""}, to: "##{Keyword.fetch!(opts, :control)}")
  end

  @doc "Unmarks a control focused."
  def blurred(js \\ %JS{}, opts) do
    JS.remove_attribute(js, "data-focused", to: "##{Keyword.fetch!(opts, :control)}")
  end
end
