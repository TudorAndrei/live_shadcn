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

  alias LiveShadcnTools.Ast
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
    tsx = Ast.parse!(Keyword.fetch!(opts, :tsx))

    docs =
      Map.new(Keyword.fetch!(opts, :markdown), fn {mod, md} -> {mod, BaseUi.parse!(md, mod)} end)

    doc = Map.get(docs, Keyword.get(opts, :module, name), BaseUi.parse!("", name))
    functions = Map.new(tsx.functions, &{&1.name, &1})
    variants = variants(tsx.const_nodes)

    ctx = %{
      doc: doc,
      docs: docs,
      styles: Keyword.get(opts, :styles, %{}),
      functions: functions,
      consts: tsx.consts,
      const_nodes: tsx.const_nodes,
      imports: tsx.imports,
      variants: Map.keys(variants),
      resolve: Keyword.get(opts, :resolve, fn _source, _name -> nil end)
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
      |> private_parts(ctx)
      |> fold(source, Keyword.get(opts, :resolve, fn _source, _name -> nil end))

    parts =
      parts
      |> Enum.map(fn part ->
        Map.update!(part, "tree", fn tree -> walk(tree, &written_content/1) end)
      end)
      |> Enum.map(&props_read(&1, variant_props(folded, variants)))

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
    |> sonner_stack(name)
    |> folds(folded)
  end

  # Sonner is a client toast manager. The server owns the equivalent list, so
  # its stack shape is a specification fact rather than a second HEEx design in
  # the toast recipe. The wrapper contributes its class, style, and toast
  # class; the hook contract names the geometry that the server must expose.
  defp sonner_stack(spec, "sonner") do
    tree = spec["parts"] |> Enum.find(&(&1["name"] == "toaster")) |> Map.fetch!("tree")

    style = tree["attrs"] |> Enum.find(&(&1["name"] == "style")) |> Map.fetch!("value")
    options = tree["attrs"] |> Enum.find(&(&1["name"] == "toastOptions")) |> Map.fetch!("value")

    Map.put(spec, "toast_stack", %{
      "container" => %{
        "tag" => tree["tag"],
        "class" => tree["class"],
        "style" => style,
        "role" => "region"
      },
      "item" => %{
        "tag" => "article",
        "slot" => "toast",
        "class" => get_in(options, ["classNames", "toast"]),
        "role" => "status",
        "live" => "polite",
        "order" => "newest_first"
      },
      "geometry" => %{
        "variables" => ~w(--toast-index --toast-height --toast-offset-y),
        "limit" => true
      }
    })
  end

  defp sonner_stack(spec, _name), do: spec

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

  # Every node of a tree, innermost first, through one change.
  defp walk(node, change) when is_map(node) do
    node
    |> Map.new(fn {key, value} -> {key, walk(value, change)} end)
    |> change.()
  end

  defp walk(nodes, change) when is_list(nodes), do: Enum.map(nodes, &walk(&1, change))
  defp walk(value, _change), do: value

  # A `<textarea>` has no value attribute. React accepts one and writes the
  # text between the tags on the way to the browser; HTML puts it there to
  # begin with, and a `value=` a browser ignores renders an empty box.
  defp written_content(%{"tag" => "textarea", "attrs" => attrs} = node) do
    case Enum.split_with(attrs, &(&1["name"] == "value")) do
      {[], _kept} ->
        node

      {[value | _duplicates], kept} ->
        node
        |> Map.put("attrs", kept)
        |> Map.put("children", [written(value) | Map.get(node, "children") || []])
    end
  end

  defp written_content(node), do: node

  defp written(%{"kind" => "code", "value" => code}), do: %{"type" => "value", "code" => code}
  defp written(%{"value" => literal}), do: %{"type" => "text", "value" => literal}

  # A part takes the props its markup reads, and no others.
  #
  # React keeps things a render needs and the markup never mentions: the object
  # it puts in a context, the state behind a controlled value. Upstream is
  # right to hold them and a template has no use for them, so declaring them
  # would ask a caller for a value that changes nothing on the page.
  #
  # `className` and `children` are the two the markup reads without naming.
  @always ~w(className children content render)

  defp props_read(part, variant_props) do
    references = MapSet.new((part["refs"] || []) ++ identifiers(part["tree"]))

    Map.update(part, "params", %{}, fn params ->
      Map.filter(params, fn {name, _default} ->
        name in @always or name in variant_props or
          MapSet.member?(references, name)
      end)
    end)
  end

  defp identifiers(%{"identifiers" => names} = node) when is_list(names) do
    names ++ (node |> Map.delete("identifiers") |> Map.values() |> Enum.flat_map(&identifiers/1))
  end

  defp identifiers(node) when is_map(node),
    do: node |> Map.values() |> Enum.flat_map(&identifiers/1)

  defp identifiers(nodes) when is_list(nodes), do: Enum.flat_map(nodes, &identifiers/1)
  defp identifiers(_node), do: []

  # A `cva` group is read without being named either: `size` is not written in
  # the markup, it picks the class string the markup carries.
  defp variant_props(folded, own) do
    for table <- Map.values(merged(folded, "variants")) ++ Map.values(own),
        group <- Map.keys(Map.get(table, "variants") || %{}),
        uniq: true,
        do: group
  end

  @doc "Every piece of JavaScript a tree still holds, wherever it holds one."
  def codes(%{"kind" => "code", "value" => value}) when is_binary(value), do: [value]
  def codes(%{"type" => "value", "code" => code}) when is_binary(code), do: [code]

  # `{ …, ...style }` reads a prop by name rather than by an expression, and a
  # part that renders one still takes it. Left out, `sidebar_provider` wrote
  # `#{@style}` into its style attribute and declared no `style` to read.
  def codes(%{"kind" => "spread", "property" => name}) when is_binary(name), do: [name]

  def codes(node) when is_map(node) do
    named = for key <- ~w(when collection binding count key), is_binary(node[key]), do: node[key]
    named ++ (node |> Map.values() |> Enum.flat_map(&codes/1))
  end

  def codes(nodes) when is_list(nodes), do: Enum.flat_map(nodes, &codes/1)
  def codes(_node), do: []

  @doc "The identifier roots of member expressions a tree records."
  def member_roots(%{"member_roots" => roots} = node) when is_list(roots) do
    roots ++
      (node
       |> Map.delete("member_roots")
       |> Map.values()
       |> Enum.flat_map(&member_roots/1))
  end

  def member_roots(node) when is_map(node),
    do: node |> Map.values() |> Enum.flat_map(&member_roots/1)

  def member_roots(nodes) when is_list(nodes), do: Enum.flat_map(nodes, &member_roots/1)
  def member_roots(_node), do: []

  # A component this file declares and does not export.
  #
  # `context` renders `<TokensWithCost>` in three of its parts and exports none
  # of them, because upstream keeps it to itself. A generated module has one
  # function per exported part, so a call to that name reaches a function
  # nobody wrote — and only the compiler says so. Its markup comes across
  # instead, wherever it was called, with the arguments it was called with.
  defp private_parts(parts, ctx) do
    exported = MapSet.new(parts, & &1["name"])

    private =
      for {name, function} <- ctx.functions,
          function.renders?,
          underscored = Macro.underscore(name),
          not MapSet.member?(exported, underscored) do
        %{
          "name" => underscored,
          "params" => function.params,
          "refs" => function.refs,
          "types" => function.param_types,
          "tree" => node(function.jsx, private_ctx(ctx, function))
        }
      end

    Enum.map(parts, &Map.put(&1, "tree", inline_parts(&1["tree"], %{"parts" => private}, [])))
  end

  defp private_ctx(ctx, function) do
    ctx
    |> Map.put(:renames, function.renames)
    |> Map.put(:params_of, function.params)
    |> Map.put(:locals, function.locals)
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
        params = known(acc.params, Map.get(part, "params") || %{})

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
          params: known(Map.get(target, "params") || %{}, acc.params)
      }

      # The reference's own children first. `<DropdownMenuTrigger><Button /></…>`
      # is two references, and matching the outer one here means nothing else
      # will ever look inside it: the children go straight into the tree the
      # outer one folds to, and the inner reference would arrive unread.
      {node, acc} = fold_children(node, source, resolve, acc)

      # The target may itself reference a third component, and from here that
      # one is just as far away. Its own `cva` call is narrowed to what this
      # reference passed *before* it goes down, because each level knows only
      # about its own reference and narrowing again on the way back up would
      # answer for a reference two components away.
      inlined = inline_parts(narrow(target["tree"], node), spec, [])

      {tree, acc} = fold_node(inlined, source, resolve, acc)
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
      |> substitute(arguments(node, part))
      |> absorb(node, Map.get(part, "params") || %{})
    else
      # An exported wrapper can contain a private helper. We keep the wrapper
      # as a part reference, but still walk the children passed to it: `Toaster`
      # passes `<ToastList />` through three exported wrappers before that local
      # list function is reached. Stopping here loses the list and its markup.
      _ -> Map.update(node, "children", [], &inline_parts(&1, spec, seen))
    end
  end

  defp inline_parts(node, spec, seen) when is_map(node),
    do: Map.new(node, fn {key, value} -> {key, inline_parts(value, spec, seen)} end)

  defp inline_parts(nodes, spec, seen) when is_list(nodes),
    do: Enum.map(nodes, &inline_parts(&1, spec, seen))

  defp inline_parts(value, _spec, _seen), do: value

  # What a reference passed, by the name the part reads it under.
  #
  # `<TokensWithCost costText={inputCostText} tokens={inputTokens} />` sets two
  # props, and the part's markup reads `costText` and `tokens`. Once that markup
  # is here those names mean nothing: what it should read is what the caller
  # passed.
  defp arguments(node, part) do
    params = Map.get(part, "params") || %{}

    for %{"name" => name, "kind" => "code", "value" => value} <- Map.get(node, "attrs") || [],
        Map.has_key?(params, name),
        into: %{},
        do: {name, value}
  end

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
      "class_when" => (tree["class_when"] || []) ++ (node["class_when"] || []),
      # Both tables. `input-group`'s button renders shadcn's `<Button>` and adds
      # `inputGroupButtonVariants({ size })` to what the button already builds,
      # so the element wears two bases and two `size` groups reading two values.
      "variant_calls" => (tree["variant_calls"] || []) ++ (node["variant_calls"] || []),
      "merges_class" => node["merges_class"] || tree["merges_class"],
      "props" => node["props"] || tree["props"],
      "slot" => node["slot"] || tree["slot"]
    })
    |> place(Map.get(node, "children") || [])
  end

  # Two defaults for one prop, and the nearer one wins.
  #
  # `snippet` folds `input-group`'s button, which folds `shadcn/button`. Both
  # give `variant` a default — `"ghost"` and `"default"` — and upstream's answer
  # is `"ghost"`, because the input group is what calls the button and an
  # explicit prop beats the callee's own default. Merged the other way, the copy
  # button declared a default nobody chose.
  defp known(into, params),
    do: Map.merge(into, params, fn _name, mine, theirs -> theirs || mine end)

  defp narrow(tree, node),
    do: Map.put(tree, "variant_calls", narrowed(tree["variant_calls"], node))

  # What the reference passed the folded component's own `cva` call.
  #
  # A reference that names no prop is forwarding: `<InputGroupAddon {...props} />`
  # hands over everything it was given, `align` included. One that names any is
  # choosing, and what it did not name it did not pass — `<Button variant={variant}
  # data-size={size} className={…} />` sets the variant and deliberately does not
  # set the size, so the button's own `size` group takes the button's own
  # default and stops asking for an assign that means something else.
  defp narrowed(calls, node) do
    case for(attr <- Map.get(node, "attrs") || [], do: attr["name"]) do
      [] ->
        calls || []

      passed ->
        for call <- calls || [],
            do: Map.update(call, "args", [], fn args -> Enum.filter(args, &(&1 in passed)) end)
    end
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

  A reference that wrapped nothing still replaces the marker — with the default
  the marker carries, or with nothing at all. `<CheckpointIcon />` renders
  `children ?? <BookmarkIcon />`, and leaving the marker there made the icon
  draw whatever the *trigger* was given, a second time.

  A component whose markup has no marker takes the content at the end, which is
  the only place left.
  """
  def place(%{"type" => "children"} = marker, children) do
    # The whole of what the reference points at is the marker: `CheckpointIcon`
    # is `children ?? <BookmarkIcon />` and nothing else.
    case {children, Map.get(marker, "default")} do
      {[], nil} -> %{"type" => "transparent", "reason" => "nothing was passed"}
      {[], default} -> hd(List.wrap(default))
      {[child], _default} -> child
      {children, _default} -> %{"type" => "transparent", "children" => children}
    end
  end

  def place(tree, children) do
    case replace(tree, children) do
      {tree, true} -> tree
      {tree, false} when children == [] -> tree
      {tree, false} -> Map.put(tree, "children", (Map.get(tree, "children") || []) ++ children)
    end
  end

  defp replace(node, children) when is_map(node) do
    {placed, done?} = replace(Map.get(node, "children") || [], children)
    {Map.put(node, "children", placed), done?}
  end

  defp replace(nodes, children) when is_list(nodes) do
    Enum.flat_map_reduce(nodes, false, fn
      # Nothing was passed, so what the marker falls back to is what is drawn.
      %{"type" => "children"} = marker, false when children == [] ->
        {List.wrap(Map.get(marker, "default")), true}

      %{"type" => "children"}, false ->
        {children, true}

      node, done? when is_map(node) ->
        replace_one(node, children, done?)

      node, done? ->
        {[node], done?}
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
  # a factory such as `createToastManager`. The parsed function tells us whether
  # it renders JSX, so an export name does not decide its role.
  defp component?(export, ctx) do
    case Map.get(ctx.functions, export) do
      %{renders?: renders?} -> renders?
      nil -> renders?(Map.get(ctx.consts, export))
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
        ctx =
          ctx
          |> Map.put(:renames, function.renames)
          |> Map.put(:params_of, function.params)
          |> Map.put(:locals, function.locals)

        %{
          "name" => Macro.underscore(export),
          "export" => export,
          "primitive" => primitive_of(function.props_type),
          "params" => Map.new(function.params, &icon_default(&1, ctx)),
          "refs" => function.refs,
          "types" => function.param_types,
          "contexts" => function.contexts |> MapSet.to_list() |> Enum.sort(),
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

  defp node(%{type: :expr, code: code, node: expression_node}, ctx) do
    expression({:expr, code, expression_node}, ctx)
    |> record_expression_facts(expression_node)
  end

  defp node(%{type: :text, value: value}, _ctx),
    do: %{"type" => "text", "value" => String.trim(value)}

  defp node(%{type: :element, tag: tag} = element, ctx) do
    class_value = Tsx.attr(element, "className")
    variant_calls = Tsx.variant_calls(class_value, ctx.variants)
    classes = Tsx.classes(class_value)
    class_when = Tsx.conditional_classes(class_value)

    styling =
      Enum.join(
        Enum.map(variant_calls, &variant_classes(&1["table"], ctx)) ++
          [classes | conditional_styling(class_when)],
        " "
      )

    element
    |> base_node(tag, ctx)
    |> Map.merge(%{
      "slot" => slot(element),
      "attrs" => attributes(element, ctx),
      "render_as" => render_as(element, ctx),
      "class" => classes,
      "class_when" => class_when,
      "variant_calls" => variant_calls,
      "merges_class" => Tsx.merges_class?(class_value),
      "props" => Tsx.spread?(element),
      "reads" => reads(styling <> " " <> styled(styling, ctx.styles)),
      "vars" => vars(styling),
      "children" => Enum.map(element.children, &node(&1, ctx))
    })
    |> external_defaults()
    |> forget_context_value()
  end

  # The questionnaire library chooses a radio input for a choice when the
  # caller does not provide one. That is browser-visible: an untyped input is
  # a text field, with different overflow and border defaults.
  defp external_defaults(
         %{"module" => "external/@shadcn/react/questionnaire", "part" => "ChoiceInput"} = node
       ) do
    Map.update!(node, "attrs", &[%{"kind" => "text", "name" => "type", "value" => "radio"} | &1])
  end

  # `input-otp` passes this property to its React wrapper. The mapped primitive
  # is the input the browser renders, so keeping it would create an unknown
  # HTML attribute and ask generated HEEx to evaluate the upstream `cn(...)`
  # call as Elixir.
  defp external_defaults(%{"module" => "external/input-otp", "part" => "Input"} = node) do
    Map.update!(
      node,
      "attrs",
      &Enum.reject(&1, fn attr -> attr["name"] == "containerClassName" end)
    )
  end

  # These are properties of the message-scroller React primitives. Their
  # browser-visible values are represented by the data attributes the wrapper
  # already writes, not by unknown HTML attributes.
  defp external_defaults(
         %{"module" => "external/@shadcn/react/message-scroller", "part" => part} = node
       )
       when part in ["Item", "Button"] do
    Map.update!(
      node,
      "attrs",
      &Enum.reject(&1, fn attr -> attr["name"] in ["direction", "scrollAnchor"] end)
    )
  end

  defp external_defaults(node), do: node

  # `<QuestionContext.Provider value={contextValue}>` puts an object in the
  # React tree for the descendants below it to read. It draws nothing, and the
  # object it holds is not markup, so the provider keeps neither.
  defp forget_context_value(%{"type" => "transparent", "reason" => "a React context"} = node),
    do: Map.put(node, "attrs", [])

  defp forget_context_value(node), do: node

  # The four expressions shadcn actually writes inside JSX. Each one carries a
  # decision the generated component has to make too, so each becomes a node
  # rather than being dropped.
  defp expression({:expr, code, _node} = expression, ctx) do
    cond do
      literal = string_literal(code) ->
        %{"type" => "text", "value" => literal}

      # `{comp}`, where `comp` is a `useRender` call bound to a name. It is the
      # component's own body, written as data and rendered somewhere the
      # component only decides once it knows what to wrap it in.
      element = local_render(code, ctx) ->
        element

      # `children ?? <Default />` and `children || suggestion` are the same
      # decision: what to render when the caller passed nothing.
      match = default_for_children(expression) ->
        %{"type" => "children", "default" => [fallback(match, ctx)]}

      # `{frame.filePath && (<span>…</span>)}` — markup drawn only when the
      # condition holds.
      match = only_when(expression) ->
        {condition, jsx} = match

        %{"type" => "optional", "when" => condition, "children" => [markup(jsx, ctx)]}

      # `{tooltip ? <Tooltip>…</Tooltip> : button}` — one of two things, chosen
      # at render. `:if` on each is what HEEx has and it says the same: the
      # condition decides, and only one is drawn.
      match = choice(expression) ->
        {condition, yes, no} = match

        %{
          "type" => "choice",
          "when" => condition,
          "then" => [branch(yes, ctx)],
          "else" => [branch(no, ctx)]
        }

      match = repeat_over(expression) ->
        {collection, binding, fields, counter, jsx} = match

        %{
          "type" => "repeat_over",
          "collection" => source(collection),
          "binding" => binding,
          # `({ token, key }) => …` reads two names off the item without naming
          # the item. HEEx binds one name per generator, so the fields are read
          # off that name instead.
          "fields" => fields,
          "counter" => counter,
          "children" => [markup(jsx, ctx)]
        }

      match = repeat(expression) ->
        {length, binding, jsx} = match

        %{
          "type" => "repeat",
          "count" => source(length),
          "binding" => binding,
          "children" => [markup(jsx, ctx)]
        }

      # `{getStatusBadge(state)}` — a helper in this file that renders markup.
      # It is not a component, because JSX would read a lowercase tag as an HTML
      # element, so upstream calls it instead. Its markup belongs to whoever
      # called it, and the argument it was called with takes the place of the
      # parameter it was written against.
      inlined = local_call(code, ctx) ->
        inlined

      # `{Icon}` — a component held under a name and rendered by naming it.
      # JSX lets a capitalised name stand on its own where an element would,
      # and it means what `<Icon />` means.
      local = component_named(code, ctx) ->
        local

      # `{statusLabels[status]}` — a table upstream declared once, read by a
      # prop. The table is data and the prop is a prop, so both come across.
      lookup = lookup(expression, ctx) ->
        lookup

      # `{getThinkingMessage(isStreaming, duration)}` — a prop that is a
      # function, called to produce markup. React calls it a render prop; HEEx
      # calls it a slot, and they mean the same thing: the caller decides what
      # goes here, and the component decides where.
      #
      # Its default is not ported. Upstream writes one as a function full of
      # conditionals, and a slot has no place to run those; what carries over is
      # the contract — this content is the caller's — and the caller supplies it.
      name = render_prop(code, ctx) ->
        %{"type" => "slot", "name" => name}

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
  defp fallback(code, ctx), do: markup(code, ctx)

  # A value the caller supplies, possibly with arithmetic or a default around
  # it: `{count}`, `{error.message}`, `{currentBranch + 1}`, `{title ?? name}`.
  #
  # What makes these one kind of thing is that every name in them is a name, and
  # the generator decides whether it knows it. Refusing them here would refuse
  # them for the wrong reason — the reader's job is to say what the expression
  # is, and `{currentBranch + 1}` is a value however the number is reached.
  @value ~r/^[a-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$/
  @arithmetic ~r/^[a-z_][A-Za-z0-9_.]*(\s*(\+|-|\*|\/|\?\?)\s*([a-z_][A-Za-z0-9_.]*|-?\d+))+$/
  # `errorText ? "Error" : "Result"` — a choice between two values, which is a
  # value. A choice between two pieces of markup contains `<` and is not one.
  @ternary ~r/^[^?<]+\?[^:<]+:[^<]+$/s

  defp local_call(code, ctx) do
    with [callee, args] <-
           Regex.run(~r/^([a-z_][A-Za-z0-9_]*)\((.*)\)$/s, String.trim(code),
             capture: :all_but_first
           ),
         {:ok, helper} <- Map.fetch(ctx.functions, callee) do
      helper.jsx
      |> node(%{ctx | params_of: helper.params, renames: helper.renames})
      |> substitute(bind(helper.params, args))
    else
      _ -> nil
    end
  end

  # The helper's parameters, by the expressions it was called with. A helper
  # written against `status` and called with `state` reads `state` here.
  defp bind(params, args) do
    args
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.zip(params |> Map.keys() |> Enum.sort())
    |> Map.new(fn {argument, param} -> {param, argument} end)
  end

  defp substitute(node, bindings) when is_map(node) do
    node
    |> Map.new(fn {key, value} -> {key, substitute(value, bindings)} end)
    |> rebind(bindings)
  end

  defp substitute(nodes, bindings) when is_list(nodes),
    do: Enum.map(nodes, &substitute(&1, bindings))

  defp substitute(value, _bindings), do: value

  defp rebind(%{"type" => "lookup", "key" => key} = node, bindings),
    do: %{node | "key" => Map.get(bindings, key, key)}

  defp rebind(%{"type" => "value", "code" => code} = node, bindings),
    do: %{node | "code" => Map.get(bindings, code, code)}

  # An attribute reads a name too — `<Progress value={percent} />` inside a
  # component called with `percent={usedPercent}` has to read `usedPercent`.
  defp rebind(%{"kind" => "code", "value" => value} = attr, bindings),
    do: %{attr | "value" => Map.get(bindings, value, value)}

  defp rebind(%{"when" => condition} = node, bindings),
    do: %{node | "when" => Map.get(bindings, condition, condition)}

  defp rebind(node, _bindings), do: node

  # `table[key]`, where `table` is an object this file declared at the top level.
  #
  # React writes a lookup table for the same reason a `cva` table exists: a
  # value per state, written once, read by whichever state the caller is in.
  # `cva` is already read as data, and this is the same fact in a plainer shape.
  #
  # The entries come across as nodes, because a table's values are as often
  # markup as they are strings — `statusIcons` holds one icon per tool state.
  defp lookup({:expr, _code, node}, ctx) do
    with %{
           "type" => "MemberExpression",
           "computed" => true,
           "object" => %{"type" => "Identifier", "name" => name},
           "property" => %{"type" => "Identifier", "name" => key}
         } <- node,
         table when map_size(table) > 0 <- Map.get(ctx.const_nodes, name) |> Ast.object_entries() do
      %{
        "type" => "lookup",
        "key" => key,
        "entries" =>
          for {value, entry} <- Enum.sort(table) do
            %{"value" => value, "node" => entry_node(entry, ctx)}
          end
      }
    else
      _ -> nil
    end
  end

  defp entry_node({:expr, _code, _node} = entry, ctx) do
    case Ast.string_literal(entry) do
      nil -> markup(entry, ctx)
      value -> %{"type" => "text", "value" => value}
    end
  end

  # A call whose callee is a prop this component destructured. A call to
  # anything else is a local function, and porting one means porting whatever it
  # computes rather than declaring a slot for it.
  defp render_prop(code, ctx) do
    with [callee] <-
           Regex.run(~r/^([a-z_][A-Za-z0-9_]*)\(.*\)$/s, String.trim(code),
             capture: :all_but_first
           ),
         true <- Map.has_key?(Map.get(ctx, :params_of) || %{}, callee) do
      Macro.underscore(callee)
    else
      _ -> nil
    end
  end

  defp value?(code) do
    code = String.trim(code)

    Regex.match?(@value, code) or Regex.match?(@arithmetic, code) or
      Regex.match?(@ternary, code)
  end

  defp string_literal(code) do
    case String.trim(code) do
      <<q, _::binary>> = literal when q in [?", ?'] -> String.slice(literal, 1..-2//1)
      _ -> nil
    end
  end

  # `children ?? X`, by the parser rather than by a regular expression: where
  # the left side stops is the same question a ternary asks.
  defp default_for_children({:expr, _code, _node} = expression) do
    case Ast.logical(expression) do
      {operator, left, default} when operator in ~w(?? ||) ->
        if source(left) == "children", do: default

      _ ->
        nil
    end
  end

  # `condition && <markup>`. Only when the right side is markup: `a && b` with
  # no element in it is a value, and the generator reads it as one.
  defp only_when({:expr, _code, _node} = expression) do
    case Ast.logical(expression) do
      {"&&", condition, right} -> if Ast.jsx(right), do: {source(condition), right}
      _ -> nil
    end
  end

  # A ternary with markup on at least one side. Which `?` is the ternary's is a
  # question for the parser, not for a bracket count: a `?` inside a string, or
  # between two JSX tags, is at no depth at all.
  defp choice({:expr, _code, _node} = expression) do
    case Ast.conditional(expression) do
      {condition, yes, no} ->
        if Ast.jsx(yes) || Ast.jsx(no), do: {source(condition), yes, no}

      _ ->
        nil
    end
  end

  # What a loop or a condition draws. Usually one element; sometimes another
  # expression, because `lines.map((line) => line.tokens.map(…))` is a loop
  # whose body is a loop, and reading that as an element asks for a `<` that is
  # three tokens further in.
  defp markup(code, ctx) when is_binary(code) do
    trimmed = String.trim(code)

    case Ast.parse_jsx(trimmed) do
      nil -> markup(expression_tuple!(trimmed), ctx)
      parsed -> node(parsed, ctx)
    end
  end

  defp markup({:expr, _code, _node} = expression, ctx) do
    case Ast.jsx(expression) do
      nil -> expression(expression, ctx)
      parsed -> node(parsed, ctx)
    end
  end

  # `expression/2` takes `{:expr, code, node}` since the parser swap, and this
  # is one of the two places that still held an expression as a string. It used
  # to hand the string straight over, which matched no clause — a
  # `FunctionClauseError` that `mix ui.spec` rescued and reported as "a JSX
  # expression it cannot turn into markup". The component was named, the reason
  # was not, and dialyzer is what found it.
  defp expression_tuple!(code) do
    case Ast.expression_of(code) do
      nil -> raise "the spec reader cannot parse #{inspect(String.slice(code, 0, 60))}"
      expression -> expression
    end
  end

  defp source({:expr, code, _node}), do: String.trim(code)

  # One side of a choice: markup, or a value when upstream renders one there.
  defp branch(code, ctx), do: markup(code, ctx)

  # `toasts.map((toast) => (<Toast />))` — one element per item in a list the
  # caller supplies.
  defp repeat_over(expression), do: Ast.mapped(expression)

  # `Array.from({ length: values.length }, (_, index) => (<Thumb />))`
  defp repeat(expression), do: Ast.counted(expression)

  # A class string an element wears only sometimes still says what the element
  # reads: `data-open:hidden` is a contract whichever branch carries it.
  defp conditional_styling(class_when),
    do: Enum.flat_map(class_when, &[&1["then"] || "", &1["else"] || ""])

  # A variant table's own class strings are part of what this element reads, so
  # `data-` variants inside them are found the same way as the inline ones.
  defp variant_classes(binding, ctx) do
    case Cva.parse(Map.get(ctx.const_nodes, binding)) do
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
      local = local_tag(tag, ctx) -> local
      registry_component(tag, ctx) -> registry_node(tag, ctx)
      primitive = external_primitive(tag, ctx) -> primitive
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

  # A third-party primitive can still be read when an existing recipe owns its
  # behaviour. The package supplies no Base UI page, so this table supplies the
  # rendered HTML contract instead. It is deliberately keyed by the imported
  # primitive, not by a component name: one package can contain controls with
  # different roles and tags.
  #
  # Questionnaire is markup only. Its state machine belongs to the caller, so
  # the presentational recipe can render its documented shape without adding a
  # client dependency.
  @external_primitives %{
    "@shadcn/react/questionnaire" => %{
      "QuestionnairePrimitive.Root" => {"Root", "form"},
      "QuestionnairePrimitive.Progress" => {"Progress", "div"},
      "QuestionnairePrimitive.Item" => {"Item", "fieldset"},
      "QuestionnairePrimitive.Title" => {"Title", "legend"},
      "QuestionnairePrimitive.Description" => {"Description", "p"},
      "QuestionnairePrimitive.Choices" => {"Choices", "div"},
      "QuestionnairePrimitive.Choice" => {"Choice", "label"},
      "QuestionnairePrimitive.ChoiceInput" => {"ChoiceInput", "input"},
      "QuestionnairePrimitive.ChoiceLabel" => {"ChoiceLabel", "span"},
      "QuestionnairePrimitive.ChoiceShortcut" => {"ChoiceShortcut", nil},
      "QuestionnairePrimitive.Input" => {"Input", "input"},
      "QuestionnairePrimitive.Error" => {"Error", "p"},
      "QuestionnairePrimitive.Actions" => {"Actions", "div"},
      "QuestionnairePrimitive.Previous" => {"Previous", "button"},
      "QuestionnairePrimitive.Skip" => {"Skip", "button"},
      "QuestionnairePrimitive.Next" => {"Next", "button"},
      "QuestionnairePrimitive.Submit" => {"Submit", "button"}
    },
    "cmdk" => %{
      "CommandPrimitive" => {"Root", "div"},
      "CommandPrimitive.Input" => {"Input", "input"},
      "CommandPrimitive.List" => {"List", "div"},
      "CommandPrimitive.Empty" => {"Empty", "div"},
      "CommandPrimitive.Group" => {"Group", "div"},
      "CommandPrimitive.Separator" => {"Separator", "div"},
      "CommandPrimitive.Item" => {"Item", "div"}
    },
    "sonner" => %{
      "Sonner" => {"Toaster", "section"}
    },
    "input-otp" => %{
      "OTPInput" => {"Input", "input"}
    },
    "@shadcn/react/message-scroller" => %{
      "MessageScrollerPrimitive.Provider" => {"Provider", nil},
      "MessageScrollerPrimitive.Root" => {"Root", "div"},
      "MessageScrollerPrimitive.Viewport" => {"Viewport", "div"},
      "MessageScrollerPrimitive.Content" => {"Content", "div"},
      "MessageScrollerPrimitive.Item" => {"Item", "div"},
      "MessageScrollerPrimitive.Button" => {"Button", "button"}
    },
    "react-resizable-panels" => %{
      "ResizablePrimitive.Group" => {"Group", "div"},
      "ResizablePrimitive.Panel" => {"Panel", "div"},
      "ResizablePrimitive.Separator" => {"Separator", "div"}
    }
  }

  defp external_primitive(tag, ctx) do
    case third_party(tag, ctx) do
      package when is_binary(package) -> external_part(package, tag)
      _not_third_party -> nil
    end
  end

  defp external_part(package, tag) do
    case get_in(@external_primitives, [package, tag]) do
      {part, nil} ->
        %{
          "type" => "transparent",
          "part" => part,
          "reason" => "an external primitive that renders nothing"
        }

      {part, element} when is_binary(element) ->
        %{
          "type" => "primitive",
          "module" => "external/#{package}",
          "part" => part,
          "tag" => element
        }

      _unmapped ->
        nil
    end
  end

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

  # `const Icon = isCopied ? CheckIcon : CopyIcon`, and then `<Icon />`.
  #
  # A copy button shows a tick for a moment after it copies, and upstream writes
  # that as one name holding one of two icons. The name is local to the render
  # and means nothing here, so what the tag refers to is the value: two icons
  # and the condition that chooses between them, which is a choice like any
  # other.
  #
  # A local holding anything else is not a tag this can read, and saying so by
  # name is better than reading the wrong thing.
  defp local_tag(tag, ctx) do
    with value when is_binary(value) <- Map.get(Map.get(ctx, :locals) || %{}, tag),
         {condition, yes, no} <- Ast.conditional(value) do
      %{
        "type" => "choice",
        "when" => condition,
        "then" => [node(element(yes), ctx)],
        "else" => [node(element(no), ctx)]
      }
    else
      _ -> nil
    end
  end

  defp local_render(code, ctx) do
    with value when is_binary(value) <- Map.get(Map.get(ctx, :locals) || %{}, String.trim(code)),
         element when is_map(element) <- Ast.rendered(value) do
      node(element, ctx)
    else
      _other -> nil
    end
  end

  # A component named but not written as a tag. `isCopied ? CheckIcon : CopyIcon`
  # names two, and each is what `<CheckIcon />` would have been.
  defp element(name), do: %{type: :element, tag: String.trim(name), attrs: [], children: []}

  # A capitalised name standing where an element would. Only when this file can
  # say what it is: a lone `Foo` that nothing declared is a name nobody bound,
  # and the raise below says so rather than this drawing an empty element.
  defp component_named(code, ctx) do
    name = String.trim(code)

    if Regex.match?(~r/^[A-Z][A-Za-z0-9_]*$/, name) and known?(name, ctx),
      do: node(element(name), ctx)
  end

  defp known?(name, ctx) do
    Map.has_key?(Map.get(ctx, :locals) || %{}, name) or Map.has_key?(ctx.functions, name) or
      Map.has_key?(ctx.imports, name)
  end

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
    function = Macro.underscore(tag)

    %{
      "type" => "component_ref",
      "source" => source,
      "component" => component,
      "function" => function,
      # The element the reference ends up as, so the generated component can
      # declare the attributes that element takes. `field_label` renders
      # shadcn's `Label`, which renders a `<label>`, and a label without a
      # `for` names nothing — which axe-core says and a spec that stopped at
      # "it is a reference" could not.
      "tag" => referenced_tag(source, component, function, ctx),
      # And which recipe the component it names is built by, because that
      # decides whether the function it names will exist. A recipe that folds
      # writes one function per component; `menubar` names fifteen parts of
      # `dropdown-menu`, and the menu recipe writes `dropdown_menu/1` and no
      # others.
      "recipe" => referenced_recipe(source, component, ctx)
    }
  end

  defp referenced_recipe(source, component, ctx) do
    with resolve when is_function(resolve, 2) <- Map.get(ctx, :resolve),
         spec when is_map(spec) <- resolve.(source, component) do
      spec["recipe"]
    else
      _unresolved -> nil
    end
  end

  defp referenced_tag(source, component, function, ctx) do
    with resolve when is_function(resolve, 2) <- Map.get(ctx, :resolve),
         spec when is_map(spec) <- resolve.(source, component),
         part when is_map(part) <- find_part(spec, function) do
      part["tree"]["tag"]
    else
      _ -> nil
    end
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
  #
  # `key` is not markup at all: it is how React tells one item of a list from
  # another between renders, and no element has an attribute by that name.
  @recorded_elsewhere ~w(className data-slot render key)

  # What HTML calls the attribute React writes in camelCase.
  #
  # A browser forgives it — attribute names are case-insensitive — so
  # `tabIndex="-1"` works and reads as though somebody had not noticed. Only
  # the names that differ are listed: `viewBox` and `strokeWidth` are camelCase
  # in SVG too, and lowercasing everything would break them.
  @html_names %{
    "autoComplete" => "autocomplete",
    "autoFocus" => "autofocus",
    "colSpan" => "colspan",
    "contentEditable" => "contenteditable",
    "crossOrigin" => "crossorigin",
    "dateTime" => "datetime",
    "formAction" => "formaction",
    "htmlFor" => "for",
    "maxLength" => "maxlength",
    "minLength" => "minlength",
    "noValidate" => "novalidate",
    "readOnly" => "readonly",
    "rowSpan" => "rowspan",
    "spellCheck" => "spellcheck",
    "srcSet" => "srcset",
    "tabIndex" => "tabindex"
  }

  defp attributes(element, ctx) do
    for {:attr, written, value} <- element.attrs,
        written not in @recorded_elsewhere,
        not react_handler?(written),
        name = Map.get(@html_names, written, written) do
      case value do
        {:string, literal} ->
          %{"name" => name, "kind" => "text", "value" => literal}

        {:expr, code} ->
          expression_attr(name, String.trim(code), ctx)

        {:expr, code, node} ->
          expression_attr(name, {:expr, String.trim(code), node}, ctx)
          |> record_expression_facts(node)

        true ->
          %{"name" => name, "kind" => "flag", "value" => nil}
      end
    end
  end

  # A name bound to a literal at the top of the file is that literal.
  #
  # `sidebar` writes `const SIDEBAR_WIDTH = "16rem"` and then
  # `style={{ "--sidebar-width": SIDEBAR_WIDTH }}`. Upstream names it because
  # three other places read it; here there is one place, and asking a caller
  # for a value upstream fixed would be asking them to guess it.
  defp constant(code, ctx) do
    case Map.get(Map.get(ctx, :consts) || %{}, String.trim(code)) do
      nil -> nil
      source -> string_literal(String.trim(source))
    end
  end

  # `onSubmit={handleSubmit}` is how React attaches a browser event to a
  # closure that lives inside the render. HEEx attaches the same event with
  # `phx-submit`, and the caller passes that through `@rest`. Writing the React
  # name out would put a DOM attribute in the output whose value names an
  # Elixir assign, which is neither the event nor the handler.
  defp react_handler?(name), do: name =~ ~r/^on[A-Z]/

  # Sonner gives each toast part its class through `toastOptions`. This is data,
  # not JavaScript that the generated component can run. Keep the object shape
  # so the toast recipe can read it without searching source text.
  defp expression_attr("toastOptions", {:expr, _code, _node} = expression, _ctx) do
    %{
      "name" => "toastOptions",
      "kind" => "object",
      "value" => object_value(Ast.object_entries(expression))
    }
  end

  # `style={{ "--ratio": ratio } as React.CSSProperties}` is a set of CSS
  # declarations, not an expression. Recording it as declarations is what lets
  # the generator write a style string instead of a JavaScript object.
  defp expression_attr("style", {:expr, _code, _node} = expression, ctx) do
    %{
      "name" => "style",
      "kind" => "style",
      "value" => style_entries(Ast.object_entries(expression), ctx)
    }
  end

  defp expression_attr(name, {:expr, code, _node}, ctx), do: expression_attr(name, code, ctx)

  defp expression_attr(name, code, ctx) do
    case constant(code, ctx) do
      nil -> expression_attr(name, code)
      literal -> %{"name" => name, "kind" => "text", "value" => literal}
    end
  end

  defp style_entries(entries, ctx) do
    Enum.map(entries, fn
      {"..." <> name, _value} ->
        %{"property" => name, "kind" => "spread"}

      {property, value} ->
        case Ast.string_literal(value) do
          literal when is_binary(literal) ->
            %{"property" => property, "kind" => "text", "value" => literal}

          nil ->
            code = source(value)

            case constant(code, ctx) do
              nil -> %{"property" => property, "kind" => "code", "value" => code}
              literal -> %{"property" => property, "kind" => "text", "value" => literal}
            end
        end
    end)
  end

  defp expression_attr(name, code), do: %{"name" => name, "kind" => "code", "value" => code}

  defp object_value(entries) do
    Map.new(entries, fn {name, value} ->
      {name,
       case Ast.string_literal(value) do
         nil -> object_value(Ast.object_entries(value))
         literal -> literal
       end}
    end)
  end

  defp record_member_roots(node, []), do: node
  defp record_member_roots(node, roots), do: Map.put(node, "member_roots", roots)

  defp record_expression_facts(node, expression) do
    node
    |> record_member_roots(Ast.member_roots(expression))
    |> then(fn recorded ->
      case Ast.identifiers(expression) do
        [] -> recorded
        names -> Map.put(recorded, "identifiers", names)
      end
    end)
  end

  # Base UI's `render` prop replaces the element a part draws with one the
  # caller supplies, keeping the part's behaviour and merging its props on:
  #
  #     <Button render={<a data-slot="pagination-link" />} />
  #
  # A pagination link is a Button that is an `<a>`. The element it becomes is a
  # fact about the markup, so the spec records it rather than losing the tag.
  defp render_as(element, ctx) do
    with {:expr, code, _node} <- Tsx.attr(element, "render"),
         true <- String.starts_with?(String.trim(code), "<") do
      node(Ast.parse_jsx!(String.trim(code)), ctx)
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

  Returns `%{"self" => [read], "group" => [group_read]}`, where a read holds
  an attribute name and, when the class requires one, its value.
  """
  def reads(classes) do
    {self, group} =
      classes
      |> String.split()
      |> Enum.flat_map(&prefixes/1)
      |> Enum.reduce({[], []}, fn variant, {self, group} ->
        case classify(variant) do
          {:self, read} -> {[read | self], group}
          {:group, name, read} -> {self, [Map.put(read, "group", name) | group]}
          :ignore -> {self, group}
        end
      end)

    %{"self" => self |> Enum.reverse() |> Enum.uniq(), "group" => Enum.uniq(Enum.reverse(group))}
  end

  defp classify("group-" <> rest) do
    case String.split(rest, "/", parts: 2) do
      [<<"data-[", _rest::binary>> = attr, name] ->
        case classify(attr) do
          {:self, read} -> {:group, name, read}
        end

      [attr, name] ->
        case classify(attr) do
          {:self, read} -> {:group, name, read}
          :ignore -> :ignore
        end

      _ ->
        :ignore
    end
  end

  defp classify(<<"data-[", _rest::binary>> = variant) do
    case Regex.run(~r/^data-\[([a-z][a-z0-9-]*)(?:[$^*]?=)([^\]]+)\]$/, variant) do
      [_, attribute, value] ->
        {:self, read("data-#{attribute}", value)}

      _ ->
        case Regex.run(~r/^data-\[([a-z][a-z0-9-]*)\]$/, variant) do
          [_, attribute] -> {:self, read("data-#{attribute}")}
          _ -> raise("unsupported data variant: #{variant}")
        end
    end
  end

  defp classify(<<"aria-[", _rest::binary>> = variant) do
    case Regex.run(~r/^aria-\[([a-z][a-z0-9-]*)(?:[$^*]?=)([^\]]+)\]$/, variant) do
      [_, attribute, value] -> {:self, read("aria-#{attribute}", value)}
      _ -> raise("unsupported aria variant: #{variant}")
    end
  end

  defp classify(<<"data-", _rest::binary>> = variant) do
    case Regex.run(~r/^data-([a-z][a-z0-9-]*)=([^=]+)$/, variant) do
      [_, attribute, value] -> {:self, read("data-#{attribute}", value)}
      _ -> classify_state_attr(variant)
    end
  end

  defp classify(<<prefix::binary-size(5), _rest::binary>> = variant)
       when prefix in ["data-", "aria-"] do
    classify_state_attr(variant)
  end

  defp classify(variant) do
    if state_attr?(variant), do: {:self, read(variant)}, else: :ignore
  end

  defp classify_state_attr(variant) do
    if state_attr?(variant),
      do: {:self, read(variant)},
      else: raise("unsupported data variant: #{variant}")
  end

  @doc "The attribute name in a reader state record."
  def read_name(%{"name" => name}), do: name
  def read_name(name) when is_binary(name), do: name

  @doc "The value a reader state record requires, if any."
  def read_value(%{"value" => value}), do: value
  def read_value(_read), do: nil

  defp read(name, value \\ nil), do: %{"name" => name, "value" => value}

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
