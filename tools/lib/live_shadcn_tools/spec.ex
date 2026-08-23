defmodule LiveShadcnTools.Spec do
  @moduledoc """
  Stage 2 of the pipeline: the shadcn `.tsx` and the Base UI `.md` become one
  JSON document.

  The spec is the only thing `mix ui.gen` reads. Anything the generator needs
  has to be a fact recorded here, so a change in generated HEEx always traces
  back to a change in the spec, and a spec change traces back to an upstream
  digest change.

  Two kinds of fact are recorded per element:

    * what shadcn renders — the tag, the `data-slot`, the class string
    * what the class string *reads* — the data and ARIA attributes its Tailwind
      variants key on, and the CSS variables its utilities interpolate

  The second kind is what makes the generator able to place attributes without
  a person deciding where they go. A class string containing
  `data-ending-style:h-0` is a declaration that this element must carry
  `data-ending-style` while it animates out.
  """

  import LiveShadcnTools, only: [ref: 2]

  alias LiveShadcnTools.BaseUi
  alias LiveShadcnTools.Cva
  alias LiveShadcnTools.Tsx

  @doc """
  The key a primitive node is documented under: its Base UI module and part.

  A component built from two modules has two `Root` sections, and they are not
  the same part, so the module is half of the name.
  """
  def key(%{"module" => module, "part" => part}), do: "#{module}.#{part}"

  # A plain element documents nothing, so it is documented under no key.
  def key(_node), do: nil

  @doc """
  Builds the spec map for one component.

  `:styles` is `%{style_name => %{cn_class => utilities}}`, from
  `LiveShadcnTools.Style`. It is optional, and a spec built without it is a spec
  that has only seen half of what shadcn styles the component with.
  """
  def build(name, opts) do
    tsx = Tsx.parse!(Keyword.fetch!(opts, :tsx))

    docs =
      Map.new(Keyword.fetch!(opts, :markdown), fn {mod, md} -> {mod, BaseUi.parse!(md, mod)} end)

    doc = Map.get(docs, Keyword.get(opts, :module, name), BaseUi.parse!("", name))
    functions = Map.new(tsx.functions, &{&1.name, &1})
    variants = variants(tsx.consts)

    ctx = %{
      doc: doc,
      docs: docs,
      styles: Keyword.get(opts, :styles, %{}),
      functions: functions,
      consts: tsx.consts,
      imports: tsx.imports,
      variants: Map.keys(variants)
    }

    exports = Enum.reject(tsx.exports, &Map.has_key?(variants, &1))
    unreadable!(exports, tsx.unreadable)

    parts = exports |> Enum.filter(&component?(&1, ctx)) |> Enum.map(&part(&1, ctx))

    # A spec with no parts renders nothing, and it is indistinguishable on disk
    # from one the reader understood and found empty. That is the silent skip
    # this reader exists to avoid, so it is a failure with a name instead.
    if parts == [] do
      raise """
      no exported component was found in #{name}.

      The file exports #{length(tsx.exports)} name(s) and the reader recognised \
      none of them as a component. Either the file declares them in a shape \
      LiveShadcnTools.Tsx does not read yet, or this is not a component file.
      """
    end

    source = Keyword.fetch!(opts, :source)

    {parts, folded} =
      parts
      |> Enum.map(&markdown_content/1)
      |> fold(source, Keyword.get(opts, :resolve, fn _source, _name -> nil end))

    own_primitives =
      for {module, page} <- docs, {key, part} <- page.parts, into: %{} do
        {"#{module}.#{key}", primitive(part)}
      end

    %{
      "name" => name,
      "recipe" => Keyword.fetch!(opts, :recipe),
      "source" => source,
      "generated_by" => "mix ui.spec",
      "upstream" => Keyword.fetch!(opts, :upstream),
      "anatomy" => doc.anatomy,
      # Keyed by module and part, because a component built from two Base UI
      # modules has two `Root` sections and they are not the same part. A part
      # folded in from another registry brings the page that documents it, or
      # the recipe would meet a primitive with no contract.
      "primitives" => Map.merge(merged(folded, "primitives"), own_primitives),
      "css_vars" =>
        ((doc.parts |> Enum.flat_map(fn {_, p} -> p.css_vars end)) ++ folded_vars(folded))
        |> Enum.uniq()
        |> Enum.sort(),
      "variants" => Map.merge(merged(folded, "variants"), variants),
      "styles" => used_styles(ctx.styles, parts),
      "parts" => parts
    }
    |> folds(folded)
  end

  # Which components' markup this one absorbed. It is what the generated
  # `@moduledoc` says a component is built on, and it is the list a drift report
  # needs: an upstream change to a folded component changes this one too, and
  # nothing else in the spec would say so.
  #
  # A component that folded nothing carries no key rather than an empty list.
  # Every spec is committed and a component's verification is recorded against
  # its digest, so a key that is always empty for one registry would demote
  # every component in it and cost a browser run each to say nothing.
  defp folds(spec, []), do: spec

  defp folds(spec, folded),
    do: Map.put(spec, "folds", folded |> Enum.map(&ref(&1["source"], &1["name"])) |> Enum.sort())

  # An arrow function whose markup `LiveShadcnTools.Tsx` could not read.
  #
  # A file is full of small helpers that render nothing, and one nobody exports
  # is not a component: dropping it is right. An exported one is a part of this
  # component, and dropping it means generating a component that is missing a
  # part. So the export list is what decides, and the reason travels with the
  # name rather than turning up later as "the spec reader does not know what
  # <CodeBlockContent> is".
  defp unreadable!(exports, unreadable) do
    case Enum.filter(exports, &Map.has_key?(unreadable, &1)) do
      [] ->
        :ok

      [name | _rest] ->
        raise "#{name} is exported and its markup could not be read: #{unreadable[name]}"
    end
  end

  # Markdown is content, not children.
  #
  # `<Streamdown>{children}</Streamdown>` looks like a wrapper and is not one:
  # AI Elements types those children as a `string`, because a markdown renderer
  # takes source text and produces the markup itself. A HEEx slot holds rendered
  # markup, which is the wrong end of the same pipe — by the time a slot has
  # been rendered, the markdown is gone.
  #
  # So a part that renders markdown takes a `content` prop and no slot, and the
  # marker inside the renderer is dropped rather than becoming one.
  defp markdown_content(part) do
    if markdown?(part["tree"]) do
      part
      |> Map.put("params", Map.put(Map.get(part, "params") || %{}, "content", nil))
      |> Map.put("tree", drop_markdown_children(part["tree"]))
    else
      part
    end
  end

  defp markdown?(%{"type" => "external", "role" => "markdown"}), do: true

  defp markdown?(node) when is_map(node),
    do: node |> Map.values() |> Enum.any?(&markdown?/1)

  defp markdown?(nodes) when is_list(nodes), do: Enum.any?(nodes, &markdown?/1)
  defp markdown?(_node), do: false

  defp drop_markdown_children(%{"type" => "external", "role" => "markdown"} = node),
    do: Map.put(node, "children", [])

  defp drop_markdown_children(node) when is_map(node),
    do: Map.new(node, fn {key, value} -> {key, drop_markdown_children(value)} end)

  defp drop_markdown_children(nodes) when is_list(nodes),
    do: Enum.map(nodes, &drop_markdown_children/1)

  defp drop_markdown_children(value), do: value

  @doc """
  Replaces every reference to a component in another registry with its markup.

  A reference inside one registry is a call, and stays one: both files are
  copied into the same application and both are renamed together. A reference
  across registries cannot be. `live_shadcn` is copied in by `mix ui.add`, which
  rewrites `LiveShadcn.UI.Collapsible` to the application's own namespace;
  `live_ai_elements` is compiled once, before any of that, so a call it made
  would name a module that no longer exists.

  So an AI Elements component that renders `<CollapsibleTrigger>` takes the
  trigger's markup — its element, its `cn-` class string, its `data-slot`, the
  Base UI part it draws — and renders it itself. Its own class string and
  attributes are merged on top, which is what React does with the props it
  passed.

  What comes back is the folded parts and the specs they were folded from. The
  second half matters: a folded part draws a Base UI primitive, and the recipe
  reads that primitive's attribute contract out of the spec it came from.

  `resolve` is `fn source, name -> spec | nil end`. A reference that resolves to
  nothing is left alone, so `mix ui.gen` reports it rather than the reader
  guessing at markup it has not read.
  """
  def fold(parts, source, resolve) do
    {parts, acc} =
      Enum.map_reduce(parts, %{specs: %{}, params: %{}}, fn part, acc ->
        {tree, acc} = fold_node(part["tree"], source, resolve, %{acc | params: %{}})

        # A folded part's props come with it. shadcn's scroll-area computes an
        # attribute from its own `orientation`, and once that markup is here,
        # `orientation` is a prop of this component too — with the default
        # shadcn gave it, because that is the value React used when upstream
        # rendered `<ScrollArea>` without one.
        #
        # The component's own props win: it destructured them itself, and a
        # folded default cannot know better.
        params = Map.merge(acc.params, Map.get(part, "params") || %{})

        {part |> Map.put("tree", tree) |> Map.put("params", params), acc}
      end)

    {parts, Map.values(acc.specs)}
  end

  defp fold_node(%{"type" => "component_ref", "source" => other} = node, source, resolve, acc)
       when other != source do
    with spec when is_map(spec) <- resolve.(other, node["component"]),
         target when is_map(target) <- find_part(spec, node["function"]) do
      acc = %{
        acc
        | specs: Map.put(acc.specs, {other, node["component"]}, spec),
          params: Map.merge(acc.params, Map.get(target, "params") || %{})
      }

      # The reference's own children first. `<DropdownMenuTrigger><Button /></…>`
      # is two references, and matching the outer one here means nothing else
      # will ever look inside it: the children go straight into the tree the
      # outer one folds to, and the inner reference would arrive unread.
      {node, acc} = fold_children(node, source, resolve, acc)

      # The target may itself reference a third component, and from here that
      # one is just as far away.
      {tree, acc} = fold_node(inline_parts(target["tree"], spec, []), source, resolve, acc)
      {absorb(tree, node, Map.get(target, "params") || %{}), acc}
    else
      _unresolved -> {node, acc}
    end
  end

  defp fold_node(node, source, resolve, acc) when is_map(node) do
    Enum.reduce(node, {node, acc}, fn {key, value}, {node, acc} ->
      {folded, acc} = fold_node(value, source, resolve, acc)
      {Map.put(node, key, folded), acc}
    end)
  end

  defp fold_node(nodes, source, resolve, acc) when is_list(nodes),
    do: Enum.map_reduce(nodes, acc, &fold_node(&1, source, resolve, &2))

  defp fold_node(value, _source, _resolve, acc), do: {value, acc}

  defp fold_children(node, source, resolve, acc) do
    {children, acc} = fold_node(Map.get(node, "children") || [], source, resolve, acc)
    {Map.put(node, "children", children), acc}
  end

  defp find_part(spec, function),
    do: Enum.find(spec["parts"] || [], &(&1["name"] == function))

  # A part of the folded component that names another part of the same
  # component. `<ScrollAreaScrollbar>` is a function in shadcn's scroll-area
  # module, and after the fold there is no such module to call: the markup
  # landed in an AI Elements component that has one function. So the sibling's
  # markup comes with it.
  #
  # `seen` stops a part that names itself, directly or through another, from
  # folding for ever.
  defp inline_parts(%{"type" => "part_ref", "part" => name} = node, spec, seen) do
    with false <- name in seen,
         part when is_map(part) <- find_part(spec, name) do
      # The reference's own children too, for the reason `fold_children/4`
      # gives: they land inside the tree this folds to, and nothing else walks
      # them afterwards.
      node = Map.put(node, "children", inline_parts(Map.get(node, "children") || [], spec, seen))

      part["tree"]
      |> inline_parts(spec, [name | seen])
      |> absorb(node, Map.get(part, "params") || %{})
    else
      _ -> node
    end
  end

  defp inline_parts(node, spec, seen) when is_map(node),
    do: Map.new(node, fn {key, value} -> {key, inline_parts(value, spec, seen)} end)

  defp inline_parts(nodes, spec, seen) when is_list(nodes),
    do: Enum.map(nodes, &inline_parts(&1, spec, seen))

  defp inline_parts(value, _spec, _seen), do: value

  # The reference's own markup, merged onto the markup it points at. Upstream
  # writes `<CollapsibleTrigger className="flex w-full …">`, and both class
  # strings apply: shadcn's, then the one AI Elements added.
  defp absorb(tree, node, params) do
    tree
    |> Map.merge(%{
      "attrs" =>
        (Map.get(tree, "attrs") || []) ++ markup_attrs(Map.get(node, "attrs") || [], params),
      "class" =>
        [tree["class"], node["class"]] |> Enum.reject(&(&1 in [nil, ""])) |> Enum.join(" "),
      "merges_class" => node["merges_class"] || tree["merges_class"],
      "props" => node["props"] || tree["props"],
      "slot" => node["slot"] || tree["slot"]
    })
    |> place(Map.get(node, "children") || [])
  end

  @doc """
  Puts what a reference wrapped where the component it names renders it.

  `<ScrollArea>{buttons}</ScrollArea>` does not put the buttons after the scroll
  area. It puts them where the scroll area renders `{children}`, which is inside
  its viewport, and everything the scroll area draws around that stays around
  it. React decides this and so does the fold.

  Appending instead is not untidy, it is wrong twice over: the content lands
  outside the box that scrolls, and the marker it should have replaced is still
  there, so every child is drawn a second time. `suggestion` rendered three
  buttons six times that way, and each copy looked right on its own.

  A reference that wrapped nothing leaves the marker alone. A component whose
  markup has no marker takes the content at the end, which is the only place
  left.
  """
  def place(tree, []), do: tree

  def place(tree, children) do
    case replace(tree, children) do
      {tree, true} -> tree
      {tree, false} -> Map.put(tree, "children", (Map.get(tree, "children") || []) ++ children)
    end
  end

  defp replace(node, children) when is_map(node) do
    {placed, done?} = replace(Map.get(node, "children") || [], children)
    {Map.put(node, "children", placed), done?}
  end

  defp replace(nodes, children) when is_list(nodes) do
    Enum.flat_map_reduce(nodes, false, fn
      %{"type" => "children"}, false -> {children, true}
      node, done? when is_map(node) -> replace_one(node, children, done?)
      node, done? -> {[node], done?}
    end)
  end

  defp replace_one(node, _children, true), do: {[node], true}

  defp replace_one(node, children, false) do
    {node, done?} = replace(node, children)
    {[node], done?}
  end

  # What a reference writes is markup for the element, or an argument to the
  # React component that is no longer there. Two things tell them apart, and
  # both had to be learned by putting the wrong thing in generated HEEx:
  #
  # A camelCase name is React's. `<Collapsible asChild defaultOpen={…}>` put
  # `asChild` and `defaultOpen={@default_open}` in the markup, and neither is an
  # attribute a browser or an assign has heard of.
  #
  # A name the target destructured is React's too. `<Button size="sm">` put
  # `size={@size}` on a `<button>`, where it means nothing — the size is a class
  # string, and the folded markup already computes it from the same prop.
  defp markup_attrs(attrs, params) do
    Enum.reject(attrs, fn attr ->
      attr["name"] =~ ~r/[A-Z]/ or Map.has_key?(params, attr["name"])
    end)
  end

  defp merged(specs, key),
    do: Enum.reduce(specs, %{}, fn spec, acc -> Map.merge(acc, Map.get(spec, key) || %{}) end)

  defp folded_vars(specs), do: Enum.flat_map(specs, &(Map.get(&1, "css_vars") || []))

  # Every top-level binding that holds a `cva` call. These are exported, but
  # they are not components: they are the variant table a component's class
  # string is built from.
  defp variants(consts) do
    consts
    |> Enum.flat_map(fn {name, code} ->
      case Cva.parse(code) do
        {:ok, variants} -> [{name, variants}]
        :error -> []
      end
    end)
    |> Map.new()
  end

  # Only the rules this component's class strings actually name. A spec that
  # carried the whole sheet would change every time an unrelated component did.
  defp used_styles(styles, parts) do
    used = parts |> Enum.flat_map(&cn_classes(&1["tree"])) |> MapSet.new()

    styles
    |> Map.new(fn {style, rules} -> {style, Map.take(rules, MapSet.to_list(used))} end)
    |> Map.reject(fn {_style, rules} -> rules == %{} end)
  end

  defp cn_classes(node) do
    own = node |> Map.get("class", "") |> String.split() |> Enum.filter(&cn_class?/1)
    own ++ Enum.flat_map(Map.get(node, "children") || [], &cn_classes/1)
  end

  defp cn_class?(class), do: String.starts_with?(class, "cn-")

  defp primitive(part) do
    %{
      "element" => part.element,
      "renders" => part.renders?,
      "hidden_input" => part.hidden_input?,
      "summary" => part.summary,
      "data" => part.data,
      "css_vars" => part.css_vars,
      "props" => part.props
    }
  end

  # Not every export renders. A file may also export a hook, a variant table, or
  # a factory such as `createToastManager`. None of them has markup, so none of
  # them becomes a part; JavaScript's own convention — components are
  # capitalised, everything else is not — is what tells them apart.
  defp component?(export, ctx) do
    cond do
      not Regex.match?(~r/^[A-Z]/, export) -> false
      Map.has_key?(ctx.functions, export) -> true
      true -> renders?(Map.get(ctx.consts, export))
    end
  end

  defp renders?(nil), do: false

  defp renders?(code) do
    code
    |> String.trim()
    |> String.split(".")
    |> List.last()
    |> then(&Regex.match?(~r/^[A-Z]/, &1))
  end

  # An export is a component two ways: a function with JSX, or a `const` that
  # aliases a Base UI part outright. shadcn writes the second when a part needs
  # no styling at all — `const Select = SelectPrimitive.Root`.
  defp part(export, ctx) do
    case Map.fetch(ctx.functions, export) do
      {:ok, function} ->
        ctx = ctx |> Map.put(:renames, function.renames) |> Map.put(:params_of, function.params)

        %{
          "name" => Macro.underscore(export),
          "export" => export,
          "primitive" => primitive_of(function.props_type),
          "params" => Map.new(function.params, &icon_default(&1, ctx)),
          "tree" => node(function.jsx, ctx)
        }

      :error ->
        alias_part(export, ctx)
    end
  end

  defp alias_part(export, ctx) do
    code = Map.get(ctx.consts, export) || raise "#{export} is exported but never defined"

    element = %{type: :element, tag: String.trim(code), attrs: [{:spread, "props"}], children: []}

    %{
      "name" => Macro.underscore(export),
      "export" => export,
      "primitive" => primitive_of(String.trim(code) <> ".Props"),
      "params" => %{},
      "tree" => node(element, ctx)
    }
  end

  # `AccordionPrimitive.Trigger.Props` -> `Trigger`
  defp primitive_of(nil), do: nil

  defp primitive_of(props_type) do
    case String.split(props_type, ".") do
      [_primitive, part, "Props"] -> part
      _ -> nil
    end
  end

  defp node(%{type: :expr, code: "children"}, _ctx), do: %{"type" => "children"}

  defp node(%{type: :expr, code: code}, ctx), do: expression(code, ctx)

  defp node(%{type: :text, value: value}, _ctx),
    do: %{"type" => "text", "value" => String.trim(value)}

  defp node(%{type: :element, tag: tag} = element, ctx) do
    class_value = Tsx.attr(element, "className")
    variant_class = Tsx.variant_call(class_value, ctx.variants)
    classes = Tsx.classes(class_value)
    styling = classes <> " " <> variant_classes(variant_class, ctx)

    element
    |> base_node(tag, ctx)
    |> Map.merge(%{
      "slot" => slot(element),
      "attrs" => attributes(element),
      "render_as" => render_as(element, ctx),
      "class" => classes,
      "variant_class" => variant_class,
      "merges_class" => Tsx.merges_class?(class_value),
      "props" => Tsx.spread?(element),
      "reads" => reads(styling <> " " <> styled(styling, ctx.styles)),
      "vars" => vars(styling),
      "children" => Enum.map(element.children, &node(&1, ctx))
    })
  end

  # The four expressions shadcn actually writes inside JSX. Each one carries a
  # decision the generated component has to make too, so each becomes a node
  # rather than being dropped.
  defp expression(code, ctx) do
    cond do
      literal = string_literal(code) ->
        %{"type" => "text", "value" => literal}

      # `children ?? <Default />` and `children || suggestion` are the same
      # decision: what to render when the caller passed nothing.
      match = Regex.run(~r/^children\s*(?:\?\?|\|\|)\s*(.+)$/s, code, capture: :all_but_first) ->
        %{"type" => "children", "default" => [fallback(hd(match), ctx)]}

      match = Regex.run(~r/^(.+?)\s*&&\s*(\(?\s*<.*)$/s, code, capture: :all_but_first) ->
        [condition, jsx] = match

        %{
          "type" => "optional",
          "when" => String.trim(condition),
          "children" => [node(jsx!(jsx), ctx)]
        }

      match = repeat_over(code) ->
        {collection, binding, jsx} = match

        %{
          "type" => "repeat_over",
          "collection" => collection,
          "binding" => binding,
          "children" => [node(jsx!(jsx), ctx)]
        }

      match = repeat(code) ->
        {length, binding, jsx} = match

        %{
          "type" => "repeat",
          "count" => length,
          "binding" => binding,
          "children" => [node(jsx!(jsx), ctx)]
        }

      # A bare value — `{text}`, `{error.message}` — is content the caller
      # supplies, so it becomes an attribute of the generated component rather
      # than markup.
      value?(code) ->
        %{"type" => "value", "code" => String.trim(code)}

      true ->
        raise """
        the spec reader met a JSX expression it cannot turn into markup: {#{code}}

        Every expression has to be understood, because a dropped one becomes a
        missing element in the generated component. Teach LiveShadcnTools.Spec
        what this expression means, or the component is not ready to generate.
        """
    end
  end

  # The other half of `children ?? …`. It is markup when it is markup, and a
  # prop the caller supplies when it is not: `children ?? suggestion` renders
  # the `suggestion` prop, and dropping it would leave the component blank
  # exactly when the caller relied on the default.
  defp fallback(code, ctx) do
    if String.contains?(code, "<"),
      do: node(jsx!(code), ctx),
      else: expression(code, ctx)
  end

  defp value?(code),
    do: Regex.match?(~r/^[a-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$/, String.trim(code))

  defp string_literal(code) do
    case String.trim(code) do
      <<q, _::binary>> = literal when q in [?", ?'] -> String.slice(literal, 1..-2//1)
      _ -> nil
    end
  end

  # `toasts.map((toast) => (<Toast />))` — one element per item in a list the
  # caller supplies.
  defp repeat_over(code) do
    pattern =
      ~r/^([A-Za-z_][A-Za-z0-9_.]*)\.map\(\(\s*([A-Za-z_][A-Za-z0-9_]*)[^)]*\)\s*=>\s*(.*)$/s

    case Regex.run(pattern, String.trim(code), capture: :all_but_first) do
      [collection, binding, body] -> {collection, binding, body}
      nil -> nil
    end
  end

  # `Array.from({ length: values.length }, (_, index) => (<Thumb />))`
  defp repeat(code) do
    pattern = ~r/^Array\.from\(\{\s*length:\s*(.+?)\s*\}\s*,\s*\(([^)]*)\)\s*=>\s*(.*)$/s

    case Regex.run(pattern, String.trim(code), capture: :all_but_first) do
      [length, args, body] ->
        binding = args |> String.split(",") |> Enum.map(&String.trim/1) |> List.last()
        {String.trim(length), binding, body}

      nil ->
        nil
    end
  end

  # The JSX inside an expression, found by its own delimiters rather than by
  # counting the brackets the expression wrapped it in.
  defp jsx!(code) do
    case :binary.match(code, "<") do
      :nomatch ->
        raise "the expression `#{String.slice(code, 0, 60)}` renders no markup"

      {start, _} ->
        finish = code |> :binary.matches(">") |> List.last() |> elem(0)
        Tsx.parse_jsx!(binary_part(code, start, finish - start + 1))
    end
  end

  # A variant table's own class strings are part of what this element reads, so
  # `data-` variants inside them are found the same way as the inline ones.
  defp variant_classes(nil, _ctx), do: ""

  defp variant_classes(binding, ctx) do
    case Cva.parse(Map.get(ctx.consts, binding, "")) do
      :error ->
        ""

      {:ok, table} ->
        [table["base"] | Enum.flat_map(table["variants"], fn {_, v} -> Map.values(v) end)]
        |> Enum.join(" ")
    end
  end

  # What the style sheets apply to this element's `cn-` classes. Every style is
  # taken together: an attribute one style reads has to be emitted whichever
  # style an application picks.
  defp styled(classes, styles) do
    wanted = classes |> String.split() |> Enum.filter(&cn_class?/1)

    styles
    |> Enum.flat_map(fn {_style, rules} -> Enum.map(wanted, &Map.get(rules, &1, "")) end)
    |> Enum.join(" ")
  end

  defp base_node(element, tag, ctx) do
    cond do
      # `<>…</>` — a React fragment groups children and renders nothing. HEEx
      # needs no grouping, so the children are simply emitted in place.
      tag == "" -> %{"type" => "transparent", "reason" => "a fragment"}
      tag == "IconPlaceholder" -> %{"type" => "icon", "icons" => icons(element)}
      tag =~ ~r/^[a-z]/ -> %{"type" => "element", "tag" => tag}
      Map.has_key?(ctx.functions, tag) -> %{"type" => "part_ref", "part" => Macro.underscore(tag)}
      base_ui?(tag, ctx) -> base_ui_node(tag, ctx)
      set = icon_set(tag, ctx) -> %{"type" => "icon", "icons" => %{set => tag}}
      prop = icon_prop(tag, ctx) -> %{"type" => "icon", "prop" => prop}
      registry_component(tag, ctx) -> registry_node(tag, ctx)
      role = external_role(tag, ctx) -> %{"type" => "external", "role" => role}
      context_provider?(tag) -> %{"type" => "transparent", "reason" => "a React context"}
      package = third_party(tag, ctx) -> raise not_base_ui(tag, package)
      true -> raise "the spec reader does not know what <#{tag}> is"
    end
  end

  # A third-party component whose job Elixir already does, mapped to the job
  # rather than to the library. The spec records `markdown`, not `Streamdown`
  # and not `PhoenixStreamdown`, so which renderer an application uses stays an
  # application's decision and the generated component names a seam.
  #
  # This table is short on purpose. A library goes in it only when the same job
  # exists in Elixir and is not worth writing again; everything else is still a
  # specialist recipe, and `not_base_ui/2` still says so.
  @external_roles %{"streamdown" => "markdown"}

  defp external_role(tag, ctx), do: Map.get(@external_roles, third_party(tag, ctx) || "")

  # shadcn writes an icon as `<IconPlaceholder lucide="ChevronDown" …>`, which
  # names the same icon in five sets at once. AI Elements imports the icon
  # itself. Both say the same thing — which icon, from which set — so both
  # become the same node and the icon package stays a configuration rather than
  # a dependency.
  @icon_packages %{
    "lucide-react" => "lucide",
    "@tabler/icons-react" => "tabler",
    "@hugeicons/react" => "hugeicons",
    "@phosphor-icons/react" => "phosphor",
    "@remixicon/react" => "remixicon"
  }

  defp icon_set(tag, ctx), do: Map.get(@icon_packages, Map.get(ctx.imports, tag, ""))

  # `{ icon: Icon = DotIcon }`, then `<Icon />`. React renames a prop that holds
  # a component, because JSX reads a lowercase tag as an HTML element. So the
  # rename says this prop is a thing to render, and the default says what kind
  # of thing: an icon, here, which is a name the caller passes rather than a
  # module it imports.
  defp icon_prop(tag, ctx) do
    with prop when is_binary(prop) <- Map.get(Map.get(ctx, :renames, %{}), tag),
         default when is_binary(default) <- Map.get(Map.get(ctx, :params_of) || %{}, prop),
         true <- icon_set(default, ctx) != nil do
      Macro.underscore(prop)
    else
      _ -> nil
    end
  end

  # An icon prop's default is a component upstream imported. Here it is the
  # icon's name, because that is what the caller passes.
  defp icon_default({name, default}, ctx) do
    if is_binary(default) and icon_set(default, ctx) do
      {name, icon_name(default)}
    else
      {name, default}
    end
  end

  @doc "`DotIcon` -> `dot`, the name a caller passes and every icon set uses."
  def icon_name(component) do
    component
    |> String.replace_suffix("Icon", "")
    |> Macro.underscore()
    |> String.replace("_", "-")
  end

  defp third_party(tag, ctx), do: Map.get(ctx.imports, tag |> String.split(".") |> hd())

  defp not_base_ui(tag, package) do
    """
    <#{tag}> comes from #{package}, which is not Base UI.

    There is no data-attribute contract to generate against, so this component
    needs a specialist recipe written against the library's own behaviour rather
    than a spec.
    """
  end

  # `SeparatorPrimitive` and `AccordionPrimitive.Trigger` both name a Base UI
  # part; the first is a component with one part, the second one of several.
  defp base_ui?(tag, ctx), do: base_ui_module(tag, ctx) != nil

  # The module a primitive alias was imported from, which is the page that
  # documents its parts. `@base-ui/react/menu` -> `menu`.
  defp base_ui_module(tag, ctx) do
    path = ctx.imports |> Map.get(tag |> String.split(".") |> hd(), "")

    cond do
      String.starts_with?(path, "@base-ui/react/") -> Path.basename(path)
      # A bare `@base-ui/react` import names no module, so the component's own
      # page is the only page it can mean.
      path == "@base-ui/react" -> ctx.doc.module
      true -> nil
    end
  end

  defp base_ui_node(tag, ctx) do
    {module, part} = base_ui_part!(tag, base_ui_module(tag, ctx), ctx)
    documented = ctx.docs[module].parts[part]

    if documented.renders? do
      %{"type" => "primitive", "module" => module, "part" => part, "tag" => documented.element}
    else
      # Base UI writes "Doesn't render its own HTML element" for these. There
      # is nothing to emit, and the children still have to reach the page.
      %{"type" => "transparent", "part" => part, "reason" => "renders no element"}
    end
  end

  # Returns the page the part is documented on, which is not always the page
  # named after the module it was imported from: Base UI documents `RadioGroup`
  # on the `radio` page, and shadcn imports it from `@base-ui/react/radio-group`.
  defp base_ui_part!(tag, module, ctx) do
    candidates =
      case String.split(tag, ".") do
        [_alias] -> root_names(module)
        segments -> [List.last(segments)]
      end

    found =
      for name <- candidates,
          page <- [module | Map.keys(ctx.docs)],
          Map.has_key?(Map.get(ctx.docs, page, %{parts: %{}}).parts, name),
          do: {page, name}

    case found do
      [pair | _] ->
        pair

      [] ->
        raise "shadcn renders #{tag}, which no fetched Base UI page documents" <>
                " (looked for #{Enum.join(candidates, " or ")})"
    end
  end

  # A bare primitive tag is the module's own root. Base UI names that section
  # after the module — `### Separator`, `### RadioGroup` — or calls it `Root`.
  defp root_names(module) do
    named =
      module |> String.replace("-", " ") |> String.split() |> Enum.map_join(&String.capitalize/1)

    [named, "Root"]
  end

  # A component built from another component that this pipeline also generates.
  # Two import shapes reach one:
  #
  #     import { Button } from "@/registry/bases/base/ui/button"     shadcn
  #     import { Shimmer } from "./shimmer"                          AI Elements
  #
  # Returns the source and the component, because which package the generated
  # module lands in follows from which registry it came out of.
  defp registry_component(tag, ctx) do
    case Map.get(ctx.imports, tag) do
      nil -> nil
      "./" <> file -> {"ai_elements", Path.basename(file)}
      path -> if String.contains?(path, "/ui/"), do: {"shadcn", Path.basename(path)}
    end
  end

  # The imported name, not the component, decides which function is called.
  # `Collapsible`, `CollapsibleTrigger` and `CollapsibleContent` all come out of
  # one file and are three different parts of it, and a reference that recorded
  # only the file would call the root three times.
  #
  # The key is `function` and not `part` because `render={<Button />}` merges
  # this node's keys over the primitive it replaces, and a `part` here would
  # shadow the Base UI part that primitive is documented under. That silently
  # dropped the dialog close button's `phx-click` once.
  defp registry_node(tag, ctx) do
    {source, component} = registry_component(tag, ctx)

    %{
      "type" => "component_ref",
      "source" => source,
      "component" => component,
      "function" => Macro.underscore(tag)
    }
  end

  defp context_provider?(tag), do: String.ends_with?(tag, [".Provider", ".Consumer"])

  @icon_sets ~w(lucide tabler hugeicons phosphor remixicon)

  defp icons(element) do
    Map.new(@icon_sets, fn set ->
      {set,
       case Tsx.attr(element, set) do
         {:string, name} -> name
         _ -> nil
       end}
    end)
  end

  # Everything upstream writes on the element other than its class and its
  # `data-slot`, which are recorded on their own. `data-size={size}` on a card
  # is as much a part of the markup as the class string is, and a generated
  # component that dropped it would render a different card.
  @recorded_elsewhere ~w(className data-slot render)

  defp attributes(element) do
    for {:attr, name, value} <- element.attrs, name not in @recorded_elsewhere do
      case value do
        {:string, literal} -> %{"name" => name, "kind" => "text", "value" => literal}
        {:expr, code} -> expression_attr(name, String.trim(code))
        true -> %{"name" => name, "kind" => "flag", "value" => nil}
      end
    end
  end

  # `style={{ "--ratio": ratio } as React.CSSProperties}` is a set of CSS
  # declarations, not an expression. Recording it as declarations is what lets
  # the generator write a style string instead of a JavaScript object.
  defp expression_attr("style", code) do
    case declarations(code) do
      nil -> %{"name" => "style", "kind" => "code", "value" => code}
      entries -> %{"name" => "style", "kind" => "style", "value" => entries}
    end
  end

  defp expression_attr(name, code), do: %{"name" => name, "kind" => "code", "value" => code}

  defp declarations(code) do
    with {at, _} <- :binary.match(code, "{"),
         {:ok, object} <- object(binary_part(code, at, byte_size(code) - at)) do
      Enum.map(object, fn
        {property, {:string, literal}} ->
          %{"property" => property, "kind" => "text", "value" => literal}

        {property, {:code, value}} ->
          %{"property" => property, "kind" => "code", "value" => value}

        {property, _other} ->
          %{"property" => property, "kind" => "code", "value" => "nil"}
      end)
    else
      _ -> nil
    end
  end

  defp object(code) do
    {:ok, Tsx.object!(code)}
  rescue
    _ -> :error
  end

  # Base UI's `render` prop replaces the element a part draws with one the
  # caller supplies, keeping the part's behaviour and merging its props on:
  #
  #     <Button render={<a data-slot="pagination-link" />} />
  #
  # A pagination link is a Button that is an `<a>`. The element it becomes is a
  # fact about the markup, so the spec records it rather than losing the tag.
  defp render_as(element, ctx) do
    with {:expr, code} <- Tsx.attr(element, "render"),
         true <- String.starts_with?(String.trim(code), "<") do
      node(Tsx.parse_jsx!(String.trim(code)), ctx)
    else
      _ -> nil
    end
  end

  defp slot(element) do
    case Tsx.attr(element, "data-slot") do
      {:string, slot} -> slot
      _ -> nil
    end
  end

  @doc """
  The attributes a class string keys on.

  Tailwind writes state as a variant prefix, so the class string says which
  attributes the element needs:

      data-ending-style:h-0                      -> self, data-ending-style
      aria-disabled:opacity-50                   -> self, aria-disabled
      group-aria-expanded/accordion-trigger:hidden -> group accordion-trigger,
                                                       aria-expanded

  Returns `%{"self" => [attr], "group" => [%{"group" => name, "attr" => attr}]}`.
  """
  def reads(classes) do
    {self, group} =
      classes
      |> String.split()
      |> Enum.flat_map(&prefixes/1)
      |> Enum.reduce({[], []}, fn variant, {self, group} ->
        case classify(variant) do
          {:self, attr} -> {[attr | self], group}
          {:group, name, attr} -> {self, [%{"group" => name, "attr" => attr} | group]}
          :ignore -> {self, group}
        end
      end)

    %{"self" => self |> Enum.reverse() |> Enum.uniq(), "group" => Enum.uniq(Enum.reverse(group))}
  end

  defp classify("group-" <> rest) do
    case String.split(rest, "/", parts: 2) do
      [attr, name] -> if state_attr?(attr), do: {:group, name, attr}, else: :ignore
      _ -> :ignore
    end
  end

  defp classify(variant) do
    if state_attr?(variant), do: {:self, variant}, else: :ignore
  end

  defp state_attr?(variant) do
    Regex.match?(~r/^(data|aria)-[a-z][a-z0-9-]*$/, variant)
  end

  # Splits `group-aria-expanded/accordion-trigger:hidden` into its variant
  # prefixes. Colons inside `[]` and `()` belong to an arbitrary value, not to a
  # variant, so bracket depth is tracked.
  defp prefixes(token), do: token |> segments(0, [], "") |> Enum.drop(-1)

  defp segments("", _depth, acc, current), do: Enum.reverse([current | acc])

  defp segments(<<c, rest::binary>>, depth, acc, current) do
    cond do
      c == ?: and depth == 0 -> segments(rest, depth, [current | acc], "")
      c in ~c"([{" -> segments(rest, depth + 1, acc, current <> <<c>>)
      c in ~c")]}" -> segments(rest, depth - 1, acc, current <> <<c>>)
      true -> segments(rest, depth, acc, current <> <<c>>)
    end
  end

  @doc """
  The CSS variables a class string interpolates, such as the
  `--accordion-panel-height` in `h-(--accordion-panel-height)`.

  A variable listed here has to be supplied at runtime, because no static class
  string can compute a height.
  """
  def vars(classes) do
    ~r/\(?(--[a-z][a-z0-9-]*)\)/
    |> Regex.scan(classes, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
  end
end
