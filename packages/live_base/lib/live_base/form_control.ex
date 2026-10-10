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

  @doc """
  Fills a radio item's identity and checked state in from its field.

  The item keeps its submitted value. A matching field value selects it unless
  the caller supplies checked state. Items sharing a field get separate ids.
  Without a field, id and name remain optional.
  """
  def from_radio(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    selected = not is_nil(field.value) and to_string(field.value) == assigns.value
    id = assigns[:id] || "#{field.id}_#{Base.encode16(assigns.value, case: :lower)}"

    assigns
    |> identity(field)
    |> assign(:id, id)
    |> assign(:checked, checked(assigns[:checked], selected))
  end

  def from_radio(assigns), do: assign(assigns, :checked, assigns[:checked] == true)

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

    * `:control` — required, the id of the control element. Use nil to target
      the element that runs the command.
    * `:state` — `:checked` for a checkbox or switch, `:pressed` for a toggle.
      Defaults to `:checked`.
    * `:input` — whether there is a hidden input beside the control. A string
      gives its id when it does not use the default derived id. With no control
      id, or a nil input id, the adjacent marked native input carries the value.
      Base UI documents which controls have one, and a toggle does not.
    * `:change` — whether to tell the form. Defaults to `true`, which is what
      makes `phx-change` fire and the server learn the new value.
  """
  def toggle(js \\ %JS{}, opts) do
    control = Keyword.fetch!(opts, :control)

    input =
      case Keyword.get(opts, :input, true) do
        true when is_nil(control) -> :adjacent
        true -> by_id(input_id(control))
        nil -> :adjacent
        false -> nil
        id when is_binary(id) -> by_id(id)
      end

    to = if control, do: by_id(control)

    js
    |> state(to, Keyword.get(opts, :state, :checked))
    |> JS.toggle_attribute({"data-filled", ""}, to: to)
    |> then(&if input, do: submit(&1, input, opts), else: &1)
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

    * `:control` — required, the id of the radio. Use nil for the current
      control and its adjacent native input.
    * `:group` — required, the id of the element that groups them

  The others are found by their role rather than by a list of ids, so a group
  the caller built with a comprehension needs no bookkeeping.
  """
  def select(js \\ %JS{}, opts) do
    control = Keyword.fetch!(opts, :control)
    group = Keyword.fetch!(opts, :group)

    if is_nil(control) do
      js
      |> JS.dispatch("live-base:select-radio", detail: %{group: group})
      |> JS.set_attribute({"data-dirty", ""})
      |> JS.set_attribute({"data-touched", ""})
    else
      select_by_id(js, control, group, Keyword.get(opts, :input, input_id(control)))
    end
  end

  defp select_by_id(js, control, group, input) do
    to = by_id(control)
    group = by_id(group)
    others = "#{group} [role='radio']:not(#{to})"

    js
    |> JS.set_attribute({"aria-checked", "false"}, to: others)
    |> JS.set_attribute({"hidden", ""}, to: indicator(others))
    |> JS.remove_attribute("hidden", to: indicator(to))
    |> JS.remove_attribute("data-checked", to: others)
    |> JS.remove_attribute("data-filled", to: others)
    |> JS.set_attribute({"data-unchecked", ""}, to: others)
    |> JS.remove_attribute("checked", to: "#{group} input[type='radio']")
    |> JS.set_attribute({"aria-checked", "true"}, to: to)
    |> JS.set_attribute({"data-checked", ""}, to: to)
    |> JS.set_attribute({"data-filled", ""}, to: to)
    |> JS.remove_attribute("data-unchecked", to: to)
    |> JS.set_attribute({"checked", ""}, to: by_id(input))
    |> notify(by_id(input))
    |> JS.set_attribute({"data-dirty", ""}, to: to)
    |> JS.set_attribute({"data-touched", ""}, to: to)
  end

  # The tick, which is drawn while the control is on.
  #
  # Base UI unmounts an indicator that is not checked. The client owns this
  # control's state — a click costs no round trip — so an element that only
  # exists when the *server* says checked can never appear on a click. It is in
  # the DOM and `hidden` instead, and these commands flip that with the rest.
  defp indicator(nil), do: {:inner, "[data-slot$='-indicator']"}
  defp indicator(control), do: "#{control} [data-slot$='-indicator']"

  # A checkbox is checked or unchecked; a toggle is pressed or not. Base UI
  # names them differently because a screen reader announces them differently,
  # and a control that claimed both would be announced twice.
  defp state(js, to, :checked) do
    js
    |> JS.toggle_attribute({"aria-checked", "true", "false"}, to: to)
    |> JS.toggle_attribute({"data-checked", ""}, to: to)
    |> JS.toggle_attribute({"data-unchecked", ""}, to: to)
    |> JS.toggle_attribute({"data-checked", ""}, to: thumb(to))
    |> JS.toggle_attribute({"data-unchecked", ""}, to: thumb(to))
    |> JS.toggle_attribute({"hidden", ""}, to: indicator(to))
  end

  defp state(js, to, :pressed) do
    js
    |> JS.toggle_attribute({"aria-pressed", "true", "false"}, to: to)
    |> JS.toggle_attribute({"data-pressed", ""}, to: to)
  end

  defp thumb(nil), do: {:inner, "[data-slot$='-thumb']"}
  defp thumb(control), do: "#{control} [data-slot$='-thumb']"

  # The reader never touches the hidden input, so its `checked` property still
  # follows its attribute. The `change` event is what makes `phx-change` fire.
  defp submit(js, :adjacent, opts) do
    JS.dispatch(js, "live-base:sync-checkable-input",
      detail: %{change: Keyword.get(opts, :change, true)}
    )
  end

  defp submit(js, input, opts) do
    js = JS.toggle_attribute(js, {"checked", ""}, to: input)
    if Keyword.get(opts, :change, true), do: notify(js, input), else: js
  end

  defp notify(js, input), do: JS.dispatch(js, "change", to: input, bubbles: true)

  defp by_id(id) do
    escaped = id |> String.replace("\\", "\\\\") |> String.replace("\"", "\\\"")
    ~s([id="#{escaped}"])
  end

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
