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
  """

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
