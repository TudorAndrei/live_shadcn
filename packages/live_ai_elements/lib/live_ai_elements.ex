defmodule LiveAiElements do
  @moduledoc """
  AI Elements for Phoenix LiveView: reasoning, tool calls, and streaming
  message parts.

  The components are the small part. The product is the reducer that turns a
  provider event stream into ordered, addressable view parts:

      LiveAiElements.Stream.reduce(state, event)
      #=> {state, [{:insert_part, part} | {:append_delta, id, text} | {:set_state, id, status}]}

  A LiveView applies those patches:

    * `:insert_part` becomes a `stream_insert/4`
    * `:append_delta` becomes a `push_event/3` handled by a hook
    * `:set_state` re-inserts only the part that changed

  The rule that makes streaming cheap: **a delta never touches an assign**. A
  token appended to a message must not re-render the conversation.

  ## Adapters

  Events arrive as plain maps or structs, so adapters pattern match on shape and
  this package depends on no AI framework. The reference adapter follows the
  Open Responses specification, which carries a stable `item_id` per part and a
  `sequence_number` for ordering. A second adapter covers Jido.
  """
end
