defmodule LiveShadcnTools.Gen.FormControl do
  @moduledoc """
  The `form-control` recipe: a control that holds a value.

  Base UI documents one attribute contract for every control it publishes —
  `data-checked`, `data-invalid`, `data-required`, `data-filled` and the rest —
  and `Phoenix.HTML.FormField` already carries every fact that contract needs.
  So the recipe's whole job is to join the two:

      <.checkbox field={@form[:subscribe]} />

  ## Three shapes, told apart by the spec

  | The spec says | The component is |
  |---|---|
  | the root's data includes `data-checked` | a checkable control |
  | the root's data includes `data-pressed` | a pressable control |
  | the root renders `<input>` or `<textarea>` | a plain field |

  Nothing else. A part that is none of these — a `<label>`, a field wrapper — is
  markup, and the presentational recipe already knows what to do with markup.

  ## The control and the input

  Base UI's checkbox page says it "renders a `<span>` element and a hidden
  `<input>` beside", and the spec records that. The span is what the class
  strings style and what a screen reader announces; the input is what the form
  submits. `LiveBase.FormControl` keeps them in step.
  """

  alias LiveShadcnTools.Gen.Heex
  alias LiveShadcnTools.Gen.Presentational
  alias LiveShadcnTools.Spec

  # What Phoenix knows about a field, and the attribute Base UI documents for it.
  @from_form %{
    "data-disabled" => "flag(@disabled)",
    "data-readonly" => "flag(@readonly)",
    "data-required" => "flag(@required)",
    "data-invalid" => "flag(@errors != [])",
    "data-valid" => "flag(@errors == [])",
    "data-checked" => "flag(@checked)",
    "data-unchecked" => "flag(not @checked)",
    "data-pressed" => "flag(@checked)",
    "data-indeterminate" => "flag(@indeterminate)",
    "data-orientation" => "@orientation"
  }

  # "Filled" is the same question asked of two different controls: a checkable
  # one is filled when it is on, a text one when it holds anything.
  @filled %{
    field: ~s|flag(@value not in [nil, ""])|,
    checkable: "flag(@checked)",
    pressable: "flag(@checked)"
  }

  # The reader's own history with the control. The server never sees it, so the
  # server never renders it.
  @client ~w(data-dirty data-touched data-focused data-dragging)

  @doc "The module source for one component."
  def module(spec, opts) do
    controls = Enum.filter(spec["parts"], &control?(&1, spec))

    if controls == [] do
      # Nothing here holds a value. That is markup, and markup has a recipe.
      Presentational.module(spec, opts)
    else
      """
      defmodule #{inspect(Keyword.fetch!(opts, :module))} do
      #{moduledoc(spec)}

        use Phoenix.Component

        alias LiveBase.FormControl

      #{Enum.map_join(spec["parts"], "\n", &function(&1, spec))}#{Presentational.variant_table(spec)}
      #{helpers(controls, spec)}
      end
      """
    end
  end

  # A part is a control when the spec says it carries a value: Base UI's own
  # attribute contract is the test, not the part's name.
  defp control?(part, spec), do: kind(part, spec) != :markup

  defp kind(part, spec) do
    root = part["tree"]
    data = documented(root, spec)

    cond do
      "data-checked" in data -> :checkable
      "data-pressed" in data -> :pressable
      Heex.tag_of(root) in ["input", "textarea"] -> :field
      true -> :markup
    end
  end

  defp documented(%{"module" => _} = node, spec),
    do: get_in(spec, ["primitives", Spec.key(node), "data"]) || []

  defp documented(_node, _spec), do: []

  defp function(part, spec) do
    case kind(part, spec) do
      :markup -> Presentational.function(part, spec)
      shape -> control(part, spec, shape)
    end
  end

  defp control(part, spec, shape) do
    name = part["name"]

    """
    #{doc(part, spec, shape)}
    #{declarations(part, spec, shape)}
      def #{name}(assigns) do
        assigns = FormControl.#{from(shape)}(assigns)

        ~H\"\"\"
    #{markup(part, spec, shape)}
        \"\"\"
      end
    """
  end

  defp markup(part, spec, shape) do
    tree = Heex.with_children(part["tree"])
    control = Heex.render(tree, ctx(part, spec, shape))

    if hidden_input?(part, spec),
      do: control <> "\n" <> hidden_input(role!(part["tree"], shape)),
      else: control
  end

  defp ctx(part, spec, shape) do
    %{
      attrs: control_attributes(part, spec, shape),
      children: "{render_slot(@inner_block)}",
      class: "@class",
      params: Map.get(part, "params", %{}),
      contexts: Map.get(part, "contexts", []),
      variants: Presentational.variant_table_of(part, spec),
      client_attributes: [],
      hook_part: nil,
      rest: true
    }
  end

  defp control_attributes(part, spec, shape) do
    node = part["tree"]
    tag = Heex.tag_of(node)

    %{
      Spec.key(node) =>
        identity(shape, tag, role!(node, shape), hidden_input?(part, spec)) ++
          state(node, spec, shape)
    }
  end

  # A plain `<input>` is already the control a form submits and a reader
  # operates. It needs its identity and its value, and nothing else: no role to
  # announce, no click to intercept.
  defp identity(:field, _tag, _role, _input?) do
    [
      {"id", :code, "@id"},
      {"name", :code, "@name"},
      {"value", :code, "@value"},
      {"disabled", :code, "@disabled"},
      {"readonly", :code, "@readonly"},
      {"required", :code, "@required"},
      {"phx-mounted", :code, "FormControl.owned_attributes()"}
    ]
  end

  # A checkable control is a `<span>` a reader operates and an `<input>` a form
  # submits, which is what Base UI documents and what a screen reader needs.
  defp identity(shape, tag, role, input?) do
    native(tag, role) ++
      [
        {"id", :code, "@id"},
        {aria(shape), :code, "to_string(@checked)"},
        {"aria-disabled", :code, "flag(@disabled)"},
        {"phx-click", :code, guarded(command(role, shape, input?))},
        {"phx-mounted", :code, "FormControl.owned_attributes()"}
      ] ++ keyboard(tag, role, shape, input?)
  end

  # A `<button>` is already a button, and already focusable. Saying so again is
  # noise a screen reader reads out.
  @implicit %{"button" => "button", "input" => "checkbox", "a" => "link"}

  defp native(tag, role) do
    if Map.get(@implicit, tag) == role,
      do: [],
      else: [{"role", :text, role}, {"tabindex", :text, "0"}]
  end

  defp guarded(command),
    do: "if(@disabled or @readonly, do: nil, else: #{command})"

  # Choosing a radio is choosing instead of the others, so it is a different
  # command from flipping a checkbox.
  defp command("radio", _shape, _input?), do: "FormControl.select(control: @id, group: @group)"

  defp command(_role, shape, input?) do
    options =
      [if(shape == :pressable, do: "state: :pressed"), if(not input?, do: "input: false")]
      |> Enum.reject(&is_nil/1)
      |> Enum.map_join("", &", #{&1}")

    "FormControl.toggle(control: @id#{options})"
  end

  # A `<button>` activates on Space and Enter by itself. A `<span>` with a role
  # does not, and the APG requires Space for a checkbox, so the recipe binds it.
  defp keyboard(tag, role, shape, input?) do
    if Map.has_key?(@implicit, tag) do
      []
    else
      [
        {"phx-keydown", :code, guarded(command(role, shape, input?))},
        {"phx-key", :text, " "}
      ]
    end
  end

  # The Base UI module names the role: a `radio` is a radio, not a checkbox,
  # and a screen reader announces the two differently. A module the recipe does
  # not recognise is a gap, not something to guess at.
  @roles %{"checkbox" => "checkbox", "switch" => "switch", "radio" => "radio"}

  defp role!(_node, :pressable), do: "button"

  # A plain field is the element it renders, and that element already has a role.
  defp role!(_node, :field), do: nil

  defp role!(%{"module" => module}, _shape) do
    Map.get(@roles, module) ||
      raise """
      the form-control recipe does not know what ARIA role a #{module} has.

      A control announced as the wrong kind of thing is worse than one that is
      not announced. Add it to LiveShadcnTools.Gen.FormControl's @roles.
      """
  end

  defp role!(_node, _shape), do: nil

  defp aria(:pressable), do: "aria-pressed"
  defp aria(_shape), do: "aria-checked"

  # Every attribute the spec says the control carries, minus the three the
  # server cannot know.
  defp state(node, spec, shape) do
    for name <- documented(node, spec), name not in @client do
      case Map.fetch(Map.put(@from_form, "data-filled", @filled[shape]), name) do
        {:ok, expression} ->
          {name, :code, expression}

        :error ->
          raise """
          the form-control recipe does not know how to compute #{name}.

          Base UI documents it, so a shadcn class string may read it. Give
          LiveShadcnTools.Gen.FormControl's @from_form the expression that
          computes it from the form field.
          """
      end
    end
  end

  defp hidden_input?(part, spec) do
    get_in(spec, ["primitives", Spec.key(part["tree"]), "hidden_input"]) == true
  end

  # Base UI's own words: "and a hidden `<input>` beside". It is what a form
  # submits, and it is out of the accessibility tree because the control beside
  # it is already announced.
  defp hidden_input(role) when role in ["checkbox", "switch", "radio"] do
    """
    <input
      type="#{input_type(role)}"
      id={FormControl.input_id(@id)}
      name={@name}
      value={@value}
      checked={@checked}
      disabled={@disabled}
      required={@required}
      tabindex="-1"
      aria-hidden="true"
      class="sr-only"
    />\
    """
  end

  defp hidden_input(_role), do: ""

  # A radio's input is a radio. Sharing a name then makes the browser enforce
  # the same exclusivity the command does, which is one fewer thing to trust.
  defp input_type("radio"), do: "radio"
  defp input_type(_role), do: "checkbox"

  defp from(:field), do: "from_field"
  defp from(_shape), do: "from_checkable"

  defp declarations(part, spec, shape) do
    """
      attr :field, Phoenix.HTML.FormField, default: nil, doc: "A form field. Fills in id, name, value and errors."
      attr :id, :string, default: nil
      attr :name, :string, default: nil
    #{value_attr(shape)}
      attr :errors, :list, default: []
      attr :disabled, :boolean, default: false
      attr :readonly, :boolean, default: false
      attr :required, :boolean, default: false
    #{extra(shape)}#{group_attr(part, shape)}#{own_params(part, spec)}  attr :class, :any, default: nil, doc: "Appended to the class string upstream renders."
      attr :rest, :global, include: #{inspect(Heex.globals(Heex.tag_of(part["tree"])))}
    #{slot(part)}\
    """
  end

  defp value_attr(:field), do: ~s|  attr :value, :any, default: nil, doc: "The field's value."|

  defp value_attr(_shape) do
    ~s|  attr :value, :string, default: "true", doc: "What the form submits when the control is on."\n| <>
      ~s|  attr :checked, :boolean, default: nil|
  end

  defp extra(:checkable), do: "  attr :indeterminate, :boolean, default: false\n"
  defp extra(_shape), do: ""

  defp group_attr(part, shape) do
    if role!(part["tree"], shape) == "radio" do
      ~s|  attr :group, :string, required: true, doc: "The id of the group this radio belongs to."\n|
    else
      ""
    end
  end

  # What the component destructured for itself, beyond what a form field
  # supplies. `type` on an input is upstream's prop, not the form's.
  @supplied ~w(class_name children render id name value checked errors disabled readonly required)

  defp own_params(part, spec) do
    part
    |> Presentational.attributes(spec)
    |> Enum.reject(&(&1.name in @supplied))
    |> Enum.map_join(fn attribute -> "#{Presentational.declaration(attribute)}\n" end)
  end

  defp slot(part) do
    if Heex.marker?(Heex.with_children(part["tree"])), do: "  slot :inner_block\n", else: ""
  end

  # Only when something reads it. A component with no state attributes needs no
  # helper, and an unused one is a compile warning.
  defp helpers(controls, spec) do
    used? =
      Enum.any?(controls, fn part ->
        kind(part, spec) != :field or documented(part["tree"], spec) != []
      end)

    if used? do
      """
        defp flag(true), do: ""
        defp flag(_state), do: nil
      """
    else
      ""
    end
  end

  defp doc(part, spec, shape) do
    summary =
      get_in(spec, ["primitives", Spec.key(part["tree"]), "summary"]) ||
        "The `#{part["tree"]["slot"] || part["name"]}` part."

    """
      @doc \"\"\"
      #{summary}

          <.#{part["name"]} field={@form[:#{field_example(shape)}]} />

    #{note(shape)}  \"\"\"\
    """
  end

  defp note(:field) do
    """
      A `:field` fills in the id, the name, the value, and the errors. Errors
      show only once the form has been used: an untouched form is not a form
      with mistakes in it.
    """
  end

  defp note(_shape) do
    """
      The control a reader sees and the input a form submits are two elements,
      as Base UI documents. Flipping one flips the other, on the client, so a
      click costs no round trip and `phx-change` still fires.

      It needs an accessible name, and a `<label for>` cannot give it one: a
      label names a labelable element, and this is not one. Name it directly:

          <.label id="subscribe-label">Send me the pull requests</.label>
          <.checkbox field={@form[:subscribe]} aria-labelledby="subscribe-label" />
    """
  end

  defp field_example(:pressable), do: "bold"
  defp field_example(:field), do: "email"
  defp field_example(_shape), do: "subscribe"

  defp moduledoc(spec) do
    """
      @moduledoc \"\"\"
      #{Heex.headline(spec)}

      Generated by `mix ui.gen` from `#{Heex.spec_ref(spec)}`. Every
      class string, every `data-slot`, and every data attribute below came from
      upstream. Change the spec or the recipe, not this file.
      \"\"\"\
    """
  end
end
