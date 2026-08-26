defmodule LiveShadcnTools.Gen.Presentational do
  @moduledoc """
  The `presentational` recipe: markup and class strings, and no behavior.

  More than half the registry is this. A card is a `<div>` with a class string;
  a badge is a `<span>` with a class string that depends on a variant. Neither
  has state, neither needs `LiveBase`, and neither needs the parts folded into
  one function — the caller composes them freely, so each exported part becomes
  a function of its own.

  ## What it still has to get right

  **Variants.** shadcn writes them as a `cva` table: which variants exist, what
  each is called, which is the default, and the class string each carries. The
  spec records all four, so the generated component declares
  `attr :variant, :string, values: ~w(default outline …)` from data rather than
  from somebody reading the table and retyping it.

  **The attributes that are not the class string.** `data-size={size}` on a card
  is markup too. A component that dropped it would render a different card, so
  every attribute upstream writes is emitted.
  """

  alias LiveShadcnTools.Gen.Heex

  @doc "The module source for one component."
  def module(spec, opts) do
    {folded, own} = spec["parts"] |> Enum.map(&unwrapped/1) |> Enum.split_with(&wrapper?/1)

    anything!(spec, own)
    own = own |> Enum.map(&without_dropped(&1, folded)) |> forwarding()

    """
    defmodule #{inspect(Keyword.fetch!(opts, :module))} do
    #{moduledoc(spec, folded)}

      use Phoenix.Component

    #{Enum.map_join(own, "\n", &function(&1, spec, opts))}
    #{class_source(spec)}
    end
    """
  end

  # What a part hands to the sibling it calls.
  #
  # `terminal` draws its own header when the caller gives no children, and that
  # header contains `<TerminalContent />` with no props at all: upstream's
  # content reads the output off a React context that the root put it in. There
  # is no context here — that was decided in phase 1a — so the root takes the
  # output and the call has to pass it on, or the header draws an empty box.
  #
  # Only what both already have. A name the caller does not take is not a name
  # it can forward, and one the call already sets is upstream's own answer.
  defp forwarding(parts) do
    declared = Map.new(parts, &{&1["name"], Map.keys(&1["params"] || %{})})

    Enum.map(parts, fn part ->
      Map.update!(
        part,
        "tree",
        &pass_down(&1, declared, MapSet.new(Map.keys(part["params"] || %{})))
      )
    end)
  end

  defp pass_down(%{"type" => "part_ref", "part" => name} = node, declared, mine) do
    written = Enum.map(Map.get(node, "attrs") || [], & &1["name"])

    shared =
      declared
      |> Map.get(name, [])
      |> Enum.filter(&MapSet.member?(mine, &1))
      |> Enum.reject(&(&1 in ["className", "children", "render"] or &1 in written))

    node
    |> Map.put(
      "attrs",
      (Map.get(node, "attrs") || []) ++
        Enum.map(shared, &%{"name" => &1, "kind" => "code", "value" => &1})
    )
    |> Map.update("children", [], &pass_down(&1, declared, mine))
  end

  defp pass_down(node, declared, mine) when is_map(node),
    do: Map.new(node, fn {key, value} -> {key, pass_down(value, declared, mine)} end)

  defp pass_down(nodes, declared, mine) when is_list(nodes),
    do: Enum.map(nodes, &pass_down(&1, declared, mine))

  defp pass_down(value, _declared, _mine), do: value

  # A call to a part this recipe decided not to write.
  #
  # `schema-display` draws three collapsible sections and its root calls all
  # three by name. Each of the three is a wrapper around `shadcn/collapsible`, so
  # none of them is written — and the root went on calling functions the module
  # does not define, which is a compile error in a package rather than a gap in
  # a report.
  #
  # The call goes with the function. What to compose in its place is the
  # `@moduledoc`'s sentence, which names the component rather than the wrapper.
  # A wrapper whose child drew something.
  #
  # `stack_trace_header` is `<Collapsible><CollapsibleTrigger asChild>` around a
  # `<div>`, and `asChild` means the trigger *is* that div. So what upstream
  # draws is one element with a class string on it — the row an error message
  # and its buttons sit on — and read as a reference to a collapsible the whole
  # part was dropped. The storybook then had no way to draw that row except by
  # typing the class string itself, which is the one thing this pipeline exists
  # to avoid.
  #
  # The collapsible around it is behaviour, and behaviour is what the caller
  # composes — the same answer `sandbox` and `menubar` get. The element is the
  # part, and it keeps the class the caller merges into and the props it
  # spreads, because those were always on the element rather than on the
  # wrapper.
  defp unwrapped(%{"tree" => %{"type" => "component_ref", "recipe" => recipe} = tree} = part)
       when recipe != nil do
    case tree["drew"] != true and Enum.filter(List.wrap(tree["children"]), &(&1["drew"] == true)) do
      [element] -> part |> Map.put("tree", element) |> forgetting(tree, element)
      _nothing_drawn -> part
    end
  end

  defp unwrapped(part), do: part

  # A prop only the wrapper read is a prop this part no longer has. The header
  # took `isOpen` to tell the collapsible which way it was; the collapsible is
  # the caller's now, and an attribute nobody reads is a promise the API table
  # would make and the markup would not keep.
  defp forgetting(part, tree, element) do
    drawn = Jason.encode!(element)

    dropped =
      for attr <- List.wrap(tree["attrs"]),
          name <- List.wrap(attr["identifiers"]),
          not Regex.match?(~r/\b#{Regex.escape(name)}\b/, drawn),
          do: name

    Map.update(part, "params", %{}, &Map.drop(&1 || %{}, dropped))
  end

  defp without_dropped(part, []), do: part

  defp without_dropped(part, folded) do
    dropped = MapSet.new(folded, & &1["name"])
    Map.update!(part, "tree", &prune(&1, dropped))
  end

  defp prune(node, dropped) when is_map(node) do
    node
    |> Map.new(fn {key, value} -> {key, prune(value, dropped)} end)
    |> Map.replace_lazy("children", fn children ->
      Enum.reject(List.wrap(children), &calls_dropped?(&1, dropped))
    end)
  end

  defp prune(nodes, dropped) when is_list(nodes), do: Enum.map(nodes, &prune(&1, dropped))
  defp prune(value, _dropped), do: value

  defp calls_dropped?(%{"type" => "part_ref", "part" => part}, dropped),
    do: MapSet.member?(dropped, part)

  defp calls_dropped?(_node, _dropped), do: false

  # A part that is one reference to a component whose recipe folds.
  #
  # `menubar` exports thirteen of them. Twelve name a part of `dropdown-menu` —
  # `dropdown_menu_trigger`, `dropdown_menu_item` — and the menu recipe writes
  # `dropdown_menu/1` and no others, because a menu's parts have to agree about
  # which menu they belong to and an id repeated nine times is nine chances to
  # mistype it. So there is no function to call and none to write.
  #
  # The thirteenth names `dropdown_menu` itself and adds only a `data-slot`.
  # A menu is a trigger and a popup together, in slots the wrapper has no way
  # to forward, so a wrapper around one cannot be called either.
  #
  # The component they belong to is the one to call, and the `@moduledoc` says
  # so.
  @folding ~w(dialog disclosure listbox menu popover tabs)

  @doc """
  Whether a part has nothing of its own to draw.

  A reference to a component whose recipe folds, or a fold that came out empty.
  Public because `form-control` asks the same question: `prompt-input` is a
  textarea and a submit button wrapped in twenty-two references to a menu, a
  select, a hover card and a command palette.
  """
  def wrapper?(%{"tree" => tree}), do: folds_elsewhere?(tree) or draws_nothing?(tree)

  # A component whose every part is one of those.
  #
  # `open-in-chat` is twelve wrappers around `dropdown-menu` and a React context
  # holding a query string. Drop the wrappers — which is the same decision
  # `menubar` makes, and the right one — and what is left is a module with one
  # function that renders its own children and nothing else. That is not a
  # component; it is a sentence saying which component to compose, and a
  # moduledoc is where a sentence goes.
  defp anything!(spec, own) do
    if own == [] do
      components = Enum.map_join(spec["folds"] || [], ", ", &"`#{&1}`")

      raise """
      every part of #{spec["name"]} is a thin wrapper around #{components}.

      What is left after the wrappers are dropped is a module whose functions \
      render their own children and nothing else. That is not a component; it \
      is a sentence saying which one to compose. Record it in ROADMAP.md with \
      the reason rather than generating the sentence as code.
      """
    end
  end

  @doc """
  Whether a part is a component that was folded away and left nothing behind.

  `voice-selector`'s root is `<Dialog {...props}>`. Base UI's dialog root
  renders no element of its own, so folding it in leaves a function that renders
  its own children — a wrapper by another name, and the moduledoc already says
  which component to compose instead.

  Both halves are required. A part that draws nothing and folded nothing is a
  React context provider, which upstream needs and this does not, but removing
  it is a decision about somebody's public API rather than a fold that came out
  empty — `message-scroller` exports one. And a part that folded something and
  still draws is simply a part.
  """
  def draws_nothing?(tree), do: folded_away?(tree) and nothing_drawn?(tree)

  # Base UI's own words for a part that renders no element, carried into the
  # spec by the reader and left behind by the fold.
  defp folded_away?(%{"reason" => "renders no element"}), do: true

  defp folded_away?(node) when is_map(node),
    do: node |> Map.values() |> Enum.any?(&folded_away?/1)

  defp folded_away?(nodes) when is_list(nodes), do: Enum.any?(nodes, &folded_away?/1)
  defp folded_away?(_node), do: false

  defp nothing_drawn?(%{"type" => type}) when type not in ~w(transparent children), do: false

  defp nothing_drawn?(node) when is_map(node),
    do: node |> Map.get("children") |> List.wrap() |> Enum.all?(&nothing_drawn?/1)

  defp nothing_drawn?(_node), do: true

  # A reference that drew an element of its own is not a wrapper.
  #
  # `<DropdownMenuItem asChild><a href={…}>…</a></DropdownMenuItem>` is one
  # element, and it is the `<a>`: a link with a class string, an icon, a title
  # and an external-link icon. `open-in-chat` is twelve of those, and read as
  # twelve references to a menu it was a component with nothing in it — which
  # is what `ROADMAP.md` said about it, before `asChild` was read as one
  # element.
  defp folds_elsewhere?(%{"type" => "component_ref", "recipe" => recipe} = node),
    do: recipe in @folding and node["drew"] != true

  # A React context provider draws no element, so a part that is one holding a
  # wrapper is a wrapper. `open-in-chat` puts a query string in a context and
  # renders `<DropdownMenu>`; the context is gone here and the menu is the
  # application's own.
  defp folds_elsewhere?(%{"type" => "transparent", "children" => [_ | _] = children}),
    do: Enum.all?(children, &folds_elsewhere?/1)

  defp folds_elsewhere?(_node), do: false

  defp underscored(component), do: String.replace(component, "-", "_")

  @doc """
  One function for one part.

  The form-control recipe borrows this for the parts of its own components that
  hold no value: a `<label>` is markup whichever recipe it appears under.
  """
  def function(part, spec, opts \\ []) do
    case opts |> Keyword.get(:function_overrides, %{}) |> Map.get(part["name"]) do
      nil -> standard_function(part, spec, opts)
      source -> source
    end
  end

  defp standard_function(part, spec, opts) do
    name = part["name"]
    attrs = attributes(part, spec)

    """
    #{part_doc(part, spec)}
    #{Enum.map_join(attrs, "\n", &declaration/1)}
    #{declared(part, opts)}\
      attr :class, :any, default: nil, doc: "Appended to the class string upstream renders."
      attr :rest, :global, include: #{inspect(Heex.globals(Heex.rest_tag(part["tree"], by_name(spec))))}
    #{slot(part)}
      def #{name}(assigns) do
        ~H\"\"\"
    #{markup(part, spec, opts)}
        \"\"\"
      end
    """
  end

  # Attributes a recipe adds that upstream never destructured.
  #
  # A recipe that puts behaviour on a presentational part has to declare what
  # that behaviour reads. `message-scroller` is the case that asked for it: its
  # viewport carries `phx-hook`, a hook needs an `id` to mount, and nothing
  # declared one — so the hook had never mounted at all, and none of the
  # scroller's measuring had ever run on that component.
  #
  # An option rather than a `String.replace` over the generated source, which is
  # what phase 7c took out of these recipes.
  defp declared(part, opts) do
    opts
    |> Keyword.get(:declare, %{})
    |> Map.get(part["name"], [])
    |> Enum.map_join("", &"  #{&1}\n")
  end

  defp by_name(spec), do: Map.new(spec["parts"], &{&1["name"], &1})

  # A prop upstream destructures is a prop the caller can set. `className` is
  # handled on its own, and the rest arrive through `:global`.
  @doc "The attributes a part exposes, with their defaults and allowed values."
  def attributes(part, spec) do
    calls = variant_calls_of(part, spec)
    paths = path_roots(part) ++ counted(part)

    # A render prop is declared as a slot, and a name cannot be both.
    rendered = Heex.slots(part["tree"])

    part
    |> Map.get("params", %{})
    |> Map.drop(["className", "children", "render"])
    |> Map.reject(fn {name, _default} -> LiveShadcnTools.assign(name) in rendered end)
    |> Enum.sort()
    |> Enum.map(fn {name, default} ->
      # The `cva` table's `defaultVariants` is as much upstream's decision as
      # the destructuring default is, and it is the one that decides which
      # class string is applied. The table that was *passed* this prop, not any
      # table that happens to define a group by the same name.
      group = Enum.find(calls, &(name in &1["args"]))
      default = default || get_in(group, ["definition", "defaults", name])
      annotation = get_in(part, ["types", name]) || %{}

      %{
        name: LiveShadcnTools.assign(name),
        default: default,
        values:
          get_in(group, ["definition", "variants", name]) |> values() || annotation["values"],
        type: type(name, default, paths, annotation)
      }
    end)
  end

  defp values(nil), do: nil
  defp values(group), do: group |> Map.keys() |> Enum.sort()

  # What a prop holds, from the two things upstream says about it: the default
  # it wrote down, and what the markup does with it. `disabled = false` is a
  # yes-or-no and `data.filename` is a value with fields, and declaring either
  # one a string makes the component lie about what it takes — a `:string`
  # holding `"false"` is true to every `:if` that reads it.
  defp type(_name, _default, _paths, %{"type" => "boolean"}), do: ":boolean"
  defp type(_name, _default, _paths, %{"type" => "integer"}), do: ":integer"
  # Phoenix has no numeric type that accepts both Elixir integers and floats.
  # TypeScript `number` permits both, so keep the public component contract open.
  defp type(_name, _default, _paths, %{"type" => "number"}), do: ":any"
  defp type(_name, default, _paths, _annotation) when default in ["true", "false"], do: ":boolean"

  defp type(name, _default, paths, _annotation),
    do: if(name in paths, do: ":any", else: ":string")

  # The props the markup counts rather than prints.
  #
  # `context` writes `Intl.NumberFormat(…).format(inputTokens)`, which is
  # arithmetic on a number. Declared `:string` — which is what a prop with no
  # default and no annotation gets — the component refuses the number a caller
  # has, and takes a string it cannot divide.
  #
  # `:any` rather than `:integer` for the same reason a `number` annotation gets
  # `:any`: TypeScript's `number` is both, and Phoenix has no type that is.
  defp counted(part) do
    codes = LiveShadcnTools.Spec.codes(part["tree"])

    formatted =
      codes
      |> Enum.filter(&String.contains?(&1, "NumberFormat"))
      |> Enum.flat_map(
        &Regex.scan(~r/\.format\(([a-z_][A-Za-z0-9_]*)\)/, &1, capture: :all_but_first)
      )

    # Every name in an expression that does arithmetic. `connection` writes
    # `M${fromX},${fromY} C ${fromX + (toX - fromX) * 0.5},…` into the `d` of a
    # path: four coordinates, two of which are added and two of which are only
    # printed. Declared by the operator beside them, two came out `:any` and two
    # `:string`, which is a component that wants numbers for x and words for y.
    #
    # One expression, one kind of value. `:any` for a name that is only printed
    # costs nothing — it already accepts the string it would have been given.
    arithmetic =
      codes
      |> Enum.filter(&Regex.match?(~r/[a-z_][A-Za-z0-9_]*\s*[-+*\/]\s*[a-z_(\d]/, &1))
      |> Enum.flat_map(&Regex.scan(~r/\b([a-z_][A-Za-z0-9_]*)\b/, &1, capture: :all_but_first))

    (formatted ++ arithmetic) |> List.flatten() |> Enum.reject(&(&1 == "")) |> Enum.uniq()
  end

  # The props the markup reads a field off, rather than rendering whole.
  #
  defp path_roots(part) do
    part["tree"]
    |> Heex.member_roots()
    |> Enum.uniq()
    |> Enum.sort()
  end

  # Every attribute gets a default, even if it is `nil`. A declared attribute
  # with no default is simply absent from the assigns, and the component would
  # raise the first time nobody passed it.
  @doc "One `attr` line."
  def declaration(%{name: name, default: default, values: values} = attribute) do
    type = Map.get(attribute, :type, ":string")

    options =
      [
        "default: #{inspect(literal(type, default))}",
        values && "values: #{inspect(allowed(values, default))}"
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.map_join("", &", #{&1}")

    "  attr :#{name}, #{type}#{options}"
  end

  # Phoenix refuses a default that is not one of the values, and a prop upstream
  # types as optional has no default to be one of them: `gender?: "male" | …` is
  # a set of six and nothing chosen. So nothing chosen is one of the answers.
  # `voice-selector` was the first component to say so, and it would not compile.
  defp allowed(values, nil), do: [nil | values]
  defp allowed(values, _default), do: values

  defp literal(":boolean", "true"), do: true
  defp literal(":boolean", "false"), do: false

  # A number upstream wrote as a number. `duration = 2` is two seconds, and two
  # seconds written as `"2"` is a string every piece of arithmetic downstream
  # then fails on — `trunc(@duration * 1000)` first.
  defp literal(type, default) when type in [":any", ":integer"] and is_binary(default) do
    case Integer.parse(default) do
      {number, ""} -> number
      _not_a_number -> computed(default)
    end
  end

  defp literal(_type, default) when is_binary(default), do: computed(default)

  defp literal(_type, default), do: default

  # `defaultExpanded = new Set()` is JavaScript running at render, not a value.
  # Written out as it stands it declared a component whose default is the four
  # words `new Set()`, which is worse than having none: a caller who passes
  # nothing gets a string that reads like code.
  #
  # Nothing is the honest default for a computed one. What upstream computes is
  # a starting point for state the client owns, and a HEEx component takes that
  # from its caller.
  defp computed(default) do
    if Regex.match?(~r/[(\[{]/, default), do: nil, else: default
  end

  # A render prop is a slot, and a slot rendered but not declared raises on the
  # component's first render.
  defp slot(part) do
    named = Enum.map_join(Heex.slots(tree(part)), &"  slot :#{&1}\n")
    inner = if Heex.marker?(tree(part)), do: "  slot :inner_block\n", else: ""

    named <> inner
  end

  defp tree(part), do: Heex.with_children(part["tree"])

  # What a third-party primitive takes as a prop rather than as an attribute.
  #
  # `<NodeToolbar position={Position.Bottom}>` is React Flow being told where to
  # put the toolbar, and a `<div>` has no `position` attribute — written out it
  # is an invented attribute whose value names a JavaScript enum.
  #
  # Only the external ones. A Base UI part's props are documented too, and the
  # recipes that fold one already decide for themselves which of them reach the
  # element; taking that decision here would change fifty components at once.
  defp external_props(spec) do
    for {key, primitive} <- spec["primitives"] || %{},
        String.starts_with?(key, "external/"),
        into: %{},
        do: {key, Enum.map(primitive["props"] || [], & &1["name"])}
  end

  defp markup(part, spec, opts) do
    Heex.render(tree(part), %{
      attrs: Keyword.get(opts, :attrs, %{}),
      props: external_props(spec),
      children: "{render_slot(@inner_block)}",
      class: "@class",
      variants: spec["variants"] || %{},
      params: Map.get(part, "params", %{}),
      contexts: Map.get(part, "contexts", []),
      client_attributes: [],
      client_state: Keyword.get(opts, :client_state, %{}),
      hook_part: nil,
      rest: true
    })
  end

  @doc """
  The `cva` tables this part's class string is built from, with the props each
  call was passed.

  A list, because there can be more than one on one element: `input-group`'s
  button renders shadcn's `<Button>` and adds `inputGroupButtonVariants` on top,
  so the element wears two bases and two `size` groups reading two values. Read
  as one name, the second table's base was lost and the two `size` groups
  collided by map order.
  """
  def variant_calls_of(part, spec), do: calls(part["tree"], spec)

  # Every value, not only `children`. A call sits on whichever element wears the
  # class string, and that element is as often inside a choice's branch or a
  # marker's default as it is inside a list of children.
  defp calls(%{"variant_calls" => [_ | _] = wearing} = node, spec) do
    resolved =
      for call <- wearing,
          table = get_in(spec, ["variants", call["table"]]),
          do: Map.put(call, "definition", table)

    resolved ++ calls(Map.delete(node, "variant_calls"), spec)
  end

  defp calls(node, spec) when is_map(node),
    do: node |> Map.values() |> Enum.flat_map(&calls(&1, spec))

  defp calls(nodes, spec) when is_list(nodes), do: Enum.flat_map(nodes, &calls(&1, spec))
  defp calls(_node, _spec), do: []

  @doc """
  The variant tables as a module attribute, written once per component and read
  by every part that has variants. They are data, so they stay data.

  Keyed by the `cva` binding and then by the group. Keyed by group alone, two
  tables that both define `size` overwrote each other in whichever order the
  map iterated, and the class string that came out was one of the two.
  """
  def variant_table(spec, body) do
    # Only what the markup looks up, read off the markup.
    #
    # A component that folded in another one's markup inherits its `cva` tables
    # too, and writing one nothing reads is a private function nobody calls —
    # which is a compiler warning, and this project compiles generated code
    # with warnings as errors.
    #
    # Asked of the spec instead, this disagreed with the markup exactly where a
    # recipe renders a slice of a part rather than the whole: `chain-of-thought`
    # has a table on a node its trigger does not draw.
    used =
      ~r/variant_class\("([^"]+)", "([^"]+)"/
      |> Regex.scan(body, capture: :all_but_first)
      |> MapSet.new(fn [binding, group] -> {binding, group} end)

    tables =
      for {binding, table} <- spec["variants"] || %{},
          {group, values} <- table["variants"] || %{},
          MapSet.member?(used, {binding, group}),
          reduce: %{} do
        acc -> Map.update(acc, binding, %{group => values}, &Map.put(&1, group, values))
      end

    if tables == %{} do
      ""
    else
      visibility = if spec["name"] == "button", do: "def", else: "defp"

      """

        # The variant tables, from the `cva` calls upstream writes them in.
        @variants #{inspect(tables, pretty: true, limit: :infinity)}

        #{visibility} variant_class(table, group, value), do: get_in(@variants, [table, group, value])
      """
    end
  end

  defp class_source(%{"name" => "button"} = spec) do
    classes = %{"button" => get_in(spec, ["variants", "buttonVariants", "base"])}

    """

      @part_classes #{inspect(classes, pretty: true, limit: :infinity)}

      def part_class(part), do: Map.fetch!(@part_classes, part)
    """
  end

  defp class_source(_spec), do: ""

  defp moduledoc(spec, folded) do
    """
      @moduledoc \"\"\"
      #{Heex.headline(spec)}
    #{elsewhere(folded)}
      Generated by `mix ui.gen` from `#{Heex.spec_ref(spec)}`. Every
      class string and every `data-slot` below came from upstream. Change the
      spec or the recipe, not this file.
      \"\"\"\
    """
  end

  defp counted(1, thing), do: "1 #{thing}"
  defp counted(many, thing), do: "#{many} #{thing}s"

  # The parts this module does not write, and what to call instead. Upstream
  # exports one wrapper per part of the component it is built on; here that
  # component is one function, so the wrappers have nothing to wrap.
  defp elsewhere([]), do: ""

  defp elsewhere(folded) do
    # A part that draws nothing of its own carries no component name to compose
    # instead — `voice-selector`'s root is a `<Dialog>` whose markup was folded
    # away, and what is left is a function that renders its own children. The
    # sentence is about the ones that name a component.
    components =
      folded
      |> Enum.map(& &1["tree"]["component"])
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.map_join(", ", &"`<.#{underscored(&1)}>`")

    if components == "" do
      ""
    else
      """

        Upstream exports #{counted(length(folded), "more part")}, each a thin
        wrapper around a part of #{components}. That component is one
        function here — its parts have to agree about which one they belong to,
        and an id repeated is an id to mistype — so it is what to compose inside
        this, and there is nothing for the wrappers to wrap.
      """
    end
  end

  defp part_doc(part, spec) do
    summary =
      get_in(spec, ["primitives", "#{spec["name"]}.#{part["primitive"]}", "summary"]) ||
        "The `#{part["tree"]["slot"] || part["name"]}` part."

    "  @doc #{inspect(summary)}"
  end
end
