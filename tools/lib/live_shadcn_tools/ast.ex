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
      %{type: :expr, code: String.t(), node: map()}
      %{type: :text, value: String.t()}

  where an attribute is `{:attr, name, {:string, s} | {:expr, code, node} | true}` or
  `{:spread, code}`. Those are the shapes the rest of the pipeline was written
  against, and they did not need to change: what changed is that they are now
  right.
  """

  @doc """
  Parses a source file and reads its top level.
  """
  def parse!(source) do
    %{
      "program" => program,
      "module" => module,
      "analysis" => %{"parameterReferences" => parameter_references}
    } = tree!(source)

    type_definitions = type_definitions(program)

    read =
      program
      |> declarations()
      |> Enum.map(&declaration(&1, source, type_definitions, parameter_references))
      |> resolve_aliases()

    %{
      functions: Enum.filter(read, &is_map/1),
      unreadable: Map.new(for {:unreadable, name, why} <- read, do: {name, why}),
      consts: consts(program, source),
      const_nodes: const_nodes(program, source),
      imports: imports(program),
      exports: exports(module)
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
  def conditional(code) when is_binary(code) do
    wrapped = "const __x = (\n#{code}\n)"

    case cached_tree(wrapped) do
      %{"body" => [%{"declarations" => [%{"init" => init}]}]} -> ternary(bare(init), wrapped)
      _ -> nil
    end
  rescue
    # Not something that parses on its own, so not a ternary either.
    _error -> nil
  end

  def conditional({:expr, _code, node} = expression) do
    case bare(node) do
      %{"type" => "ConditionalExpression", "test" => test, "consequent" => yes, "alternate" => no} ->
        {expression(expression, test), expression(expression, bare(yes)),
         expression(expression, bare(no))}

      _other ->
        nil
    end
  end

  @doc """
  One JSX element, or `nil` when the source is something else.

  The caller sometimes has an expression that may or may not be markup — a
  loop's body is one element, or another loop — and asking is cheaper than
  guessing from whether a `<` appears somewhere in it.
  """
  def parse_jsx(code) do
    parse_jsx!(code)
  rescue
    _error -> nil
  end

  @doc "The exact source span of a child node within an expression tuple."
  def source({:expr, code, parent}, child) when is_map(child) do
    start = child["start"] - parent["start"]
    binary_part(code, start, child["end"] - child["start"])
  end

  @doc "A child node as an expression tuple, with its source span retained."
  def expression({:expr, _code, _parent} = parent, child),
    do: {:expr, source(parent, child), child}

  @doc "The named properties of an object expression, with their OXC nodes."
  def object_entries(nil), do: %{}

  def object_entries({:expr, _code, node} = expression) do
    case bare(node) do
      %{"type" => "ObjectExpression", "properties" => properties} ->
        for property <- properties,
            {name, value} <- object_entry(property),
            into: %{},
            do: {name, expression(expression, value)}

      _other ->
        %{}
    end
  end

  @doc "The JSX represented by an expression tuple, or `nil` when it is not JSX."
  def jsx({:expr, code, parent}) do
    case bare(parent) do
      %{"type" => type} = node when type in ~w(JSXElement JSXFragment) ->
        jsx_node(node, {code, parent})

      _other ->
        nil
    end
  end

  @doc "The identifier roots of member expressions below an OXC expression node."
  def member_roots(node) do
    node
    |> member_roots([])
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp member_roots(%{"type" => "MemberExpression", "object" => object} = node, acc) do
    root = member_root(object)

    node
    |> Map.values()
    |> Enum.reduce(if(root, do: [root | acc], else: acc), &member_roots/2)
  end

  defp member_roots(node, acc) when is_map(node), do: Enum.reduce(node, acc, &member_roots/2)
  defp member_roots({_key, value}, acc), do: member_roots(value, acc)
  defp member_roots(nodes, acc) when is_list(nodes), do: Enum.reduce(nodes, acc, &member_roots/2)
  defp member_roots(_node, acc), do: acc

  defp member_root(%{"type" => "Identifier", "name" => name}), do: name
  defp member_root(%{"type" => "MemberExpression", "object" => object}), do: member_root(object)

  defp member_root(%{"type" => "ChainExpression", "expression" => expression}),
    do: member_root(expression)

  defp member_root(_node), do: nil

  @doc "The identifiers an expression reads, excluding non-computed member names."
  def identifiers(node), do: node |> identifiers([]) |> Enum.uniq() |> Enum.sort()

  defp identifiers(%{"type" => "Identifier", "name" => name}, acc), do: [name | acc]

  defp identifiers(
         %{"type" => "MemberExpression", "object" => object, "property" => property} = node,
         acc
       ) do
    acc = identifiers(object, acc)
    if node["computed"], do: identifiers(property, acc), else: acc
  end

  defp identifiers(%{"type" => "Property", "value" => value}, acc), do: identifiers(value, acc)
  defp identifiers(node, acc) when is_map(node), do: Enum.reduce(node, acc, &identifiers/2)
  defp identifiers({_key, value}, acc), do: identifiers(value, acc)
  defp identifiers(nodes, acc) when is_list(nodes), do: Enum.reduce(nodes, acc, &identifiers/2)
  defp identifiers(_node, acc), do: acc

  defp property_name(%{"name" => name}) when is_binary(name), do: name
  defp property_name(%{"value" => name}) when is_binary(name), do: name
  defp property_name(_key), do: nil

  defp object_entry(%{"type" => "Property", "key" => key, "value" => value}) do
    case property_name(key) do
      name when is_binary(name) -> [{name, value}]
      _other -> []
    end
  end

  defp object_entry(%{"type" => "SpreadElement", "argument" => %{"name" => name} = value}),
    do: [{"..." <> name, value}]

  defp object_entry(_property), do: []

  @doc """
  Splits `a && b`, `a || b` or `a ?? b` into its operator and two sides.

  Both are the same question as a ternary: where does the left stop. Answering
  it by regular expression took `frame.functionName && (<span>…</span>)` and
  swallowed the three siblings after it, because `.*$` does not know that a
  JSX element ended.
  """
  def logical(code) when is_binary(code) do
    wrapped = "const __x = (\n#{code}\n)"

    case cached_tree(wrapped) do
      %{"body" => [%{"declarations" => [%{"init" => init}]}]} -> sides(bare(init), wrapped)
      _ -> nil
    end
  rescue
    _error -> nil
  end

  def logical({:expr, _code, node} = expression) do
    case bare(node) do
      %{"type" => "LogicalExpression", "operator" => operator, "left" => left, "right" => right} ->
        {operator, expression(expression, bare(left)), expression(expression, bare(right))}

      _other ->
        nil
    end
  end

  @doc """
  Splits `items.map((item) => …)` into the list, the name, and the body.

  Where the body ends is the same question again, and a regular expression that
  reads to the end of the string hands back one bracket too many.
  """
  def mapped(code) when is_binary(code) do
    wrapped = "const __x = (\n#{code}\n)"

    case cached_tree(wrapped) do
      %{"body" => [%{"declarations" => [%{"init" => init}]}]} -> mapping(bare(init), wrapped)
      _ -> nil
    end
  rescue
    _error -> nil
  end

  def mapped({:expr, _code, node} = expression) do
    case bare(node) do
      %{
        "type" => "CallExpression",
        "callee" => %{"type" => "MemberExpression", "property" => %{"name" => "map"}} = callee,
        "arguments" => [argument | _]
      } ->
        case bare(argument) do
          %{"type" => "ArrowFunctionExpression", "params" => [binding | rest], "body" => body} ->
            {name, fields} = bound_item(binding)

            {expression(expression, callee["object"]), name, fields, counter(rest),
             expression(expression, bare(body))}

          _other ->
            nil
        end

      _other ->
        nil
    end
  end

  defp mapping(
         %{
           "type" => "CallExpression",
           "callee" => %{"type" => "MemberExpression", "property" => %{"name" => "map"}} = callee,
           "arguments" => [argument | _]
         },
         source
       ) do
    case bare(argument) do
      %{"type" => "ArrowFunctionExpression", "params" => [binding | rest], "body" => body} ->
        {name, fields} = bound_item(binding)

        {slice(callee["object"], source), name, fields, counter(rest), slice(bare(body), source)}

      _ ->
        nil
    end
  end

  defp mapping(_node, _source), do: nil

  @doc """
  Splits `Array.from({ length: n }, (_, index) => …)` into the count, the name
  and the body.

  `slider` draws one thumb per value this way. Where the body ends is the
  question a `.map` asks too, and the regular expression that used to answer it
  read to the end of the string — so the body came back with the call's own
  closing bracket on it and parsed as nothing at all.
  """
  def counted(code) when is_binary(code) do
    wrapped = "const __x = (\n#{code}\n)"

    case cached_tree(wrapped) do
      %{"body" => [%{"declarations" => [%{"init" => init}]}]} -> counting(bare(init), wrapped)
      _ -> nil
    end
  rescue
    _error -> nil
  end

  def counted({:expr, _code, node} = expression) do
    case bare(node) do
      %{
        "type" => "CallExpression",
        "callee" => %{
          "type" => "MemberExpression",
          "object" => %{"name" => "Array"},
          "property" => %{"name" => "from"}
        },
        "arguments" => [shape, mapper | _rest]
      } ->
        with %{"type" => "ObjectExpression", "properties" => properties} <- bare(shape),
             %{"value" => length} <-
               Enum.find(properties, &(get_in(&1, ["key", "name"]) == "length")),
             %{"type" => "ArrowFunctionExpression", "params" => params, "body" => body} <-
               bare(mapper) do
          {expression(expression, bare(length)), counter(Enum.drop(params, 1)) || "index",
           expression(expression, bare(body))}
        else
          _other -> nil
        end

      _other ->
        nil
    end
  end

  defp counting(
         %{
           "type" => "CallExpression",
           "callee" => %{
             "type" => "MemberExpression",
             "object" => %{"name" => "Array"},
             "property" => %{"name" => "from"}
           },
           "arguments" => [shape, mapper | _rest]
         },
         source
       ) do
    with %{"type" => "ObjectExpression", "properties" => properties} <- bare(shape),
         %{"value" => length} <-
           Enum.find(properties, &(get_in(&1, ["key", "name"]) == "length")),
         %{"type" => "ArrowFunctionExpression", "params" => params, "body" => body} <-
           bare(mapper) do
      # `(_, index)` — the first parameter is the array's own element, which
      # `Array.from` fills with `undefined`. The second is the one that counts.
      {slice(bare(length), source), counter(Enum.drop(params, 1)) || "index",
       slice(bare(body), source)}
    else
      _other -> nil
    end
  end

  defp counting(_node, _source), do: nil

  @doc """
  Every call to one of `names` in an expression, with the props it passed.

  `cn(buttonVariants({ variant, size, className }), inputGroupButtonVariants({ size }))`
  is two `cva` tables on one element, and which of them a group belongs to
  decides what class string comes out. `size` is passed to the second and not
  the first, so the first uses its own default — and reading only the name of
  one table lost the other's base class and made the two `size` groups collide.

  Returns `[{name, [prop]}]`, outermost first.
  """
  def calls(code, names) when is_binary(code) do
    wrapped = "const __x = (\n#{code}\n)"

    case cached_tree(wrapped) do
      %{"body" => [%{"declarations" => [%{"init" => init}]}]} -> called(bare(init), names)
      _ -> []
    end
  rescue
    _error -> []
  end

  def calls(node, names) when is_map(node), do: called(bare(node), names)

  @doc "The arguments of an expression call to `name`, or an empty list."
  def call_args({:expr, _code, node}, name), do: call_args(node, name)

  def call_args(node, name) when is_map(node) do
    case bare(node) do
      %{
        "type" => "CallExpression",
        "callee" => %{"type" => "Identifier", "name" => ^name},
        "arguments" => arguments
      } ->
        arguments

      _node ->
        []
    end
  end

  @doc "The string value of an OXC literal node, or `nil`."
  def string_literal({:expr, _code, node}), do: string_literal(node)
  def string_literal(%{"type" => "Literal", "value" => value}) when is_binary(value), do: value

  def string_literal(node) when is_map(node) do
    case bare(node) do
      ^node -> nil
      inner -> string_literal(inner)
    end
  end

  def string_literal(_node), do: nil

  defp called(%{"type" => "CallExpression", "callee" => %{"name" => name}} = call, names) do
    passed = if name in names, do: [{name, object_keys(call["arguments"])}], else: []

    passed ++ called(call["arguments"], names)
  end

  defp called(node, names) when is_map(node),
    do: node |> Map.values() |> Enum.flat_map(&called(&1, names))

  defp called(nodes, names) when is_list(nodes), do: Enum.flat_map(nodes, &called(&1, names))
  defp called(_node, _names), do: []

  defp object_keys([first | _rest]) do
    case bare(first) do
      %{"type" => "ObjectExpression", "properties" => properties} ->
        for property <- properties, name = get_in(property, ["key", "name"]), do: name

      _other ->
        []
    end
  end

  defp object_keys(_arguments), do: []

  # `.map((branch, index) => …)` — the second parameter is where the item sits
  # in the list, which is a fact about the loop rather than about the item.
  defp counter([%{"type" => "Identifier", "name" => name} | _rest]), do: name
  defp counter(_rest), do: nil

  # `(frame) => …` names the item; `({ token, key }) => …` names its fields and
  # not the item. HEEx binds one name per generator, so the item gets a name and
  # the fields are read off it.
  defp bound_item(%{"type" => "Identifier", "name" => name}), do: {name, []}

  defp bound_item(%{"type" => "ObjectPattern", "properties" => properties}),
    do: {"item", for(%{"key" => %{"name" => name}} <- properties, do: name)}

  defp bound_item(_pattern), do: {"item", []}

  defp sides(%{"type" => "LogicalExpression"} = node, source),
    do: {node["operator"], slice(bare(node["left"]), source), slice(bare(node["right"]), source)}

  defp sides(_node, _source), do: nil

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
        tree = tree!(source)["program"]
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
        {json, 0} ->
          Jason.decode!(json)

        {output, _status} ->
          # With the source, because "unexpected token" on its own is a message
          # about a file nobody can find. What reaches here is usually a
          # fragment this pipeline built, so the fragment is the bug.
          raise """
          the parser could not read this source: #{String.trim(output)}

          #{String.slice(source, 0, 400)}
          """
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

  # OXC has already resolved every export form to one module record. A shadcn
  # export list and an AI Elements inline export therefore take the same path.
  defp exports(%{"staticExports" => exports}) do
    for %{"entries" => entries} <- exports,
        %{"exportName" => %{"kind" => "Name", "name" => name}} <- entries,
        is_binary(name),
        uniq: true,
        do: name
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

  # Source remains available for the small places that must emit an upstream
  # expression. Readers that need to understand a constant use this node map.
  defp const_nodes(program, source) do
    for declaration <- declarations(program),
        declaration["type"] == "VariableDeclarator",
        name = name_of(declaration),
        init = declaration["init"],
        is_map(init),
        into: %{},
        do: {name, {:expr, slice(init, source), init}}
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

  defp declaration(
         %{"type" => "FunctionDeclaration"} = node,
         source,
         type_definitions,
         parameter_references
       ) do
    function(
      node["id"]["name"],
      node["params"],
      node["body"],
      source,
      type_definitions,
      parameter_references
    )
  end

  defp declaration(
         %{"type" => "VariableDeclarator", "id" => %{"name" => name}} = node,
         source,
         type_definitions,
         parameter_references
       ) do
    case node["init"] |> bare() |> unwrap() do
      %{"type" => type} = arrow when type in ~w(ArrowFunctionExpression FunctionExpression) ->
        function(
          name,
          arrow["params"],
          arrow["body"],
          source,
          type_definitions,
          parameter_references
        )

      # `export const Shimmer = memo(ShimmerComponent)` — the export and the
      # component are two names for one thing, and only the first is exported.
      %{"type" => "Identifier", "name" => target} ->
        {:alias, name, target}

      _other ->
        nil
    end
  end

  defp declaration(_node, _source, _type_definitions, _parameter_references), do: nil

  # A name that is another name for a component this file already read. The
  # alias keeps its own name, because that is the one the file exports and the
  # one every later stage will look for.
  defp resolve_aliases(read) do
    by_name = Map.new(for function <- read, is_map(function), do: {function.name, function})

    Enum.flat_map(read, fn
      {:alias, name, target} ->
        case Map.fetch(by_name, target) do
          {:ok, function} -> [%{function | name: name}]
          :error -> []
        end

      other ->
        [other]
    end)
  end

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

  defp function(name, params, body, source, type_definitions, parameter_references) do
    signature = List.first(params) || %{}

    %{
      name: name,
      props_type: type_name(signature["typeAnnotation"]),
      params: props(signature, body, source),
      param_types: prop_types(signature, type_definitions),
      refs: parameter_references(body, parameter_references),
      renames: renames(signature),
      locals: locals(body, source),
      contexts: contexts(body),
      renders?: renders?(body),
      jsx: jsx(body, source)
    }
  rescue
    error -> {:unreadable, name, Exception.message(error)}
  end

  defp parameter_references(body, references) do
    for %{"name" => name, "start" => start, "end" => finish} <- references,
        start >= body["start"],
        finish <= body["end"],
        uniq: true,
        do: name
  end

  # A local type alias is the only annotation this reader can resolve. Imported
  # Base UI types describe primitive behavior, which the Base UI documentation
  # already supplies. Local aliases describe the wrapper's own public props.
  defp type_definitions(program) do
    for declaration <- program["body"],
        declaration <- [Map.get(declaration, "declaration", declaration)],
        %{"type" => type, "id" => %{"name" => name}, "typeAnnotation" => annotation} <- [
          declaration
        ],
        type in ~w(TSTypeAliasDeclaration TSInterfaceDeclaration),
        into: %{},
        do: {name, annotation}
  end

  @doc """
  What a render bound under a name, by the source of what it bound.

  `const Icon = isCopied ? CheckIcon : CopyIcon` and then `<Icon />`. The name
  is local to the render and means nothing outside it, so what the markup
  refers to is the value, and the value is what comes back here.

  `props/3` records the same names as props, because a name the markup reads is
  a name the caller has to supply when nothing here can work it out. These two
  are the same list read for different reasons: one asks what a component takes
  and the other asks what a name meant.
  """
  def locals(body, source) do
    for %{"type" => "VariableDeclaration", "declarations" => declarations} <- statements(body),
        %{"id" => %{"type" => "Identifier", "name" => name}, "init" => init} <- declarations,
        is_map(init),
        into: %{},
        do: {name, slice(bare(init), source)}
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

  A handler is none of the three. `onSubmit` and the `handleSubmit` it is
  wired to are React's way of running a closure when the browser fires an
  event; HEEx runs a `phx-` binding instead, which the caller passes through
  `@rest`. Asking a caller for `on_submit` would ask for a function the
  template cannot call.
  """
  def props(signature, body, source) do
    contexts = contexts(body)

    written =
      body
      |> statements()
      |> Enum.flat_map(&bound(&1, source))
      |> Map.new()
      |> Map.merge(destructured(signature, source))
      |> Map.drop(MapSet.to_list(contexts))

    body
    |> context_fields(contexts)
    |> Map.new(&{&1, nil})
    |> Map.merge(written)
    |> Map.reject(fn {name, _default} -> event_prop?(name) end)
  end

  # `onClick`, `onValueChange`, `onOpenChangeComplete`: React names a callback
  # prop after the event that runs it.
  defp event_prop?(name), do: name =~ ~r/^on[A-Z]/

  @doc """
  The names a render bound to a whole React context.

  `const question = useQuestion()` and then `question.disabled`. The binding is
  React's way of reaching what an ancestor put in the tree; a HEEx component
  has no ancestor to ask, so the caller passes the field. That makes the field
  the prop and the binding nothing at all — `question` names a value that this
  component can never be given.
  """
  def contexts(body) do
    for %{"type" => "VariableDeclaration", "declarations" => declarations} <- statements(body),
        %{"id" => %{"type" => "Identifier", "name" => name}, "init" => init} <- declarations,
        context_read?(bare(init)),
        into: MapSet.new(),
        do: name
  end

  defp context_read?(%{
         "type" => "CallExpression",
         "callee" => %{"name" => callee},
         "arguments" => []
       }),
       do: callee =~ ~r/^use[A-Z]/

  defp context_read?(_init), do: false

  # A method on a context is not a field of it. `question.toggleValue(value)`
  # runs on a click, and the argument it runs with is still a value.
  defp context_fields(
         %{"type" => "CallExpression", "callee" => %{"type" => "MemberExpression"} = callee} =
           call,
         contexts
       ),
       do:
         context_fields(callee["object"], contexts) ++ context_fields(call["arguments"], contexts)

  defp context_fields(
         %{
           "type" => "MemberExpression",
           "object" => %{"type" => "Identifier", "name" => name},
           "property" => %{"type" => "Identifier", "name" => field}
         },
         contexts
       ) do
    if MapSet.member?(contexts, name), do: [field], else: []
  end

  defp context_fields(node, contexts) when is_map(node),
    do: node |> Map.values() |> Enum.flat_map(&context_fields(&1, contexts))

  defp context_fields(nodes, contexts) when is_list(nodes),
    do: Enum.flat_map(nodes, &context_fields(&1, contexts))

  defp context_fields(_node, _contexts), do: []

  defp statements(%{"type" => "BlockStatement", "body" => body}), do: body
  defp statements(_body), do: []

  # `const [isOpen, setIsOpen] = useState(false)` and
  # `const { isOpen } = useChainOfThought()` are both React holding something,
  # and `const derivedName = …` is React computing something. All three are a
  # name the markup reads and the caller has to supply.
  #
  # A setter is not one. Nothing renders `setIsOpen`.
  #
  # Neither is a function. `const handleSubmit = useCallback(async (event) => …)`
  # binds a name to code that runs on an event, and a template renders values.
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
          if handler?(declaration["init"]), do: [], else: [{name, nil}]

        _other ->
          []
      end
    end)
  end

  defp bound(_statement, _source), do: []

  # A function that returns markup is not a handler, it is a piece of the
  # render written down under a name. `attachments` calls its `renderContent()`
  # from inside the JSX, and what comes back is an element.
  defp handler?(%{"type" => type} = node)
       when type in ~w(ArrowFunctionExpression FunctionExpression),
       do: not markup?(node)

  # `useCallback(fn, deps)` hands back the function it was given, so the
  # question is asked again of that argument. `useMemo` is not the same thing:
  # it hands back what the function *returned*, which is a value.
  defp handler?(%{
         "type" => "CallExpression",
         "callee" => %{"name" => "useCallback"},
         "arguments" => [first | _rest]
       }),
       do: handler?(bare(first))

  defp handler?(_init), do: false

  defp markup?(%{"type" => type}) when type in ~w(JSXElement JSXFragment), do: true
  defp markup?(node) when is_map(node), do: node |> Map.values() |> Enum.any?(&markup?/1)
  defp markup?(nodes) when is_list(nodes), do: Enum.any?(nodes, &markup?/1)
  defp markup?(_node), do: false

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

  # The wrapper's local TypeScript annotation can describe a caller-facing
  # value more exactly than its default can. Keep only the small, portable
  # subset that Phoenix.Component can declare: booleans, integers, and a
  # finite set of string values.
  defp prop_types(%{"typeAnnotation" => %{"typeAnnotation" => annotation}}, definitions),
    do: fields(annotation, definitions)

  defp prop_types(_signature, _definitions), do: %{}

  defp fields(%{"type" => "TSTypeLiteral", "members" => members}, definitions) do
    for %{
          "type" => "TSPropertySignature",
          "key" => %{"name" => name},
          "typeAnnotation" => %{"typeAnnotation" => annotation}
        } = member <- members,
        type = attribute_type(annotation, definitions),
        not is_nil(type),
        into: %{},
        do: {name, Map.put(type, "optional", member["optional"] == true)}
  end

  defp fields(%{"type" => "TSInterfaceBody", "body" => members}, definitions),
    do: fields(%{"type" => "TSTypeLiteral", "members" => members}, definitions)

  defp fields(%{"type" => "TSIntersectionType", "types" => types}, definitions),
    do: Enum.reduce(types, %{}, &Map.merge(&2, fields(&1, definitions)))

  defp fields(%{"type" => "TSTypeReference", "typeName" => %{"name" => name}}, definitions),
    do: definitions |> Map.get(name) |> fields(definitions)

  defp fields(_annotation, _definitions), do: %{}

  defp attribute_type(%{"type" => "TSBooleanKeyword"}, _definitions), do: %{"type" => "boolean"}
  defp attribute_type(%{"type" => "TSNumberKeyword"}, _definitions), do: %{"type" => "integer"}

  defp attribute_type(%{"type" => "TSUnionType", "types" => types}, _definitions) do
    values =
      for %{"type" => "TSLiteralType", "literal" => %{"value" => value}} <- types,
          is_binary(value),
          do: value

    if length(values) == length(types) and values != [], do: %{"values" => values}, else: nil
  end

  defp attribute_type(_annotation, _definitions), do: nil

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

  # Whether this function is a component at all.
  #
  # `question` writes `getSelectedValues` next to its components: same file,
  # same `const name = (…) => …`, and it returns an array of strings. Reading
  # its `return` as markup asks what element `[...currentValues, optionValue]`
  # is, which is a question about a helper nobody renders.
  #
  # Base UI's `useRender` is the exception that has to be named: it renders,
  # and it writes no JSX to say so.
  defp renders?(body), do: markup?(body) or uses_render?(body)

  defp uses_render?(%{"type" => "CallExpression", "callee" => %{"name" => "useRender"}}), do: true

  defp uses_render?(node) when is_map(node),
    do: node |> Map.values() |> Enum.any?(&uses_render?/1)

  defp uses_render?(nodes) when is_list(nodes), do: Enum.any?(nodes, &uses_render?/1)
  defp uses_render?(_node), do: false

  @doc """
  The element a `useRender` call describes, or `nil` when the source is
  something else.

  Usually a component *returns* one and `jsx/2` reads it there. shadcn binds one
  to a name when it has to decide afterwards what to put around it: `sidebar`'s
  menu button is a button, and a button inside a tooltip when it was given one.
  So the name is rendered rather than the call, and the name has to lead back
  here — or the generated component asks its caller for `comp`, which is the
  component's own body.
  """
  def rendered(code) do
    wrapped = "const __x = (\n#{code}\n)"

    case cached_tree(wrapped) do
      %{"body" => [%{"declarations" => [%{"init" => init}]}]} ->
        case bare(init) do
          %{"callee" => %{"name" => "useRender"}} = call -> returned(call, wrapped)
          _other -> nil
        end

      _ ->
        nil
    end
  rescue
    _error -> nil
  end

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
  defp returned(node, source), do: %{type: :expr, code: slice(node, source), node: node}

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
      value -> {:attr, "className", {:expr, slice(value, source), value}}
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
      _ -> %{type: :expr, code: slice(expression, source), node: expression}
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
    do: {:expr, slice(expression, source), expression}

  defp attribute_value(%{"type" => type} = node, source) when type in ~w(JSXElement JSXFragment),
    do: {:expr, slice(node, source), node}

  defp attribute_value(_value, _source), do: true

  # ── source ────────────────────────────────────────────────────────────────

  # The exact bytes a node came from. This is the whole reason for a real
  # parser: an expression's source is a fact the tree carries, and every attempt
  # to work it out by counting brackets was a place to be wrong.
  defp slice(%{"start" => start, "end" => finish}, source) when is_binary(source),
    do: binary_part(source, start, finish - start)

  defp slice(node, {code, parent}), do: source({:expr, code, parent}, node)

  defp slice(_node, _source), do: ""
end
