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

  test "keeps each selected example result when a browser batch has a failure" do
    report = %{
      "suites" => [
        suite("parity.spec.mjs", [
          spec(
            "input-otp / default draws what React draws",
            "parity.spec.mjs",
            "expected"
          ),
          spec(
            "input-otp / invalid draws what React draws",
            "parity.spec.mjs",
            "unexpected",
            "slot differs"
          )
        ])
      ]
    }

    result =
      PlaywrightReport.example_results(report, ["input-otp.default", "input-otp.invalid"])

    assert result.components["input-otp.default"] == %{"pass" => true}

    assert result.components["input-otp.invalid"] == %{
             "detail" => "input-otp / invalid draws what React draws\nslot differs",
             "pass" => false
           }

    assert result.global_failures == []
  end

  test "maps generic interaction evidence to each selected example" do
    report = %{
      "suites" => [
        suite("interaction-parity.spec.mjs", [
          spec(
            "calendar / rtl keeps inferred interaction semantics",
            "interaction-parity.spec.mjs",
            "expected"
          ),
          spec(
            "calendar / time keeps inferred interaction semantics",
            "interaction-parity.spec.mjs",
            "unexpected",
            "select value differs"
          )
        ])
      ]
    }

    result =
      PlaywrightReport.incremental_example_results(report, "interaction", [
        "calendar.rtl",
        "calendar.time"
      ])

    assert result.components["calendar.rtl"] == %{"pass" => true}
    refute result.components["calendar.time"]["pass"]
    assert result.components["calendar.time"]["detail"] =~ "select value differs"
  end

  test "records a named behavior report against its explicit single example" do
    report = %{
      "suites" => [
        suite("calendar.spec.mjs", [
          spec("RTL retains its caption contract", "calendar.spec.mjs", "expected")
        ])
      ]
    }

    result = PlaywrightReport.incremental_example_results(report, "behavior", ["calendar.rtl"])

    assert result.components["calendar.rtl"] == %{"pass" => true}
  end

  test "authored behavior evidence requires an actual pass and retains retry failures" do
    for {status, expected_status, attempts, pass?} <- [
          {"expected", "passed", ["passed"], true},
          {"expected", "failed", ["failed"], false},
          {"expected", "passed", [], false},
          {"skipped", "skipped", ["skipped"], false},
          {"flaky", "passed", ["failed", "passed"], false},
          {"unexpected", "passed", ["failed", "failed"], false}
        ] do
      interaction = %{
        "title" => "selects a microphone with the keyboard",
        "tests" => [
          %{
            "status" => status,
            "expectedStatus" => expected_status,
            "results" =>
              Enum.map(attempts, fn result ->
                %{
                  "status" => result,
                  "errors" =>
                    if(result == "failed", do: [%{"message" => "no selection"}], else: [])
                }
              end)
          }
        ]
      }

      report = %{"suites" => [suite("mic-selector.spec.mjs", [interaction])]}
      result = PlaywrightReport.behavior_results(report, ["mic-selector.default"])
      check = result.components["mic-selector.default"]

      assert check["pass"] == pass?, inspect({status, expected_status, attempts})

      if "failed" in attempts, do: assert(check["detail"] =~ "no selection")
    end
  end

  test "require_example_coverage! rejects reports that omit scoped examples" do
    result = %{components: %{"button.default" => %{"pass" => true}}, global_failures: []}

    assert_raise ArgumentError, ~r/missing scoped results for button\.basic/, fn ->
      PlaywrightReport.require_example_coverage!(result, ["button.default", "button.basic"])
    end
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
