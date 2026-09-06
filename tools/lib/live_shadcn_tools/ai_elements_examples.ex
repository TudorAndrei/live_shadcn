defmodule LiveShadcnTools.AiElementsExamples do
  @moduledoc """
  Discovers the public AI Elements examples stored in the pinned manifest.

  AI Elements publishes its examples as ordinary `.tsx` files. The pinned
  source imports its owned component from `@repo/elements/<name>`. Discovery
  uses that import, after it finds filename candidates. A filename collision
  must therefore be resolved by source, or it is reported as an error.
  """

  @doc "Builds the official example entries for one AI Elements component."
  def from_manifest(manifest, component) when is_map(manifest) and is_binary(component) do
    manifest
    |> all()
    |> Map.get(component, [])
  end

  @doc "Builds the official example entries for every AI Elements component."
  def all(manifest), do: manifest |> discovery() |> Map.fetch!(:entries)

  @doc "Builds entries with a supplied pinned-source reader."
  def all(manifest, source_reader) when is_function(source_reader, 1),
    do: manifest |> discovery(source_reader) |> Map.fetch!(:entries)

  @doc "Reports examples that filename and pinned source cannot classify safely."
  def problems(manifest), do: manifest |> discovery() |> Map.fetch!(:problems)

  @doc "Returns entries and guarded discovery errors for a manifest."
  def discovery(manifest, source_reader \\ &read_pinned_source/1)

  def discovery(%{"files" => files}, source_reader)
      when is_map(files) and is_function(source_reader, 1) do
    components =
      files
      |> Map.keys()
      |> Enum.flat_map(&component_name/1)
      |> Enum.sort()

    files
    |> Map.keys()
    |> Enum.flat_map(&example_name/1)
    |> Enum.sort()
    |> Enum.reduce(%{entries: %{}, problems: []}, fn source, discovered ->
      candidates = filename_candidates(source, components)
      imports = source |> source_reader.() |> imports()
      owned = Enum.filter(candidates, &(&1 in imports))

      case owned do
        [] when candidates == [] ->
          discovered

        [] ->
          add_problem(
            discovered,
            source,
            "filename candidates #{Enum.join(candidates, ", ")} are not imported"
          )

        [component] ->
          entry = %{"id" => example_id(component, source), "source" => source}

          update_in(
            discovered,
            [:entries],
            &Map.update(&1, component, [entry], fn entries -> entries ++ [entry] end)
          )

        components ->
          add_problem(
            discovered,
            source,
            "imports more than one filename candidate: #{Enum.join(components, ", ")}"
          )
      end
    end)
  end

  def discovery(_manifest, _source_reader), do: %{entries: %{}, problems: []}

  @doc "Checks each discovered official example against local HEEx previews."
  def coverage(expected, local_examples, local_only_examples \\ [])

  def coverage([], local_examples, local_only_examples) do
    coverage_result([], local_examples, local_only_examples, false)
  end

  def coverage(expected, local_examples, local_only_examples)
      when is_list(expected) and is_list(local_examples) and is_list(local_only_examples) do
    coverage_result(expected, local_examples, local_only_examples, true)
  end

  defp coverage_result(expected, local_examples, local_only_examples, official_comparison?) do
    local = MapSet.new(local_examples)
    official = MapSet.new(expected, & &1["id"])
    local_only = MapSet.new(local_only_examples)
    missing_heex = Enum.reject(expected, &MapSet.member?(local, &1["id"]))

    extra_local =
      local |> MapSet.difference(official) |> MapSet.difference(local_only) |> MapSet.to_list()

    stale_local_only = local_only |> MapSet.difference(local) |> MapSet.to_list()
    official_local_only = local_only |> MapSet.intersection(official) |> MapSet.to_list()

    problems =
      [
        problem("missing HEEx", missing_heex, &label/1),
        problem("extra local HEEx", extra_local, & &1),
        problem("stale local-only HEEx", stale_local_only, & &1),
        problem("official examples marked local-only", official_local_only, & &1)
      ]
      |> Enum.reject(&is_nil/1)

    cond do
      problems != [] ->
        %{
          "pass" => false,
          "official_comparison" => official_comparison?,
          "detail" => Enum.join(problems, "\n")
        }

      official_comparison? ->
        count = length(expected)

        %{
          "pass" => true,
          "official_comparison" => true,
          "detail" => "#{count} of #{count} official examples have HEEx previews"
        }

      local_examples == [] ->
        %{
          "pass" => false,
          "official_comparison" => false,
          "detail" =>
            "AI Elements publishes no official example and this component has no local-only HEEx preview"
        }

      true ->
        count = length(local_examples)

        %{
          "pass" => true,
          "official_comparison" => false,
          "detail" =>
            "not applicable: #{count} local-only HEEx preview#{if count == 1, do: "", else: "s"}; no official comparison"
        }
    end
  end

  defp component_name("ai_elements/" <> file) do
    if Path.extname(file) == ".tsx", do: [Path.basename(file, ".tsx")], else: []
  end

  defp component_name(_path), do: []

  defp example_name("ai_examples/" <> file) do
    if Path.extname(file) == ".tsx", do: [Path.basename(file, ".tsx")], else: []
  end

  defp example_name(_path), do: []

  defp filename_candidates(source, components),
    do: Enum.filter(components, &(source == &1 or String.starts_with?(source, &1 <> "-")))

  defp example_id(component, source) do
    if source == component,
      do: "default",
      else: String.replace_prefix(source, component <> "-", "")
  end

  defp imports(nil), do: []

  defp imports(source) do
    ~r/@repo\/elements\/([a-z0-9-]+)/
    |> Regex.scan(source, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
  end

  defp add_problem(discovered, source, detail),
    do: update_in(discovered, [:problems], &(&1 ++ ["#{source}: #{detail}"]))

  defp problem(_heading, [], _format), do: nil

  defp problem(heading, entries, format),
    do: heading <> ": " <> Enum.map_join(entries, ", ", format)

  defp read_pinned_source(source) do
    Path.join([repo_root(), "registry", "upstream", "ai_examples", source <> ".tsx"])
    |> File.read!()
  end

  defp repo_root, do: Path.expand("../../..", __DIR__)

  defp label(example), do: "#{example["id"]} (#{example["source"]})"
end
