defmodule LiveAiElements.HookTest do
  use ExUnit.Case, async: true

  @owners [
    LiveAiElements.Delta,
    LiveAiElements.Transcription,
    LiveAiElements.Components.FileTree,
    LiveAiElements.Components.MicSelector,
    LiveAiElements.Components.Persona,
    LiveAiElements.Components.PromptInput,
    LiveAiElements.Components.Question,
    LiveAiElements.Components.SpeechInput,
    LiveAiElements.Components.Terminal,
    LiveAiElements.Components.WebPreview
  ]

  test "every hook name is a key of the colocated hooks manifest" do
    manifest =
      Path.join(Mix.Project.build_path(), "phoenix-colocated/live_ai_elements/index.js")
      |> File.read!()

    registered = Regex.scan(~r/\["([\w.]+)"\] = js_/, manifest, capture: :all_but_first)

    assert Enum.sort(List.flatten(registered)) == Enum.sort(Enum.map(@owners, & &1.hook()))
  end
end
