defmodule LiveShadcnTools.ShadcnExamples do
  @moduledoc """
  Reads the examples that the pinned shadcn component documentation publishes.

  The documentation is the source of truth for example coverage. A local
  example counts only when Storybook has its HEEx preview. The parity app loads
  the matching official React source directly from the pinned checkout.
  """

  @preview ~r/<ComponentPreview\b[^>]*\bname="([^"]+)"[^>]*>/s
  @source_owners %{
    "card-rtl" => "card"
  }

  @doc "Reads the unique `ComponentPreview` entries from one component page."
  def parse(component, markdown) when is_binary(component) and is_binary(markdown) do
    @preview
    |> Regex.scan(markdown, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
    |> then(&from_sources(component, &1))
  end

  @doc "Returns the component pages a fetch must read."
  def doc_pages(_registry_pages, _docs_pages, only) when is_binary(only), do: [only]

  def doc_pages(registry_pages, docs_pages, nil)
      when is_list(registry_pages) and is_list(docs_pages) do
    Enum.uniq(registry_pages ++ docs_pages)
  end

  @doc "Builds coverage entries from source names stored in the manifest."
  def from_sources(component, sources) when is_binary(component) and is_list(sources) do
    sources
    |> Enum.map(&source_entry(component, &1))
    |> Enum.filter(&belongs_to_component?(component, &1["source"]))
    |> Enum.map_reduce(MapSet.new(), fn entry, used ->
      source = entry["source"]
      id = unique_id(entry["id"] || example_id(component, source), source, used)
      {%{"id" => id, "source" => source}, MapSet.put(used, id)}
    end)
    |> elem(0)
  end

  @doc "Checks official examples against local HEEx previews."
  def coverage([], _local_examples) do
    %{"pass" => false, "detail" => "official documentation has no examples"}
  end

  def coverage(expected, local_examples) when is_list(expected) and is_list(local_examples) do
    local = MapSet.new(local_examples)

    missing_heex =
      Enum.reject(expected, &MapSet.member?(local, &1["id"]))

    problems = [problem("missing HEEx", missing_heex, &label/1)] |> Enum.reject(&is_nil/1)

    if problems == [] do
      count = length(expected)

      %{
        "pass" => true,
        "detail" => "#{count} of #{count} official examples have HEEx previews"
      }
    else
      %{"pass" => false, "detail" => Enum.join(problems, "\n")}
    end
  end

  # The Chart page reserves `default` for its local chart overview.
  defp example_id("chart", "chart-demo"), do: "demo"

  defp example_id(component, source) do
    cond do
      source == component <> "-demo" ->
        "default"

      String.starts_with?(source, component <> "-") ->
        String.replace_prefix(source, component <> "-", "")

      true ->
        source
    end
  end

  # Most entries name a ComponentPreview source. A small number of pinned
  # registry examples have no documentation page and contain more than one
  # public fixture. They carry their own stable id and full source path in the
  # manifest. Keep this shape here so the coverage gate treats both kinds of
  # official evidence in the same way.
  defp source_entry(_component, %{"id" => id, "source" => source})
       when is_binary(id) and is_binary(source),
       do: %{"id" => id, "source" => source}

  defp source_entry(_component, source) when is_binary(source), do: %{"source" => source}

  # `direction.mdx` embeds the Card RTL fixture to demonstrate a provider.
  # The fixture renders Card, and the Card page owns its parity requirement.
  # Most related examples remain under the page that documents them.
  defp belongs_to_component?(component, source) do
    case Map.get(@source_owners, source) do
      nil -> true
      owner -> owner == component
    end
  end

  defp unique_id(candidate, source, used) do
    [candidate, source]
    |> Stream.concat(Stream.iterate(2, &(&1 + 1)) |> Stream.map(&(source <> "-#{&1}")))
    |> Enum.find(&(not MapSet.member?(used, &1)))
  end

  defp problem(_heading, [], _format), do: nil

  defp problem(heading, examples, format) do
    heading <> ": " <> Enum.map_join(examples, ", ", format)
  end

  defp label(example), do: "#{example["id"]} (#{example["source"]})"
end
