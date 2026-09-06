defmodule LiveShadcnTools.AiElementsExamplesTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.AiElementsExamples

  test "discovers the longest component prefix and ignores application examples" do
    manifest = %{
      "files" => %{
        "ai_elements/audio-player.tsx" => %{},
        "ai_elements/tool.tsx" => %{},
        "ai_examples/audio-player-remote.tsx" => %{},
        "ai_examples/audio-player.tsx" => %{},
        "ai_examples/chatbot.tsx" => %{},
        "ai_examples/tool-input-available.tsx" => %{},
        "ai_examples/tool.tsx" => %{}
      }
    }

    sources = %{
      "audio-player" => ~s(import { AudioPlayer } from "@repo/elements/audio-player";),
      "audio-player-remote" => ~s(import { AudioPlayer } from "@repo/elements/audio-player";),
      "chatbot" => ~s(import { Message } from "@repo/elements/message";),
      "tool" => ~s(import { Tool } from "@repo/elements/tool";),
      "tool-input-available" => ~s(import { Tool } from "@repo/elements/tool";)
    }

    assert AiElementsExamples.all(manifest, &Map.fetch!(sources, &1)) == %{
             "audio-player" => [
               %{"id" => "default", "source" => "audio-player"},
               %{"id" => "remote", "source" => "audio-player-remote"}
             ],
             "tool" => [
               %{"id" => "default", "source" => "tool"},
               %{"id" => "input-available", "source" => "tool-input-available"}
             ]
           }
  end

  test "rejects a filename prefix collision when the pinned source imports both candidates" do
    manifest = %{
      "files" => %{
        "ai_elements/tool.tsx" => %{},
        "ai_elements/tool-call.tsx" => %{},
        "ai_examples/tool-call-state.tsx" => %{}
      }
    }

    source = fn _ ->
      ~s(import { Tool } from "@repo/elements/tool"; import { ToolCall } from "@repo/elements/tool-call";)
    end

    assert AiElementsExamples.discovery(manifest, source).problems == [
             "tool-call-state: imports more than one filename candidate: tool, tool-call"
           ]
  end

  test "reports every missing official HEEx example" do
    expected = [
      %{"id" => "default", "source" => "tool"},
      %{"id" => "input-available", "source" => "tool-input-available"}
    ]

    assert AiElementsExamples.coverage(expected, ["default"]) == %{
             "pass" => false,
             "official_comparison" => true,
             "detail" => "missing HEEx: input-available (tool-input-available)"
           }
  end

  test "permits declared local-only previews without an official comparison" do
    assert AiElementsExamples.coverage([], ["default"], ["default"]) == %{
             "pass" => true,
             "official_comparison" => false,
             "detail" => "not applicable: 1 local-only HEEx preview; no official comparison"
           }
  end

  test "rejects undeclared extra and stale local-only previews" do
    expected = [%{"id" => "default", "source" => "tool"}]

    assert AiElementsExamples.coverage(expected, ["default", "local"], ["stale"]) == %{
             "pass" => false,
             "official_comparison" => true,
             "detail" => "extra local HEEx: local\nstale local-only HEEx: stale"
           }
  end

  test "discovers all component examples from the pinned checkout" do
    manifest =
      Path.expand("../../registry/UPSTREAM.json", __DIR__)
      |> File.read!()
      |> Jason.decode!()

    count =
      manifest
      |> AiElementsExamples.all()
      |> Map.values()
      |> List.flatten()
      |> length()

    assert count == 84
  end

  test "matches the JavaScript discovery output for the pinned checkout" do
    manifest =
      Path.expand("../../registry/UPSTREAM.json", __DIR__)
      |> File.read!()
      |> Jason.decode!()

    script = Path.expand("../../parity/test/ai-elements-discovery-output.mjs", __DIR__)
    {output, 0} = System.cmd("node", [script])
    javascript = Jason.decode!(output)

    elixir_entries =
      manifest
      |> AiElementsExamples.all()
      |> Enum.flat_map(fn {component, entries} ->
        Enum.map(entries, &Map.put(&1, "component", component))
      end)
      |> Enum.sort_by(&{&1["component"], &1["source"]})

    assert javascript == %{
             "entries" => elixir_entries,
             "problems" => AiElementsExamples.problems(manifest)
           }
  end
end
