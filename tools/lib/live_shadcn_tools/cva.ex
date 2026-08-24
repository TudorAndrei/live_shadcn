defmodule LiveShadcnTools.Cva do
  @moduledoc """
  Reads a `class-variance-authority` call.

  shadcn writes a component's variants as data, which is what makes them
  portable:

      const buttonVariants = cva("cn-button inline-flex …", {
        variants: {
          variant: { default: "cn-button-variant-default", … },
          size: { default: "cn-button-size-default", … },
        },
        defaultVariants: { variant: "default", size: "default" },
      })

  Every one of those is a decision — which variants exist, what each is called,
  which is the default, and what class string each carries. A HEEx component
  needs the same four facts to declare its attributes, so the spec records them
  rather than a person retyping them into an `attr :variant, :string`.
  """

  alias LiveShadcnTools.Ast
  alias LiveShadcnTools.Tsx

  @doc """
  Parses a `cva(...)` call.

  Returns `%{"base" => classes, "variants" => %{name => %{value => classes}},
  "defaults" => %{name => value}}`, or `:error` when the code is not a `cva`
  call at all.
  """
  def parse(code) when is_binary(code) do
    code = String.trim(code)

    if String.starts_with?(code, "cva(") do
      {args, _rest} = arguments(code)
      {:ok, build(args)}
    else
      :error
    end
  end

  def parse({:expr, _code, _node} = expression) do
    case Ast.call_args(expression, "cva") |> Enum.map(&Ast.expression(expression, &1)) do
      [] -> :error
      arguments -> {:ok, build_nodes(arguments)}
    end
  end

  defp arguments(code) do
    inner = String.slice(code, byte_size("cva(")..-1//1)
    depth = count(inner, ["(", "[", "{"]) - count(inner, [")", "]", "}"])
    # The trailing `)` of the call itself is the one bracket left unclosed.
    inner = if depth < 0, do: String.slice(inner, 0..-2//1), else: inner

    {Tsx.split_args(inner), ""}
  end

  defp count(string, chars),
    do: string |> String.graphemes() |> Enum.count(&(&1 in chars))

  defp build(args) do
    base = args |> Enum.at(0, "") |> literal()
    options = args |> Enum.at(1) |> options()

    %{
      "base" => base,
      "variants" => variants(options["variants"]),
      "defaults" => defaults(options["defaultVariants"])
    }
  end

  defp build_nodes(args) do
    base = args |> Enum.at(0) |> Ast.string_literal() || ""

    options =
      args
      |> Enum.at(1)
      |> Ast.object_entries()
      |> Map.new(fn {name, value} -> {name, value_of(value)} end)

    %{
      "base" => base |> String.split() |> Enum.join(" "),
      "variants" => variants(Map.get(options, "variants")),
      "defaults" => defaults(Map.get(options, "defaultVariants"))
    }
  end

  defp options(nil), do: %{}

  defp options(code) do
    if String.starts_with?(String.trim(code), "{"), do: Tsx.object!(code), else: %{}
  end

  defp value_of(node) do
    cond do
      literal = Ast.string_literal(node) ->
        {:string, literal |> String.split() |> Enum.join(" ")}

      true ->
        {:object,
         node |> Ast.object_entries() |> Map.new(fn {name, value} -> {name, value_of(value)} end)}
    end
  end

  defp variants({:object, groups}) do
    Map.new(groups, fn {name, value} ->
      {name, Map.new(values(value), fn {key, classes} -> {key, classes} end)}
    end)
  end

  defp variants(_other), do: %{}

  defp values({:object, entries}) do
    for {key, {:string, classes}} <- entries, do: {key, classes}
  end

  defp values(_other), do: []

  defp defaults({:object, entries}) do
    for {name, {:string, value}} <- entries, into: %{}, do: {name, value}
  end

  defp defaults(_other), do: %{}

  defp literal(<<q, _::binary>> = arg) when q in [?", ?'],
    do: arg |> String.slice(1..-2//1) |> String.split() |> Enum.join(" ")

  defp literal(_other), do: ""
end
