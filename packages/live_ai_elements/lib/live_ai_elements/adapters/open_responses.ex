defmodule LiveAiElements.Adapters.OpenResponses do
  @moduledoc """
  The reference adapter: Open Responses, the streaming shape the Responses API
  publishes.

  It is the reference for one reason. Every other provider streams tokens and
  leaves ordering and identity to the reader. Open Responses carries both:

    * `item_id` — stable for the life of an output item, so a part has an
      identity the provider gave it rather than one this package invented
    * `sequence_number` — monotonic across the whole turn, so two interleaved
      items sort the way the model produced them

  Those two are exactly what `phx-update="stream"` needs, which is why this
  adapter is short and the reducer needs no counters.

  ## Events it models

  | Event | What it does |
  |---|---|
  | `response.output_item.added` | opens a tool call; notes what a message or reasoning item is |
  | `response.content_part.added` | opens a text or refusal part |
  | `response.output_text.delta` / `.done` | streams and then completes it |
  | `response.output_text.annotation.added` | opens a source |
  | `response.refusal.delta` / `.done` | streams and then completes a refusal |
  | `response.reasoning_summary_part.added` | opens a reasoning part |
  | `response.reasoning_summary_text.delta` / `.done` | streams and completes it |
  | `response.reasoning_text.delta` / `.done` | the same, for raw reasoning |
  | `response.function_call_arguments.delta` / `.done` | streams a tool's input |
  | `response.mcp_call_arguments.*`, `response.custom_tool_call_input.*` | the same, other tool kinds |
  | `response.code_interpreter_call_code.*` | the same, for interpreted code |
  | `response.*_call.in_progress` / `.searching` / `.completed` / `.failed` | a built-in tool's progress |
  | `response.output_item.done` | completes an item and records its output |
  | `response.completed` / `.incomplete` / `.failed` / `error` | ends the turn |

  Every other event returns no operations. That includes `response.created`,
  `response.in_progress`, and `response.queued`: they change nothing a reader
  sees, and a part opened on `response.created` would be a part with no content
  and no type.

  ## Part identity

  One output item can hold several content parts, and each is its own block on
  the page. So an id is the item's id and the index inside it, with a letter
  for which index it is:

      "msg_01"          a tool call — one part per item, so the item's own id
      "msg_01:0"        content part 0 of a message
      "msg_01:r0"       reasoning content part 0
      "msg_01:s0"       reasoning summary part 0
      "msg_01:0:a2"     annotation 2 on content part 0

  Every one is derived from the event. Nothing counts, so a replay of the same
  events gives the same ids.

  ## A missing announcement does not lose a token

  A delta should always follow the event that announced its part. When it does
  not — a provider that skips `response.content_part.added`, a stream joined
  late — the adapter opens the part from the delta itself rather than dropping
  the token. Only the first delta of a part can do this, so the rule that a
  delta returns unchanged state still holds for every token after it.

  Events may arrive with string keys or with atom keys — see
  `LiveAiElements.Adapter.field/2`.
  """

  @behaviour LiveAiElements.Adapter

  import LiveAiElements.Adapter, only: [field: 2, prune: 1]

  # Output item types that become one tool-call part, with the label the `tool`
  # component shows when the item carries no name of its own.
  @tool_items %{
    "function_call" => nil,
    "custom_tool_call" => nil,
    "web_search_call" => "web_search",
    "file_search_call" => "file_search",
    "code_interpreter_call" => "code_interpreter",
    "image_generation_call" => "image_generation",
    "mcp_call" => nil,
    "mcp_list_tools" => "mcp_list_tools",
    "mcp_approval_request" => "mcp_approval_request",
    "local_shell_call" => "local_shell",
    "computer_call" => "computer_use"
  }

  @impl true
  def init(_opts), do: %{opened: MapSet.new()}

  @impl true
  def normalize(event, state) do
    handle(field(event, :type), event, state)
  end

  # ── the turn ──────────────────────────────────────────────────────────────

  defp handle("response.completed", _event, state), do: {[{:finish, :complete}], state}
  defp handle("response.incomplete", _event, state), do: {[{:finish, :incomplete}], state}

  defp handle("response.failed", event, state) do
    fail(error_of(field(event, :response)), field(event, :sequence_number), state)
  end

  defp handle("error", event, state) do
    fail(error_of(event), field(event, :sequence_number), state)
  end

  # ── output items ──────────────────────────────────────────────────────────

  defp handle("response.output_item.added", event, state) do
    item = field(event, :item) || %{}
    id = field(item, :id)
    type = field(item, :type)

    cond do
      is_nil(id) or is_nil(type) ->
        {[], state}

      Map.has_key?(@tool_items, type) ->
        meta = %{tool: tool_name(item, type), kind: type, call_id: field(item, :call_id)}
        open(id, :tool_call, seq(event), state, status: :streaming, meta: prune(meta))

      true ->
        # A message or a reasoning item holds parts rather than being one, and
        # each of those parts is announced by an event of its own. So this
        # event opens nothing.
        {[], state}
    end
  end

  defp handle("response.output_item.done", event, state) do
    item = field(event, :item) || %{}
    id = field(item, :id)
    type = field(item, :type)

    if is_binary(id) and Map.has_key?(@tool_items, type) do
      attrs = %{status: item_status(field(item, :status)), meta: prune(output_of(item))}
      {[{:update, id, attrs}], state}
    else
      {[], state}
    end
  end

  # ── message content ───────────────────────────────────────────────────────

  defp handle("response.content_part.added", event, state) do
    id = content_id(event)
    part = field(event, :part) || %{}

    case field(part, :type) do
      "output_text" -> open(id, :text, seq(event), state, status: :streaming)
      "refusal" -> open(id, :refusal, seq(event), state, status: :streaming)
      _ -> {[], state}
    end
  end

  defp handle("response.output_text.delta", event, state),
    do: delta(content_id(event), :text, event, state)

  defp handle("response.output_text.done", event, state),
    do: done(content_id(event), :text, field(event, :text), event, state)

  defp handle("response.refusal.delta", event, state),
    do: delta(content_id(event), :refusal, event, state)

  defp handle("response.refusal.done", event, state),
    do: done(content_id(event), :refusal, field(event, :refusal), event, state)

  defp handle("response.output_text.annotation.added", event, state) do
    annotation = field(event, :annotation) || %{}
    id = "#{content_id(event)}:a#{field(event, :annotation_index)}"

    open(id, :source, seq(event), state,
      status: :complete,
      text: field(annotation, :title) || field(annotation, :url) || "",
      meta: prune(source_of(annotation))
    )
  end

  # ── reasoning ─────────────────────────────────────────────────────────────

  defp handle("response.reasoning_summary_part.added", event, state),
    do: open(summary_id(event), :reasoning, seq(event), state, status: :streaming)

  defp handle("response.reasoning_summary_text.delta", event, state),
    do: delta(summary_id(event), :reasoning, event, state)

  defp handle("response.reasoning_summary_text.done", event, state),
    do: done(summary_id(event), :reasoning, field(event, :text), event, state)

  defp handle("response.reasoning_text.delta", event, state),
    do: delta(reasoning_id(event), :reasoning, event, state)

  defp handle("response.reasoning_text.done", event, state),
    do: done(reasoning_id(event), :reasoning, field(event, :text), event, state)

  # ── tool input ────────────────────────────────────────────────────────────

  defp handle("response.function_call_arguments.delta", event, state),
    do: delta(field(event, :item_id), :tool_call, event, state)

  defp handle("response.function_call_arguments.done", event, state),
    do: input_done(event, field(event, :arguments), state)

  defp handle("response.mcp_call_arguments.delta", event, state),
    do: delta(field(event, :item_id), :tool_call, event, state)

  defp handle("response.mcp_call_arguments.done", event, state),
    do: input_done(event, field(event, :arguments), state)

  defp handle("response.custom_tool_call_input.delta", event, state),
    do: delta(field(event, :item_id), :tool_call, event, state)

  defp handle("response.custom_tool_call_input.done", event, state),
    do: input_done(event, field(event, :input), state)

  defp handle("response.code_interpreter_call_code.delta", event, state),
    do: delta(field(event, :item_id), :tool_call, event, state)

  defp handle("response.code_interpreter_call_code.done", event, state),
    do: input_done(event, field(event, :code), state)

  # ── built-in tool progress ────────────────────────────────────────────────

  # Every built-in tool reports progress under its own event prefix and the
  # same four suffixes. Matching the suffix covers the tools that exist and the
  # ones added after this was written.
  defp handle("response." <> rest, event, state) do
    case progress(rest) do
      nil -> {[], state}
      attrs -> {[{:update, field(event, :item_id), attrs}], state}
    end
  end

  defp handle(_type, _event, state), do: {[], state}

  defp progress(rest) do
    case String.split(rest, ".") do
      [call, phase] ->
        cond do
          not String.ends_with?(call, "_call") ->
            nil

          phase == "in_progress" ->
            %{status: :running}

          phase == "completed" ->
            %{status: :complete}

          phase == "failed" ->
            %{status: :error}

          phase in ~w(searching interpreting generating) ->
            %{status: :running, meta: %{phase: phase}}

          true ->
            nil
        end

      _ ->
        nil
    end
  end

  # ── operations ────────────────────────────────────────────────────────────

  defp open(id, type, seq, state, attrs) when is_binary(id) do
    attrs = attrs |> Map.new() |> Map.merge(%{type: type, seq: seq})
    {[{:open, id, attrs}], %{state | opened: MapSet.put(state.opened, id)}}
  end

  defp open(_id, _type, _seq, state, _attrs), do: {[], state}

  # The identity rule lives here: a delta for a part already announced returns
  # the state term it was given, so `assign/3` marks nothing changed.
  defp delta(id, type, event, state) when is_binary(id) do
    chunk = field(event, :delta) || ""

    if MapSet.member?(state.opened, id) do
      {[{:delta, id, chunk}], state}
    else
      {ops, state} = open(id, type, seq(event), state, status: :streaming)
      {ops ++ [{:delta, id, chunk}], state}
    end
  end

  defp delta(_id, _type, _event, state), do: {[], state}

  defp done(id, type, text, event, state) when is_binary(id) do
    {ops, state} =
      if MapSet.member?(state.opened, id),
        do: {[], state},
        else: open(id, type, seq(event), state, status: :streaming)

    {ops ++ [{:update, id, %{status: :complete, text: text || ""}}], state}
  end

  defp done(_id, _type, _text, _event, state), do: {[], state}

  # A tool's input is complete and the tool is now running. That is
  # `input-available` in AI Elements, which the badge reads as "Running".
  defp input_done(event, text, state) do
    id = field(event, :item_id)

    if is_binary(id),
      do: {[{:update, id, %{status: :running, text: text || ""}}], state},
      else: {[], state}
  end

  defp fail(error, seq, state) do
    {ops, state} =
      open("error:#{seq}", :error, seq, state,
        status: :error,
        text: field(error, :message) || "The turn failed.",
        meta: prune(%{code: field(error, :code)})
      )

    {ops ++ [{:finish, :error}], state}
  end

  # ── reading an event ──────────────────────────────────────────────────────

  defp content_id(event), do: index_id(event, "", field(event, :content_index))
  defp reasoning_id(event), do: index_id(event, "r", field(event, :content_index))
  defp summary_id(event), do: index_id(event, "s", field(event, :summary_index))

  defp index_id(event, prefix, index) do
    case field(event, :item_id) do
      id when is_binary(id) -> "#{id}:#{prefix}#{index || 0}"
      _ -> nil
    end
  end

  # A part sorts by the ordering number of the event that opened it. Without
  # one, the number of parts already open is the next position, which is the
  # same on every replay of the same stream.
  defp seq(event) do
    case field(event, :sequence_number) do
      n when is_integer(n) -> n
      _ -> 0
    end
  end

  defp tool_name(item, type) do
    field(item, :name) || field(item, :server_label) || Map.fetch!(@tool_items, type) || type
  end

  defp item_status("incomplete"), do: :incomplete
  defp item_status("failed"), do: :error
  defp item_status(_status), do: :complete

  defp output_of(item) do
    %{
      output: field(item, :output) || field(item, :result),
      results: field(item, :results),
      error: field(item, :error)
    }
  end

  defp source_of(annotation) do
    %{
      url: field(annotation, :url),
      title: field(annotation, :title),
      file_id: field(annotation, :file_id),
      filename: field(annotation, :filename),
      kind: field(annotation, :type)
    }
  end

  defp error_of(nil), do: %{}
  defp error_of(container), do: field(container, :error) || container
end
