defmodule LiveShadcnTools.PlaywrightReportTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.PlaywrightReport

  test "assigns each test result only to its component" do
    report = %{
      "suites" => [
        suite("accessibility.spec.mjs", [
          spec("badge / default is clean under axe-core", "accessibility.spec.mjs", "expected"),
          spec(
            "conversation / default is clean under axe-core",
            "accessibility.spec.mjs",
            "expected"
          )
        ]),
        suite("conversation.spec.mjs", [
          spec(
            "uses the same final scroll geometry as React",
            "conversation.spec.mjs",
            "unexpected",
            "scroll geometry differs"
          )
        ]),
        suite("unslotted-parity.spec.mjs", [
          spec(
            "commit unslotted text has React geometry",
            "unslotted-parity.spec.mjs",
            "unexpected",
            "text geometry differs"
          )
        ])
      ]
    }

    result = PlaywrightReport.results(report, ["badge", "commit", "conversation"])

    assert result.components["badge"] == %{"pass" => true}

    assert result.components["conversation"] == %{
             "detail" => "uses the same final scroll geometry as React\nscroll geometry differs",
             "pass" => false
           }

    assert result.components["commit"] == %{
             "detail" => "commit unslotted text has React geometry\ntext geometry differs",
             "pass" => false
           }

    assert result.global_failures == []
  end

  test "uses the describe block for tests that share a file" do
    report = %{
      "suites" => [
        %{
          "file" => "checkbox.spec.mjs",
          "specs" => [],
          "suites" => [
            %{
              "title" => "a switch",
              "file" => "checkbox.spec.mjs",
              "specs" => [
                spec(
                  "carries the same contract, drawn differently",
                  "checkbox.spec.mjs",
                  "unexpected",
                  "switch state differs"
                )
              ]
            }
          ],
          "title" => "checkbox.spec.mjs"
        }
      ]
    }

    result = PlaywrightReport.results(report, ["checkbox", "radio-group", "switch", "toggle"])

    assert result.components["switch"]["pass"] == false
    assert result.components["switch"]["detail"] =~ "switch state differs"
    refute Map.has_key?(result.components, "checkbox")
  end

  test "keeps an unmapped failure as a suite failure" do
    report = %{
      "suites" => [
        suite("navigation.spec.mjs", [
          spec("keeps its place", "navigation.spec.mjs", "unexpected", "navigation failed")
        ])
      ]
    }

    result = PlaywrightReport.results(report, ["badge"])

    assert result.components == %{}
    assert result.global_failures == ["keeps its place\nnavigation failed"]
  end

  defp suite(file, specs) do
    %{"file" => file, "specs" => specs, "suites" => [], "title" => file}
  end

  defp spec(title, file, status, error \\ nil) do
    errors = if error, do: [%{"message" => error}], else: []

    %{
      "file" => file,
      "ok" => status == "expected",
      "tests" => [
        %{
          "results" => [%{"errors" => errors, "status" => result_status(status)}],
          "status" => status
        }
      ],
      "title" => title
    }
  end

  defp result_status("expected"), do: "passed"
  defp result_status(_status), do: "failed"
end
