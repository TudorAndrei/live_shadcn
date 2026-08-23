defmodule LiveAiElements do
  @moduledoc """
  AI Elements for Phoenix LiveView: reasoning, tool calls, and streaming
  message parts.

  The components are the small part. The product is the reducer that turns a
  provider event stream into ordered, addressable view parts:

      state = LiveAiElements.Stream.new(adapter: LiveAiElements.Adapters.OpenResponses)
      {state, patches} = LiveAiElements.Stream.reduce(state, event)

  A LiveView applies those patches, and each one costs exactly one thing:

    * `{:insert_part, part}` becomes a `stream_insert/4`
    * `{:append_delta, id, chunk}` becomes a `push_event/3` the
      `LiveAiElements.Delta` hook handles
    * `{:set_state, part}` re-inserts the one part that changed

  The rule that makes streaming cheap: **a delta never touches an assign**. A
  token appended to a message must not re-render the conversation.
  `LiveAiElements.Stream` says how that is kept, and `LiveAiElements.Part` says
  what it costs.

  ## The four modules

  | Module | What it is |
  |---|---|
  | `LiveAiElements.Part` | the view model: one addressable block of a turn |
  | `LiveAiElements.Stream` | the reducer: events in, parts and patches out |
  | `LiveAiElements.Adapter` | the boundary: one provider's events to four operations |
  | `LiveAiElements.Delta` | the names the server and the client hook share |

  ## Adapters

  Events arrive as plain maps or structs, so adapters pattern match on shape and
  this package depends on no AI framework. The reference adapter follows the
  Open Responses specification, which carries a stable `item_id` per part and a
  `sequence_number` for ordering. A second adapter covers Jido.
  """
end
