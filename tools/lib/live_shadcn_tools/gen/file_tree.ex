defmodule LiveShadcnTools.Gen.FileTree do
  @moduledoc """
  The `file-tree` recipe: presentational markup, and the ARIA a tree owes.

  ## Why there is a recipe at all

  Every class string here is upstream's and every element is upstream's, which
  is the presentational recipe's whole job. What upstream does not write is the
  contract the roles it *does* write imply:

    * a `role="treeitem"` has to be owned by a `tree` or a `group`, and
      upstream's are wrapped in plain `<div>`s — a collapsible root, and the
      padding box a tree draws its items in
    * a folder's chevron is a `<button>` with an icon in it and no words, which
      is a control a screen reader announces as nothing

  axe reports both, and it is right to. This is not a difference of opinion with
  upstream about markup: `role="tree"` and `role="treeitem"` are upstream's own,
  and they name a contract that the rest of the markup does not keep.

  ## What the recipe adds, and what it does not

  Two `role="group"`, one `role="none"`, an `aria-expanded`, and a chevron taken
  out of the accessibility tree. Every one of them follows from a role upstream
  wrote; none of them invents a word for a screen reader to read.

  The chevron is hidden rather than named because naming it would mean writing
  English — "Toggle" — and the row's other button already opens the folder. A
  control that duplicates its neighbour is what `aria-hidden` is for.
  """

  alias LiveShadcnTools.Gen.Presentational
  alias LiveShadcnTools.Gen.Tree

  @doc "The module source for one component."
  def module(spec, opts) do
    spec
    |> Map.update!("parts", fn parts -> Enum.map(parts, &owned/1) end)
    |> Tree.put_attrs_at_slot("collapsible", [{"role", :text, "none"}])
    |> Tree.put_attrs_at_slot("collapsible-trigger", [
      {"aria-hidden", :text, "true"},
      {"tabindex", :text, "-1"}
    ])
    |> Presentational.module(opts)
  end

  # A `role="treeitem"` is owned by whatever holds it, and both of the things
  # that hold one here are plain boxes: the padding box the tree draws its items
  # in, and the indented box a folder draws its children in.
  @groups ["p-2", "ml-4 border-l pl-2"]

  defp owned(part), do: Map.update!(part, "tree", &walk/1)

  defp walk(%{"type" => "element"} = node) do
    node
    |> grouped()
    |> expanded()
    |> Map.update("children", [], &walk/1)
  end

  defp walk(node) when is_map(node),
    do: Map.new(node, fn {key, value} -> {key, walk(value)} end)

  defp walk(nodes) when is_list(nodes), do: Enum.map(nodes, &walk/1)
  defp walk(value), do: value

  defp grouped(%{"class" => class} = node) when class in @groups,
    do: with_role(node, "group")

  defp grouped(node), do: node

  # Whether a folder is open is what `aria-expanded` says, and the folder
  # already takes it: upstream puts it on the collapsible and nowhere a reader
  # can hear it.
  defp expanded(node) do
    if role(node) == "treeitem" and reads_expansion?(node),
      do:
        with_attr(node, %{"name" => "aria-expanded", "kind" => "code", "value" => "isExpanded"}),
      else: node
  end

  defp reads_expansion?(node),
    do: node |> LiveShadcnTools.Spec.codes() |> Enum.any?(&String.contains?(&1, "isExpanded"))

  defp role(node) do
    Enum.find_value(Map.get(node, "attrs") || [], fn
      %{"name" => "role", "value" => value} -> value
      _other -> nil
    end)
  end

  defp with_role(node, role),
    do: with_attr(node, %{"name" => "role", "kind" => "text", "value" => role})

  defp with_attr(node, attr),
    do:
      Map.update(
        node,
        "attrs",
        [attr],
        &(Enum.reject(&1, fn a -> a["name"] == attr["name"] end) ++ [attr])
      )
end
