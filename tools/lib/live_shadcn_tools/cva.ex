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

  @doc """
  Parses a `cva(...)` call.

  Returns `%{"base" => classes, "variants" => %{name => %{value => classes}},
  "defaults" => %{name => value}}`, or `:error` when the code is not a `cva`
  call at all.
  """
  def parse({:expr, _code, _node} = expression) do
    case Ast.call_args(expression, "cva") |> Enum.map(&Ast.expression(expression, &1)) do
      [] -> :error
      arguments -> {:ok, build_nodes(arguments)}
    end
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
end
