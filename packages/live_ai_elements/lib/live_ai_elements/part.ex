defmodule LiveAiElements.Part do
  @moduledoc """
  One addressable piece of an assistant turn.

  A provider sends a flat stream of events. A reader sees a list of blocks: some
  prose, a block of reasoning, a tool call and its result, a list of sources.
  A `Part` is one of those blocks, and the part list is the whole view model.

  ## Why a part and not a message

  A message is not addressable. If the view model is one string per message,
  then a reasoning token and an answer token both change the same string, and
  the only way to render them differently is to parse the string back apart.

  A part is addressable, so `phx-update="stream"` can insert it once and touch
  nothing else afterwards. That is what makes a token append cost one DOM
  operation instead of one re-render.

  ## Fields

    * `id` — stable for the life of the part, and unique inside one turn. The
      adapter derives it from the provider's own identifiers, never from a
      counter, so replaying the same stream gives the same ids.
    * `type` — which component renders it. See `t:type/0`.
    * `status` — where the part is on the ladder below.
    * `seq` — the provider's ordering number at the moment the part opened.
      Parts sort by it. It is not a position: numbers have gaps, because one
      part opens on one event out of many.
    * `text` — the part's text, and empty while the text is still arriving.
      See "Text arrives twice" below.
    * `meta` — everything type-specific: a tool's name and arguments, a
      source's URL and title, an error's code.

  ## The status ladder

      :pending -> :streaming -> :running -> :complete
                                         -> :incomplete
                                         -> :error

    * `:pending` — the part exists and nothing has arrived for it yet
    * `:streaming` — text is arriving
    * `:running` — the input is complete and the part is waiting on something
      else, which for a tool call means the tool itself
    * `:complete` — finished, and `text` is authoritative
    * `:incomplete` — the turn ended while the part was still open
    * `:error` — the part failed, and `meta.error` says why

  The last three are alternatives, not steps: a part reaches one of them and
  stops. A part never moves backwards and never moves again once it has
  stopped, so an event that arrives after the end of a turn cannot mark a
  finished part incomplete. `update/2` is where that is enforced.

  ## Text arrives twice

  `text` is empty while a part streams, and is filled in one step when the part
  completes. That looks like a bug and is the central design decision:

  A delta is pushed to the browser and appended to the DOM by a hook. It is
  never accumulated on the server, because accumulating it means writing to an
  assign, and writing to an assign on every token means one LiveView render per
  token. So during `:streaming` the browser holds the text and the server does
  not.

  Every provider's terminal event carries the complete text — Open Responses
  sends it as `text` on `response.output_text.done` — so the server takes the
  authoritative copy from there rather than trusting its own accumulation. One
  `stream_insert` then replaces what the hook appended.

  The cost is stated plainly: a reader who reconnects mid-part loses the tokens
  of that one part until it completes. That is the price of never re-rendering
  a conversation to append a token, and it is paid once per interrupted part.
  """

  @typedoc """
  Which component renders the part.

    * `:text` — assistant prose, rendered by `message`
    * `:reasoning` — a thinking block, rendered by `reasoning` or
      `chain-of-thought`
    * `:tool_call` — a call and its result, rendered by `tool`
    * `:task` — a step of work the model reports, rendered by `task`
    * `:source` — one citation, rendered by `sources`
    * `:refusal` — the model declined, rendered by `message`
    * `:error` — the turn failed
  """
  @type type :: :text | :reasoning | :tool_call | :task | :source | :refusal | :error

  @type status :: :pending | :streaming | :running | :complete | :incomplete | :error

  @type t :: %__MODULE__{
          id: String.t(),
          type: type(),
          status: status(),
          seq: non_neg_integer(),
          text: String.t(),
          meta: map()
        }

  @enforce_keys [:id, :type]
  defstruct [:id, :type, status: :pending, seq: 0, text: "", meta: %{}]

  @terminal [:complete, :incomplete, :error]

  # The ladder, as a height per rung. A part may move up and never down, which
  # is what stops a late event from putting a running tool back to pending.
  #
  # The three terminal rungs share a height on purpose. They are three ways to
  # stop, not three steps, so none of them is reachable from another: the end
  # of a turn marks its open parts incomplete, and a part that had already
  # completed must not be marked incomplete along with them.
  @rank %{pending: 0, streaming: 1, running: 2, complete: 3, incomplete: 3, error: 3}

  @doc """
  Builds a part.

  `attrs` accepts every field except `id` and `type`, which are required.

      iex> LiveAiElements.Part.new("msg_1", :text, seq: 3)
      %LiveAiElements.Part{id: "msg_1", type: :text, status: :pending, seq: 3, text: "", meta: %{}}
  """
  @spec new(String.t(), type(), keyword()) :: t()
  def new(id, type, attrs \\ []) do
    struct!(%__MODULE__{id: id, type: type}, attrs)
  end

  @doc """
  Applies a change to a part.

  `attrs` is a map, and only the keys it carries are touched. Two keys are not
  a plain overwrite:

    * `:status` moves along the ladder and never back, so an event that arrives
      after the part completed cannot reopen it
    * `:meta` merges, so an adapter that learns a tool's arguments now and its
      output later does not have to resend the name

  Returns the part unchanged when nothing moved, which is what lets
  `LiveAiElements.Stream` emit no patch for an event that told it nothing new.
  """
  @spec update(t(), map()) :: t()
  def update(%__MODULE__{} = part, attrs) when is_map(attrs) do
    part
    |> apply_status(attrs)
    |> apply_meta(attrs)
    |> apply_text(attrs)
  end

  defp apply_status(part, %{status: status}) when is_atom(status) do
    if not terminal?(part) and rank(status) > rank(part.status),
      do: %{part | status: status},
      else: part
  end

  defp apply_status(part, _attrs), do: part

  defp apply_meta(part, %{meta: meta}) when map_size(meta) > 0 do
    %{part | meta: Map.merge(part.meta, meta)}
  end

  defp apply_meta(part, _attrs), do: part

  defp apply_text(part, %{text: text}) when is_binary(text), do: %{part | text: text}
  defp apply_text(part, _attrs), do: part

  defp rank(status), do: Map.fetch!(@rank, status)

  @doc """
  Whether the part has reached the end of the ladder.

  A terminal part takes no further events. `LiveAiElements.Stream` uses this to
  decide which parts the end of a turn has to close.
  """
  @spec terminal?(t()) :: boolean()
  def terminal?(%__MODULE__{status: status}), do: status in @terminal
end
