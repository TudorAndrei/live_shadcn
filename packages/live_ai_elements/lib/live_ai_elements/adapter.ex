defmodule LiveAiElements.Adapter do
  @moduledoc """
  Turns one provider's events into the four operations the reducer understands.

  This is the only place in the package that knows what any provider calls
  anything. `LiveAiElements.Stream` reads operations; it never reads an event.
  So supporting a new provider is one module and no change anywhere else, and
  that is the boundary a second adapter exists to prove.

  ## The four operations

      {:open, id, attrs}      a part begins
      {:delta, id, chunk}     text is appended to a part
      {:update, id, attrs}    a part's status, text, or meta changed
      {:finish, status}       the turn ended

  `attrs` is the map `LiveAiElements.Part.update/2` takes: any of `:status`,
  `:text`, `:meta`, and for `:open` also `:type` and `:seq`.

  An adapter that has nothing to say about an event returns no operations. That
  is the normal case: Open Responses sends about sixty event types and this
  package models the dozen that change what a reader sees.

  ## Why four and not more

  Each one costs something different in the browser:

  | Operation | What the LiveView does | Cost |
  |---|---|---|
  | `:open` | `stream_insert/4` | one node added |
  | `:delta` | `push_event/3` | one text append, no render |
  | `:update` | `stream_insert/4` | one node replaced |
  | `:finish` | closes what is still open | one node per open part |

  A fifth operation would have to cost one of those four, and would then be one
  of them.

  ## Ordering

  An adapter reports the provider's own ordering number as `:seq` on `:open`.
  Open Responses calls it `sequence_number`, and it is monotonic across the
  whole turn. A provider without one may pass a counter it keeps in its own
  state, as long as replaying the same events gives the same numbers — the
  golden test in this package is the check on that.

  ## Writing one

      defmodule MyAdapter do
        @behaviour LiveAiElements.Adapter

        @impl true
        def init(_opts), do: %{}

        @impl true
        def normalize(%{"type" => "text", "id" => id, "delta" => chunk}, state) do
          {[{:delta, id, chunk}], state}
        end

        def normalize(_event, state), do: {[], state}
      end

  `normalize/2` is pure. Everything it has to remember between events — which
  output index carries which item, what type an item was declared as — goes in
  the state it returns.
  """

  alias LiveAiElements.Part

  @typedoc "An instruction to the reducer. See the module documentation."
  @type op ::
          {:open, String.t(), map()}
          | {:delta, String.t(), String.t()}
          | {:update, String.t(), map()}
          | {:finish, Part.status()}

  @typedoc "Whatever the adapter needs to remember between events."
  @type state :: term()

  @doc """
  The adapter's starting state, built once per turn.
  """
  @callback init(opts :: keyword()) :: state()

  @doc """
  Reads one provider event and returns the operations it implies.

  Returns `{[], state}` for an event the adapter does not model. It must never
  raise on an unknown event: a provider adds event types, and a conversation
  that crashes because the provider shipped a new one is worse than one that
  ignores it.
  """
  @callback normalize(event :: term(), state()) :: {[op()], state()}
end
