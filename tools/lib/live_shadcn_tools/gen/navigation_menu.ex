defmodule LiveShadcnTools.Gen.NavigationMenu do
  @moduledoc """
  The `navigation-menu` recipe.

  ## A navigation menu is not a menu

  It shares the popover machinery and nothing else. Its root is a `<nav>` rather
  than a `role="menu"`; its trigger sits inside a list item rather than beside
  the popup; and its content is presented through a viewport shared by every
  item. The `menu` recipe has one trigger and one popup, so a navigation menu
  put through it comes out as a `role="menu"` with no list, no items, no
  viewport, no content element — and no room for what the caller passed.

  That is not hypothetical. The component was pointed at the `menu` recipe in
  `registry/INVENTORY.json`, this recipe was deleted as unused, and the markup
  silently lost five elements and the caller's own content. Nothing failed: the
  module compiled and the snapshot was stable.

  ## Every layer comes from the spec

  The recipe assembles the parts; it does not describe them. Not one class
  string is written here, because upstream owns every one of them and a class
  string typed by a person is invisible to `mix ui.drift`.
  """

  alias LiveShadcnTools.Gen.Heex
  alias LiveShadcnTools.Spec

  @required %{
    root: "Root",
    list: "List",
    item: "Item",
    trigger: "Trigger",
    positioner: "Positioner",
    popup: "Popup",
    viewport: "Viewport",
    content: "Content"
  }

  # `Link` is deliberately absent. Upstream's is a styled `<a>` whose
  # `data-active` says "this is the page you are on" — a fact the caller has and
  # the component does not. The caller writes their own links inside the
  # content, so the recipe never renders that part and never has to invent the
  # answer.
  @optional %{portal: "Portal"}

  # `data-instant` is the one worth naming: Base UI sets it when the popup moves
  # from one item to the next without animating, which only the browser knows
  # because it is about the transition that is already running.
  @client_attributes ~w(data-open data-closed data-side data-align data-anchor-hidden
                        data-starting-style data-ending-style data-activation-direction
                        data-instant data-motion)

  @doc "The attribute names the recipe computes, by the role that carries them."
  def attribute!("data-orientation", _role), do: {:code, ~s|@orientation|}
  def attribute!("data-popup-open", :trigger), do: :client
  def attribute!("data-pressed", :trigger), do: :client
  def attribute!("aria-expanded", _role), do: :existing
  def attribute!("data-highlighted", _role), do: :client
  def attribute!("data-disabled", _role), do: {:code, ~s|if(@disabled, do: "")|}
  def attribute!(name, _role) when name in @client_attributes, do: :client
  def attribute!("data-slot", _role), do: :existing

  def attribute!(name, role) do
    raise """
    the navigation-menu recipe does not know how to compute #{name} on the #{role}.

    Base UI documents the attribute, so a shadcn class string may read it. Give
    LiveShadcnTools.Gen.NavigationMenu.attribute!/2 the expression that computes
    it.
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

    #{function_doc(name)}
    #{declarations()}
      def #{name}(assigns) do
        ~H\"\"\"
    #{markup(spec, roles)}
        \"\"\"
      end
    end
    """
  end

  defp roles!(spec) do
    required =
      Map.new(@required, fn {role, primitive} ->
        case find(spec["parts"], primitive) do
          nil -> raise "#{spec["name"]} has no #{primitive} part, so it is not a navigation menu"
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

  # The anatomy upstream draws, nested the way upstream nests it:
  #
  #   nav → ul → li → button
  #   portal → positioner → popup → viewport → content
  #
  # The root's own tree already holds a children marker and a reference to the
  # positioner part, so rendering it with the list inside puts the popup chain
  # where upstream puts it.
  # Two chains, assembled separately and placed side by side inside the `<nav>`,
  # because they need different content and a tree has one children marker:
  #
  #   ul → li → button          the trigger the caller labels
  #   portal → positioner → popup → viewport → content   what it opens
  #
  # The root's own tree names the second chain as a part reference. That
  # reference is dropped and the chain rendered here instead: a reference is a
  # name, not a tree, so a marker cannot be placed inside one — and rendering
  # the reference as it stands is exactly how the caller's content went missing,
  # in markup that compiled and snapshotted cleanly.
  defp markup(spec, roles) do
    trigger = render(spec, roles, roles.trigger, "{render_slot(@trigger)}")
    item = render(spec, roles, roles.item, trigger)
    list = render(spec, roles, roles.list, item)

    content = render(spec, roles, roles.content, "{render_slot(@inner_block)}")
    opened = render_at(spec, roles, roles.positioner, content, Spec.key(roles.viewport.node))

    """
    <div
      id={@id}
      class="contents"
      phx-window-keydown={Popover.close(@id)}
      phx-key="Escape"
      phx-click-away={Popover.dismiss(@id)}
      {@rest}
    >
    #{render(spec, roles, roles.root, list <> "\n" <> opened)}
    </div>\
    """
  end

  # The whole part rather than the one node, with the marker placed at a named
  # element inside it. That is how four nested elements come out as four rather
  # than as one with the rest lost.
  defp render_at(spec, roles, role, children, key) do
    tree =
      role.part["tree"]
      |> Heex.with_children_at(key)
      |> Map.put("merges_class", true)

    draw(spec, roles, role, tree, children)
  end

  # A part reference the recipe assembles itself. Left in, it would draw the
  # popup chain a second time, empty.
  defp without_ref(tree, name) do
    Map.update(tree, "children", [], fn children ->
      children
      |> List.wrap()
      |> Enum.reject(&match?(%{"type" => "part_ref", "part" => ^name}, &1))
    end)
  end

  # The root already holds a children marker — that is where the list goes — and
  # beside it a reference to the part that draws the portal, the positioner, the
  # popup and the viewport. So the caller's content has to reach four elements
  # down, through a reference.
  #
  # `with_children_at` walks a tree, and a `part_ref` is not a tree: it is a
  # name. Rendering the root and hoping the marker lands inside the reference is
  # how the caller's content went missing here in the first place, in markup
  # that compiled and snapshotted cleanly.
  #
  # So the marker is placed in the referenced part *before* the reference is
  # resolved. `Heex.render` looks parts up in `ctx.parts` by name, so handing it
  # a map whose positioner already carries the marker is the same substitution,
  # made where the tree is still a tree.
  defp render(spec, roles, role, children) do
    tree =
      if role == roles.root do
        # Its marker is already there, and its reference to the popup chain is
        # dropped because `markup/2` draws that chain itself.
        without_ref(role.node, roles.positioner.part["name"])
      else
        Heex.with_children(role.node)
      end
      |> Map.put("merges_class", true)

    draw(spec, roles, role, tree, children)
  end

  defp draw(spec, roles, role, tree, children) do
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
      layout_transparent: portal_keys(roles),
      rest: false
    })
  end

  defp portal_keys(roles) do
    case roles[:portal] do
      nil -> []
      portal -> [Spec.key(portal.node)]
    end
  end

  defp class_expression(spec, part) do
    case String.replace_prefix(part["name"], String.replace(spec["name"], "-", "_"), "") do
      "" -> "@class"
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

  # The wrapper above it already carries `@id`, and every derived id — trigger,
  # positioner, popup — hangs off that one. A second id on the `<nav>` would be
  # a third name for the same component.
  defp role_attributes(:root), do: []
  defp role_attributes(:portal), do: []
  defp role_attributes(:list), do: []
  defp role_attributes(:item), do: []
  defp role_attributes(:viewport), do: []
  defp role_attributes(:content), do: [{"hidden", :code, "not @open"}]

  defp role_attributes(:trigger) do
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

  # The popup is not the menu here. A navigation menu's popup is a container for
  # a viewport, and what a reader tabs through is the links the caller wrote —
  # so no roving hook, and no `role="menu"`.
  defp role_attributes(:popup) do
    [
      {"id", :code, "Popover.popup_id(@id)"},
      {"hidden", :code, "not @open"},
      {"data-lb-popup", :bare},
      {"phx-mounted", :code, "Popover.owned_attributes(:popup)"}
    ]
  end

  # ---- declarations ----

  defp declarations do
    """
      attr :id, :string, required: true, doc: "Every id inside the menu derives from it."
      attr :open, :boolean, default: false, doc: "Whether the content starts open."
      attr :disabled, :boolean, default: false, doc: "Whether the trigger refuses interaction."
      attr :orientation, :string, default: "horizontal", values: ["horizontal", "vertical"]
      attr :side, :string, default: "bottom", values: ["top", "right", "bottom", "left"]
      attr :align, :string, default: "start", values: ["start", "center", "end"]
      attr :offset, :integer, default: 8
      attr :class, :any, default: nil, doc: "Appended to the class string upstream renders."
      attr :list_class, :any, default: nil
      attr :item_class, :any, default: nil
      attr :trigger_class, :any, default: nil
      attr :positioner_class, :any, default: nil
      attr :popup_class, :any, default: nil
      attr :viewport_class, :any, default: nil
      attr :content_class, :any, default: nil
      attr :rest, :global

      slot :trigger, required: true, doc: "What opens the navigation content."
      slot :inner_block, required: true, doc: "The navigation content."
    """
  end

  defp function_doc(name) do
    ~s'''
      @doc """
      Navigation links, and the panel one of them opens.

          <.#{name} id="docs">
            <:trigger>Documentation</:trigger>
            <p>The roadmap, the inventory, and the architecture.</p>
          </.#{name}>

      Opening and closing run on the client. The panel is presented through a
      viewport, which is what upstream animates between one item and the next.
      """
    '''
  end

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
