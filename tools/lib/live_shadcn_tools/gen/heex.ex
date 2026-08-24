defmodule LiveShadcnTools.Gen.Heex do
  @moduledoc """
  Turns a spec node tree into HEEx text.

  This module knows about markup and nothing about behavior. What attribute a
  part needs, and what expression computes it, is the recipe's business; this
  module is handed that list and places it.

  Three attributes it does add on its own, because all three follow from facts
  the spec already records rather than from a decision:

    * `data-lb-style-target` — the element's class string reads an attribute the
      client hook owns, so the hook has to find it
    * `data-lb-measure` — the element's class string interpolates a CSS variable
      no static class string can compute, so the hook has to measure it
    * the class list itself, when a `cva` table says the class string depends on
      props
  """

  alias LiveShadcnTools.Spec

  @doc """
  Renders a node tree.

  `ctx` carries:

    * `:attrs` — `%{part_key => [attribute]}`, from the recipe
    * `:children` — the HEEx that replaces `{children}`
    * `:class` — an expression appended to the class list of the node that
      merges `className` upstream, or `nil`
    * `:variants` — every `cva` table the component has, by its binding. A node
      names the ones it wears, and it can wear more than one.
    * `:params` — the props upstream destructured, which is what makes an
      expression such as `{size}` resolvable to `@size`
    * `:parts` — `%{part_name => part}`, for a recipe that folds every part into
      one function: a reference to another part is rendered in place rather than
      calling a function that does not exist.
    * `:props` — `%{part_key => [prop_name]}`, the props Base UI documents for
      each part. A `<Positioner align={align}>` is passing a prop, not writing
      an HTML attribute, and emitting it would put `align` on a `<div>`.
    * `:client_attributes` — the attribute names the client hook owns
    * `:hook_part` — the part the hook is declared on, which never needs a
      marker because the hook already holds it
    * `:rest` — whether this tree carries the component's `:global` attribute

  An attribute is `{name, :text, value}`, `{name, :code, expression}`,
  `{name, :bare}`, or `{:spread, expression}`.
  """
  def render(node, ctx, indent \\ 0)

  # `render={<a />}` replaces the element this part draws. The part's own
  # attributes and class string are merged onto it, which is what Base UI does.
  def render(%{"render_as" => target} = node, ctx, indent) when is_map(target) do
    node
    |> Map.delete("render_as")
    |> Map.merge(Map.drop(target, ["attrs", "children", "slot", "class"]))
    |> Map.merge(%{
      "attrs" => (Map.get(node, "attrs") || []) ++ (Map.get(target, "attrs") || []),
      "slot" => target["slot"] || node["slot"],
      # Both class strings apply: the part's own and the one written on the
      # element it was told to render as.
      "class" =>
        [node["class"], target["class"]] |> Enum.reject(&(&1 in [nil, ""])) |> Enum.join(" "),
      "children" => (Map.get(node, "children") || []) ++ (Map.get(target, "children") || [])
    })
    |> render(ctx, indent)
  end

  # `{children ?? name}` — what to draw when the caller passes nothing.
  #
  # The fold resolves this when it knows the answer: a reference that wrapped
  # nothing takes the default and the marker is gone. A part rendered as its own
  # function cannot know, because whether the slot was filled is a fact about
  # the call, so the component asks at render.
  def render(%{"type" => "children", "default" => [_ | _] = default}, ctx, indent) do
    # A block, not `:if` on each node: a default is as often a fragment of three
    # things as it is one element, and `{render_slot(@x)}` inside it takes no
    # attribute at all.
    #
    # `render_slot/1` draws nothing when the slot is empty, so only the default
    # is guarded. Exactly one of the two ever draws.
    otherwise = Enum.map_join(default, "\n", &render(&1, ctx, indent + 1))

    Enum.join(
      [
        pad(indent) <> "<%= if @inner_block == [] do %>",
        otherwise,
        pad(indent) <> "<% end %>",
        pad(indent) <> ctx.children
      ],
      "\n"
    )
  end

  def render(%{"type" => "children"}, ctx, indent), do: pad(indent) <> ctx.children

  def render(%{"type" => "text", "value" => value}, _ctx, indent), do: pad(indent) <> value

  def render(%{"type" => "value", "code" => code}, ctx, indent),
    do: pad(indent) <> "{#{expression(code, ctx)}}"

  # A render prop. React passes a function and calls it here; HEEx takes a slot
  # and renders it here, and the caller decides what goes in either way.
  def render(%{"type" => "slot", "name" => name}, _ctx, indent),
    do: pad(indent) <> "{render_slot(@#{name})}"

  # A table of values, read by a prop. A table of strings is a map lookup, and
  # one whose values are markup is one element per entry, each rendered only for
  # the value it belongs to. Both say the same thing; only one of them can be
  # written inside `{…}`.
  def render(%{"type" => "lookup", "key" => key, "entries" => entries}, ctx, indent) do
    if Enum.all?(entries, &match?(%{"node" => %{"type" => "text"}}, &1)) do
      pairs =
        Enum.map_join(entries, ", ", fn %{"value" => value, "node" => text} ->
          ~s|"#{value}" => "#{text["value"]}"|
        end)

      pad(indent) <> "{Map.get(%{#{pairs}}, #{expression(key, ctx)})}"
    else
      Enum.map_join(entries, "\n", fn %{"value" => value, "node" => entry} ->
        condition = "#{expression(key, ctx)} == #{inspect(value)}"

        render(with_attr(entry, {":if", :code, condition}), ctx, indent)
      end)
    end
  end

  # Base UI says this part renders no element of its own, so neither does the
  # generated component. Its children still have to reach the page.
  def render(%{"type" => "transparent"} = node, ctx, indent),
    do: children(node, ctx, indent) |> Enum.join("\n")

  # `{showCloseButton && (<Close />)}` — the same decision, made in HEEx.
  def render(%{"type" => "optional", "when" => condition} = node, ctx, indent) do
    node
    |> Map.get("children")
    |> List.wrap()
    |> Enum.map_join(
      "\n",
      &render(with_attr(&1, {":if", :code, expression(condition, ctx)}), ctx, indent)
    )
  end

  # `{tooltip ? <Tooltip>…</Tooltip> : button}`. HEEx has `:if` and no `:else`,
  # so the condition is written twice — once as itself and once negated — and
  # only one branch is ever drawn.
  def render(%{"type" => "choice", "when" => condition} = node, ctx, indent) do
    yes = expression(condition, ctx)

    [{"then", yes}, {"else", "!(#{yes})"}]
    |> Enum.flat_map(fn {branch, test} ->
      node
      |> Map.get(branch)
      |> List.wrap()
      |> Enum.map(&(&1 |> onto(node) |> with_attr({":if", :code, test})))
    end)
    |> Enum.map_join("\n", &render(&1, ctx, indent))
  end

  def render(%{"type" => "repeat_over", "collection" => collection} = node, ctx, indent) do
    # `.map((branch, index) => …)` counts as it goes, and `Enum.with_index` is
    # the same walk with the same count.
    generator =
      case node["counter"] do
        nil ->
          "#{node["binding"]} <- #{expression(collection, ctx)}"

        counter ->
          "{#{node["binding"]}, #{counter}} <- Enum.with_index(#{expression(collection, ctx)})"
      end

    # The binding is in scope inside the loop and nowhere else, so it reads like
    # a prop there — `{branch.key}` is a field of the item, not of the
    # component, and `@branch` would be an assign nobody made.
    #
    # A destructured item names its fields and not itself, so each field reads
    # off the name this generator gave the item.
    bound = if node["counter"], do: bind(ctx, node["counter"]), else: ctx

    inner =
      node
      |> Map.get("fields")
      |> List.wrap()
      |> Enum.reduce(bind(bound, node["binding"]), fn field, ctx ->
        bind(ctx, field, "#{node["binding"]}.#{field}")
      end)

    node
    |> Map.get("children")
    |> List.wrap()
    |> Enum.map_join("\n", &render(with_attr(&1, {":for", :code, generator}), inner, indent))
  end

  def render(%{"type" => "repeat", "count" => count, "binding" => binding} = node, ctx, indent) do
    generator = "#{binding} <- 0..(#{expression(count, ctx)} - 1)//1"

    # The counter is in scope inside the loop and nowhere else, the same as a
    # `.map` binding. Leaving it unbound made `slider` report `index` as a name
    # the component never destructured, which was true and not the problem.
    inner = bind(ctx, binding)

    node
    |> Map.get("children")
    |> List.wrap()
    |> Enum.map_join("\n", &render(with_attr(&1, {":for", :code, generator}), inner, indent))
  end

  # A reference to another exported part. A recipe that emits one function per
  # part calls it; a recipe that folds them all into one has no such function to
  # call, so the part it names is rendered in place.
  def render(%{"type" => "part_ref", "part" => part} = node, ctx, indent) do
    case ctx |> Map.get(:parts, %{}) |> Map.get(part) do
      nil -> call(".#{part}", node, ctx, indent)
      referenced -> render(inline(node, referenced), ctx, indent)
    end
  end

  def render(%{"type" => "component_ref", "component" => component} = node, ctx, indent) do
    namespace = LiveShadcnTools.namespace(Map.get(node, "source", "shadcn"))
    module = component |> String.replace("-", "_") |> Macro.camelize()
    function = Map.get(node, "function") || String.replace(component, "-", "_")

    call("#{inspect(namespace)}.#{module}.#{function}", node, ctx, indent)
  end

  # A job Elixir already does, so the generated component calls the seam that
  # names the job. Which library sits behind it is the application's decision,
  # and nothing in the spec or in this file knows.
  def render(%{"type" => "external", "role" => "markdown"} = node, ctx, indent) do
    tag(
      "LiveAiElements.Markdown.markdown",
      structural(node) ++ [{"content", :code, "@content"}] ++ class_attr(node, ctx),
      [],
      indent
    )
  end

  def render(%{"type" => "icon"} = node, ctx, indent) do
    tag(
      "LiveShadcn.Icon.icon",
      # `structural/1` first, because that is where `:if` and `:for` live and an
      # icon can be conditional like anything else. Leaving it out rendered
      # every entry of a lookup table at once: five icons, one after another,
      # where the table meant one.
      structural(node) ++ [icon_attr(node)] ++ slot_attr(node, ctx) ++ class_attr(node, ctx),
      [],
      indent
    )
  end

  def render(%{"type" => "primitive"} = node, ctx, indent) do
    key = Spec.key(node)

    tag(
      node["tag"],
      structural(node) ++
        slot_attr(node, ctx) ++
        Map.get(ctx.attrs, key, []) ++
        own_attrs(node, ctx) ++
        class_attr(node, ctx) ++ markers(node, ctx, key) ++ rest_attr(node, ctx),
      children(node, ctx, indent),
      indent
    )
  end

  def render(%{"type" => "element"} = node, ctx, indent) do
    tag(
      node["tag"],
      structural(node) ++
        slot_attr(node, ctx) ++
        own_attrs(node, ctx) ++
        class_attr(node, ctx) ++ markers(node, ctx, nil) ++ rest_attr(node, ctx),
      children(node, ctx, indent),
      indent
    )
  end

  # A name in scope for one subtree: a loop's binding. It is written without an
  # `@`, so `:bindings` is where it goes rather than `:params`.
  defp bind(ctx, name, reads_as \\ nil)

  defp bind(ctx, name, reads_as) when is_binary(name) do
    reads_as = reads_as || name

    Map.update(ctx, :bindings, %{name => reads_as}, &Map.put(&1 || %{}, name, reads_as))
  end

  defp bind(ctx, _name, _reads_as), do: ctx

  # An icon upstream chose, or one the caller chooses. Both are a name, because
  # the icon set is configuration and a name is what every set has in common.
  defp icon_attr(%{"prop" => prop}), do: {"name", :code, "@" <> prop}
  defp icon_attr(node), do: {"name", :text, icon_name(node)}

  # What was written on the choice belongs to whichever branch is drawn.
  # `<Icon className="size-4" />` where `Icon` is one of two icons puts the
  # class on both, because exactly one of them is the icon.
  defp onto(branch, %{"attrs" => attrs, "class" => class})
       when attrs != [] or class not in [nil, ""] do
    Map.merge(branch, %{
      "attrs" => (Map.get(branch, "attrs") || []) ++ (attrs || []),
      "class" => [branch["class"], class] |> Enum.reject(&(&1 in [nil, ""])) |> Enum.join(" ")
    })
  end

  defp onto(branch, _node), do: branch

  defp inline(node, referenced) do
    referenced["tree"]
    |> Map.merge(%{
      "attrs" => (Map.get(referenced["tree"], "attrs") || []) ++ (Map.get(node, "attrs") || []),
      "class" =>
        [referenced["tree"]["class"], node["class"]]
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.join(" "),
      "children" =>
        (Map.get(referenced["tree"], "children") || []) ++ (Map.get(node, "children") || [])
    })
  end

  # An element that cannot hold content, so `{...props}` on it never carried
  # children either.
  @void ~w(area base br col embed hr img input link meta source track wbr)

  @doc """
  Puts a children marker in a tree that has none.

  `<Card {...props} />` takes its children through the spread, so upstream never
  writes `{children}`. They still belong inside the element, and a generated
  component that could not hold content would not be the same component.

  Inside *that* element, which is not always the outermost one.
  `native-select` draws a wrapper, a `<select>` and an icon over the arrow, and
  spreads on the `<select>`. Content appended to the wrapper instead put every
  `<option>` after the box that was supposed to list them.
  """
  def with_children(tree) do
    cond do
      marker?(tree) -> tree
      tree["tag"] in @void -> tree
      true -> hold(tree) || append(tree)
    end
  end

  # The element the caller's content arrives through, when it is not the root.
  defp hold(%{"props" => true}), do: nil

  defp hold(tree) do
    children = Map.get(tree, "children") || []

    case Enum.find_index(children, &spreads?/1) do
      nil -> nil
      at -> Map.put(tree, "children", List.update_at(children, at, &with_children/1))
    end
  end

  defp spreads?(%{"props" => true, "tag" => tag}), do: tag not in @void

  defp spreads?(node) when is_map(node),
    do: Enum.any?(Map.get(node, "children") || [], &spreads?/1)

  defp spreads?(_node), do: false

  defp append(tree),
    do: Map.update(tree, "children", [], &(List.wrap(&1) ++ [%{"type" => "children"}]))

  @doc """
  Puts the children marker inside one named part of a tree.

  A popover's content is three nested elements — portal, positioner, popup —
  and the caller's content belongs in the innermost one. Rendering the tree
  whole and saying where the content goes beats rendering each layer separately
  and nesting them by hand.
  """
  def with_children_at(tree, key) do
    if Spec.key(tree) == key do
      with_children(tree)
    else
      Map.update(tree, "children", [], fn children ->
        Enum.map(List.wrap(children), &with_children_at(&1, key))
      end)
    end
  end

  # Phoenix accepts the global HTML attributes on any `:global`, and no others.
  # An `<a>` still needs `href`, an `<img>` still needs `src`. Which ones follow
  # from the tag, so the generator reads them off it rather than a person
  # noticing the omission when a page fails to compile.
  @tag_attributes %{
    "a" => ~w(href target rel download hreflang),
    "area" => ~w(href alt coords shape target),
    "audio" => ~w(src controls autoplay loop muted preload),
    "button" => ~w(type value name formaction),
    "form" => ~w(action method enctype novalidate target),
    "img" => ~w(src srcset sizes alt loading decoding width height),
    "input" => ~w(type name value placeholder checked min max step pattern readonly multiple),
    "label" => ~w(for),
    "ol" => ~w(start reversed),
    "option" => ~w(value selected),
    "progress" => ~w(value max),
    "select" => ~w(name multiple size),
    "source" => ~w(src srcset type media sizes),
    "td" => ~w(colspan rowspan headers),
    "textarea" => ~w(name placeholder rows cols readonly wrap),
    "th" => ~w(colspan rowspan headers scope abbr),
    "time" => ~w(datetime),
    "track" => ~w(src kind srclang label default),
    "video" => ~w(src poster controls autoplay loop muted preload width height)
  }

  @doc "Base UI's own one-line summary of a component, or an empty string."
  def summary(spec) do
    get_in(spec, ["primitives", "#{spec["name"]}.Root", "summary"]) || built_on(spec)
  end

  # A component with no Base UI page of its own has no sentence of its own
  # either, and borrowing the sentence of the component it folded in would
  # describe the wrong thing: a task is not "all parts of the collapsible".
  # What is true, and worth a reader knowing, is which component it is built on.
  defp built_on(spec) do
    case Map.get(spec, "folds") || [] do
      [] -> ""
      folds -> "Built on #{Enum.map_join(folds, ", ", &"`#{&1}`")}."
    end
  end

  @doc """
  The first line of a generated module's `@moduledoc`.

  Base UI's summary follows the component's name when the page has one, and
  nothing follows it when it does not. The result is trimmed. A generated file
  must not carry trailing whitespace: a formatter would strip it, which edits a
  file nobody is allowed to edit, and `mix ui.gen --check` then fails with
  nothing in the diff to explain why.
  """
  def headline(spec) do
    name = spec["name"] |> String.replace("-", " ") |> String.capitalize()

    String.trim("#{name}. #{summary(spec)}")
  end

  @doc "Where the spec a module was generated from lives, for its `@moduledoc`."
  def spec_ref(spec), do: "registry/spec/#{spec["source"]}/#{spec["name"]}.json"

  @doc """
  The attributes a tag needs that Phoenix does not treat as global.

  Always includes `data-slot`, because every generated part carries one and it
  is written by the generator rather than by the caller.
  """
  def globals(tag), do: ["data-slot" | Map.get(@tag_attributes, tag, [])]

  @doc """
  The tag the caller's attributes reach, which is the one that spreads.

  `tag_of/3` answers what the component *is*, and that is the outermost
  element. This answers where `{...props}` lands, and the two are not always
  the same: `native-select` draws a wrapper around a `<select>` and spreads on
  the `<select>`, so a `:global` list read off the wrapper accepted no `name`
  and no `multiple` — on the one element in the registry that is a form field
  by itself.
  """
  def rest_tag(tree, parts \\ %{}), do: tag_of(spreading(tree) || tree, parts)

  # The node that carries `{...props}` itself, outermost first. Not a node whose
  # descendant carries one — that is every ancestor of it.
  defp spreading(%{"props" => true} = node), do: node

  defp spreading(node) when is_map(node),
    do: node |> Map.get("children") |> List.wrap() |> Enum.find_value(&spreading/1)

  defp spreading(_node), do: nil

  @doc """
  The tag a tree renders as, after any `render` prop is applied and any
  reference to another part in the same component is followed.

  A pagination link is a Button that is an `<a>`, and a pagination previous is
  a pagination link. Only the tag at the end of that chain says which
  attributes the component has to accept.
  """
  def tag_of(tree, parts \\ %{}, depth \\ 0)
  def tag_of(_tree, _parts, depth) when depth > 8, do: nil

  def tag_of(tree, parts, depth) do
    cond do
      is_map(tree["render_as"]) ->
        tag_of(tree["render_as"], parts, depth + 1)

      tree["type"] == "part_ref" ->
        case Map.get(parts, tree["part"]) do
          nil -> nil
          part -> tag_of(part["tree"], parts, depth + 1)
        end

      true ->
        tree["tag"]
    end
  end

  @doc "Every piece of JavaScript a tree still holds, wherever it holds one."
  defdelegate codes(tree), to: Spec

  @doc "Whether a tree renders the caller's content anywhere."
  def marker?(%{"type" => "children"}), do: true
  def marker?(node), do: node |> Map.get("children") |> List.wrap() |> Enum.any?(&marker?/1)

  @doc """
  The slots a tree renders, by name.

  A recipe declares one `slot` per name, because a slot rendered but not
  declared raises on the component's first render — which is a browser run
  away from the generator that wrote it.
  """
  def slots(node) when is_map(node) do
    case node do
      %{"type" => "slot", "name" => name} -> [name]
      _ -> node |> Map.values() |> slots()
    end
  end

  def slots(nodes) when is_list(nodes), do: nodes |> Enum.flat_map(&slots/1) |> Enum.uniq()
  def slots(_node), do: []

  @doc "One HTML tag, its attributes, and its already-rendered children."
  def tag(name, attrs, children, indent) do
    open = pad(indent) <> "<" <> name <> attributes(attrs)

    case children do
      [] ->
        open <> " />"

      children ->
        Enum.join([open <> ">"] ++ children ++ [pad(indent) <> "</" <> name <> ">"], "\n")
    end
  end

  defp call(name, node, ctx, indent) do
    # `structural/1` first for the same reason an element takes it first: `:if`
    # and `:for` belong to whatever is drawn, and a function component is drawn.
    attrs =
      structural(node) ++
        slot_attr(node, ctx) ++
        Map.get(ctx.attrs, Spec.key(node), []) ++
        own_attrs(node, ctx) ++ class_attr(node, ctx) ++ rest_attr(node, ctx)

    tag(name, attrs, children(node, ctx, indent), indent)
  end

  defp children(node, ctx, indent),
    do: node |> Map.get("children") |> List.wrap() |> Enum.map(&render(&1, ctx, indent + 1))

  defp attributes(attrs) do
    attrs
    |> Enum.reject(&is_nil/1)
    |> Enum.map_join(fn
      {name, :bare} -> " " <> name
      {name, :text, value} -> ~s( #{name}="#{value}")
      {name, :code, expression} -> " #{name}={#{expression}}"
      {:spread, expression} -> " {#{expression}}"
    end)
  end

  defp name_of({name, _kind}), do: name
  defp name_of({name, _kind, _value}), do: name
  defp name_of(_other), do: nil

  # `:for` and `:if`, which the enclosing node put here rather than upstream.
  defp structural(node), do: Map.get(node, "__structural__", [])

  defp with_attr(node, attr),
    do: Map.update(node, "__structural__", [attr], &(&1 ++ [attr]))

  @doc """
  Puts the recipe's own attributes on a node.

  `:attrs` in the context reaches a Base UI primitive, keyed by the part it
  draws. A plain element has no part to be keyed by, and shadcn's sidebar is
  twenty-three of them and not one Base UI primitive — so a recipe that has
  something to say about one of those says it here, on the node itself.

  What upstream wrote for the same attribute is replaced, not joined: two
  `data-state` on one element is not an override, it is one attribute an HTML
  parser reads and one it discards.
  """
  def with_attrs(node, attributes) do
    replaced = Enum.map(attributes, &name_of/1)

    node
    |> Map.update("attrs", [], fn attrs -> Enum.reject(attrs, &(&1["name"] in replaced)) end)
    |> then(fn node -> Enum.reduce(attributes, node, &with_attr(&2, &1)) end)
  end

  # A component's own `data-slot` is a default, not a fixed value: shadcn passes
  # `data-slot="dialog-close"` to a `<Button>` and expects it to win. Two of the
  # same attribute is not an override — an HTML parser keeps the first — so the
  # caller's is read out of the globals and the rest are spread without it.
  #
  # `:global` keys its map by atom, including for hyphenated names, so the key
  # is `:"data-slot"` and not the string it was written as.
  defp slot_attr(%{"slot" => nil}, _ctx), do: []

  defp slot_attr(%{"slot" => slot} = node, ctx) do
    if overridable?(node, ctx),
      do: [{"data-slot", :code, ~s|@rest[:"data-slot"]| <> " || " <> inspect(slot)}],
      else: [{"data-slot", :text, slot}]
  end

  defp slot_attr(_node, _ctx), do: []

  defp overridable?(node, ctx), do: node["props"] == true and Map.get(ctx, :rest) == true

  # Everything upstream writes on the element that is not its class string. A
  # value it computes from a prop is emitted as that prop's assign.
  # An attribute the recipe computes wins over the one upstream wrote: both say
  # the same thing, and two of the same attribute is not an override.
  defp own_attrs(node, ctx) do
    computed = ctx |> Map.get(:attrs, %{}) |> Map.get(Spec.key(node), []) |> Enum.map(&name_of/1)
    props = ctx |> Map.get(:props, %{}) |> Map.get(Spec.key(node), [])

    for attr <- Map.get(node, "attrs") || [],
        attr["name"] not in computed,
        attr["name"] not in props do
      case attr["kind"] do
        "text" -> {attr["name"], :text, attr["value"]}
        "flag" -> {attr["name"], :bare}
        "code" -> {attr["name"], :code, written(attr, ctx)}
        "style" -> {attr["name"], :code, style(attr["value"], ctx)}
      end
    end
  end

  # `data-align-trigger={alignItemWithTrigger}` reads `"true"` in the browser,
  # because React writes a boolean into an attribute as its name. HEEx writes
  # it as presence instead — the attribute is there or it is not — and a class
  # string of the form `data-[align-trigger=true]:…` has nothing to compare.
  # So a yes-or-no in a data attribute is spelled out.
  defp written(%{"name" => "data-" <> _rest, "value" => code} = attr, ctx) do
    if yes_or_no?(code, ctx),
      do: "to_string(#{expression(code, ctx)})",
      else: expression(attr["value"], ctx)
  end

  defp written(attr, ctx), do: expression(attr["value"], ctx)

  defp yes_or_no?(code, ctx),
    do: Map.get(Map.get(ctx, :params) || %{}, String.trim(code)) in ["true", "false"]

  # A set of CSS declarations becomes a style string, interpolating the values
  # the component computes.
  defp style(declarations, ctx) do
    body =
      Enum.map_join(declarations, "; ", fn
        # What the caller wrote, appended whole. It is already a style string.
        %{"kind" => "spread", "property" => property} ->
          "\#{@#{LiveShadcnTools.assign(property)}}"

        %{"kind" => "text", "property" => property, "value" => value} ->
          "#{property}: #{value}"

        %{"property" => property, "value" => value} ->
          "#{property}: \#{#{expression(value, ctx)}}"
      end)

    ~s|"#{body}"|
  end

  # JavaScript that means the same thing in Elixir, and nothing more. An
  # identifier upstream destructured from its props is an assign here; anything
  # else that looks like an identifier is a gap, because emitting it verbatim
  # would produce HEEx that reads a variable nobody bound.
  defp expression(code, ctx) do
    code = code |> String.trim() |> unwrapped()
    params = Map.get(ctx, :params) || %{}

    cond do
      code in ~w(true false) -> code
      code in ~w(undefined null) -> "nil"
      Regex.match?(~r/^-?\d+(\.\d+)?$/, code) -> code
      binding = Map.get(Map.get(ctx, :bindings) || %{}, code) -> binding
      Map.has_key?(params, code) -> "@" <> LiveShadcnTools.assign(code)
      negation = negation(code, ctx) -> negation
      fallback = fallback(code, ctx) -> fallback
      ternary = ternary(code, ctx) -> ternary
      literal?(code) -> code
      member = member(code, ctx) -> member
      binary = binary(code, ctx) -> binary
      true -> raise unbound(code)
    end
  end

  # Brackets a person wrote to make an expression readable. They change nothing
  # about what is inside them, and every reader below this line splits on an
  # operator — which finds the operator inside the brackets and keeps the
  # bracket. So the outermost pair comes off first.
  defp unwrapped("(" <> rest = code) do
    inner = String.trim_trailing(rest)

    if String.ends_with?(inner, ")") and wraps_all?(rest) do
      inner |> binary_part(0, byte_size(inner) - 1) |> String.trim() |> unwrapped()
    else
      code
    end
  end

  defp unwrapped(code), do: code

  # Whether the opening bracket is closed by the last character and not before.
  # `(a) && (b)` opens and closes twice, so its brackets are not one pair
  # around the whole expression.
  defp wraps_all?(rest) do
    chars = rest |> String.trim_trailing() |> String.to_charlist()
    last = length(chars) - 1

    chars
    |> Enum.with_index()
    |> Enum.reduce_while(1, fn
      {?(, _at}, depth -> {:cont, depth + 1}
      {?), at}, 1 -> {:halt, if(at == last, do: :whole, else: :partial)}
      {?), _at}, depth -> {:cont, depth - 1}
      {_char, _at}, depth -> {:cont, depth}
    end)
    |> Kernel.==(:whole)
  end

  # `totalBranches <= 1`, `currentBranch + 1`, `a && b`. Every one of these
  # means in Elixir what it meant in JavaScript once both sides are translated,
  # and both sides are `expression/2` again — so an unknown name in one of them
  # is still reported by name.
  #
  # JavaScript's strict operators are Elixir's ordinary ones. Its loose ones
  # have no counterpart worth writing: `==` in Elixir is `===` in JavaScript,
  # and `==` in JavaScript is a rule nobody wants.
  #
  # `&&` is Elixir's `&&` and not its `and`. JavaScript asks whether a value is
  # there; `and` insists both sides are already `true` or `false`, and
  # `package_info` renders `currentVersion && newVersion` where either may be
  # absent. `&&` takes any term, which is the question being asked.
  #
  # The order is the whole of the list: `<` matches inside `<=`, and trying it
  # first split `totalBranches <= 1` into a name and `= 1`.
  @operators [
    {"===", "=="},
    {"!==", "!="},
    {"<=", "<="},
    {">=", ">="},
    {"&&", "&&"},
    {"<", "<"},
    {">", ">"},
    {"+", "+"},
    {"*", "*"},
    {"/", "/"}
  ]

  defp binary(code, ctx) do
    Enum.find_value(@operators, fn {javascript, elixir} ->
      case String.split(code, javascript, parts: 2) do
        [left, right] when left != "" and right != "" ->
          "#{expression(left, ctx)} #{elixir} #{expression(right, ctx)}"

        _ ->
          nil
      end
    end)
  end

  # A quoted string, and a template literal with nothing interpolated. Both
  # already mean in Elixir what they meant in JavaScript.
  defp literal?(code) do
    Regex.match?(~r/^"[^"]*"$/, code) or
      (Regex.match?(~r/^`[^`$]*`$/, code) and not String.contains?(code, "${"))
  end

  # `values.length` is `length(values)` here. JavaScript reads the size of a
  # list as a field of it and Elixir asks a function, and a `.length` left as
  # written would read a key nobody put in a map.
  defp member(code, ctx) do
    case String.split(code, ".") do
      [_head, _more | _rest] = parts ->
        if List.last(parts) == "length",
          do: sized(parts, ctx),
          else: path(parts, ctx)

      _shorter ->
        nil
    end
  end

  defp sized(parts, ctx) do
    case path(Enum.drop(parts, -1), ctx) do
      nil -> nil
      of -> "length(#{of})"
    end
  end

  # `item.title` — a field of something upstream destructured. The head has to
  # be a prop; a path rooted anywhere else reads a binding nobody made.
  defp path([head], ctx) do
    case root(head, ctx) do
      root when is_binary(root) -> root
      _nothing -> nil
    end
  end

  defp path([head | rest], ctx) do
    with true <- Regex.match?(~r/^[a-z_][A-Za-z0-9_]*$/, head),
         true <- Enum.all?(rest, &Regex.match?(~r/^[a-z_][A-Za-z0-9_]*$/, &1)) do
      case root(head, ctx) do
        # `question.disabled` — a React context holds nothing here, so the path
        # through it disappears and the field it reached is the prop.
        :context -> expression(Enum.join(rest, "."), ctx)
        root when is_binary(root) -> Enum.join([root | rest], ".")
        nil -> nil
      end
    else
      _ -> nil
    end
  end

  # A prop is written `@item`; a loop's binding is written plain. A path rooted
  # in anything else reads a name nobody bound.
  defp root(head, ctx) do
    cond do
      binding = Map.get(Map.get(ctx, :bindings) || %{}, head) -> binding
      head in (Map.get(ctx, :contexts) || []) -> :context
      Map.has_key?(Map.get(ctx, :params) || %{}, head) -> "@" <> LiveShadcnTools.assign(head)
      true -> nil
    end
  end

  # `!x` is "not x" and `!!x` is "x, as a yes or no". JavaScript's truthiness is
  # not Elixir's, so the second is written out rather than assumed.
  defp negation("!!" <> rest, ctx), do: "#{expression(rest, ctx)} not in [nil, false, \"\"]"
  defp negation("!" <> rest, ctx), do: "!#{expression(rest, ctx)}"
  defp negation(_code, _ctx), do: nil

  # `variant ?? "ghost"` — a default when the caller set nothing.
  #
  # `question.disabled || disabled` asks two sources for the same fact: the
  # group and the option. A HEEx component has no group to ask, so both sides
  # read the one prop, and asking it twice reads no better than asking once.
  defp fallback(code, ctx) do
    case String.split(code, ~r/\?\?|\|\|/, parts: 2) do
      [value, default] ->
        case {expression(value, ctx), expression(default, ctx)} do
          {same, same} -> same
          {value, default} -> "#{value} || #{default}"
        end

      [_] ->
        nil
    end
  end

  # `isActive ? "page" : undefined` says the same thing an `if` does.
  defp ternary(code, ctx) do
    case Regex.run(~r/^([^?]+)\?([^:]+):(.+)$/s, code, capture: :all_but_first) do
      [condition, yes, no] ->
        "if(#{expression(condition, ctx)}, " <>
          "do: #{expression(yes, ctx)}, else: #{expression(no, ctx)})"

      nil ->
        nil
    end
  end

  defp unbound(code) do
    """
    the generator met `#{code}`, which the component never destructured.

    A generated component can only read what upstream declared as a prop. Teach
    the reader where this value comes from, or the component is not ready to
    generate.

    Writing it through unread is the one thing that must not happen. It is
    JavaScript, and HEEx that reads a variable nobody bound either fails to
    compile — `providers.chatgpt.createUrl(query)` did — or compiles and is
    wrong.
    """
  end

  # shadcn merges the caller's class into whichever element called `cn` with it.
  # The spec records which element that was, so the generator never guesses.
  defp class_attr(node, ctx) do
    entries =
      base_classes(node, ctx) ++
        conditional_classes(node, ctx) ++ variant_classes(node, ctx) ++ caller_class(node, ctx)

    case entries do
      [] -> []
      [{:text, literal}] -> [{"class", :text, literal}]
      entries -> [{"class", :code, "[#{Enum.map_join(entries, ", ", &entry/1)}]"}]
    end
  end

  defp entry({:text, literal}), do: inspect(literal)
  defp entry({:code, code}), do: code

  defp base_classes(node, ctx) do
    literal =
      [variant_base(node, ctx), Map.get(node, "class", "")]
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.join(" ")

    if literal == "", do: [], else: [{:text, literal}]
  end

  # Every `cva` base the element wears, and the class for every group whose call
  # did not pass it. Both are the same string on every render, so both belong in
  # the literal rather than behind a lookup.
  #
  # `input-group`'s button is two tables: shadcn's `<Button>` builds one and the
  # group adds `inputGroupButtonVariants({ size })` on top. `size` reaches only
  # the second, so the first uses its own default — and reading one table lost
  # the other's base entirely.
  defp variant_base(node, ctx) do
    node
    |> calls(ctx)
    |> Enum.flat_map(fn {_binding, table, args} -> [table["base"] | unpassed(table, args)] end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" ")
  end

  # A group the call did not pass takes the table's own default, which is one
  # class string forever. `<Button>` inside an input group is given no `size`,
  # so it wears `cn-button-size-default` and nothing asks.
  defp unpassed(table, args) do
    defaults = Map.get(table, "defaults") || %{}

    for {group, values} <- Map.get(table, "variants") || %{},
        group not in args,
        chosen = Map.get(defaults, group),
        do: Map.get(values, chosen)
  end

  # This node's own calls, each with the table it names. `ctx.variants` is every
  # table the component has; the node says which of them it wears.
  defp calls(node, ctx) do
    tables = Map.get(ctx, :variants) || %{}

    for call <- Map.get(node, "variant_calls") || [],
        table = Map.get(tables, call["table"]),
        do: {call["table"], table, call["args"] || []}
  end

  # A class string the element wears only when something is true. `nil` on the
  # other branch, because a class list drops what is nil.
  defp conditional_classes(node, ctx) do
    for segment <- Map.get(node, "class_when") || [] do
      condition = expression(segment["when"], ctx)

      {:code,
       "if(#{condition}, do: #{inspect(segment["then"])}, else: #{inspect(segment["else"])})"}
    end
  end

  # One lookup per group the call was actually passed, named by its table. Two
  # tables that both define `size` are two different questions with two
  # different answers, and a lookup keyed by the group alone answered whichever
  # table the map happened to iterate last.
  defp variant_classes(node, ctx) do
    for {binding, table, args} <- calls(node, ctx),
        group <- table |> Map.get("variants", %{}) |> Map.keys() |> Enum.sort(),
        group in args,
        do:
          {:code, ~s|variant_class("#{binding}", "#{group}", @#{LiveShadcnTools.assign(group)})|}
  end

  defp caller_class(node, ctx) do
    case {node["merges_class"], Map.get(ctx, :class)} do
      {true, expression} when is_binary(expression) -> [{:code, expression}]
      _ -> []
    end
  end

  # Upstream forwards `{...props}` on every part, because upstream has one
  # component per part. A folded component has one caller and one `:global`, so
  # the spread belongs to the element the caller is actually addressing.
  defp rest_attr(%{"props" => true, "slot" => slot} = node, %{rest: true} = ctx)
       when is_binary(slot) do
    if overridable?(node, ctx),
      do: [{:spread, ~s|Map.drop(@rest, [:"data-slot"])|}],
      else: [{:spread, "@rest"}]
  end

  defp rest_attr(%{"props" => true}, %{rest: true}), do: [{:spread, "@rest"}]
  defp rest_attr(_node, _ctx), do: []

  # Both markers are plumbing between the generator and a client hook. A
  # component with no hook has nobody to say them to, and `sidebar` is one:
  # every width it interpolates is set in a style attribute by the wrapper
  # above it, so `data-lb-measure` on two of its `<div>`s asked a hook that is
  # not there to measure something already known.
  defp markers(_node, %{hook_part: nil}, _key), do: []

  defp markers(node, ctx, key) do
    reads = get_in(node, ["reads", "self"]) || []
    client? = key != ctx.hook_part and Enum.any?(reads, &(&1 in ctx.client_attributes))
    measure? = (node["vars"] || []) != []

    Enum.reject(
      [
        if(client?, do: {"data-lb-style-target", :bare}),
        if(measure?, do: {"data-lb-measure", :bare})
      ],
      &is_nil/1
    )
  end

  # shadcn names an icon per set. The lucide name is the one shadcn's own
  # documentation uses, so it is the name the icon component is asked for.
  defp icon_name(%{"icons" => icons}) do
    icons
    |> Map.get("lucide")
    |> to_string()
    |> String.replace_suffix("Icon", "")
    |> Macro.underscore()
    |> String.replace("_", "-")
  end

  defp pad(indent), do: String.duplicate("  ", indent)
end
