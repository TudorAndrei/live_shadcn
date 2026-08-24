defmodule LiveShadcnTools.Gen.Tree do
  @moduledoc false

  alias LiveShadcnTools.Gen.Heex

  @doc "Adds recipe-owned attributes to every node with the given slot."
  def put_attrs_at_slot(spec, slot, attrs) do
    Map.update!(spec, "parts", fn parts ->
      Enum.map(parts, fn part -> Map.update!(part, "tree", &put_attrs(&1, slot, attrs)) end)
    end)
  end

  @doc "Renames an upstream attribute on every node with the given slot."
  def rename_attr_at_slot(spec, slot, from, to) do
    Map.update!(spec, "parts", fn parts ->
      Enum.map(parts, fn part -> Map.update!(part, "tree", &rename_attr(&1, slot, from, to)) end)
    end)
  end

  @doc "Removes an upstream attribute from every node with the given slot."
  def drop_attr_at_slot(spec, slot, name) do
    Map.update!(spec, "parts", fn parts ->
      Enum.map(parts, fn part -> Map.update!(part, "tree", &drop_attr(&1, slot, name)) end)
    end)
  end

  defp put_attrs(%{"slot" => slot} = node, slot, attrs), do: Heex.with_attrs(node, attrs)

  defp put_attrs(node, slot, attrs) when is_map(node) do
    Map.update(node, "children", [], fn children ->
      Enum.map(children, &put_attrs(&1, slot, attrs))
    end)
  end

  defp put_attrs(node, _slot, _attrs), do: node

  defp rename_attr(%{"slot" => slot} = node, slot, from, to) do
    Map.update(node, "attrs", [], fn attrs ->
      Enum.map(attrs, fn attr ->
        if attr["name"] == from, do: Map.put(attr, "name", to), else: attr
      end)
    end)
  end

  defp rename_attr(node, slot, from, to) when is_map(node) do
    Map.update(node, "children", [], fn children ->
      Enum.map(children, &rename_attr(&1, slot, from, to))
    end)
  end

  defp rename_attr(node, _slot, _from, _to), do: node

  defp drop_attr(%{"slot" => slot} = node, slot, name) do
    Map.update(node, "attrs", [], &Enum.reject(&1, fn attr -> attr["name"] == name end))
  end

  defp drop_attr(node, slot, name) when is_map(node) do
    Map.update(node, "children", [], fn children ->
      Enum.map(children, &drop_attr(&1, slot, name))
    end)
  end

  defp drop_attr(node, _slot, _name), do: node
end
