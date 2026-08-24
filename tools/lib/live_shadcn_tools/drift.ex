defmodule LiveShadcnTools.Drift do
  @moduledoc """
  What moved upstream, in words rather than file statistics.

  The weekly sync opens a pull request. `git diff --stat` would tell a reviewer
  that four files changed and 807 lines moved, which is true and useless. What
  they need to know is whether a class string moved, an attribute appeared, or a
  component gained a part — because the first is routine and the last is not.

  So the comparison reads the specs, which is where the facts are. A spec is the
  only thing the generator reads, so a spec that did not change cannot have
  changed a component. That is what makes the summary trustworthy rather than a
  guess at a diff.
  """

  @doc """
  The four kinds of change a spec can carry, between two versions of one.

  Returns a list of `{:added | :removed, kind, names}`, ordered by how much a
  reviewer should care: an attribute that appeared may need a recipe to learn
  it, while a class string that moved needs nothing at all.
  """
  def between(previous, current) do
    [
      {"attribute", &attributes/1},
      {"part", &slots/1},
      {"variant", &variants/1},
      {"class string", &classes/1}
    ]
    |> Enum.flat_map(fn {kind, fun} -> compare(fun.(previous), fun.(current), kind) end)
  end

  defp compare(before, now, kind) do
    added = MapSet.difference(now, before)
    removed = MapSet.difference(before, now)

    [
      if(MapSet.size(added) > 0, do: {:added, kind, Enum.sort(added)}),
      if(MapSet.size(removed) > 0, do: {:removed, kind, Enum.sort(removed)})
    ]
    |> Enum.reject(&is_nil/1)
  end

  @doc "Every data or ARIA attribute the component's class strings read."
  def attributes(spec),
    do:
      walk(spec, fn node ->
        node
        |> get_in(["reads", "self"])
        |> List.wrap()
        |> Enum.map(&LiveShadcnTools.Spec.read_name/1)
      end)

  @doc "Every class string the component renders."
  def classes(spec), do: walk(spec, &List.wrap(&1["class"]))

  @doc "Every `data-slot` the component renders, which is its anatomy."
  def slots(spec), do: walk(spec, &List.wrap(&1["slot"]))

  @doc "Every variant the component accepts, as `group=value`."
  def variants(spec) do
    for {_binding, table} <- spec["variants"] || %{},
        {group, values} <- table["variants"] || %{},
        value <- Map.keys(values),
        into: MapSet.new(),
        do: "#{group}=#{value}"
  end

  defp walk(spec, fun) do
    spec["parts"]
    |> List.wrap()
    |> Enum.flat_map(&nodes(&1["tree"]))
    |> Enum.flat_map(fun)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> MapSet.new()
  end

  defp nodes(nil), do: []
  defp nodes(node), do: [node | Enum.flat_map(Map.get(node, "children") || [], &nodes/1)]

  @doc "One line, for a pull request title."
  def title([]), do: "sync shadcn — nothing moved"

  def title(drift) do
    counted =
      drift
      |> Enum.flat_map(& &1.changes)
      |> Enum.flat_map(fn {_kind, what, names} -> List.duplicate(what, length(names)) end)
      |> Enum.frequencies()
      |> Enum.sort()
      |> Enum.map_join(", ", fn {what, n} -> "#{n} #{plural(what, n)}" end)

    new = Enum.count(drift, & &1.new?)

    parts =
      [counted, new > 0 && "#{new} new #{plural("component", new)}"]
      |> Enum.reject(&(&1 in [nil, "", false]))

    "sync shadcn — " <> Enum.join(parts, ", ")
  end

  @doc "The body of the pull request: what moved, per component."
  def report([]), do: "Nothing moved. Every spec matches the last commit."

  def report(drift) do
    """
    #{title(drift)}

    #{Enum.map_join(drift, "\n", &component/1)}

    Read the snapshot diff first: it is the markup a reader gets. The spec diff
    beside it says which upstream fact produced it.
    """
  end

  defp component(%{name: name, new?: true}), do: "- **#{name}** — new component"

  defp component(%{name: name, changes: changes}) do
    "- **#{name}**\n" <> Enum.map_join(changes, "\n", &change/1)
  end

  defp change({kind, what, names}) do
    listed = names |> Enum.map(&shorten/1) |> Enum.join(", ")
    "  - #{kind} #{plural(what, length(names))}: #{listed}"
  end

  defp plural(what, 1), do: what
  defp plural(what, _n), do: what <> "s"

  # A class string is long enough to bury the change it contains.
  defp shorten(name) when byte_size(name) > 72, do: String.slice(name, 0, 69) <> "…"
  defp shorten(name), do: name
end
