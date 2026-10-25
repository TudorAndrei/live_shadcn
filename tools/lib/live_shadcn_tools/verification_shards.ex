defmodule LiveShadcnTools.VerificationShards do
  @moduledoc "Distributes complete component checks across independent CI runners."

  def plan(targets, previews, count, costs \\ %{})

  def plan(targets, previews, count, costs) when is_integer(count) and count in 1..64 do
    count = min(count, length(targets))
    if count == 0, do: raise(ArgumentError, "no verification targets")

    bins = for index <- 1..count, do: %{index: index, weight: 0, components: []}

    targets
    |> Enum.map(&{&1, weight(&1, previews, costs)})
    |> Enum.sort_by(fn {target, weight} -> {-weight, target} end)
    |> Enum.reduce(bins, fn {{source, name}, weight}, bins ->
      selected = Enum.min_by(bins, &{&1.weight, &1.index})

      Enum.map(bins, fn bin ->
        if bin.index == selected.index,
          do: %{
            bin
            | weight: bin.weight + weight,
              components: [source <> "/" <> name | bin.components]
          },
          else: bin
      end)
    end)
    |> Enum.map(fn bin ->
      %{
        "index" => bin.index,
        "shard" => "#{bin.index}/#{count}",
        "weight" => bin.weight,
        "components" => Enum.sort(bin.components)
      }
    end)
  end

  def plan(_targets, _previews, _count, _costs),
    do: raise(ArgumentError, "shard count must be between 1 and 64")

  def select(targets, previews, shard, costs \\ %{}) do
    with [_, index, total] <- Regex.run(~r/^(\d+)\/(\d+)$/, shard),
         {index, ""} <- Integer.parse(index),
         {total, ""} <- Integer.parse(total),
         true <- total in 1..64 and index in 1..total,
         plans <- plan(targets, previews, total, costs),
         %{"components" => components} <- Enum.find(plans, &(&1["shard"] == shard)) do
      Enum.map(components, fn reference ->
        [source, name] = String.split(reference, "/", parts: 2)
        {source, name}
      end)
    else
      _ ->
        raise ArgumentError,
              "shard must name nonempty work as INDEX/TOTAL, with TOTAL between 1 and 64"
    end
  end

  @doc "Loads reviewed component times, with snapshot estimates for unmeasured components."
  def costs(previews, root) do
    estimates =
      Map.new(previews, fn {key, examples} ->
        cost =
          Enum.reduce(examples, 0, fn example, sum ->
            path = Path.join([root, "registry", "snapshot", "#{key}-#{example}.html"])

            html =
              case File.read(path) do
                {:ok, html} -> html
                {:error, _} -> ""
              end

            controls =
              length(Regex.scan(~r/\saria-(?:expanded|selected|checked|pressed)="/, html))

            sum + 1 + 3 * min(controls, 8)
          end)

        {key, cost}
      end)

    Map.merge(estimates, measured_costs(root))
  end

  defp weight({source, name}, previews, costs) do
    key = preview_key(source, name, previews)
    layers = if source == "shadcn", do: 4, else: 2
    estimate = 1 + Map.get(costs, key, length(Map.get(previews, key, []))) * layers
    Map.get(costs, "#{source}/#{name}", estimate)
  end

  defp preview_key(source, name, previews),
    do: if(Map.has_key?(previews, "#{source}-#{name}"), do: "#{source}-#{name}", else: name)

  defp measured_costs(root) do
    path = Path.join(root, "registry/VERIFICATION_TIMINGS.json")

    case File.read(path) do
      {:error, :enoent} ->
        %{}

      {:error, reason} ->
        raise File.Error, reason: reason, action: "read file", path: path

      {:ok, bytes} ->
        case Jason.decode!(bytes) do
          %{"version" => 1, "milliseconds_per_weight_unit" => unit, "components_ms" => timings}
          when is_integer(unit) and unit > 0 and is_map(timings) ->
            Map.new(timings, &measured_cost(&1, unit))

          _ ->
            raise ArgumentError, "invalid verification timings in #{path}"
        end
    end
  end

  defp measured_cost({reference, milliseconds}, unit)
       when is_binary(reference) and is_integer(milliseconds) and milliseconds > 0 do
    if not Regex.match?(~r/^(shadcn|ai_elements)\/[a-z0-9]+(?:-[a-z0-9]+)*$/, reference),
      do: raise(ArgumentError, "invalid verification timing reference: #{reference}")

    {reference, max(1, round(milliseconds / unit))}
  end

  defp measured_cost(_entry, _unit),
    do: raise(ArgumentError, "verification component times must be positive integer milliseconds")
end
