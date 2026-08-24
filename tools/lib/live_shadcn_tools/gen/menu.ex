defmodule LiveShadcnTools.Gen.Menu do
  @moduledoc """
  The `menu` recipe: a list of things to choose from, opened beside its
  trigger. Dropdown menu, context menu, menubar.

  ## What it borrows and what it adds

  Opening, positioning and dismissal are the popover's, and the recipe reuses
  them rather than writing a second copy: the same three layers, the same
  `LiveBase.Floating` hook, the same Escape and click-away.

  What a menu adds is the list. Items are a slot, so the caller writes what they
  mean once:

      <.dropdown_menu id="actions">
        <:trigger>Actions</:trigger>
        <:item value="regenerate" phx-click="regenerate">Regenerate</:item>
        <:item value="verify" phx-click="verify">Verify</:item>
      </.dropdown_menu>

  ## Moving is not choosing

  The arrow keys walk the items and mark the one arrived at with
  `data-highlighted`, which shadcn styles. They do not choose it: that is a
  separate click or keypress, and only that closes the menu. A set of tabs is
  the other way round — arriving at a tab shows its panel — and the same hook
  does both, told which by one attribute.
  """

  alias LiveShadcnTools.Gen.Heex
  alias LiveShadcnTools.Gen.Popover
  alias LiveShadcnTools.Gen.Presentational
  alias LiveShadcnTools.Spec

  @client_attributes Popover.client_attributes() ++ ["data-highlighted"]

  @required %{root: "Root", trigger: "Trigger", popup: "Popup", positioner: "Positioner"}
  @optional %{portal: "Portal", item: "Item", separator: "Separator", label: "GroupLabel"}

  @doc "The attribute names the client hook owns rather than the server."
  def client_attributes, do: @client_attributes

  @doc "The expression that computes an attribute the spec says an element carries."
  def attribute!(name, role)

  def attribute!(name, _role) when name in @client_attributes, do: :client
  def attribute!("data-open", _role), do: {:code, "flag(@open)"}
  def attribute!("data-closed", _role), do: {:code, "flag(not @open)"}
  def attribute!("data-popup-open", _role), do: {:code, "flag(@open)"}
  def attribute!("data-pressed", _role), do: {:code, "flag(@open)"}
  def attribute!("data-disabled", :item), do: {:code, "flag(item[:disabled] == true)"}
  def attribute!("data-disabled", _role), do: {:code, "flag(@disabled)"}

  # shadcn's own prop, not Base UI's: an inset item lines its text up with the
  # ones that have an icon beside them.
  def attribute!("data-inset", _role), do: {:code, "flag(@inset)"}
  def attribute!("data-variant", _role), do: {:code, "@variant"}
  def attribute!("data-slot", _role), do: :existing

  # The menu's class string styles a submenu trigger inside it, so the variant
  # scanner sees `aria-expanded` on the menu. It belongs to the trigger, which
  # the recipe renders separately; putting it on a `role="menu"` would be ARIA
  # a screen reader refuses.
  def attribute!("aria-expanded", :popup), do: :client

  def attribute!(name, role) do
    raise """
    the menu recipe does not know how to compute #{name} on the #{role}.

    Base UI documents the attribute, so a shadcn class string may read it. Give
    LiveShadcnTools.Gen.Menu.attribute!/2 the expression that computes it.
    """
  end

  @doc "The module source for one component."
  def module(spec, opts) do
    if composition?(spec) do
      # A menubar is not a menu: every part of it is a reference to another
      # component in the registry. That is markup composing something else, and
      # markup already has a recipe.
      Presentational.module(spec, opts)
    else
      menu(spec, opts)
    end
  end

  defp composition?(spec) do
    Enum.all?(spec["parts"], &(&1["tree"]["type"] in ["component_ref", "transparent"]))
  end

  defp menu(spec, opts) do
    roles = roles!(spec)
    name = String.replace(spec["name"], "-", "_")

    """
    defmodule #{inspect(Keyword.fetch!(opts, :module))} do
    #{moduledoc(spec)}

      use Phoenix.Component

      alias LiveBase.Menu
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
    end
    """
  end

  defp roles!(spec) do
    required =
      Map.new(@required, fn {role, primitive} ->
        case find(spec["parts"], primitive) do
          nil -> raise "#{spec["name"]} has no #{primitive} part, so it is not a menu"
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
      render(spec, roles, %{roles.popup | node: roles.popup.part["tree"]}, items(spec, roles),
        at: Spec.key(roles.popup.node)
      )

    """
    <div
      id={@id}
      class="contents"
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

  defp items(spec, roles) do
    if roles[:item],
      do: render(spec, roles, roles.item, "{render_slot(item)}"),
      else: "  {render_slot(@inner_block)}"
  end

  defp render(spec, roles, role, children, opts \\ []) do
    tree =
      case Keyword.get(opts, :at) do
        nil -> Heex.with_children(role.node)
        key -> Heex.with_children_at(role.node, key)
      end
      |> Map.put("merges_class", true)

    Heex.render(tree, %{
      attrs: attributes(spec, roles),
      props: props(spec, roles),
      parts: Map.new(spec["parts"], &{&1["name"], &1}),
      children: children,
      class: class_expression(spec, role.part),
      params: Map.get(role.part, "params", %{}),
      contexts: Map.get(role.part, "contexts", []),
      variants: spec["variants"] || %{},
      client_attributes: @client_attributes,
      hook_part: Spec.key(roles.positioner.node),
      layout_transparent: [Spec.key(roles.portal.node)],
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

      {Spec.key(node), attrs ++ slot_attribute(role) ++ documented(spec, node, role)}
    end)
  end

  defp slot_attribute(role) when role in [:trigger, :popup, :item],
    do: [{"data-slot", :code, "@#{role}_slot"}]

  defp slot_attribute(_role), do: []

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
    read = node |> get_in(["reads", "self"]) |> List.wrap() |> Enum.map(&Spec.read_name/1)

    (documented ++ read)
    |> Enum.uniq()
    |> Enum.flat_map(fn name ->
      case attribute!(name, role) do
        :client -> []
        :existing -> []
        {:code, expression} -> [{name, :code, expression}]
      end
    end)
  end

  defp role_attributes(:root), do: []
  defp role_attributes(:portal), do: []
  defp role_attributes(:separator), do: [{"role", :text, "separator"}]
  defp role_attributes(:label), do: []

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

  # The popup is the menu, and the menu is what the arrow keys walk. The focus
  # starts here so a screen reader announces the menu before its first item.
  defp role_attributes(:popup) do
    [
      {"id", :code, "Popover.popup_id(@id)"},
      {"role", :text, "menu"},
      {"tabindex", :text, "-1"},
      {"hidden", :code, "not @open"},
      {"data-lb-popup", :bare},
      {"phx-hook", :code, "Menu.hook()"},
      {"data-lb-roving", :text, "menuitem"},
      {"data-lb-orientation", :text, "vertical"},
      {"data-lb-loop", :bare},
      {"data-lb-highlight", :text, "data-highlighted"},
      {"phx-mounted", :code, "Popover.owned_attributes(:popup)"}
    ]
  end

  defp role_attributes(:item) do
    [
      {":for", :code, "item <- @item"},
      {"id", :code, "Menu.item_id(@id, item[:value])"},
      {"role", :text, "menuitem"},
      {"tabindex", :text, "-1"},
      {"phx-click", :code,
       ~s|if(item[:disabled] != true, do: Menu.choose(@id, item[:"phx-click"]))|},
      {"phx-mounted", :code, "Menu.owned_attributes(:item)"},
      {:spread, ~s|Map.take(item, [:"phx-value-value", :navigate, :patch, :href])|}
    ]
  end

  # A context menu's trigger is a `<div>`, not a `<button>`, and `aria-expanded`
  # on a plain `<div>` is an attribute a screen reader refuses. Giving it the
  # role it is behaving as makes the same ARIA valid, and makes it operable by
  # keyboard while we are at it.
  defp trigger_attributes("button") do
    [
      {"id", :code, "Popover.trigger_id(@id)"},
      {"type", :text, "button"},
      {"aria-haspopup", :text, "menu"},
      {"aria-expanded", :code, "to_string(@open)"},
      {"aria-controls", :code, "Popover.popup_id(@id)"},
      {"phx-click", :code, "if(not @disabled, do: Popover.toggle(@id))"},
      {"phx-mounted", :code, "Popover.owned_attributes(:trigger)"}
    ]
  end

  defp trigger_attributes(_tag) do
    [{"role", :text, "button"}, {"tabindex", :text, "0"}] ++ trigger_attributes("button")
  end

  # ---- declarations ----

  defp declarations(spec, roles) do
    """
      attr :id, :string, required: true, doc: "Every id inside the menu derives from it."
      attr :open, :boolean, default: false, doc: "Whether it starts open."
      attr :disabled, :boolean, default: false, doc: "Whether the trigger refuses interaction."
      attr :side, :string, default: "bottom", values: ["top", "right", "bottom", "left"]
      attr :align, :string, default: "start", values: ["start", "center", "end"]
      attr :offset, :integer, default: 4
      attr :class, :any, default: nil, doc: "Appended to the menu's class string."
      attr :inset, :boolean, default: false, doc: "Line the text up with items that have an icon."
      attr :trigger_slot, :string, default: #{inspect(roles.trigger.node["slot"])}
      attr :popup_slot, :string, default: #{inspect(roles.popup.node["slot"])}
    #{item_slot_attr(roles)}
    #{part_classes(spec, roles)}#{own_params(spec, roles)}  attr :rest, :global

      slot :trigger, required: true, doc: "What opens it."
    #{item_slot(roles)}  slot :inner_block, doc: "Anything the items do not cover."
    """
  end

  defp item_slot(roles) do
    if roles[:item] do
      """
        slot :item, doc: "One thing to choose. Choosing it closes the menu." do
          attr :value, :string, required: true, doc: "Unique. The item's id derives from it."
          attr :disabled, :boolean, doc: "Whether it refuses to be chosen."
          attr :"phx-click", :any, doc: "What choosing it does, beside closing the menu."
          attr :"phx-value-value", :any
          attr :navigate, :string
          attr :patch, :string
          attr :href, :string
        end
      """
    else
      ""
    end
  end

  defp item_slot_attr(roles) do
    if roles[:item],
      do: ~s|  attr :item_slot, :string, default: #{inspect(roles.item.node["slot"])}\n|,
      else: ""
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

  @declared ~w(class_name children render id open disabled side align offset inset)

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

          <.#{name} id="actions">
            <:trigger>Actions</:trigger>
            <:item value="regenerate" phx-click="regenerate">Regenerate</:item>
            <:item value="verify" phx-click="verify">Verify</:item>
          </.#{name}>

      The arrow keys walk the items and mark the one they arrive at. Choosing is
      a separate gesture, and only choosing closes the menu.
      \"\"\"\
    """
  end
end
