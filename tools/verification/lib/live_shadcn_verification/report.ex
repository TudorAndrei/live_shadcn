defmodule LiveShadcnVerification.Report do
  @moduledoc false

  @version 2

  def version, do: @version

  def envelope(source, name, layer, preview_key, examples, identity_digest, opts \\ []) do
    states = Keyword.get(opts, :states, %{})
    completed? = Keyword.get(opts, :completed, true)

    %{
      "version" => @version,
      "source" => source,
      "name" => name,
      "layer" => layer,
      "preview_key" => preview_key,
      "examples" => Enum.sort(examples),
      "states" => states,
      "identity" => identity_digest,
      "completed" => completed?
    }
  end

  def validate!(report, expected) when is_map(report) and is_map(expected) do
    with :ok <- validate_top_level_errors(report),
         :ok <- validate_metadata(report, expected),
         :ok <- validate_states(report, expected),
         :ok <- validate_execution(report) do
      report
    else
      {:error, reason} -> Mix.raise(reason <> failure_details(report))
    end
  end

  defp validate_top_level_errors(report) do
    errors = Map.get(report, "errors", [])

    if errors == [] do
      :ok
    else
      messages =
        errors
        |> Enum.map_join("\n", fn
          %{"message" => message} when is_binary(message) -> message
          other -> inspect(other)
        end)

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
             &(is_list(&1) and Enum.sort(&1) == Enum.sort(expected.examples)),
             "example scope"
           ),
         :ok <-
           require_field(
             meta,
             expected,
             "identity",
             &(&1 == expected.identity),
             "verification identity"
           ) do
      require_completed(meta)
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

  defp validate_states(report, expected) do
    states = get_in(report, ["_live_shadcn_verification", "states"])
    tests = tests(report)

    keys =
      if expected.layer == "behavior",
        do: ["__tests__"],
        else: Enum.map(expected.examples, &"#{expected.preview_key}.#{&1}")

    observed =
      if expected.layer == "behavior" do
        %{
          "__tests__" => %{
            "expected" => Enum.map(tests, & &1["title"]),
            "completed" => tests |> Enum.filter(&executed?/1) |> Enum.map(& &1["title"])
          }
        }
      else
        tests
        |> Enum.flat_map(&Map.get(&1, "annotations", []))
        |> Enum.filter(&(&1["type"] == "verification-state-coverage"))
        |> Enum.reduce(%{}, &collect_state_coverage/2)
      end

    valid? =
      is_map(states) and keys != [] and
        Enum.all?(keys, fn key ->
          case Map.get(states, key) do
            %{"expected" => needed, "completed" => completed} = coverage
            when is_list(needed) and needed != [] ->
              needed == completed and Map.get(observed, key) == coverage

            _ ->
              false
          end
        end)

    if valid?,
      do: :ok,
      else:
        {:error, "Playwright report has missing or incomplete state coverage; rerun verification"}
  end

  defp collect_state_coverage(annotation, acc) do
    case Jason.decode(Map.get(annotation, "description", "")) do
      {:ok, %{"example" => key, "expected" => needed, "completed" => completed}} ->
        if Map.has_key?(acc, key),
          do: Map.put(acc, key, :duplicate),
          else: Map.put(acc, key, %{"expected" => needed, "completed" => completed})

      _ ->
        acc
    end
  end

  defp failure_details(report) do
    report
    |> tests()
    |> Enum.flat_map(fn test ->
      for result <- Map.get(test, "results", []),
          error <- Map.get(result, "errors", List.wrap(Map.get(result, "error"))),
          is_map(error),
          is_binary(error["message"]),
          do: "\n#{test["title"]}: #{error["message"]}"
    end)
    |> Enum.join()
  end

  defp validate_execution(report) do
    tests = tests(report)

    if tests != [] and Enum.all?(tests, &executed?/1),
      do: :ok,
      else: {:error, "Playwright report has skipped, interrupted, or missing test execution"}
  end

  defp tests(report), do: Enum.flat_map(Map.get(report, "suites", []), &suite_tests/1)

  defp suite_tests(suite) do
    local =
      for spec <- Map.get(suite, "specs", []),
          test <- Map.get(spec, "tests", []),
          do: Map.put(test, "title", Map.get(spec, "title"))

    local ++ Enum.flat_map(Map.get(suite, "suites", []), &suite_tests/1)
  end

  defp executed?(test) do
    case List.last(Map.get(test, "results", [])) do
      %{"status" => status} when status in ["passed", "failed"] -> true
      _ -> false
    end
  end
end
