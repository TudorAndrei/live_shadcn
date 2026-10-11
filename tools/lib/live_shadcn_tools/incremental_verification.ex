defmodule LiveShadcnTools.IncrementalVerification do
  @moduledoc """
  Stores browser evidence from small Playwright batches.

  Evidence belongs to one current verification identity. A changed source,
  snapshot, verifier rule, or pixel budget makes all prior batch evidence
  unavailable. A component passes only when every current example has passed
  every browser layer.
  """

  alias LiveShadcnTools.BrowserVerification

  @layers ~w(interaction behavior accessibility parity pixel)

  @doc "The browser layers required for every current official example."
  def layers(source \\ "shadcn")
  def layers("ai_elements"), do: ~w(behavior accessibility)
  def layers(_source), do: @layers

  @doc "Merges one layer from a completed Playwright batch into current evidence."
  def merge(record, identity, layer, results)
      when is_map(record) and is_map(identity) and is_binary(layer) and is_map(results) do
    validate_layer!(layer, identity)

    examples = examples(identity)

    unknown = Map.keys(results) -- examples

    if unknown != [] do
      raise ArgumentError,
            "incremental #{layer} evidence includes out-of-scope examples: #{Enum.join(unknown, ", ")}"
    end

    record
    |> current_record(identity)
    |> Map.update("examples", %{}, fn stored -> Map.take(stored, examples) end)
    |> Map.update!("examples", fn stored ->
      Enum.reduce(results, stored, fn {example, result}, evidence ->
        if example in examples do
          Map.update(evidence, example, %{layer => result}, &Map.put(&1, layer, result))
        else
          evidence
        end
      end)
    end)
  end

  @doc "Aggregates per-example evidence into the current browser check results."
  def aggregate(record, identity) when is_map(record) and is_map(identity) do
    current? = Map.get(record, "identity") == identity
    evidence = if current?, do: Map.get(record, "examples", %{}), else: %{}

    layer_checks =
      Map.new(layers(Map.get(identity, "source")), fn layer ->
        {layer, layer_check(layer, examples(identity), evidence, current?)}
      end)

    browser =
      ~w(interaction behavior accessibility)
      |> Enum.filter(&Map.has_key?(layer_checks, &1))
      |> Enum.map(&Map.fetch!(layer_checks, &1))
      |> BrowserVerification.merge_checks()

    checks =
      layer_checks
      |> Map.put("browser", browser)

    %{
      "pass" => Enum.all?(Map.values(checks), & &1["pass"]),
      "checks" => checks
    }
  end

  defp current_record(%{"identity" => identity, "examples" => examples}, identity)
       when is_map(examples),
       do: %{"identity" => identity, "examples" => examples}

  defp current_record(_record, identity), do: %{"identity" => identity, "examples" => %{}}

  defp layer_check(layer, examples, evidence, current?) do
    checks =
      Enum.map(examples, fn example ->
        case get_in(evidence, [example, layer]) do
          %{"pass" => _pass} = result -> BrowserVerification.label(result, "#{layer} #{example}")
          _ -> missing(layer, example, current?)
        end
      end)

    BrowserVerification.merge_checks(checks)
  end

  defp missing(layer, example, false),
    do: %{
      "pass" => false,
      "detail" => "#{layer} evidence identity changed; rerun #{example}"
    }

  defp missing(layer, example, true),
    do: %{"pass" => false, "detail" => "missing #{layer} evidence for #{example}"}

  defp examples(identity) do
    identity
    |> Map.get("examples", [])
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp validate_layer!(layer, identity) do
    if layer not in layers(Map.get(identity, "source")) do
      raise ArgumentError, "unknown incremental verification layer: #{layer}"
    end
  end
end
