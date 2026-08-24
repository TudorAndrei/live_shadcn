defmodule LiveShadcnTools.Gen.Disclosure do
  @moduledoc """
  The `disclosure` recipe: a trigger that opens and closes a panel.

  A recipe is the one hand-written, reviewed-once part of the pipeline. It says
  three things and nothing more:

    1. which Base UI part plays which role — root, item, header, trigger, panel
    2. what expression computes each documented attribute
    3. how the parts nest into one component

  Everything else — tags, class strings, `data-slot` values, which element
  merges the caller's class, which element needs a measurement — is read from
  the spec.

  ## One shape or many

  An accordion is a list of items; a collapsible is one panel. Base UI says
  which by whether the component has an `Item` part, so the recipe reads that
  rather than being told:

      <.accordion id="faq">          <.collapsible id="more" title="Details">
        <:item id="q" title="…">…</:item>   …
      </.accordion>                  </.collapsible>

  The two differ only in where the open state lives — in a slot entry or in the
  component's own assigns — so that is the only thing the recipe branches on.

  ## Why one function and not four

  shadcn exports four components and React threads the item's identity between
  them through context. HEEx has no implicit context, so four functions would
  mean the caller repeating an id on each of them, and a broken `aria-controls`
  the first time they mistyped it. `LiveBase.Disclosure` derives every id the
  ARIA contract needs from the one the caller wrote.
  """

  alias LiveShadcnTools.Gen.Heex
  alias LiveShadcnTools.Spec

  @client_attributes ["data-starting-style", "data-ending-style"]

  @required %{root: "Root", trigger: "Trigger", panel: "Panel"}
  @optional %{item: "Item", header: "Header"}

  # How to say "this disclosure's open state" in each of the two shapes.
  @many %{
    subject: "item",
    open: "open?(item)",
    disabled: "disabled?(item)",
    id: "item.id",
    index: "index",
    title: "{item.title}",
    body: "{render_slot(item)}"
  }

  @one %{
    subject: "assigns",
    open: "@open",
    disabled: "@disabled",
    id: "@id",
    index: "0",
    title: "{@title}",
    body: "{render_slot(@inner_block)}"
  }

  @doc "The attribute names the client hook owns rather than the server."
  def client_attributes, do: @client_attributes

  @doc """
  The expression that computes an attribute the spec says an element carries.

  A documented attribute with no entry here is a gap in the recipe, not
  something to leave out, so this raises rather than emit markup that quietly
  fails to match a class string.
  """
  def attribute!(name, role, shape)

  def attribute!(name, _role, _shape) when name in @client_attributes, do: :client
  def attribute!("data-orientation", _role, _shape), do: {:code, "@orientation"}
  def attribute!("data-disabled", :root, _shape), do: {:code, "flag(@disabled)"}
  def attribute!("data-open", _role, shape), do: {:code, "flag(#{shape.open})"}

  # Not a Base UI attribute. The shadcn style sheets read it to pick the
  # collapse animation, which is why the spec records what the sheets read and
  # not only what the `.tsx` does.
  def attribute!("data-closed", _role, shape), do: {:code, "flag(not #{shape.open})"}

  def attribute!("data-panel-open", _role, shape), do: {:code, "flag(#{shape.open})"}
  def attribute!("data-disabled", _role, shape), do: {:code, "flag(#{shape.disabled})"}
  # An ARIA state is a word, not a presence. `data-open=""` is how Base UI marks
  # state and `flag/1` writes it, but `aria-disabled=""` is not a value ARIA
  # defines, and Tailwind compiles `aria-disabled:` to `[aria-disabled="true"]`
  # — so a trigger written that way was disabled and drawn as though it were
  # not. Every one of these reads `to_string`, which is what React writes.
  def attribute!("aria-disabled", _role, shape), do: {:code, "to_string(#{shape.disabled})"}
  def attribute!("data-index", _role, shape), do: {:code, shape.index}

  def attribute!(name, role, _shape) do
    raise """
    the disclosure recipe does not know how to compute #{name} on the #{role}.

    Base UI documents the attribute, so a shadcn class string may read it. Give
    LiveShadcnTools.Gen.Disclosure.attribute!/3 the expression that computes it,
    or the generated component will not match its own styling.
    """
  end

  @doc "The module source for one component."
  def module(spec, opts) do
    roles = roles!(spec)
    shape = if roles[:item], do: @many, else: @one
    name = String.replace(spec["name"], "-", "_")
    markup = markup(spec, roles, shape)
    declarations = declarations(spec, roles, shape)

    """
    defmodule #{inspect(Keyword.fetch!(opts, :module))} do
    #{moduledoc(spec)}

      use Phoenix.Component

      alias LiveBase.Disclosure

    #{function_doc(spec, name, shape)}
    #{declarations}#{undeclared(markup, declarations)}
      def #{name}(assigns) do
        ~H\"\"\"
    #{markup}
        \"\"\"
      end

    #{helpers(shape)}end
    """
  end

  defp helpers(%{subject: "item"}) do
    """
      defp open?(item), do: item[:open] == true
      defp disabled?(item), do: item[:disabled] == true

    #{shared_helpers()}\
    """
  end

  defp helpers(_shape), do: shared_helpers()

  defp shared_helpers do
    """
      # A disabled disclosure ignores interaction. `aria-disabled` and
      # `pointer-events-none` say so to a reader and to a mouse, but a keypress
      # on a focused trigger reaches neither, so the command itself is withheld.
      defp interactive(false, command), do: command
      defp interactive(_disabled, _command), do: nil

      # An HTML attribute with no value, or no attribute at all. Base UI marks
      # state by presence, so `data-open=""` and a missing `data-open` are the
      # two states a shadcn class string distinguishes.
      defp flag(true), do: ""
      defp flag(_state), do: nil
    """
  end

  # A role is found by the Base UI primitive it wraps, never by a name, so a
  # component whose panel is exported under a different name still generates.
  # `Item` and `Header` are optional: a collapsible has neither.
  defp roles!(spec) do
    required =
      Map.new(@required, fn {role, primitive} ->
        case find(spec["parts"], primitive) do
          nil -> raise "#{spec["name"]} has no #{primitive} part, so it is not a disclosure"
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

  defp locate(%{"type" => "primitive", "part" => primitive} = node, primitive), do: node

  defp locate(node, primitive),
    do: node |> Map.get("children") |> List.wrap() |> Enum.find_value(&locate(&1, primitive))

  # ---- markup ----

  defp markup(spec, roles, shape) do
    trigger = render(spec, roles, shape, roles.trigger, shape.title)
    panel = render(spec, roles, shape, roles.panel, shape.body)
    inside = trigger <> "\n" <> panel

    inside =
      case roles[:item] do
        nil -> inside
        item -> render(spec, roles, shape, item, inside)
      end

    render(spec, roles, shape, roles.root, inside, rest: true)
  end

  # A role is rendered from its part's tree, because the part usually holds
  # wrappers above the role that are as much a part of the markup as the role
  # itself: an accordion trigger comes wrapped in its heading.
  #
  # Not when that part wraps its role in a component root of its own. A
  # component has one root and this recipe writes it, so a second one is a
  # second component: `chain-of-thought` puts a whole collapsible inside its
  # header and another inside its content, both driven by one React context,
  # and rendering those trees produced a component containing itself twice.
  # There the role's own node is the whole of what the part contributes.
  defp subtree(role, roles) do
    cond do
      # The root wraps what this recipe assembles, so anything upstream put
      # inside it is being assembled here instead. `chain-of-thought` renders
      # its trigger inside its root in one part, and keeping both drew the
      # trigger twice.
      role == roles.root and holds_another_role?(role, roles) ->
        Map.put(role.node, "children", [])

      role != roles.root and locate(role.part["tree"], "Root") ->
        role.node

      true ->
        role.part["tree"]
    end
  end

  defp holds_another_role?(role, roles) do
    Enum.any?(roles, fn {name, other} ->
      name != :root and contains?(role.node["children"], other.node)
    end)
  end

  defp contains?(node, node), do: true
  defp contains?(nodes, wanted) when is_list(nodes), do: Enum.any?(nodes, &contains?(&1, wanted))

  defp contains?(node, wanted) when is_map(node),
    do: contains?(Map.get(node, "children") || [], wanted)

  defp contains?(_node, _wanted), do: false

  defp render(spec, roles, shape, role, children, opts \\ []) do
    part = role.part

    node =
      role
      |> subtree(roles)
      |> Map.put("merges_class", role == roles.root or role.node["merges_class"] == true)

    Heex.render(Heex.with_children(node), %{
      attrs: attributes(spec, roles, shape),
      children: children,
      class: class_expression(spec, role, roles, shape),
      params: Map.get(part, "params", %{}),
      contexts: Map.get(part, "contexts", []),
      variants: spec["variants"] || %{},
      # Opening and closing is this recipe's, whatever upstream called it. A
      # component that read `isOpen` out of a React context would otherwise
      # grow a second flag beside the one the recipe already sets.
      bindings: %{"isOpen" => "@open", "open" => "@open"},
      client_attributes: @client_attributes,
      hook_part: Spec.key(roles.panel.node),
      rest: Keyword.get(opts, :rest, false)
    })
  end

  # The caller's class goes on the element shadcn merged `className` into. The
  # name it is exposed under follows the part: `accordion_trigger` becomes
  # `trigger_class`, on the item slot or on the component itself.
  # The root is the component, so the caller's own `class` lands there whatever
  # the part it was found in happens to be called.
  defp class_expression(spec, role, roles, shape) do
    if role == roles.root do
      "@class"
    else
      part_class(spec, role.part, shape)
    end
  end

  defp part_class(spec, part, shape) do
    suffix = String.replace_prefix(part["name"], String.replace(spec["name"], "-", "_"), "")

    case {suffix, shape.subject} do
      {"", _} -> "@class"
      {"_item", _} -> "item[:class]"
      {"_" <> name, "item"} -> "item[:#{name}_class]"
      {"_" <> name, _} -> "@#{name}_class"
    end
  end

  defp attributes(spec, roles, shape) do
    Map.new(roles, fn {role, %{node: node}} ->
      {Spec.key(node),
       role_attributes(role, spec, roles, shape) ++ documented(spec, node, role, shape)}
    end)
  end

  # Every data attribute Base UI documents for the part, plus any the class
  # string reads without Base UI documenting it. Both are contracts.
  defp documented(spec, node, role, shape) do
    documented = get_in(spec, ["primitives", Spec.key(node), "data"]) || []
    read = get_in(node, ["reads", "self"]) || []

    (documented ++ read)
    |> Enum.uniq()
    |> Enum.flat_map(fn name ->
      case attribute!(name, role, shape) do
        :client -> []
        {:code, expression} -> [{name, :code, expression}]
      end
    end)
  end

  defp role_attributes(:root, _spec, _roles, _shape), do: [{"id", :code, "@id"}]

  defp role_attributes(:item, _spec, _roles, _shape) do
    [
      {":for", :code, "{item, index} <- Enum.with_index(@item)"},
      {"id", :code, "item.id"},
      {"phx-mounted", :code, "Disclosure.owned_attributes(:item)"}
    ]
  end

  defp role_attributes(:header, _spec, _roles, shape) do
    [
      {"id", :code, "Disclosure.header_id(#{shape.id})"},
      {"phx-mounted", :code, "Disclosure.owned_attributes(:header)"}
    ]
  end

  defp role_attributes(:trigger, _spec, _roles, shape) do
    toggle = "Disclosure.toggle(item: #{shape.id}, root: @id, multiple: #{multiple(shape)})"

    [
      {"id", :code, "Disclosure.trigger_id(#{shape.id})"},
      {"type", :text, "button"},
      {"aria-expanded", :code, "to_string(#{shape.open})"},
      {"aria-controls", :code, "Disclosure.panel_id(#{shape.id})"},
      {"phx-click", :code, "interactive(#{shape.disabled}, #{toggle})"},
      {"phx-mounted", :code, "Disclosure.owned_attributes(:trigger)"}
    ]
  end

  defp role_attributes(:panel, spec, roles, shape) do
    vars = get_in(spec, ["primitives", Spec.key(roles.panel.node), "css_vars"]) || []

    [
      {"id", :code, "Disclosure.panel_id(#{shape.id})"},
      {"role", :text, "region"},
      {"aria-labelledby", :code, labelled_by(roles, shape)},
      {"hidden", :code, "not #{shape.open}"},
      {"phx-hook", :code, "Disclosure.hook()"},
      {"phx-mounted", :code, "Disclosure.owned_attributes(:panel)"}
    ] ++ var_attributes(vars)
  end

  # A single-panel disclosure has no heading of its own, so the trigger is what
  # names the panel.
  defp labelled_by(roles, shape) do
    if roles[:header],
      do: "Disclosure.header_id(#{shape.id})",
      else: "Disclosure.trigger_id(#{shape.id})"
  end

  # One panel cannot close another, so single-panel mode never needs the
  # close-the-others step.
  defp multiple(%{subject: "item"}), do: "@multiple"
  defp multiple(_shape), do: "true"

  # The hook has to be told which variable carries the measurement, because the
  # name belongs to the component, not to the recipe.
  defp var_attributes(vars) do
    Enum.flat_map([{"height", "-height"}, {"width", "-width"}], fn {key, suffix} ->
      case Enum.find(vars, &String.ends_with?(&1, suffix)) do
        nil -> []
        var -> [{"data-lb-#{key}-var", :text, var}]
      end
    end)
  end

  # ---- declarations ----

  # Everything the markup reads and the declarations do not name.
  #
  # A recipe declares the props it knows about, and the markup may read one it
  # does not: `reasoning` renders its panel through the markdown seam, which
  # reads `@content`, and the recipe has never heard of markdown. An assign that
  # is read and not declared raises on the component's first render, which is a
  # browser run away from the generator that wrote it.
  #
  # So what is read is declared. The recipe still names the ones it means
  # something by; this is the remainder, and being the remainder is why it can
  # say nothing about them.
  defp undeclared(markup, declarations) do
    declared =
      ~r/(?:attr|slot)\s+:([a-z_][A-Za-z0-9_]*)/
      |> Regex.scan(declarations, capture: :all_but_first)
      |> List.flatten()

    # A name the markup hands to `render_slot/1` is a slot, and declaring it an
    # attribute makes the component raise on the render prop it was written for.
    rendered =
      ~r/render_slot\(@([a-z_][A-Za-z0-9_]*)\)/
      |> Regex.scan(markup, capture: :all_but_first)
      |> List.flatten()

    ~r/@([a-z_][A-Za-z0-9_]*)/
    |> Regex.scan(markup, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
    |> Kernel.--(declared)
    |> Enum.map_join(fn name ->
      if name in rendered,
        do: "  slot :#{name}\n",
        else: "  attr :#{name}, :any, default: nil\n"
    end)
  end

  defp declarations(spec, roles, %{subject: "item"}) do
    root = props(spec, roles.root)
    item = props(spec, roles.item)

    """
      attr :id, :string, required: true, doc: "The id every item id and ARIA reference is derived from."
    #{prop_attr(root, "multiple", ":boolean", "false")}
    #{prop_attr(root, "disabled", ":boolean", "false")}
    #{prop_attr(root, "orientation", ":string", "\"vertical\"")}
      attr :class, :any, default: nil, doc: "Appended to the class string upstream renders."
      attr :rest, :global

      slot :item, required: true, doc: "One collapsible panel. Its content is the panel body." do
        attr :id, :string, required: true, doc: "Unique. Every id inside the item derives from it."
        attr :title, :any, required: true, doc: "The trigger content."
        attr :open, :boolean, doc: "Whether the panel starts open."
    #{prop_attr(item, "disabled", ":boolean", nil, 4)}
        attr :class, :any, doc: "Appended to the item class string."
        attr :trigger_class, :any, doc: "Appended to the trigger class string."
        attr :content_class, :any, doc: "Appended to the panel class string."
      end
    """
  end

  defp declarations(spec, roles, shape) do
    root = props(spec, roles.root)

    """
      attr :id, :string, required: true, doc: "Every id inside the component derives from it."
      attr :title, :any, required: true, doc: "The trigger content."
    #{prop_attr(root, "defaultOpen", ":boolean", "false", 2, "open")}
    #{prop_attr(root, "disabled", ":boolean", "false")}
    #{prop_attr(root, "orientation", ":string", "\"vertical\"")}
      attr :class, :any, default: nil, doc: "Appended to the class string upstream renders."
    #{class_attrs(spec, roles, shape)}  attr :rest, :global

      slot :inner_block, required: true, doc: "The panel body."
    """
  end

  # One class attribute per part this recipe renders, named the way
  # `class_expression/4` names it. Declaring a fixed pair instead worked until a
  # component had a part the pair did not cover: `chain-of-thought` has a
  # header, the markup read `@header_class`, and the component raised on its
  # first render with the attribute undeclared. The markup and the declaration
  # come from one place now.
  defp class_attrs(spec, roles, shape) do
    roles
    |> Enum.map(fn {_name, role} -> class_expression(spec, role, roles, shape) end)
    |> Enum.flat_map(fn
      "@" <> rest -> if String.ends_with?(rest, "_class"), do: [rest], else: []
      _other -> []
    end)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.map_join(fn name ->
      part = name |> String.replace_suffix("_class", "") |> String.replace("_", " ")
      "  attr :#{name}, :any, default: nil, doc: \"Appended to the #{part} class string.\"\n"
    end)
  end

  defp props(spec, %{node: node}),
    do: Map.new(get_in(spec, ["primitives", Spec.key(node), "props"]) || [], &{&1["name"], &1})

  defp prop_attr(props, name, type, default, indent \\ 2, as \\ nil) do
    doc = get_in(props, [name, "doc"]) || ""
    default = if default, do: ", default: #{default}", else: ""

    String.duplicate(" ", indent) <>
      ~s|attr :#{as || name}, #{type}#{default}, doc: #{inspect(doc)}|
  end

  # ---- documentation ----

  defp moduledoc(spec) do
    """
      @moduledoc \"\"\"
      #{Heex.headline(spec)}

      Generated by `mix ui.gen` from `#{Heex.spec_ref(spec)}`. Every
      class string, every `data-slot`, and every data attribute below came from
      upstream. Change the spec or the recipe, not this file.

      | Upstream | Digest |
      |---|---|
      | `#{digest_row(spec)}` |
      \"\"\"\
    """
  end

  defp digest_row(spec) do
    entry = get_in(spec, ["upstream", "shadcn"]) || %{}
    "#{entry["file"]}` | `#{String.slice(entry["sha256"] || "-", 0, 12)}"
  end

  defp function_doc(spec, name, %{subject: "item"}) do
    """
      @doc \"\"\"
      #{Heex.summary(spec)}

          <.#{name} id="faq">
            <:item id="faq-1" title="What is Base UI?">
              Base UI is a library of unstyled components.
            </:item>
          </.#{name}>

      Opening and closing runs entirely on the client. The server is not told,
      and does not need to be: the state is which panel a reader is looking at.
      \"\"\"\
    """
  end

  defp function_doc(spec, name, _shape) do
    """
      @doc \"\"\"
      #{Heex.summary(spec)}

          <.#{name} id="details" title="Show details">
            The panel body.
          </.#{name}>

      Opening and closing runs entirely on the client. The server is not told,
      and does not need to be: the state is whether a reader is looking at it.
      \"\"\"\
    """
  end
end
