defmodule LiveShadcnTools.Ast do
  @moduledoc """
  Reads an upstream `.tsx` into a syntax tree, and that tree into the facts the
  spec is built from.

  ## Why a real parser

  This used to be regular expressions over the source, and it read most files
  most of the time. What it could not do is know where anything ended. Brackets
  inside strings, a `}` in a template literal, a ternary whose branches are both
  JSX, a `return` belonging to a callback rather than to the component — each of
  those is a place where counting characters gives the wrong answer, and each
  one it got wrong silently: a component came out missing a part, and nothing
  said so until a browser did.

  `oxc-parser` answers those questions exactly. Every node carries a byte offset,
  so "the source of this expression" stops being a guess.

  ## What stays in Elixir

  All of it but the parse. `priv/parse.mjs` prints the tree and decides nothing;
  what a class string is, what a `cva` call is, what an expression means, are
  read here and in `LiveShadcnTools.Spec`. One language to review, which is what
  a pipeline nobody may edit by hand has to be.

  ## The shapes it produces

      %{
        functions: [%{name:, props_type:, params:, renames:, jsx:}],
        consts: %{name => source},
        imports: %{local_name => package},
        exports: [name],
        unreadable: %{name => reason}
      }

  and a JSX tree of:

      %{type: :element, tag: String.t(), attrs: [attr], children: [node]}
      %{type: :expr, code: String.t()}
      %{type: :text, value: String.t()}

  where an attribute is `{:attr, name, {:string, s} | {:expr, code} | true}` or
  `{:spread, code}`. Those are the shapes the rest of the pipeline was written
  against, and they did not need to change: what changed is that they are now
  right.
  """

  @doc """
  Parses a source file and reads its top level.
  """
  def parse!(source) do
    program = tree!(source)
    read = Enum.map(declarations(program), &declaration(&1, source))

    %{
      functions: Enum.filter(read, &is_map/1),
      unreadable: Map.new(for {:unreadable, name, why} <- read, do: {name, why}),
      consts: consts(program, source),
      imports: imports(program),
      exports: exports(program)
    }
  end

  @doc """
  Parses one JSX element, written as source.

  `LiveShadcnTools.Spec` meets JSX inside an expression — `children ?? <Icon />`
  is a decision with markup on one side of it — and hands the markup back here
  rather than deciding what it is. It arrives as source because that is what the
  expression around it was.
  """
  def parse_jsx!(code) do
    # Wrapped, because a fragment is not a program. The wrapper's own bytes are
    # part of the source every offset is measured against, so it is what the
    # slices are taken from.
    wrapped = "const __jsx = (\n#{code}\n)"

    case cached_tree(wrapped) do
      %{"body" => [%{"declarations" => [%{"init" => init}]}]} -> jsx!(bare(init), wrapped, code)
      _ -> raise "not a JSX element: #{String.slice(code, 0, 60)}"
    end
  end

  @doc """
  Splits a ternary into its three parts, or returns `nil`.

  `{tooltip ? <Tooltip>…</Tooltip> : button}` is one of two things chosen at
  render, and telling it from `costText={x}` used to be a matter of counting
  brackets and getting it wrong — a `?` inside a string or between JSX tags is
  not the one that matters, and there is no depth to count in `<Tooltip>`.

  The parser knows which `?` is the ternary's, so this asks it.
  """
  def conditional(code) do
    wrapped = "const __x = (\n#{code}\n)"

    case cached_tree(wrapped) do
      %{"body" => [%{"declarations" => [%{"init" => init}]}]} -> ternary(bare(init), wrapped)
      _ -> nil
    end
  rescue
    # Not something that parses on its own, so not a ternary either.
    _error -> nil
  end

  defp ternary(%{"type" => "ConditionalExpression"} = node, source),
    do:
      {slice(node["test"], source), slice(bare(node["consequent"]), source),
       slice(bare(node["alternate"]), source)}

  defp ternary(_node, _source), do: nil

  # One parse per distinct fragment. The same `children ?? <ChevronDown />`
  # appears in a dozen components, and a subprocess each time is a subprocess
  # for nothing.
  defp cached_tree(source) do
    case :persistent_term.get({__MODULE__, source}, nil) do
      nil ->
        tree = tree!(source)
        :persistent_term.put({__MODULE__, source}, tree)
        tree

      tree ->
        tree
    end
  end

  # Through a file, because the parser reads to end of input and an Erlang port
  # has no way to say the input ended without also ending the process.
  defp tree!(source) do
    script = Path.join(:code.priv_dir(:live_shadcn_tools), "parse.mjs")
    path = Path.join(System.tmp_dir!(), "live-shadcn-#{:erlang.phash2(source)}.tsx")

    File.write!(path, source)

    try do
      case System.cmd(node!(), [script, path], stderr_to_stdout: true) do
        {json, 0} -> Jason.decode!(json)
        {output, _status} -> raise "the parser could not read this source: #{String.trim(output)}"
      end
    after
      File.rm(path)
    end
  end

  defp node! do
    System.find_executable("node") ||
      raise """
      `node` is not on the PATH, and the pipeline parses upstream TypeScript
      with it. `mise install` puts it there.
      """
  end

  # `import { Button } from "@/registry/bases/base/ui/button"` becomes
  # `%{"Button" => ".../ui/button"}`, which is how a reference to another
  # component in the registry is told apart from anything else. A namespace
  # import binds the whole module under one name, and its parts are read off
  # that name.
  defp imports(program) do
    for %{"type" => "ImportDeclaration"} = declaration <- program["body"],
        specifier <- declaration["specifiers"] || [],
        into: %{},
        do: {specifier["local"]["name"], declaration["source"]["value"]}
  end

  # Two registries write their exports two ways. shadcn declares everything and
  # exports it in one list at the foot of the file; AI Elements exports each
  # binding where it is declared. Both are the same list.
  defp exports(program) do
    program["body"]
    |> Enum.flat_map(fn
      %{"type" => "ExportNamedDeclaration", "declaration" => declaration}
      when is_map(declaration) ->
        declaration |> bindings() |> Enum.map(&name_of/1)

      %{"type" => "ExportNamedDeclaration", "specifiers" => specifiers} ->
        Enum.map(specifiers || [], & &1["exported"]["name"])

      _node ->
        []
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp name_of(%{"type" => "FunctionDeclaration", "id" => %{"name" => name}}), do: name
  defp name_of(%{"id" => %{"name" => name}}), do: name
  defp name_of(_node), do: nil

  # Every top-level binding, by the source of what it was bound to. `cva` tables
  # and object literals are read out of these, and both want the text.
  defp consts(program, source) do
    for declaration <- declarations(program),
        declaration["type"] == "VariableDeclarator",
        name = name_of(declaration),
        init = declaration["init"],
        is_map(init),
        into: %{},
        do: {name, slice(init, source)}
  end

  # ── the top level ─────────────────────────────────────────────────────────

  defp declarations(program) do
    Enum.flat_map(program["body"], fn
      %{"type" => "ExportNamedDeclaration", "declaration" => declaration}
      when is_map(declaration) ->
        bindings(declaration)

      node ->
        bindings(node)
    end)
  end

  defp bindings(%{"type" => "FunctionDeclaration"} = node), do: [node]

  defp bindings(%{"type" => "VariableDeclaration", "declarations" => declarations}),
    do: declarations

  defp bindings(_node), do: []

  defp declaration(%{"type" => "FunctionDeclaration"} = node, source) do
    function(node["id"]["name"], node["params"], node["body"], source)
  end

  defp declaration(%{"type" => "VariableDeclarator", "id" => %{"name" => name}} = node, source) do
    case node["init"] |> bare() |> unwrap() do
      %{"type" => type} = arrow when type in ~w(ArrowFunctionExpression FunctionExpression) ->
        function(name, arrow["params"], arrow["body"], source)

      _other ->
        nil
    end
  end

  defp declaration(_node, _source), do: nil

  # Brackets a person wrote for readability, and a cast written for the type
  # checker. Neither is markup and neither changes what the thing inside is, so
  # every place that asks "what kind of node is this" looks through them first.
  defp bare(%{"type" => "ParenthesizedExpression", "expression" => inner}), do: bare(inner)
  defp bare(%{"type" => "TSAsExpression", "expression" => inner}), do: bare(inner)
  defp bare(%{"type" => "TSNonNullExpression", "expression" => inner}), do: bare(inner)
  defp bare(%{"type" => "TSSatisfiesExpression", "expression" => inner}), do: bare(inner)
  defp bare(node), do: node

  # `memo(…)` and `forwardRef(…)` say something about React's rendering and
  # nothing about the markup, so they are read through rather than read.
  defp unwrap(%{
         "type" => "CallExpression",
         "callee" => %{"name" => name},
         "arguments" => [inner | _]
       })
       when name in ~w(memo forwardRef),
       do: unwrap(bare(inner))

  defp unwrap(node), do: node

  defp function(name, params, body, source) do
    signature = List.first(params) || %{}

    %{
      name: name,
      props_type: type_name(signature["typeAnnotation"]),
      params: props(signature, body, source),
      renames: renames(signature),
      jsx: jsx(body, source)
    }
  rescue
    error -> {:unreadable, name, Exception.message(error)}
  end

  # ── what a component takes ────────────────────────────────────────────────

  @doc """
  The props a component takes, from the three places it can get one.

  What it destructured is a prop. What it kept as state is a prop, because the
  server owns state and a variable inside a render is not somewhere state can
  live. What it computed is a prop, because a template cannot run the
  computation and the value is still needed — `tool` derives a name from a tool
  call's type, and the alternative to asking for it is rendering a blank.

  A destructured prop wins over the other two, since upstream wrote a default
  for it and neither of the others has one worth carrying.
  """
  def props(signature, body, source) do
    body
    |> statements()
    |> Enum.flat_map(&bound(&1, source))
    |> Map.new()
    |> Map.merge(destructured(signature, source))
  end

  defp statements(%{"type" => "BlockStatement", "body" => body}), do: body
  defp statements(_body), do: []

  # `const [isOpen, setIsOpen] = useState(false)` and
  # `const { isOpen } = useChainOfThought()` are both React holding something,
  # and `const derivedName = …` is React computing something. All three are a
  # name the markup reads and the caller has to supply.
  #
  # A setter is not one. Nothing renders `setIsOpen`.
  defp bound(%{"type" => "VariableDeclaration", "declarations" => declarations}, source) do
    Enum.flat_map(declarations, fn declaration ->
      case declaration["id"] do
        %{"type" => "ArrayPattern", "elements" => [%{"name" => name} | _rest]} ->
          [{name, initial(declaration["init"], source)}]

        %{"type" => "ObjectPattern"} = pattern ->
          pattern
          |> destructured(source)
          |> Map.keys()
          |> Enum.reject(&String.starts_with?(&1, "set"))
          |> Enum.map(&{&1, nil})

        %{"type" => "Identifier", "name" => name} ->
          [{name, nil}]

        _other ->
          []
      end
    end)
  end

  defp bound(_statement, _source), do: []

  # The value state starts at, when it is written down. `useState(false)` says
  # false; `useState(defaultBranch)` says "whatever that prop is", and the prop
  # is declared already.
  defp initial(%{"type" => "CallExpression", "arguments" => [%{"value" => value} | _]}, _source)
       when is_boolean(value) or is_number(value),
       do: to_string(value)

  defp initial(_init, _source), do: nil

  defp destructured(%{"type" => "ObjectPattern", "properties" => properties}, source) do
    for %{"type" => "Property", "key" => %{"name" => name}} = property <- properties,
        into: %{},
        do: {name, default(property["value"], source)}
  end

  defp destructured(_signature, _source), do: %{}

  defp default(%{"type" => "AssignmentPattern", "right" => right}, source) do
    case right do
      %{"type" => "Literal", "value" => value} when is_binary(value) -> value
      %{"type" => "Literal", "value" => value} -> to_string(value)
      node -> slice(node, source)
    end
  end

  defp default(_value, _source), do: nil

  @doc """
  The props a function destructured under another name, by the name it gave
  them.

  `{ icon: Icon = DotIcon }` yields `%{"Icon" => "icon"}`. React renames a prop
  when it holds a component, because JSX reads a lowercase tag as an HTML
  element: `<Icon />` renders what the caller passed and `<icon />` would render
  an element nobody has heard of. So a rename is a signal, and what it signals
  is that this prop is a thing to render.
  """
  def renames(%{"type" => "ObjectPattern", "properties" => properties}) do
    for %{"type" => "Property", "key" => %{"name" => name}, "value" => value} <- properties,
        binding = binding_name(value),
        binding != name,
        into: %{},
        do: {binding, name}
  end

  def renames(_signature), do: %{}

  defp binding_name(%{"type" => "Identifier", "name" => name}), do: name
  defp binding_name(%{"type" => "AssignmentPattern", "left" => left}), do: binding_name(left)
  defp binding_name(_value), do: nil

  # `({ … }: Accordion.Trigger.Props)` -> "Accordion.Trigger.Props"
  defp type_name(%{"typeAnnotation" => %{"type" => "TSTypeReference", "typeName" => name}}),
    do: qualified(name)

  defp type_name(_annotation), do: nil

  defp qualified(%{"type" => "Identifier", "name" => name}), do: name

  defp qualified(%{"type" => "TSQualifiedName", "left" => left, "right" => right}),
    do: qualified(left) <> "." <> qualified(right)

  defp qualified(_name), do: nil

  # ── what a component renders ──────────────────────────────────────────────

  # An arrow with an expression body renders that expression. A block body
  # renders what its own `return` returns — its own, at this level, and not one
  # belonging to a `useEffect` cleanup three lines up.
  defp jsx(%{"type" => "BlockStatement", "body" => body}, source) do
    case Enum.find(body, &(&1["type"] == "ReturnStatement")) do
      %{"argument" => argument} when is_map(argument) -> returned(bare(argument), source)
      _ -> nil
    end
  end

  defp jsx(body, source) when is_map(body), do: returned(bare(body), source)
  defp jsx(_body, _source), do: nil

  defp returned(%{"type" => type} = node, source) when type in ~w(JSXElement JSXFragment),
    do: jsx_node(node, source)

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
  defp returned(
         %{
           "type" => "CallExpression",
           "callee" => %{"name" => "useRender"},
           "arguments" => [call | _]
         },
         source
       ) do
    fields = object(call)
    slot = fields |> Map.get("state") |> object() |> Map.get("slot") |> literal()

    attrs =
      [
        slot && {:attr, "data-slot", {:string, slot}},
        merged_class(fields["props"], source),
        {:spread, "props"}
      ]
      |> Enum.reject(&is_nil/1)

    %{
      type: :element,
      tag: fields |> Map.get("defaultTagName") |> literal() || "div",
      attrs: attrs,
      children: [%{type: :expr, code: "children"}]
    }
  end

  # Anything else is an expression the spec decides the meaning of, exactly as
  # it does for an expression written inside JSX.
  defp returned(node, source), do: %{type: :expr, code: slice(node, source)}

  defp object(%{"type" => "ObjectExpression", "properties" => properties}) do
    for %{"type" => "Property", "key" => %{"name" => name}, "value" => value} <- properties,
        into: %{},
        do: {name, value}
  end

  defp object(_node), do: %{}

  defp literal(%{"type" => "Literal", "value" => value}) when is_binary(value), do: value
  defp literal(_node), do: nil

  # `mergeProps<"span">({ className: … }, props)` — the class string is in the
  # first object the call merges.
  defp merged_class(%{"type" => "CallExpression", "arguments" => [first | _]}, source) do
    case first |> object() |> Map.get("className") do
      nil -> nil
      value -> {:attr, "className", {:expr, slice(value, source)}}
    end
  end

  defp merged_class(_props, _source), do: nil

  defp jsx!(%{"type" => type} = node, source, _code) when type in ~w(JSXElement JSXFragment),
    do: jsx_node(node, source)

  defp jsx!(_node, _source, code), do: raise("not a JSX element: #{String.slice(code, 0, 60)}")

  # ── the markup itself ─────────────────────────────────────────────────────

  defp jsx_node(%{"type" => "JSXElement"} = node, source) do
    opening = node["openingElement"]

    %{
      type: :element,
      tag: tag(opening["name"]),
      attrs: Enum.map(opening["attributes"], &attribute(&1, source)),
      children: children(node["children"], source)
    }
  end

  # `<>…</>` groups children and renders nothing. HEEx needs no grouping, and
  # the spec reads an empty tag as exactly that.
  defp jsx_node(%{"type" => "JSXFragment"} = node, source),
    do: %{type: :element, tag: "", attrs: [], children: children(node["children"], source)}

  defp children(children, source) do
    children
    |> Enum.map(&child(&1, source))
    |> Enum.reject(&is_nil/1)
  end

  defp child(%{"type" => "JSXText", "value" => value}, _source) do
    if String.trim(value) == "", do: nil, else: %{type: :text, value: value}
  end

  defp child(%{"type" => "JSXExpressionContainer", "expression" => expression}, source) do
    case expression["type"] do
      # `{/* a comment */}` renders nothing and says nothing to a reader.
      "JSXEmptyExpression" -> nil
      _ -> %{type: :expr, code: slice(expression, source)}
    end
  end

  defp child(%{"type" => type} = node, source) when type in ~w(JSXElement JSXFragment),
    do: jsx_node(node, source)

  defp child(_node, _source), do: nil

  defp tag(%{"type" => "JSXIdentifier", "name" => name}), do: name

  defp tag(%{"type" => "JSXMemberExpression", "object" => object, "property" => property}),
    do: tag(object) <> "." <> tag(property)

  defp tag(%{"type" => "JSXNamespacedName", "namespace" => ns, "name" => name}),
    do: tag(ns) <> ":" <> tag(name)

  defp tag(_name), do: ""

  defp attribute(%{"type" => "JSXSpreadAttribute", "argument" => argument}, source),
    do: {:spread, slice(argument, source)}

  defp attribute(%{"type" => "JSXAttribute", "name" => name, "value" => value}, source),
    do: {:attr, tag(name), attribute_value(value, source)}

  # `<button disabled>` — an attribute with no value is present, and presence is
  # the whole of what it says.
  defp attribute_value(nil, _source), do: true

  defp attribute_value(%{"type" => "Literal", "value" => value}, _source) when is_binary(value),
    do: {:string, value}

  defp attribute_value(%{"type" => "JSXExpressionContainer", "expression" => expression}, source),
    do: {:expr, slice(expression, source)}

  defp attribute_value(%{"type" => type} = node, source) when type in ~w(JSXElement JSXFragment),
    do: {:expr, slice(node, source)}

  defp attribute_value(_value, _source), do: true

  # ── source ────────────────────────────────────────────────────────────────

  # The exact bytes a node came from. This is the whole reason for a real
  # parser: an expression's source is a fact the tree carries, and every attempt
  # to work it out by counting brackets was a place to be wrong.
  defp slice(%{"start" => start, "end" => finish}, source) when is_binary(source),
    do: binary_part(source, start, finish - start)

  defp slice(_node, _source), do: ""
end
