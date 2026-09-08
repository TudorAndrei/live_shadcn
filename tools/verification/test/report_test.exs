defmodule LiveShadcnVerification.ReportTest do
  use ExUnit.Case, async: true

  alias LiveShadcnVerification.Report

  test "envelope carries source, layer, examples, identity, and test-time coverage" do
    envelope = metadata("digest-1")
    assert envelope["version"] == 2
    assert envelope["source"] == "shadcn"
    assert envelope["name"] == "button"
    assert envelope["layer"] == "parity"
    assert envelope["preview_key"] == "button"
    assert envelope["examples"] == ["default"]
    assert envelope["states"] == coverage()
    assert envelope["identity"] == "digest-1"
    assert envelope["completed"]
  end

  test "rejects legacy raw reports and old envelopes" do
    assert_raise Mix.Error, ~r/missing verification metadata/, fn ->
      Report.validate!(%{"suites" => [], "errors" => []}, expected())
    end

    assert_raise Mix.Error, ~r/wrong report version/, fn ->
      Report.validate!(put_in(report(), ["_live_shadcn_verification", "version"], 1), expected())
    end
  end

  test "rejects wrong identity, ownership, layer, or example scope" do
    for {key, value, reason} <- [
          {"identity", "old-digest", "verification identity"},
          {"name", "dialog", "component name"},
          {"source", "ai_elements", "source"},
          {"layer", "pixel", "layer"},
          {"examples", ["other"], "example scope"},
          {"examples", "default", "example scope"}
        ] do
      assert_raise Mix.Error, ~r/wrong #{reason}/, fn ->
        Report.validate!(put_in(report(), ["_live_shadcn_verification", key], value), expected())
      end
    end
  end

  test "rejects global errors and explicitly incomplete execution" do
    assert_raise Mix.Error, ~r/top-level errors/, fn ->
      Report.validate!(
        Map.put(report(), "errors", [%{"message" => "browser crashed"}]),
        expected()
      )
    end

    assert_raise Mix.Error, ~r/incomplete/, fn ->
      Report.validate!(
        put_in(report(), ["_live_shadcn_verification", "completed"], false),
        expected()
      )
    end
  end

  test "actual import expectations require coverage without a caller-supplied state list" do
    for invalid <- [
          nil,
          [],
          %{},
          %{"button.default" => %{"expected" => [], "completed" => []}},
          %{"button.default" => %{"expected" => ["initial", "open"], "completed" => ["initial"]}}
        ] do
      assert_raise Mix.Error, ~r/state coverage/, fn ->
        Report.validate!(
          put_in(report(), ["_live_shadcn_verification", "states"], invalid),
          expected()
        )
      end
    end
  end

  test "metadata cannot invent coverage absent from the executed test" do
    without_annotation =
      update_in(report(), ["suites"], fn [suite] ->
        [
          put_in(suite, ["specs"], [
            %{
              "title" => "button / default",
              "tests" => [%{"results" => [%{"status" => "passed"}], "annotations" => []}]
            }
          ])
        ]
      end)

    assert_raise Mix.Error, ~r/state coverage/, fn ->
      Report.validate!(without_annotation, expected())
    end
  end

  test "rejects skipped and interrupted tests even when metadata claims completion" do
    for status <- ["skipped", "interrupted", "timedOut"] do
      assert_raise Mix.Error, ~r/test execution/, fn ->
        Report.validate!(report(status), expected())
      end
    end
  end

  test "an incomplete report retains the underlying test failure in its rejection reason" do
    broken = report("timedOut")

    broken =
      put_in(
        broken,
        [
          "suites",
          Access.at(0),
          "specs",
          Access.at(0),
          "tests",
          Access.at(0),
          "results",
          Access.at(0),
          "errors"
        ],
        [%{"message" => "locator never became visible"}]
      )

    assert_raise Mix.Error, ~r/locator never became visible/, fn ->
      Report.validate!(broken, expected())
    end
  end

  test "accepts complete passed or failed execution with matching test annotations" do
    for status <- ["passed", "failed"] do
      assert Report.validate!(report(status), expected()) == report(status)
    end
  end

  defp expected do
    %{
      source: "shadcn",
      name: "button",
      layer: "parity",
      preview_key: "button",
      examples: ["default"],
      identity: "digest-1"
    }
  end

  defp coverage do
    %{
      "button.default" => %{"expected" => ["initial", "open"], "completed" => ["initial", "open"]}
    }
  end

  defp metadata(identity) do
    Report.envelope("shadcn", "button", "parity", "button", ["default"], identity,
      states: coverage()
    )
  end

  defp report(status \\ "passed") do
    annotation = coverage()["button.default"] |> Map.put("example", "button.default")

    %{
      "errors" => [],
      "_live_shadcn_verification" => metadata("digest-1"),
      "suites" => [
        %{
          "specs" => [
            %{
              "title" => "button / default",
              "tests" => [
                %{
                  "results" => [%{"status" => status}],
                  "annotations" => [
                    %{
                      "type" => "verification-state-coverage",
                      "description" => Jason.encode!(annotation)
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
  end
end
