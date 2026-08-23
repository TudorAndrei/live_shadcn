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
    * `:variants` — the `cva` table this part's class string is built from
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

  def render(%{"type" => "children"}, ctx, indent), do: pad(indent) <> ctx.children

  def render(%{"type" => "text", "value" => value}, _ctx, indent), do: pad(indent) <> value

  def render(%{"type" => "value", "code" => code}, ctx, indent),
    do: pad(indent) <> "{#{expression(code, ctx)}}"

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

  def render(%{"type" => "repeat_over", "collection" => collection} = node, ctx, indent) do
    generator = "#{node["binding"]} <- #{expression(collection, ctx)}"

    node
    |> Map.get("children")
    |> List.wrap()
    |> Enum.map_join("\n", &render(with_attr(&1, {":for", :code, generator}), ctx, indent))
  end

  def render(%{"type" => "repeat", "count" => count, "binding" => binding} = node, ctx, indent) do
    generator = "#{binding} <- 0..(#{expression(count, ctx)} - 1)//1"

    node
    |> Map.get("children")
    |> List.wrap()
    |> Enum.map_join("\n", &render(with_attr(&1, {":for", :code, generator}), ctx, indent))
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
      [{"content", :code, "@content"}] ++ class_attr(node, ctx),
      [],
      indent
    )
  end

  def render(%{"type" => "icon"} = node, ctx, indent) do
    tag(
      "LiveShadcn.Icon.icon",
      [{"name", :text, icon_name(node)}] ++ slot_attr(node, ctx) ++ class_attr(node, ctx),
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
  """
  def with_children(tree) do
    cond do
      marker?(tree) -> tree
      tree["tag"] in @void -> tree
      true -> Map.update(tree, "children", [], &(List.wrap(&1) ++ [%{"type" => "children"}]))
    end
  end

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

  @doc "Whether a tree renders the caller's content anywhere."
  def marker?(%{"type" => "children"}), do: true
  def marker?(node), do: node |> Map.get("children") |> List.wrap() |> Enum.any?(&marker?/1)

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
    attrs =
      slot_attr(node, ctx) ++
        Map.get(ctx.attrs, Spec.key(node), []) ++ own_attrs(node, ctx) ++ class_attr(node, ctx)

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
        "code" -> {attr["name"], :code, expression(attr["value"], ctx)}
        "style" -> {attr["name"], :code, style(attr["value"], ctx)}
      end
    end
  end

  # A set of CSS declarations becomes a style string, interpolating the values
  # the component computes.
  defp style(declarations, ctx) do
    body =
      Enum.map_join(declarations, "; ", fn
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
    code = String.trim(code)
    params = Map.get(ctx, :params) || %{}

    cond do
      code in ~w(true false) -> code
      code in ~w(undefined null) -> "nil"
      Regex.match?(~r/^-?\d+(\.\d+)?$/, code) -> code
      Map.has_key?(params, code) -> "@" <> Macro.underscore(code)
      negation = negation(code, ctx) -> negation
      fallback = fallback(code, ctx) -> fallback
      ternary = ternary(code, ctx) -> ternary
      literal?(code) -> code
      member = member(code, ctx) -> member
      true -> raise unbound(code)
    end
  end

  # A quoted string, and a template literal with nothing interpolated. Both
  # already mean in Elixir what they meant in JavaScript.
  defp literal?(code) do
    Regex.match?(~r/^"[^"]*"$/, code) or
      (Regex.match?(~r/^`[^`$]*`$/, code) and not String.contains?(code, "${"))
  end

  # `item.title` — a field of something upstream destructured. The head has to
  # be a prop; a path rooted anywhere else reads a binding nobody made.
  defp member(code, ctx) do
    with [head | rest] when rest != [] <- String.split(code, "."),
         true <- Regex.match?(~r/^[a-z_][A-Za-z0-9_]*$/, head),
         true <- Enum.all?(rest, &Regex.match?(~r/^[a-z_][A-Za-z0-9_]*$/, &1)),
         true <- Map.has_key?(Map.get(ctx, :params) || %{}, head) do
      Enum.join(["@" <> Macro.underscore(head) | rest], ".")
    else
      _ -> nil
    end
  end

  # `!x` is "not x" and `!!x` is "x, as a yes or no". JavaScript's truthiness is
  # not Elixir's, so the second is written out rather than assumed.
  defp negation("!!" <> rest, ctx), do: "#{expression(rest, ctx)} not in [nil, false, \"\"]"
  defp negation("!" <> rest, ctx), do: "!#{expression(rest, ctx)}"
  defp negation(_code, _ctx), do: nil

  # `variant ?? "ghost"` — a default when the caller set nothing.
  defp fallback(code, ctx) do
    case String.split(code, "??", parts: 2) do
      [value, default] -> "#{expression(value, ctx)} || #{expression(default, ctx)}"
      [_] -> nil
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
      base_classes(node, ctx) ++ variant_classes(node, ctx) ++ caller_class(node, ctx)

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

  defp variant_base(node, ctx) do
    if node["variant_class"], do: Map.get(table(ctx), "base")
  end

  defp variant_classes(node, ctx) do
    if node["variant_class"] do
      table(ctx)
      |> Map.get("variants", %{})
      |> Map.keys()
      |> Enum.sort()
      |> Enum.map(&{:code, ~s|variant_class("#{&1}", @#{Macro.underscore(&1)})|})
    else
      []
    end
  end

  defp table(ctx), do: Map.get(ctx, :variants) || %{}

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
