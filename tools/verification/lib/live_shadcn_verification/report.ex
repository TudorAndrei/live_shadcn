defmodule LiveShadcnVerification.Report do
  @moduledoc false

  @version 1

  def version, do: @version

  def envelope(source, name, layer, preview_key, examples, identity_digest, opts \\ []) do
    states = Keyword.get(opts, :states, [])
    completed? = Keyword.get(opts, :completed, true)

    %{
      "version" => @version,
      "source" => source,
      "name" => name,
      "layer" => layer,
      "preview_key" => preview_key,
      "examples" => Enum.sort(examples),
      "states" => Enum.sort(states),
      "identity" => identity_digest,
      "completed" => completed?
    }
  end

  def validate!(report, expected) when is_map(report) and is_map(expected) do
    with :ok <- validate_top_level_errors(report),
         :ok <- validate_metadata(report, expected) do
      report
    else
      {:error, reason} -> Mix.raise(reason)
    end
  end

  defp validate_top_level_errors(report) do
    errors = Map.get(report, "errors", [])

    if errors == [] do
      :ok
    else
      messages =
        errors
        |> Enum.map(fn
          %{"message" => message} when is_binary(message) -> message
          other -> inspect(other)
        end)
        |> Enum.join("\n")

      {:error, "Playwright report has top-level errors:\n#{messages}"}
    end
  end

  defp validate_metadata(report, expected) do
    case Map.get(report, "_live_shadcn_verification") do
      nil ->
        {:error,
         "Playwright report is missing verification metadata; rerun with the current browser wrapper"}

      %{} = meta ->
        validate_meta_fields(meta, expected)

      _other ->
        {:error, "Playwright report has invalid verification metadata"}
    end
  end

  defp validate_meta_fields(meta, expected) do
    with :ok <- require_field(meta, expected, "version", &(&1 == @version), "report version"),
         :ok <- require_field(meta, expected, "source", &(&1 == expected.source), "source"),
         :ok <- require_field(meta, expected, "name", &(&1 == expected.name), "component name"),
         :ok <- require_field(meta, expected, "layer", &(&1 == expected.layer), "layer"),
         :ok <-
           require_field(
             meta,
             expected,
             "preview_key",
             &(&1 == expected.preview_key),
             "preview key"
           ),
         :ok <-
           require_field(
             meta,
             expected,
             "examples",
             &(Enum.sort(&1) == Enum.sort(expected.examples)),
             "example scope"
           ),
         :ok <-
           require_field(
             meta,
             expected,
             "identity",
             &(&1 == expected.identity),
             "verification identity"
           ),
         :ok <- validate_states(meta, expected),
         :ok <- require_completed(meta) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp require_field(meta, _expected, key, valid?, label) do
    value = Map.get(meta, key)

    cond do
      is_nil(value) -> {:error, "Playwright report metadata is missing #{label}"}
      valid?.(value) -> :ok
      true -> {:error, "Playwright report metadata has the wrong #{label}; rerun verification"}
    end
  end

  defp require_completed(%{"completed" => true}), do: :ok

  defp require_completed(%{"completed" => false}),
    do: {:error, "Playwright report metadata marks the run incomplete"}

  defp require_completed(_meta),
    do: {:error, "Playwright report metadata does not prove successful completion"}

  defp validate_states(_meta, %{states: []}), do: :ok

  defp validate_states(meta, %{states: expected}) when is_list(expected) do
    actual = Map.get(meta, "states", [])

    if Enum.sort(actual) == Enum.sort(expected) do
      :ok
    else
      {:error, "Playwright report metadata has incomplete state coverage; rerun verification"}
    end
  end

  defp validate_states(_meta, _expected), do: :ok
end
