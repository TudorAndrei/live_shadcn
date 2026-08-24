defmodule LiveShadcnTools.Gen.Listbox do
  @moduledoc """
  The `listbox` recipe: choosing one value from a list. Select, combobox,
  native select.

  ## What it borrows

  Everything about opening: the three layers, the `LiveBase.Floating` hook,
  Escape and click-away, and the arrow keys walking the options. A listbox is a
  menu that remembers what you picked.

  ## What it adds

  A value. The options are a slot with a value and a label, so the caller says
  each one once:

      <.select id="style" field={@form[:style]}>
        <:option value="vega" label="Vega" />
        <:option value="nova" label="Nova" />
      </.select>

  and the recipe wires the four things that follow from choosing one: the
  option is marked, the others are unmarked, the trigger reads the new label,
  and the hidden input a form submits carries the new value.

  ## Why a hidden input

  The trigger is a `<button>`, and a button submits nothing. Base UI's select
  renders an input beside it for exactly this reason, and the spec records that
  the same way it does for a checkbox.
  """

  alias LiveShadcnTools.Gen.Heex
  alias LiveShadcnTools.Gen.Popover
  alias LiveShadcnTools.Gen.Presentational
  alias LiveShadcnTools.Spec

  @client_attributes Popover.client_attributes() ++
                       ["data-highlighted", "data-selected", "data-visible", "data-direction"]

  @required %{root: "Root", trigger: "Trigger", popup: "Popup", positioner: "Positioner"}
  @optional %{
    portal: "Portal",
    option: "Item",
    value: "Value",
    label: "GroupLabel",
    separator: "Separator",
    list: "List"
  }

  @doc "The attribute names the client hook owns rather than the server."
  def client_attributes, do: @client_attributes

  @doc "The expression that computes an attribute the spec says an element carries."
  def attribute!(name, role)

  def attribute!(name, _role) when name in @client_attributes, do: :client
  def attribute!("data-open", _role), do: {:code, "flag(@open)"}
  def attribute!("data-closed", _role), do: {:code, "flag(not @open)"}
  def attribute!("data-popup-open", _role), do: {:code, "flag(@open)"}
  def attribute!("data-pressed", _role), do: {:code, "flag(@open)"}
  def attribute!("data-disabled", :option), do: {:code, "flag(option[:disabled] == true)"}
  def attribute!("data-disabled", _role), do: {:code, "flag(@disabled)"}
  def attribute!("data-readonly", _role), do: {:code, "flag(@readonly)"}
  def attribute!("data-required", _role), do: {:code, "flag(@required)"}
  def attribute!("data-valid", _role), do: {:code, "flag(@errors == [])"}
  def attribute!("data-invalid", _role), do: {:code, "flag(@errors != [])"}
  def attribute!("data-filled", _role), do: {:code, ~s|flag(@value not in [nil, ""])|}

  # The trigger shows a placeholder until something has been chosen, and
  # shadcn styles that state.
  def attribute!("data-placeholder", _role), do: {:code, ~s|flag(@value in [nil, ""])|}
  def attribute!("data-empty", _role), do: {:code, "flag(@option == [])"}
  def attribute!("data-list-empty", _role), do: {:code, "flag(@option == [])"}

  # shadcn styles the trigger against the ARIA attribute, which Base UI does
  # not document. Both are contracts; the class string is the one that breaks.
  def attribute!("aria-invalid", _role), do: {:code, "flag(@errors != [])"}

  # The list's class string styles the trigger it belongs to, so the variant
  # scanner sees `aria-expanded` on the list. It belongs to the trigger, and a
  # `role="listbox"` cannot be expanded.
  def attribute!("aria-expanded", :popup), do: :client

  # What the reader has done to it, and where the popup landed. Neither is a
  # fact the server has.
  def attribute!(name, _role)
      when name in ~w(data-dirty data-touched data-focused data-popup-side),
      do: :client

  def attribute!(name, role) do
    raise """
    the listbox recipe does not know how to compute #{name} on the #{role}.

    Base UI documents the attribute, so a shadcn class string may read it. Give
    LiveShadcnTools.Gen.Listbox.attribute!/2 the expression that computes it.
    """
  end

  @doc "The module source for one component."
  def module(spec, opts) do
    roles = roles!(spec)
    name = String.replace(spec["name"], "-", "_")

    """
    defmodule #{inspect(Keyword.fetch!(opts, :module))} do
    #{moduledoc(spec)}

      use Phoenix.Component

      alias LiveBase.FormControl
      alias LiveBase.Listbox
      alias LiveBase.Popover

    #{function_doc(spec, name)}
    #{declarations(spec, roles)}
      def #{name}(assigns) do
        assigns = FormControl.from_field(assigns)

        ~H\"\"\"
    #{markup(spec, roles)}
        \"\"\"
      end

      # What the trigger reads before anything has been chosen, and after.
      defp label(options, value) do
        case Enum.find(options, &(&1[:value] == value)) do
          nil -> nil
          option -> option[:label] || option[:value]
        end
      end

      defp flag(true), do: ""
      defp flag(_state), do: nil
    #{Presentational.variant_table(spec)}end
    """
  end

  defp roles!(spec) do
    required =
      Map.new(@required, fn {role, primitive} ->
        case find(spec["parts"], primitive) do
          nil -> raise "#{spec["name"]} has no #{primitive} part, so it is not a listbox"
          found -> {role, found}
        end
      end)

    optional =
      for {role, primitive} <- @optional,
          found = find(spec["parts"], primitive),
          into: %{},
          do: {role, found}

    Map.merge(required, optional)
  end

  defp find(parts, primitive) do
    Enum.find_value(parts, fn part ->
      case locate(part["tree"], primitive) do
        nil -> nil
        node -> %{node: node, part: part}
      end
    end)
  end

  defp locate(%{"part" => primitive} = node, primitive), do: node

  defp locate(node, primitive),
    do: node |> Map.get("children") |> List.wrap() |> Enum.find_value(&locate(&1, primitive))

  # ---- markup ----

  defp markup(spec, roles) do
    content =
      render(spec, roles, %{roles.popup | node: roles.popup.part["tree"]}, options(spec, roles),
        at: Spec.key(roles.popup.node)
      )

    """
    <div
      id={@id}
      data-slot="#{root_slot(spec, roles)}"
      phx-window-keydown={Popover.close(@id)}
      phx-key="Escape"
      phx-click-away={Popover.dismiss(@id)}
      {@rest}
    >
    #{render(spec, roles, roles.trigger, trigger_content(spec, roles))}
    #{hidden_input()}
    #{content}
    </div>\
    """
  end

  # A part that renders no element has no `data-slot` of its own, and the
  # wrapper still needs one to be found by.
  defp root_slot(spec, roles), do: roles.root.node["slot"] || spec["name"]

  # The trigger reads the chosen label. It is written into `data-label` by the
  # command and read back by a class string, because no attribute sets text.
  defp trigger_content(spec, roles) do
    if roles[:value],
      do: render(spec, roles, roles.value, "{label(@option, @value) || @placeholder}"),
      else: "  {label(@option, @value) || @placeholder}"
  end

  defp hidden_input do
    """
      <input
        type="hidden"
        id={Listbox.input_id(@id)}
        name={@name}
        value={@value}
        disabled={@disabled}
        required={@required}
        phx-mounted={Listbox.owned_attributes(:input)}
      />\
    """
  end

  defp options(spec, roles) do
    if roles[:option],
      do: render(spec, roles, roles.option, "{option[:label] || option[:value]}"),
      else: "  {render_slot(@inner_block)}"
  end

  defp render(spec, roles, role, children, opts \\ []) do
    tree =
      case Keyword.get(opts, :at) do
        nil -> Heex.with_children(role.node)
        key -> Heex.with_children_at(role.node, key)
      end

    Heex.render(tree, %{
      attrs: attributes(spec, roles),
      props: props(spec, roles),
      parts: Map.new(spec["parts"], &{&1["name"], &1}),
      children: children,
      class: class_expression(spec, role.part),
      params: Map.get(role.part, "params", %{}),
      contexts: Map.get(role.part, "contexts", []),
      variants: Presentational.variant_table_of(role.part, spec),
      client_attributes: @client_attributes,
      hook_part: Spec.key(roles.positioner.node),
      rest: false
    })
  end

  defp class_expression(spec, part) do
    case String.replace_prefix(part["name"], String.replace(spec["name"], "-", "_"), "") do
      "" -> "@class"
      "_content" -> "@class"
      "_" <> suffix -> "@#{suffix}_class"
    end
  end

  defp attributes(spec, roles) do
    Map.new(roles, fn {role, %{node: node}} ->
      {Spec.key(node), role_attributes(role) ++ documented(spec, node, role)}
    end)
  end

  defp props(spec, roles) do
    Map.new(roles, fn {_role, %{node: node}} ->
      names =
        spec
        |> get_in(["primitives", Spec.key(node), "props"])
        |> List.wrap()
        |> Enum.map(& &1["name"])

      {Spec.key(node), names}
    end)
  end

  defp documented(spec, node, role) do
    documented = get_in(spec, ["primitives", Spec.key(node), "data"]) || []
    read = get_in(node, ["reads", "self"]) || []

    (documented ++ read)
    |> Enum.uniq()
    |> Enum.flat_map(fn name ->
      case attribute!(name, role) do
        :client -> []
        {:code, expression} -> [{name, :code, expression}]
      end
    end)
  end

  defp role_attributes(role) when role in [:root, :portal, :list], do: []
  defp role_attributes(:separator), do: [{"role", :text, "separator"}]
  defp role_attributes(:label), do: []

  defp role_attributes(:value), do: [{"id", :code, "Listbox.value_id(@id)"}]

  defp role_attributes(:trigger) do
    [
      {"id", :code, "Popover.trigger_id(@id)"},
      {"type", :text, "button"},
      {"role", :text, "combobox"},
      # The trigger is the control, so the label names the trigger. `:global`
      # lands on the wrapper, which would leave the control itself unnamed.
      {"aria-labelledby", :code, "@labelledby"},
      {"aria-haspopup", :text, "listbox"},
      {"aria-expanded", :code, "to_string(@open)"},
      {"aria-controls", :code, "Popover.popup_id(@id)"},
      {"phx-click", :code, "if(not @disabled, do: Popover.toggle(@id))"},
      {"phx-mounted", :code, "Popover.owned_attributes(:trigger)"}
    ]
  end

  defp role_attributes(:positioner) do
    [
      {"id", :code, "Popover.positioner_id(@id)"},
      {"hidden", :code, "not @open"},
      {"phx-hook", :code, "Popover.hook()"},
      {"data-lb-anchor", :code, "Popover.trigger_id(@id)"},
      {"data-lb-side", :code, "@side"},
      {"data-lb-align", :code, "@align"},
      {"data-lb-offset", :code, "to_string(@offset)"},
      {"data-lb-autofocus", :bare},
      {"phx-mounted", :code, "Popover.owned_attributes(:positioner)"}
    ]
  end

  defp role_attributes(:popup) do
    [
      {"id", :code, "Popover.popup_id(@id)"},
      {"role", :text, "listbox"},
      {"tabindex", :text, "-1"},
      {"hidden", :code, "not @open"},
      {"data-lb-popup", :bare},
      {"phx-hook", :code, ~s|"LiveBase.Roving"|},
      {"data-lb-roving", :text, "option"},
      {"data-lb-orientation", :text, "vertical"},
      {"data-lb-highlight", :text, "data-highlighted"},
      {"phx-mounted", :code, "Popover.owned_attributes(:popup)"}
    ]
  end

  defp role_attributes(:option) do
    [
      {":for", :code, "option <- @option"},
      {"id", :code, "Listbox.option_id(@id, option[:value])"},
      {"role", :text, "option"},
      {"tabindex", :text, "-1"},
      {"aria-selected", :code, "to_string(option[:value] == @value)"},
      {"data-selected", :code, "flag(option[:value] == @value)"},
      {"phx-click", :code, choose()},
      {"phx-mounted", :code, "Listbox.owned_attributes(:option)"}
    ]
  end

  defp choose do
    chosen = "Listbox.choose(listbox: @id, value: option[:value], label: option[:label])"
    "if(option[:disabled] != true, do: #{chosen})"
  end

  # ---- declarations ----

  defp declarations(spec, roles) do
    """
      attr :id, :string, required: true, doc: "Every id inside the listbox derives from it."
      attr :field, Phoenix.HTML.FormField, default: nil, doc: "A form field. Fills in id, name, value and errors."
      attr :name, :string, default: nil
      attr :value, :any, default: nil, doc: "The chosen value."
      attr :placeholder, :string, default: "Select…", doc: "What the trigger reads with nothing chosen."
      attr :labelledby, :string, default: nil, doc: "The id of the label that names it."
      attr :errors, :list, default: []
      attr :open, :boolean, default: false
      attr :disabled, :boolean, default: false
      attr :readonly, :boolean, default: false
      attr :required, :boolean, default: false
      attr :side, :string, default: "bottom", values: ["top", "right", "bottom", "left"]
      attr :align, :string, default: "start", values: ["start", "center", "end"]
      attr :offset, :integer, default: 4
      attr :class, :any, default: nil, doc: "Appended to the list's class string."
    #{part_classes(spec, roles)}#{own_params(spec, roles)}  attr :rest, :global

      slot :option, doc: "One value to choose." do
        attr :value, :string, required: true, doc: "Unique. What the form submits."
        attr :label, :string, doc: "What it reads. Defaults to the value."
        attr :disabled, :boolean
      end

      slot :inner_block, doc: "Anything the options do not cover."
    """
  end

  defp part_classes(spec, roles) do
    roles
    |> ordered()
    |> Enum.reject(fn {role, _} -> role in [:root, :popup] end)
    |> Enum.map(fn {_role, %{part: part}} -> class_suffix(spec, part) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.map_join(&~s|  attr :#{&1}_class, :any, default: nil\n|)
  end

  defp class_suffix(spec, part) do
    case String.replace_prefix(part["name"], String.replace(spec["name"], "-", "_"), "") do
      "_" <> suffix when suffix != "content" -> suffix
      _ -> nil
    end
  end

  @declared ~w(class_name children render id open disabled side align offset name value
               placeholder errors readonly required field labelledby)

  defp own_params(spec, roles) do
    roles
    |> ordered()
    |> Enum.flat_map(fn {_role, %{part: part}} -> Presentational.attributes(part, spec) end)
    |> Enum.uniq_by(& &1.name)
    |> Enum.reject(&(&1.name in @declared))
    |> Enum.sort_by(& &1.name)
    |> Enum.map_join(fn attribute -> "#{Presentational.declaration(attribute)}\n" end)
  end

  # Atoms sort by when the VM first saw them, not by their letters.
  defp ordered(roles), do: Enum.sort_by(roles, fn {role, _} -> Atom.to_string(role) end)

  # ---- documentation ----

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

  defp function_doc(spec, name) do
    """
      @doc \"\"\"
      #{Heex.summary(spec)}

          <.#{name} id="style" field={@form[:style]}>
            <:option value="vega" label="Vega" />
            <:option value="nova" label="Nova" />
          </.#{name}>

      The trigger is a button, and a button submits nothing, so there is a hidden
      input beside it carrying the chosen value. Choosing runs on the client and
      fires `change`, so `phx-change` still sees it.
      \"\"\"\
    """
  end
end
