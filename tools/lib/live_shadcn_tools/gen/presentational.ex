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
    {folded, own} = Enum.split_with(spec["parts"], &wrapper?/1)

    anything!(spec, own)

    """
    defmodule #{inspect(Keyword.fetch!(opts, :module))} do
    #{moduledoc(spec, folded)}

      use Phoenix.Component

    #{Enum.map_join(own, "\n", &function(&1, spec, opts))}
    #{class_source(spec)}
    end
    """
  end

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

  # A part with nothing of its own to draw: a reference to a component whose
  # recipe folds, or a fold that came out empty.
  defp wrapper?(%{"tree" => tree}), do: folds_elsewhere?(tree) or draws_nothing?(tree)

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

  defp folds_elsewhere?(%{"type" => "component_ref", "recipe" => recipe}), do: recipe in @folding

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
    paths = path_roots(part)

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
  defp literal(_type, default), do: default

  # A render prop is a slot, and a slot rendered but not declared raises on the
  # component's first render.
  defp slot(part) do
    named = Enum.map_join(Heex.slots(tree(part)), &"  slot :#{&1}\n")
    inner = if Heex.marker?(tree(part)), do: "  slot :inner_block\n", else: ""

    named <> inner
  end

  defp tree(part), do: Heex.with_children(part["tree"])

  defp markup(part, spec, opts) do
    Heex.render(tree(part), %{
      attrs: Keyword.get(opts, :attrs, %{}),
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

        Upstream exports #{length(folded)} more parts, and every one of them is a
        thin wrapper around a part of #{components}. That component is one
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
