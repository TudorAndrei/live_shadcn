defmodule LiveAiElements.Transcription do
  @moduledoc """
  The names that connect a transcription to its client hook.

  The hook reads the audio time, updates each timed segment, and seeks the
  audio when a user selects a segment. It does this work in the browser, with
  no LiveView event.
  """

  @hook "LiveAiElements.Transcription"

  @doc "The client hook name the transcription root declares in `phx-hook`."
  @spec hook() :: String.t()
  def hook, do: @hook
end
