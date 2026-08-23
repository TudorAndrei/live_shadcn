defmodule LiveShadcnTools.Tsx do
  @moduledoc """
  A small TSX reader for the two upstream registries.

  This is not a TypeScript compiler. It reads the shapes those two files are
  written in, and nothing else. shadcn declares and then exports:

      function Name({ className, ...props }: Primitive.Part.Props) {
        return (
          <JSX />
        )
      }

      export { Name, ... }

  AI Elements exports where it declares, and wraps the component in `memo`:

      export const Name = memo(({ className }: NameProps) => (
        <JSX />
      ))

  Neither shape says anything the other does not. Both give a name, the props
  the component destructured, and the markup it renders, so both are read into
  one result and `mix ui.spec` never learns which file it came from.

  It returns the JSX as a tree, so the spec records the anatomy upstream
  renders instead of guessing it. Anything the reader does not understand
  raises rather than being dropped, because a silently skipped element becomes
  a missing element in the generated HEEx.
  """

  @type value :: {:string, String.t()} | {:expr, String.t()} | true
  @type attr :: {:attr, String.t(), value} | {:spread, String.t()}
  @type node_t :: %{
          required(:type) => :element | :expr | :text,
          optional(:tag) => String.t(),
          optional(:attrs) => [attr],
          optional(:children) => [node_t],
          optional(:code) => String.t(),
          optional(:value) => String.t()
        }

  @doc """
  Reads a registry component source.

  Returns the top-level `function` declarations, the top-level `const`
  bindings, what the file imports and from where, and the `export { ... }` list.

  Not every export is a function. shadcn writes `const Select =
  SelectPrimitive.Root` when a part needs no styling at all, and
  `const buttonVariants = cva(...)` when a part's class string depends on props.
  Both are components' facts, so both are read.
  """
  def parse!(source) do
    read = declared(source) ++ arrows(source)

    %{
      functions: Enum.filter(read, &is_map/1),
      unreadable: Map.new(for {:unreadable, name, why} <- read, do: {name, why}),
      consts: consts(source),
      imports: imports(source),
      exports: exports(source)
    }
  end

  # `import { Button } from "@/registry/bases/base/ui/button"` becomes
  # `%{"Button" => ".../ui/button"}`, which is how a reference to another
  # component in the registry is told apart from anything else.
  defp imports(source) do
    named =
      ~r/import \{([^}]*)\} from "([^"]+)"/
      |> Regex.scan(source, capture: :all_but_first)
      |> Enum.flat_map(fn [names, from] ->
        names
        |> String.split(",")
        |> Enum.map(&(&1 |> String.trim() |> String.split(" as ") |> List.last()))
        |> Enum.reject(&(&1 == ""))
        |> Enum.map(&{&1, from})
      end)

    # `import * as ResizablePrimitive from "react-resizable-panels"` binds the
    # whole module under one name, and its parts are read off that name.
    namespace =
      ~r/import \* as ([A-Za-z_][A-Za-z0-9_]*) from "([^"]+)"/
      |> Regex.scan(source, capture: :all_but_first)
      |> Enum.map(fn [name, from] -> {name, from} end)

    Map.new(named ++ namespace)
  end

  # A top-level `const NAME = ...`, read to the end of its statement. The value
  # may span lines, as `cva(...)` always does, so lines are taken until the
  # brackets balance.
  defp consts(source) do
    ~r/^const ([A-Za-z_][A-Za-z0-9_]*)(?::[^=]+)? = /m
    |> Regex.scan(source, return: :index)
    |> Enum.map(fn [{at, length}, {name_at, name_length}] ->
      {binary_part(source, name_at, name_length), statement(source, at + length)}
    end)
    |> Map.new()
  end

  defp statement(source, at) do
    source
    |> binary_part(at, byte_size(source) - at)
    |> String.split("\n")
    |> Enum.reduce_while({[], 0, false}, fn line, {lines, depth, started?} ->
      depth = depth + bracket_delta(line)
      lines = [line | lines]

      # A line ending in `=>` has closed its brackets and not finished its
      # statement: the arrow's body is on the lines after it. Halting there cut
      # `CheckpointIcon` off at its own signature and left it with no markup.
      if started? and depth <= 0 and not String.ends_with?(String.trim_trailing(line), "=>"),
        do: {:halt, {lines, depth, true}},
        else: {:cont, {lines, depth, started? or depth > 0 or String.trim(line) != ""}}
    end)
    |> then(fn {lines, _depth, _started?} -> lines |> Enum.reverse() |> Enum.join("\n") end)
    |> String.trim()
    |> String.trim_trailing(";")
  end

  defp bracket_delta(line) do
    opens = line |> String.graphemes() |> Enum.count(&(&1 in ["(", "[", "{"]))
    closes = line |> String.graphemes() |> Enum.count(&(&1 in [")", "]", "}"]))
    opens - closes
  end

  # Two registries write their exports two ways. shadcn declares everything and
  # exports it in one list at the foot of the file; AI Elements exports each
  # binding where it is declared. Both lists are read, because which one a file
  # uses says nothing about what it exports.
  defp exports(source) do
    listed =
      case Regex.run(~r/export \{([^}]*)\}/, source, capture: :all_but_first) do
        [list] ->
          list |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

        nil ->
          []
      end

    inline =
      ~r/^export (?:const|function) ([A-Za-z_][A-Za-z0-9_]*)/m
      |> Regex.scan(source, capture: :all_but_first)
      |> List.flatten()

    Enum.uniq(listed ++ inline)
  end

  defp declared(source) do
    ~r/^(?:export )?function ([A-Z][A-Za-z0-9_]*)\(/m
    |> Regex.scan(source, return: :index)
    |> Enum.map(fn [{at, length}, {name_at, name_len}] ->
      name = binary_part(source, name_at, name_len)
      {signature, rest} = balanced(source, at + length, ?(, ?))

      %{
        name: name,
        props_type: props_type(signature),
        params: params(signature),
        renames: renames(signature),
        jsx: rest |> body!(name) |> return_jsx!(name)
      }
    end)
  end

  # `export const Name = ({ className }: NameProps) => (<div />)`, which is how
  # every AI Elements component is written. A `const` that holds no arrow
  # function — a variant table, a lookup map, a plain value — is not one, and is
  # left to `consts/1`.
  defp arrows(source) do
    ~r/^(?:export )?const ([A-Z][A-Za-z0-9_]*)(?::[^=]+)? = /m
    |> Regex.scan(source, return: :index)
    |> Enum.flat_map(fn [{at, length}, {name_at, name_len}] ->
      name = binary_part(source, name_at, name_len)

      case arrow(statement(source, at + length), name) do
        nil -> []
        read -> [read]
      end
    end)
  end

  defp arrow(code, name) do
    case signature(unwrap(String.trim(code))) do
      # Not an arrow function. It is a value, and `consts/1` already has it.
      nil ->
        nil

      {signature, body} ->
        %{
          name: name,
          props_type: props_type(signature),
          params: params(signature),
          renames: renames(signature),
          jsx: arrow_jsx!(String.trim(body), name)
        }
    end
  rescue
    # An arrow function whose markup could not be read. Whether that matters
    # depends on something this module cannot see: a file is full of small
    # arrow helpers that render nothing, and a helper nobody exports is not a
    # component. `mix ui.spec` knows what the file exports, so it decides.
    #
    # What must not happen is what happened before this was recorded at all:
    # `CodeBlockContent` was dropped as "not a component", and the file that
    # rendered it failed thirty lines later with "the spec reader does not know
    # what <CodeBlockContent> is".
    error -> {:unreadable, name, Exception.message(error)}
  end

  # `(args) => body`, and nothing else. A const whose value merely starts with a
  # bracket is not one.
  defp signature(code) do
    with {at, _} <- :binary.match(code, "("),
         {signature, rest} <- balanced(code, at + 1, ?(, ?)),
         "=>" <> body <- String.trim_leading(rest) do
      {signature, body}
    else
      _ -> nil
    end
  rescue
    # An unbalanced bracket means the brackets were never a signature.
    _error -> nil
  end

  # `memo(...)` and `forwardRef(...)` say something about React's rendering and
  # nothing about the markup, so they are read through rather than read.
  defp unwrap(code) do
    case Regex.run(~r/^(?:memo|forwardRef)\s*\(/, code, return: :index) do
      [{_at, length}] -> code |> balanced(length, ?(, ?)) |> elem(0) |> String.trim() |> unwrap()
      nil -> code
    end
  end

  # An arrow body is markup three ways: wrapped in brackets, a block that
  # returns, or the element on its own.
  defp arrow_jsx!("(" <> rest, _name), do: rest |> balanced(0, ?(, ?)) |> elem(0) |> parse_jsx!()

  defp arrow_jsx!("{" <> rest, name),
    do: rest |> balanced(0, ?{, ?}) |> elem(0) |> return_jsx!(name)

  defp arrow_jsx!("<" <> _rest = body, _name), do: parse_jsx!(body)

  # An expression body: `({ children }) => children ?? (<BookmarkIcon />)`. It
  # is the same shape as `return toasts.map(…)`, without the `return`, so it is
  # handed on the same way — the spec decides what the expression means.
  defp arrow_jsx!(body, name) do
    if String.contains?(body, "<"),
      do: %{type: :expr, code: String.trim(body)},
      else: raise("#{name}: no markup to read")
  end

  # Only this function's own body. Reading past it would let a function with no
  # `return (` quietly adopt the next function's markup, which is worse than
  # failing to read it at all.
  defp body!(source, name) do
    case :binary.match(source, "{") do
      :nomatch -> raise "#{name}: no body to read"
      {at, _} -> source |> balanced(at + 1, ?{, ?}) |> elem(0)
    end
  end

  @doc """
  The props a function destructures, and the default each was given.

  `{ className, size = "default", ...props }` yields
  `%{"className" => nil, "size" => "default"}`. The default is a decision
  upstream made, so a generated component has to make the same one.
  """
  def params(signature) do
    with {at, _} <- :binary.match(signature, "{"),
         {body, _rest} <- balanced(signature, at + 1, ?{, ?}) do
      body
      |> split_args()
      |> Enum.reject(&String.starts_with?(&1, "..."))
      |> Map.new(fn entry ->
        {name, default} =
          case String.split(entry, "=", parts: 2) do
            [name] -> {String.trim(name), nil}
            [name, default] -> {String.trim(name), default |> String.trim() |> String.trim("\"")}
          end

        {name |> String.split(":") |> hd() |> String.trim(), default}
      end)
    else
      _ -> %{}
    end
  end

  @doc """
  The props a function destructured under another name, by the name it gave
  them.

  `{ icon: Icon = DotIcon }` yields `%{"Icon" => "icon"}`. React renames a prop
  when it holds a component, because JSX reads a lowercase tag as an HTML
  element: `<Icon />` renders what the caller passed and `<icon />` would render
  an element nobody has heard of. So a renamed prop is a signal, not a style,
  and what it signals is that this prop is a thing to render.
  """
  def renames(signature) do
    with {at, _} <- :binary.match(signature, "{"),
         {body, _rest} <- balanced(signature, at + 1, ?{, ?}) do
      body
      |> split_args()
      |> Enum.reject(&String.starts_with?(&1, "..."))
      |> Enum.flat_map(fn entry ->
        with [name, rest] <- String.split(entry, ":", parts: 2),
             binding when binding != "" <- rest |> String.split("=") |> hd() |> String.trim() do
          [{binding, String.trim(name)}]
        else
          _ -> []
        end
      end)
      |> Map.new()
    else
      _ -> %{}
    end
  end

  # `({ className, ...props }: Accordion.Trigger.Props)` -> "Accordion.Trigger.Props"
  defp props_type(signature) do
    case Regex.run(~r/[\}\w]\s*:\s*([A-Za-z0-9_.]+)\s*$/, String.trim(signature),
           capture: :all_but_first
         ) do
      [type] -> type
      nil -> nil
    end
  end

  # The three shapes a registry component returns in.
  defp return_jsx!(body, fun) do
    # Only this function's own return. A component's body is full of other
    # people's returns — `useEffect(() => { … return () => clearTimeout(t) })`
    # writes one — and taking the first `return (` in the text picked that
    # cleanup out of `Reasoning` and then failed with an empty JSX element.
    body = own_return(body)

    parenthesised = :binary.match(body, "return (")
    use_render = :binary.match(body, "return useRender(")
    bare = :binary.match(body, "return <")

    cond do
      first?(use_render, [parenthesised, bare]) ->
        body
        |> balanced(elem(use_render, 0) + byte_size("return useRender("), ?(, ?))
        |> elem(0)
        |> use_render!()

      first?(parenthesised, [use_render, bare]) ->
        body
        |> balanced(elem(parenthesised, 0) + byte_size("return ("), ?(, ?))
        |> elem(0)
        |> jsx_or_expression!()

      bare != :nomatch ->
        at = elem(bare, 0) + byte_size("return ")
        finish = body |> :binary.matches(">") |> List.last() |> elem(0)
        parse_jsx!(binary_part(body, at, finish - at + 1))

      returns_expression(body) ->
        # `return toasts.map((toast) => (<Toast />))`. The reader hands the
        # expression on rather than deciding what it means; that is the spec's
        # job, and it is the same decision it makes for an expression in JSX.
        %{type: :expr, code: returns_expression(body)}

      true ->
        raise "#{fun}: no return to read"
    end
  end

  # The body from its own first `return` onwards, where "its own" means at the
  # nesting level of the body itself. Anything deeper belongs to a callback.
  defp own_return(body) do
    at = at_own_return(body, 0, 0)
    binary_part(body, at, byte_size(body) - at)
  end

  defp at_own_return(body, at, depth) when at < byte_size(body) do
    case body do
      <<_::binary-size(^at), c, _::binary>> when c in [?{, ?(, ?[] ->
        at_own_return(body, at + 1, depth + 1)

      <<_::binary-size(^at), c, _::binary>> when c in [?}, ?), ?]] ->
        at_own_return(body, at + 1, depth - 1)

      <<_::binary-size(^at), c, _::binary>> when c in [?", ?\', ?`] ->
        at_own_return(body, scan(body, at + 1, :quoted, c, c) + 1, depth)

      <<_::binary-size(^at), "return", _::binary>> when depth == 0 ->
        at

      _ ->
        at_own_return(body, at + 1, depth)
    end
  end

  # No return at this level. The caller decides what that means, and its own
  # clauses read the whole body as they did before.
  defp at_own_return(_body, _at, _depth), do: 0

  defp returns_expression(body) do
    case Regex.run(~r/\breturn\s+(.+)$/s, body, capture: :all_but_first) do
      [expression] -> expression |> String.trim() |> String.trim_trailing(";")
      nil -> nil
    end
  end

  # What a bracketed return holds is usually one element and sometimes an
  # expression that decides which. `return (!isAtBottom && <Button />)` is the
  # second, and reading it as the first asked for a JSX element and found `!`.
  defp jsx_or_expression!(code) do
    case String.trim(code) do
      "<" <> _rest = jsx -> parse_jsx!(jsx)
      expression -> %{type: :expr, code: expression}
    end
  end

  defp first?(:nomatch, _others), do: false

  defp first?({at, _}, others),
    do: Enum.all?(others, fn other -> other == :nomatch or at < elem(other, 0) end)

  # Base UI's `useRender` is the other way shadcn writes a component:
  #
  #     return useRender({
  #       defaultTagName: "span",
  #       props: mergeProps<"span">({ className: cn(badgeVariants({ variant })) }, props),
  #       state: { slot: "badge" },
  #     })
  #
  # It says the same three things a JSX element does — the tag, the class
  # string, the `data-slot` — so it is read into the same shape.
  defp use_render!(code) do
    call = object!(code)
    tag = call |> Map.get("defaultTagName") |> string_value("div")
    slot = call |> Map.get("state") |> state_slot()
    classes = call |> Map.get("props") |> merged_class()

    attrs =
      [
        if(slot, do: {:attr, "data-slot", {:string, slot}}),
        if(classes, do: {:attr, "className", {:expr, classes}}),
        {:spread, "props"}
      ]
      |> Enum.reject(&is_nil/1)

    %{type: :element, tag: tag, attrs: attrs, children: [%{type: :expr, code: "children"}]}
  end

  defp string_value({:string, value}, _default), do: value
  defp string_value(_other, default), do: default

  defp state_slot({:object, state}), do: state |> Map.get("slot") |> string_value(nil)
  defp state_slot(_other), do: nil

  # `mergeProps<"span">({ className: … }, props)` — the class string lives in
  # the first object the call merges.
  defp merged_class({:code, code}) do
    with {at, _} <- :binary.match(code, "{"),
         {body, _rest} <- balanced(code, at + 1, ?{, ?}),
         %{"className" => {:code, expression}} <- object!("{" <> body <> "}") do
      expression
    else
      _ -> nil
    end
  end

  defp merged_class(_other), do: nil

  @doc "Parses a single JSX element and its subtree."
  def parse_jsx!(source) do
    {node, rest} = source |> ws() |> element!()

    case ws(rest) do
      "" -> node
      trailing -> raise "unread JSX after the root element: #{String.slice(trailing, 0, 40)}"
    end
  end

  defp element!("<" <> rest) do
    {tag, rest} = name(rest)
    {attrs, rest, self_closing?} = attributes(rest, [])

    if self_closing? do
      {%{type: :element, tag: tag, attrs: attrs, children: []}, rest}
    else
      {children, rest} = children(rest, [])
      {%{type: :element, tag: tag, attrs: attrs, children: children}, close!(rest, tag)}
    end
  end

  defp element!(other), do: raise("expected a JSX element at: #{String.slice(other, 0, 40)}")

  defp attributes(source, acc) do
    case ws(source) do
      "/>" <> rest -> {Enum.reverse(acc), rest, true}
      ">" <> rest -> {Enum.reverse(acc), rest, false}
      "{..." <> _ = rest -> spread(rest, acc)
      rest -> attribute(rest, acc)
    end
  end

  defp spread(source, acc) do
    {expr, rest} = balanced(source, 1, ?{, ?})
    attributes(rest, [{:spread, expr |> String.trim() |> String.trim_leading(".")} | acc])
  end

  defp attribute(source, acc) do
    {key, rest} = name(source)
    if key == "", do: raise("unreadable attribute at: #{String.slice(source, 0, 40)}")

    case ws(rest) do
      "=" <> rest ->
        {value, rest} = value(key, ws(rest))
        attributes(rest, [{:attr, key, value} | acc])

      rest ->
        attributes(rest, [{:attr, key, true} | acc])
    end
  end

  defp value(key, source) do
    case source do
      "\"" <> _ ->
        {literal, rest} = balanced(source, 1, ?", ?")
        {{:string, literal}, rest}

      "'" <> _ ->
        {literal, rest} = balanced(source, 1, ?', ?')
        {{:string, literal}, rest}

      "{" <> _ ->
        {code, rest} = balanced(source, 1, ?{, ?})
        {{:expr, String.trim(code)}, rest}

      other ->
        raise "unreadable value for #{key}: #{String.slice(other, 0, 40)}"
    end
  end

  defp children(source, acc) do
    case source do
      "</" <> _ ->
        {Enum.reverse(acc), source}

      "<" <> _ ->
        {node, rest} = element!(source)
        children(rest, [node | acc])

      "{" <> _ ->
        {code, rest} = balanced(source, 1, ?{, ?})
        children(rest, [%{type: :expr, code: String.trim(code)} | acc])

      "" ->
        raise "JSX ended while children were still open"

      _ ->
        {text, rest} = text(source)
        acc = if String.trim(text) == "", do: acc, else: [%{type: :text, value: text} | acc]
        children(rest, acc)
    end
  end

  defp text(source) do
    at =
      case :binary.matches(source, ["<", "{"]) do
        [] -> byte_size(source)
        [{at, _} | _] -> at
      end

    split(source, at)
  end

  defp close!(source, tag) do
    expected = "</" <> tag <> ">"
    rest = ws(source)

    if String.starts_with?(rest, expected) do
      binary_part(rest, byte_size(expected), byte_size(rest) - byte_size(expected))
    else
      raise "expected #{expected}, found #{String.slice(rest, 0, 40)}"
    end
  end

  defp name(source), do: take(source, 0)

  defp take(source, at) do
    case source do
      <<_::binary-size(^at), c, _::binary>> when c in ?a..?z or c in ?A..?Z or c in ?0..?9 ->
        take(source, at + 1)

      <<_::binary-size(^at), c, _::binary>> when c in [?_, ?., ?-, ?:, ?$] ->
        take(source, at + 1)

      _ ->
        split(source, at)
    end
  end

  defp split(source, at),
    do: {binary_part(source, 0, at), binary_part(source, at, byte_size(source) - at)}

  defp ws(<<c, rest::binary>>) when c in ~c" \t\n\r", do: ws(rest)
  defp ws(source), do: source

  # Reads from `at`, which sits just past the opening delimiter, to the
  # matching close. Delimiters inside a string or template literal are skipped.
  defp balanced(source, at, open, close) do
    state = if open == close, do: :quoted, else: {:depth, 1}
    finish = scan(source, at, state, open, close)

    {binary_part(source, at, finish - at),
     binary_part(source, finish + 1, byte_size(source) - finish - 1)}
  end

  defp scan(source, at, state, open, close) do
    case source do
      <<_::binary-size(^at), c, _::binary>> -> step(source, at, state, open, close, c)
      _ -> raise "unbalanced #{<<open>>} … #{<<close>>}"
    end
  end

  defp step(source, at, :quoted, open, close, ?\\), do: scan(source, at + 2, :quoted, open, close)
  defp step(_source, at, :quoted, _open, close, c) when c == close, do: at
  defp step(source, at, :quoted, open, close, _c), do: scan(source, at + 1, :quoted, open, close)

  defp step(source, at, state, open, close, c) when c in [?", ?', ?`],
    do: scan(source, scan(source, at + 1, :quoted, c, c) + 1, state, open, close)

  defp step(source, at, {:depth, n}, open, close, c) when c == open,
    do: scan(source, at + 1, {:depth, n + 1}, open, close)

  defp step(_source, at, {:depth, 1}, _open, close, c) when c == close, do: at

  defp step(source, at, {:depth, n}, open, close, c) when c == close,
    do: scan(source, at + 1, {:depth, n - 1}, open, close)

  defp step(source, at, state, open, close, _c), do: scan(source, at + 1, state, open, close)

  @doc """
  The literal class names in a `className` value.

  `cn("a b", className)` and `"a b"` both yield `"a b"`. Anything that is not a
  string literal — a conditional, an interpolation — is not a class name the
  generator can emit, so it is left out.
  """
  def classes({:string, literal}), do: normalise(literal)

  def classes({:expr, code}) do
    code
    |> call_args("cn")
    |> Enum.flat_map(&literal/1)
    |> Enum.join(" ")
    |> normalise()
  end

  def classes(_), do: ""

  @doc """
  Whether this element is the one that merges the caller's class.

  shadcn threads a `className` prop down to exactly one element per component,
  by naming it where that element's class string is built. The generator has to
  put the caller's class on the same element, so the spec records which one it
  is. It reaches there two ways — `cn("…", className)` directly, or
  `cn(buttonVariants({ variant, className }))` — and both count.
  """
  def merges_class?({:expr, code}), do: Regex.match?(~r/\bclassName\b/, code)
  def merges_class?(_), do: false

  @doc """
  The `cva` binding a class value is built from, if any.

  `cn(buttonVariants({ variant, size, className }))` means this element's class
  string is not fixed: it depends on props. `bindings` is the set of names known
  to hold a `cva` call, so a call to something else is not mistaken for one.
  """
  def variant_call({:expr, code}, bindings) do
    Enum.find(bindings, fn name -> Regex.match?(~r/\b#{Regex.escape(name)}\(/, code) end)
  end

  def variant_call(_value, _bindings), do: nil

  @doc """
  Reads a JavaScript object literal into a map.

  Values come back tagged: `{:string, literal}`, `{:object, map}`, or
  `{:code, source}` for anything the reader does not need to understand.
  """
  def object!(code) do
    code = String.trim(code)

    unless String.starts_with?(code, "{"), do: raise("not an object literal: #{code}")

    {body, _rest} = balanced(code, 1, ?{, ?})

    body
    |> split_args()
    |> Enum.map(&pair/1)
    |> Map.new()
  end

  defp pair(entry) do
    case String.split(entry, ":", parts: 2) do
      [key, value] -> {unquote_key(key), value(String.trim(value))}
      [shorthand] -> {unquote_key(shorthand), {:code, String.trim(shorthand)}}
    end
  end

  defp unquote_key(key), do: key |> String.trim() |> String.trim("\"") |> String.trim("'")

  defp value(<<q, _::binary>> = literal) when q in [?", ?'],
    do: {:string, literal |> String.slice(1..-2//1) |> normalise()}

  defp value("{" <> _ = object), do: {:object, object!(object)}
  defp value(code), do: {:code, code}

  defp call_args(code, fun) do
    prefix = fun <> "("

    if String.starts_with?(code, prefix) do
      {args, _} = balanced(code, byte_size(prefix), ?(, ?))
      split_args(args)
    else
      [code]
    end
  end

  @doc "Splits a comma-separated argument or entry list at its top level."
  def split_args(args), do: args |> String.trim() |> do_split_args(0, [], "")

  defp do_split_args("", _depth, acc, current), do: Enum.reverse(add_arg(acc, current))

  defp do_split_args(source, depth, acc, current) do
    case source do
      <<",", rest::binary>> when depth == 0 ->
        do_split_args(rest, 0, add_arg(acc, current), "")

      <<c, _::binary>> when c in [?", ?', ?`] ->
        {literal, rest} = balanced(source, 1, c, c)
        do_split_args(rest, depth, acc, current <> <<c>> <> literal <> <<c>>)

      <<c, rest::binary>> when c in ~c"([{" ->
        do_split_args(rest, depth + 1, acc, current <> <<c>>)

      <<c, rest::binary>> when c in ~c")]}" ->
        do_split_args(rest, depth - 1, acc, current <> <<c>>)

      <<c, rest::binary>> ->
        do_split_args(rest, depth, acc, current <> <<c>>)
    end
  end

  defp add_arg(acc, current) do
    case String.trim(current) do
      "" -> acc
      arg -> [arg | acc]
    end
  end

  defp literal(<<q, _::binary>> = arg) when q in [?", ?'], do: [String.slice(arg, 1..-2//1)]
  defp literal(_), do: []

  defp normalise(string), do: string |> String.split() |> Enum.join(" ")

  @doc "The value of an attribute, or `nil`."
  def attr(%{attrs: attrs}, key) do
    Enum.find_value(attrs, fn
      {:attr, ^key, value} -> value
      _ -> nil
    end)
  end

  def attr(_node, _key), do: nil

  @doc "Whether the element forwards `{...props}`."
  def spread?(%{attrs: attrs}), do: Enum.any?(attrs, &match?({:spread, _}, &1))
  def spread?(_node), do: false
end
