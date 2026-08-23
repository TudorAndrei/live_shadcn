defmodule LiveAiElements.Delta do
  @moduledoc """
  The names the server and the delta hook have to agree on.

  A token reaches the browser as a `push_event/3` and is written into the DOM by
  the `LiveAiElements.Delta` client hook. Four strings connect the two halves —
  one event name and three attributes — and they are defined here so that
  neither half can be renamed without the other failing to compile or to find
  its element.

  ## The markup the hook expects

      <div id="conversation" phx-hook={LiveAiElements.Delta.hook()} phx-update="stream">
        <div :for={{dom_id, part} <- @streams.parts} id={dom_id}
             data-lae-part={part.id}
             data-lae-stream={part.status == :streaming}>
          <span data-lae-text>{part.text}</span>
        </div>
      </div>

  `data-lae-stream` is what tells the hook whose text it still owns. While it is
  present the server renders the part's text as empty and the hook writes every
  token; once it is gone the server's text is the authoritative one and the hook
  lets go. `LiveAiElements.Part` explains why the text arrives that way.

  The prefix is `data-lae-`, which no shadcn class string and no Base UI
  contract uses, for the same reason `live_base` uses `data-lb-`.
  """

  @hook "LiveAiElements.Delta"

  @doc "The client hook name the container declares in `phx-hook`."
  @spec hook() :: String.t()
  def hook, do: @hook

  @doc "Carries the part id the server addresses a delta to."
  @spec part_attr() :: String.t()
  def part_attr, do: "data-lae-part"

  @doc "Present on a part only while its text is still arriving."
  @spec stream_attr() :: String.t()
  def stream_attr, do: "data-lae-stream"

  @doc "Marks the descendant a token is written into."
  @spec text_attr() :: String.t()
  def text_attr, do: "data-lae-text"
end
