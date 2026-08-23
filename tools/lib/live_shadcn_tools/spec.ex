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

    parts =
      tsx.exports
      |> Enum.reject(&Map.has_key?(variants, &1))
      |> Enum.filter(&component?(&1, ctx))
      |> Enum.map(&part(&1, ctx))

    %{
      "name" => name,
      "recipe" => Keyword.fetch!(opts, :recipe),
      "source" => "shadcn",
      "generated_by" => "mix ui.spec",
      "upstream" => Keyword.fetch!(opts, :upstream),
      "anatomy" => doc.anatomy,
      # Keyed by module and part, because a component built from two Base UI
      # modules has two `Root` sections and they are not the same part.
      "primitives" =>
        for {module, page} <- docs, {key, part} <- page.parts, into: %{} do
          {"#{module}.#{key}", primitive(part)}
        end,
      "css_vars" => doc.parts |> Enum.flat_map(fn {_, p} -> p.css_vars end) |> Enum.sort(),
      "variants" => variants,
      "styles" => used_styles(ctx.styles, parts),
      "parts" => parts
    }
  end

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
        %{
          "name" => Macro.underscore(export),
          "export" => export,
          "primitive" => primitive_of(function.props_type),
          "params" => function.params,
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

      match = Regex.run(~r/^children\s*\?\?\s*(.+)$/s, code, capture: :all_but_first) ->
        %{"type" => "children", "default" => [node(jsx!(hd(match)), ctx)]}

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
      tag == "IconPlaceholder" -> %{"type" => "icon", "icons" => icons(element)}
      tag =~ ~r/^[a-z]/ -> %{"type" => "element", "tag" => tag}
      Map.has_key?(ctx.functions, tag) -> %{"type" => "part_ref", "part" => Macro.underscore(tag)}
      base_ui?(tag, ctx) -> base_ui_node(tag, ctx)
      registry_component(tag, ctx) -> registry_node(tag, ctx)
      context_provider?(tag) -> %{"type" => "transparent", "reason" => "a React context"}
      package = third_party(tag, ctx) -> raise not_base_ui(tag, package)
      true -> raise "the spec reader does not know what <#{tag}> is"
    end
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

  # `import { Button } from "@/registry/bases/base/ui/button"` — a component
  # built from another component in the same registry.
  defp registry_component(tag, ctx) do
    case Map.get(ctx.imports, tag) do
      nil -> nil
      path -> if String.contains?(path, "/ui/"), do: Path.basename(path)
    end
  end

  defp registry_node(tag, ctx) do
    %{"type" => "component_ref", "component" => registry_component(tag, ctx)}
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
