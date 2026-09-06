defmodule LiveShadcnVerification.ReportTest do
  use ExUnit.Case, async: true

  alias LiveShadcnVerification.Report

  test "envelope carries source, layer, examples, identity, and completion" do
    envelope =
      Report.envelope("shadcn", "button", "parity", "button", ["default"], "digest-1",
        states: ["default"]
      )

    assert envelope["version"] == 1
    assert envelope["source"] == "shadcn"
    assert envelope["name"] == "button"
    assert envelope["layer"] == "parity"
    assert envelope["preview_key"] == "button"
    assert envelope["examples"] == ["default"]
    assert envelope["states"] == ["default"]
    assert envelope["identity"] == "digest-1"
    assert envelope["completed"]
  end

  test "validate! rejects raw reports without verification metadata" do
    report = %{"suites" => [], "errors" => []}

    assert_raise Mix.Error, ~r/missing verification metadata/, fn ->
      Report.validate!(report, %{
        source: "shadcn",
        name: "button",
        layer: "parity",
        preview_key: "button",
        examples: ["default"],
        identity: "digest-1"
      })
    end
  end

  test "validate! rejects top-level Playwright errors" do
    report = %{
      "errors" => [%{"message" => "browser crashed"}],
      "_live_shadcn_verification" => metadata("digest-1")
    }

    assert_raise Mix.Error, ~r/top-level errors/, fn ->
      Report.validate!(report, expected("digest-1"))
    end
  end

  test "validate! rejects wrong component ownership" do
    report = %{
      "errors" => [],
      "_live_shadcn_verification" => metadata("digest-1", %{"name" => "dialog"})
    }

    assert_raise Mix.Error, ~r/wrong component name/, fn ->
      Report.validate!(report, expected("digest-1"))
    end
  end

  test "validate! rejects stale identity digests" do
    report = %{
      "errors" => [],
      "_live_shadcn_verification" => metadata("old-digest")
    }

    assert_raise Mix.Error, ~r/wrong verification identity/, fn ->
      Report.validate!(report, expected("current-digest"))
    end
  end

  test "validate! rejects incomplete metadata" do
    report = %{
      "errors" => [],
      "_live_shadcn_verification" => Map.put(metadata("digest-1"), "completed", false)
    }

    assert_raise Mix.Error, ~r/incomplete/, fn ->
      Report.validate!(report, expected("digest-1"))
    end
  end

  test "validate! rejects missing state coverage" do
    report = %{
      "errors" => [],
      "_live_shadcn_verification" => metadata("digest-1", %{"states" => ["default"]})
    }

    assert_raise Mix.Error, ~r/incomplete state coverage/, fn ->
      Report.validate!(
        report,
        Map.put(expected("digest-1"), :states, ["default", "expanded:Open"])
      )
    end
  end

  test "validate! accepts matching metadata" do
    report = %{
      "errors" => [],
      "_live_shadcn_verification" =>
        metadata("digest-1", %{"states" => ["default", "expanded:Open"]})
    }

    assert report ==
             Report.validate!(
               report,
               Map.put(expected("digest-1"), :states, ["default", "expanded:Open"])
             )
  end

  defp expected(identity) do
    %{
      source: "shadcn",
      name: "button",
      layer: "parity",
      preview_key: "button",
      examples: ["default"],
      identity: identity
    }
  end

  defp metadata(identity, overrides \\ %{}) do
    envelope("digest-1")
    |> Map.merge(overrides)
    |> Map.put("identity", identity)
  end

  defp envelope(identity) do
    Report.envelope("shadcn", "button", "parity", "button", ["default"], identity,
      states: ["default"]
    )
  end
end
