defmodule LiveShadcnTools.Tsx do
  @moduledoc """
  The small JavaScript facts the spec reads out of values.

  `LiveShadcnTools.Ast` reads the file: what it declares, what it exports, what
  each component renders. This module reads what is *inside* the pieces that
  reader hands over — a class string, a `cva` call, an object literal — because
  those arrive as source and mean something specific to this pipeline rather
  than to JavaScript.

  It used to read the file too, with regular expressions, and that is what
  `Ast` replaced. What is left needs no parser: an object literal is a
  comma-separated list at one nesting level, and a class string is the string
  literals inside it. Those are shallow questions, and the answers are exact.

  Where a question stops being shallow — where an argument stops, when it holds
  a ternary — it asks `Ast`, which asks the parser.
  """

  alias LiveShadcnTools.Ast

  @doc """
  The literal class names in a `className` value.

  `cn("a b", className)` and `"a b"` both yield `"a b"`. An argument that is not
  a string literal is not an unconditional class name; the ones that hold class
  names under a condition come back from `conditional_classes/1` instead.
  """
  def classes({:string, literal}), do: normalise(literal)

  def classes({:expr, code}) do
    code
    |> call_args("cn")
    |> Enum.flat_map(&literal/1)
    |> Enum.join(" ")
    |> normalise()
  end

  def classes({:expr, _code, node}) do
    case Ast.string_literal(node) do
      nil ->
        node
        |> Ast.call_args("cn")
        |> Enum.flat_map(&literal_node/1)
        |> Enum.join(" ")
        |> normalise()

      literal ->
        normalise(literal)
    end
  end

  def classes(_), do: ""

  @doc """
  The class names a `className` value applies only under a condition.

  `cn("group", from === "user" ? "is-user" : "is-assistant")` says a message
  from a person looks different from a message from a model, and that is the
  whole of what `message` is for. Reading only the literals dropped the
  difference and left a component that draws both the same way.

  `cond && "a"` says the same thing with nothing on the other side.
  """
  def conditional_classes({:expr, code}) do
    code
    |> call_args("cn")
    |> Enum.flat_map(&condition/1)
  end

  def conditional_classes({:expr, _code, _node} = expression) do
    expression
    |> Ast.call_args("cn")
    |> Enum.map(&Ast.expression(expression, &1))
    |> Enum.flat_map(&condition/1)
  end

  def conditional_classes(_value), do: []

  defp condition(arg) when is_binary(arg) do
    arg = String.trim(arg)

    cond do
      literal(arg) != [] ->
        []

      parts = Ast.conditional(arg) ->
        {when_, yes, no} = parts
        segment(when_, class_of(yes), class_of(no))

      match?({"&&", _, _}, Ast.logical(arg)) ->
        {"&&", left, right} = Ast.logical(arg)
        segment(left, class_of(right), nil)

      true ->
        []
    end
  end

  defp condition({:expr, _code, _node} = expression) do
    cond do
      Ast.string_literal(expression) ->
        []

      parts = Ast.conditional(expression) ->
        {when_, yes, no} = parts
        segment(when_, class_of(yes), class_of(no))

      match?({"&&", _, _}, Ast.logical(expression)) ->
        {"&&", left, right} = Ast.logical(expression)
        segment(left, class_of(right), nil)

      true ->
        []
    end
  end

  defp segment(_when, nil, nil), do: []

  # The condition is kept as source, and what it *reads* is kept beside it.
  #
  # A segment used to record `!showValues` as text and nothing else, so nothing
  # downstream could tell that this element reads `showValues` — and the prop
  # the reader had made for it was filtered straight back out as unused. Every
  # other place an expression reaches the spec records its identifiers; this one
  # did not, and the component stopped generating.
  defp segment(when_, yes, no) do
    segment = %{"when" => when_ |> source_of() |> String.trim(), "then" => yes, "else" => no}

    case identifiers_of(when_) do
      [] -> [segment]
      names -> [Map.put(segment, "identifiers", names)]
    end
  end

  defp source_of({:expr, code, _node}), do: code
  defp source_of(code) when is_binary(code), do: code

  defp identifiers_of({:expr, _code, node}), do: Ast.identifiers(node)
  defp identifiers_of(_code), do: []

  defp class_of(code) when is_binary(code) do
    case literal(String.trim(code)) do
      [literal] -> normalise(literal)
      [] -> nil
    end
  end

  defp class_of({:expr, _code, _node} = expression) do
    case Ast.string_literal(expression) do
      nil -> nil
      literal -> normalise(literal)
    end
  end

  @doc """
  Whether this element is the one that merges the caller's class.

  shadcn threads a `className` prop down to exactly one element per component,
  by naming it where that element's class string is built. The generator has to
  put the caller's class on the same element, so the spec records which one it
  is. It reaches there two ways — `cn("…", className)` directly, or
  `cn(buttonVariants({ variant, className }))` — and both count.
  """
  def merges_class?({:expr, code}), do: Regex.match?(~r/\bclassName\b/, code)
  def merges_class?({:expr, _code, node}), do: identifier?(node, "className")
  def merges_class?(_), do: false

  defp identifier?(%{"type" => "Identifier", "name" => name}, name), do: true

  defp identifier?(node, name) when is_map(node),
    do: node |> Map.values() |> Enum.any?(&identifier?(&1, name))

  defp identifier?(nodes, name) when is_list(nodes), do: Enum.any?(nodes, &identifier?(&1, name))
  defp identifier?(_node, _name), do: false

  @doc """
  The `cva` tables a class value is built from, and the props each was passed.

  `cn(buttonVariants({ variant, size, className }))` means this element's class
  string is not fixed: it depends on props. `bindings` is the set of names known
  to hold a `cva` call, so a call to something else is not mistaken for one.

  There can be more than one. `input-group`'s button renders shadcn's `<Button>`
  with `inputGroupButtonVariants({ size })`, and the fold puts both tables on
  one element: two bases, and a `size` group in each reading a different value.
  """
  def variant_calls({:expr, code}, bindings) do
    for {name, args} <- Ast.calls(code, bindings), do: %{"table" => name, "args" => args}
  end

  def variant_calls({:expr, _code, node}, bindings) do
    for {name, args} <- Ast.calls(node, bindings), do: %{"table" => name, "args" => args}
  end

  def variant_calls(_value, _bindings), do: []

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

  defp literal_node(node) do
    case Ast.string_literal(node) do
      nil -> []
      literal -> [literal]
    end
  end

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

  # The text between one bracket and its partner, and what follows it. A quote
  # counts as its own kind of bracket, because a bracket inside one is text.
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
end
