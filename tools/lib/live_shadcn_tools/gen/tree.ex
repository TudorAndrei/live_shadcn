defmodule LiveShadcnTools.Gen.Tree do
  @moduledoc false

  alias LiveShadcnTools.Gen.Heex

  @doc "Adds recipe-owned attributes to every node with the given slot."
  def put_attrs_at_slot(spec, slot, attrs) do
    Map.update!(spec, "parts", fn parts ->
      Enum.map(parts, fn part -> Map.update!(part, "tree", &put_attrs(&1, slot, attrs)) end)
    end)
  end

  defp put_attrs(%{"slot" => slot} = node, slot, attrs), do: Heex.with_attrs(node, attrs)

  defp put_attrs(node, slot, attrs) when is_map(node) do
    Map.update(node, "children", [], fn children ->
      Enum.map(children, &put_attrs(&1, slot, attrs))
    end)
  end

  defp put_attrs(node, _slot, _attrs), do: node
end
