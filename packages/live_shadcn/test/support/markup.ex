defmodule LiveShadcn.Test.Markup do
  @moduledoc """
  Assertions about rendered markup, written against the contract rather than
  against a string.

  A reviewed port is correct when it emits the attributes Base UI
  documents, on the elements shadcn's class strings read them from. These
  helpers are how a test says that, so the test does not have to be rewritten
  every time upstream reorders a class.
  """

  import ExUnit.Assertions

  @doc "The element carrying `data-slot=\"<slot>\"`, or a failure naming the slot."
  def slot(html, slot) do
    case Floki.find(document(html), "[data-slot='#{slot}']") do
      [] -> flunk("no element with data-slot=\"#{slot}\" in:\n\n#{html}")
      [element] -> element
      elements -> elements
    end
  end

  @doc """
  The value of an attribute, `:present` for a valueless one, or `nil`.

  A valueless attribute reaches the parser two ways: HEEx writes `data-open=""`
  for a state flag, and an HTML boolean attribute such as `hidden` parses back
  as its own name. Both mean the same thing to a class string, so both read as
  `:present` here.
  """
  def attribute(element, name) do
    case Floki.attribute(List.wrap(element), name) do
      [] -> nil
      [""] -> :present
      [^name] -> :present
      [value] -> value
      values -> values
    end
  end

  @doc "Every class on an element, as a set, so order never breaks a test."
  def classes(element) do
    element
    |> attribute("class")
    |> to_string()
    |> String.split()
    |> MapSet.new()
  end

  defp document(html) when is_binary(html), do: Floki.parse_fragment!(html)
  defp document(parsed), do: parsed
end
