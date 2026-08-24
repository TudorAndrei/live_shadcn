defmodule LiveShadcnTools.Gen.Popover do
  @moduledoc """
  The `popover` recipe: something that opens beside its trigger rather than
  over the whole page. Popover, tooltip, hover card.

  ## Three layers, and why

  Base UI puts a `Positioner` between the trigger and the popup, and it is not
  ceremony. The positioner is what gets moved — `position: fixed`, a computed
  `left` and `top` — and the popup is what gets styled and animated. Trying to
  do both on one element means an animation that fights the position on every
  scroll.

  So the recipe emits all three, and the `LiveBase.Floating` hook moves the
  middle one.

  ## What the caller writes

      <.popover id="details">
        <:trigger>Details</:trigger>
        <:title>Accordion</:title>
        Generated from registry/spec/accordion.json.
      </.popover>

  ## Dismissal

  Escape and a click outside. Both are `JS` commands — `phx-window-keydown` and
  `phx-click-away` — so neither costs a round trip and neither needs the hook.

  Both sit on the element that holds the trigger *and* the popup, not on the
  popup. A click on the trigger is outside the popup, so a click-away bound
  there would close the popover the same click was opening.
  """

  alias LiveShadcnTools.Gen.Heex
  alias LiveShadcnTools.Gen.Presentational
  alias LiveShadcnTools.Spec

  @client_attributes [
    "data-starting-style",
    "data-ending-style",
    "data-side",
    "data-align",
    "data-anchor-hidden",
    "data-instant",
    "data-uncentered"
  ]

  @required %{root: "Root", trigger: "Trigger", popup: "Popup", positioner: "Positioner"}
  @optional %{portal: "Portal", title: "Title", description: "Description", arrow: "Arrow"}

  @doc "The attribute names the client hook owns rather than the server."
  def client_attributes, do: @client_attributes

  @doc """
  The expression that computes an attribute the spec says an element carries.

  Everything about *where* the popup landed belongs to the hook, because none
  of it exists until the popup is on the page.
  """
  def attribute!(name, role)

  def attribute!(name, _role) when name in @client_attributes, do: :client
  def attribute!("data-open", _role), do: {:code, "flag(@open)"}
  def attribute!("data-closed", _role), do: {:code, "flag(not @open)"}
  def attribute!("data-popup-open", _role), do: {:code, "flag(@open)"}
  def attribute!("data-pressed", _role), do: {:code, "flag(@open)"}
  def attribute!("data-disabled", _role), do: {:code, "flag(@disabled)"}
  def attribute!("data-trigger-disabled", _role), do: {:code, "flag(@disabled)"}

  def attribute!(name, role) do
    raise """
    the popover recipe does not know how to compute #{name} on the #{role}.

    Base UI documents the attribute, so a shadcn class string may read it. Give
    LiveShadcnTools.Gen.Popover.attribute!/2 the expression that computes it.
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

      alias LiveBase.Popover

    #{function_doc(spec, name)}
    #{declarations(spec, roles)}
      def #{name}(assigns) do
        ~H\"\"\"
    #{markup(spec, roles)}
        \"\"\"
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
          nil -> raise "#{spec["name"]} has no #{primitive} part, so it is not a popover"
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

  # The content part's tree is already portal, positioner and popup nested; it
  # is rendered whole, with the caller's content placed in the popup.
  defp markup(spec, roles) do
    content =
      render(spec, roles, %{roles.popup | node: roles.popup.part["tree"]}, body(spec, roles),
        at: Spec.key(roles.popup.node)
      )

    """
    <div
      id={@id}
      data-slot="#{slot(roles.root)}"
      phx-window-keydown={Popover.close(@id)}
      phx-key="Escape"
      phx-click-away={Popover.dismiss(@id)}
      {@rest}
    >
    #{render(spec, roles, roles.trigger, "{render_slot(@trigger)}")}
    #{content}
    </div>\
    """
  end

  defp body(spec, roles) do
    [heading(spec, roles), "  {render_slot(@inner_block)}"]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join("\n")
  end

  defp heading(spec, roles) do
    title = if roles[:title], do: render(spec, roles, roles.title, "{render_slot(@title)}")

    description =
      if roles[:description],
        do: render(spec, roles, roles.description, "{render_slot(@description)}")

    case Enum.reject([title, description], &is_nil/1) do
      [] -> nil
      parts -> Enum.join(parts, "\n")
    end
  end

  defp slot(%{node: node}), do: node["slot"]

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
      attrs =
        if role == :trigger,
          do: trigger_attributes(Heex.tag_of(node)),
          else: role_attributes(role)

      {Spec.key(node), attrs ++ documented(spec, node, role)}
    end)
  end

  # What Base UI documents as a prop of a part is a prop, not an HTML
  # attribute. `<Positioner align={align}>` configures the positioning; it does
  # not put `align` on a `<div>`.
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

  defp role_attributes(:root), do: []
  defp role_attributes(:portal), do: []

  # The positioner is what the hook moves. Everything it needs to do that is on
  # the element, so a popover that is never opened costs nothing.
  defp role_attributes(:positioner) do
    [
      {"id", :code, "Popover.positioner_id(@id)"},
      {"hidden", :code, "not @open"},
      {"phx-hook", :code, "Popover.hook()"},
      {"data-lb-anchor", :code, "Popover.trigger_id(@id)"},
      {"data-lb-side", :code, "@side"},
      {"data-lb-align", :code, "@align"},
      {"data-lb-offset", :code, "to_string(@offset)"},
      {"data-lb-autofocus", :code, "flag(@autofocus)"},
      {"phx-mounted", :code, "Popover.owned_attributes(:positioner)"}
    ]
  end

  defp role_attributes(:popup) do
    [
      {"id", :code, "Popover.popup_id(@id)"},
      {"role", :text, "dialog"},
      {"tabindex", :text, "-1"},
      {"hidden", :code, "not @open"},
      # The hook moves the positioner and animates the popup, so it has to be
      # able to find the popup inside it.
      {"data-lb-popup", :bare},
      {"phx-mounted", :code, "Popover.owned_attributes(:popup)"}
    ]
  end

  defp role_attributes(:title), do: [{"id", :code, ~s|@id <> "-title"|}]
  defp role_attributes(:description), do: [{"id", :code, ~s|@id <> "-description"|}]
  defp role_attributes(:arrow), do: [{"data-lb-arrow", :bare}]

  # What ARIA a trigger gets follows the element Base UI says it renders. A
  # `<button>` that opens a dialog is `aria-expanded`; a hover card's trigger is
  # an `<a>`, and a link cannot be expanded — saying so is not a small
  # imprecision, it is an attribute a screen reader will refuse.
  defp trigger_attributes("button") do
    [
      {"id", :code, "Popover.trigger_id(@id)"},
      {"type", :text, "button"},
      {"aria-haspopup", :text, "dialog"},
      {"aria-expanded", :code, "to_string(@open)"},
      {"aria-controls", :code, "Popover.popup_id(@id)"},
      {"phx-click", :code, "if(not @disabled, do: Popover.toggle(@id))"},
      {"phx-mounted", :code, "Popover.owned_attributes(:trigger)"}
    ]
  end

  defp trigger_attributes(_tag) do
    [
      {"id", :code, "Popover.trigger_id(@id)"},
      {"phx-click", :code, "if(not @disabled, do: Popover.toggle(@id))"},
      {"phx-mounted", :code, "Popover.owned_attributes(:trigger)"}
    ]
  end

  # ---- declarations ----

  defp declarations(spec, roles) do
    """
      attr :id, :string, required: true, doc: "Every id inside the popover derives from it."
      attr :open, :boolean, default: false, doc: "Whether it starts open."
      attr :disabled, :boolean, default: false, doc: "Whether the trigger refuses interaction."
      attr :side, :string, default: "bottom", values: ["top", "right", "bottom", "left"],
        doc: "The side asked for. Where it lands is what `data-side` reports."
      attr :align, :string, default: "center", values: ["start", "center", "end"]
      attr :offset, :integer, default: 4, doc: "The gap between the trigger and the popup."
      attr :autofocus, :boolean, default: true,
        doc: "Whether opening moves the focus into the popup. False for a tooltip."
      attr :class, :any, default: nil, doc: "Appended to the popup's class string."
    #{part_classes(spec, roles)}#{own_params(spec, roles)}  attr :rest, :global

      slot :trigger, required: true, doc: "What opens it."
    #{part_slots(roles)}  slot :inner_block, required: true, doc: "The popup's body."
    """
  end

  defp part_slots(roles) do
    for role <- [:title, :description], roles[role], into: "" do
      ~s|  slot :#{role}\n|
    end
  end

  defp part_classes(spec, roles) do
    roles
    |> ordered()
    |> Enum.reject(fn {role, _} -> role in [:root, :popup] end)
    |> Enum.map(fn {_role, %{part: part}} -> class_suffix(spec, part) end)
    |> Enum.reject(&is_nil/1)
    # Two roles can live in one exported part, and one attribute cannot be
    # declared twice.
    |> Enum.uniq()
    |> Enum.map_join(&~s|  attr :#{&1}_class, :any, default: nil\n|)
  end

  defp class_suffix(spec, part) do
    case String.replace_prefix(part["name"], String.replace(spec["name"], "-", "_"), "") do
      "_" <> suffix when suffix != "content" -> suffix
      _ -> nil
    end
  end

  @declared ~w(class_name children render id open disabled side align offset)

  defp own_params(spec, roles) do
    roles
    |> ordered()
    |> Enum.flat_map(fn {_role, %{part: part}} -> Presentational.attributes(part, spec) end)
    |> Enum.uniq_by(& &1.name)
    |> Enum.reject(&(&1.name in @declared))
    |> Enum.sort_by(& &1.name)
    |> Enum.map_join(fn attribute -> "#{Presentational.declaration(attribute)}\n" end)
  end

  # Atoms sort by when the VM first saw them, not by their letters, so the
  # order is made explicit rather than inherited from the map.
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

          <.#{name} id="details">
            <:trigger>Details</:trigger>
            Generated from registry/spec/accordion.json.
          </.#{name}>

      `side` and `align` are what is asked for. Where the popup lands is what
      the browser had room for, and `data-side` reports that.
      \"\"\"\
    """
  end
end
