defmodule LiveAiElements.Adapters.Jido do
  @moduledoc """
  The second adapter: Jido's ReAct runtime.

  It was written second on purpose. One adapter proves a provider can be read;
  two prove the boundary is in the right place, and only if the second one is
  shaped differently enough to have argued for moving it.

  Jido is `%Jido.AI.Reasoning.ReAct.Event{}` values off `ReAct.stream/2` or
  `ask_stream/3`. This module names no Jido module and adds no dependency: it
  reads `kind`, `seq`, `data`, `llm_call_id`, `tool_call_id` and `tool_name`
  off a plain map, which is what a struct is.

  ## Events it models

  | Kind | What it does |
  |---|---|
  | `:llm_delta` | streams a token into the content or the thinking part |
  | `:llm_completed` | completes both with the text the runtime assembled |
  | `:tool_started` | opens a tool call, already running |
  | `:tool_completed` | completes it with its result |
  | `:request_completed` | ends the turn |
  | `:request_failed` | opens an error part and ends the turn |
  | `:request_cancelled` | ends the turn as incomplete |

  `:request_started`, `:llm_started` and `:checkpoint` change nothing a reader
  sees, so they produce nothing.

  ## What was different, and what it cost

  Three things, and none of them moved the boundary:

  **Identity is per call, not per content part.** Open Responses gives every
  content part an index inside its item. Jido gives one id per LLM call and
  sorts a token by `data.chunk_type` instead. So the part id is the call id and
  the chunk type — `"call_1:content"`, `"call_1:thinking"` — which is still
  derived from what the provider sent and still the same on a replay.

  **The kind of a part arrives with its first token.** A ReAct run does not
  announce that it is about to think. So the first `:llm_delta` of each chunk
  type opens its part, using the path that already exists for a provider that
  skips an announcement. Every token after the first is free, which is what the
  rule requires.

  **A tool's input does not stream.** Open Responses streams a tool's arguments
  as a JSON string, so they are the part's `text`. Jido hands the whole
  `params` map at `:tool_started`, so they are `meta.input` and `text` stays
  empty. A part records what a provider gave it; neither adapter invents the
  other's shape. `LiveAiElements.Part` says which is which.

  ## Interleaving

  A ReAct run is a loop: think, call a tool, think again. Each pass is a new
  LLM call with a new id, so each pass gets its own parts and they sort by the
  `seq` the runtime stamped. A reader sees the loop in the order it ran.
  """

  @behaviour LiveAiElements.Adapter

  import LiveAiElements.Adapter, only: [field: 2, prune: 1]

  # `data.chunk_type` sorts a token into a part. `:content` is the answer and
  # `:thinking` is the reasoning behind it, and they arrive interleaved.
  @chunks %{content: :text, thinking: :reasoning}

  # Every name this module answers to. A recorded event that crossed a JSON
  # boundary carries its kind as a string, and matching against this list is
  # what converts it back without letting a stream grow atoms on the node.
  @names Map.keys(@chunks) ++
           ~w(llm_delta llm_completed tool_started tool_completed
              request_completed request_failed request_cancelled
              request_started llm_started checkpoint)a

  @impl true
  def init(_opts), do: %{opened: MapSet.new()}

  @impl true
  def normalize(event, state) do
    handle(kind(event), event, state)
  end

  defp handle(:llm_delta, event, state) do
    data = field(event, :data) || %{}

    case chunk(field(data, :chunk_type)) do
      nil ->
        {[], state}

      type ->
        delta(part_id(event, field(data, :chunk_type)), type, field(data, :delta), event, state)
    end
  end

  defp handle(:llm_completed, event, state) do
    data = field(event, :data) || %{}

    # The runtime assembled both texts while the tokens went to the browser, so
    # this is where the server takes its authoritative copy of each.
    {ops, state} = complete(event, state, :content, :text, field(data, :text))
    {more, state} = complete(event, state, :thinking, :reasoning, field(data, :thinking_content))

    {ops ++ more, state}
  end

  defp handle(:tool_started, event, state) do
    data = field(event, :data) || %{}

    # A tool Jido has started is already running: there is no arguments stream
    # to wait through, so it never passes through `:streaming`.
    open(tool_id(event), :tool_call, seq(event), state,
      status: :running,
      meta: prune(%{tool: tool_name(event, data), input: field(data, :params)})
    )
  end

  defp handle(:tool_completed, event, state) do
    data = field(event, :data) || %{}
    result = field(data, :result)

    attrs = %{status: status_of(result), meta: prune(%{output: result})}
    update(tool_id(event), attrs, state)
  end

  defp handle(:request_completed, _event, state), do: {[{:finish, :complete}], state}
  defp handle(:request_cancelled, _event, state), do: {[{:finish, :incomplete}], state}

  defp handle(:request_failed, event, state) do
    data = field(event, :data) || %{}

    {ops, state} =
      open("error:#{seq(event)}", :error, seq(event), state,
        status: :error,
        text: message(field(data, :error)),
        meta: prune(%{code: field(data, :error_type)})
      )

    {ops ++ [{:finish, :error}], state}
  end

  defp handle(_kind, _event, state), do: {[], state}

  # ── operations ────────────────────────────────────────────────────────────

  defp open(id, type, seq, state, attrs) when is_binary(id) do
    attrs = attrs |> Map.new() |> Map.merge(%{type: type, seq: seq})
    {[{:open, id, attrs}], %{state | opened: MapSet.put(state.opened, id)}}
  end

  defp open(_id, _type, _seq, state, _attrs), do: {[], state}

  defp update(id, attrs, state) when is_binary(id), do: {[{:update, id, attrs}], state}
  defp update(_id, _attrs, state), do: {[], state}

  # The state comes back untouched for every token but the first of a part.
  defp delta(id, type, chunk, event, state) when is_binary(id) and is_binary(chunk) do
    if MapSet.member?(state.opened, id) do
      {[{:delta, id, chunk}], state}
    else
      {ops, state} = open(id, type, seq(event), state, status: :streaming)
      {ops ++ [{:delta, id, chunk}], state}
    end
  end

  defp delta(_id, _type, _chunk, _event, state), do: {[], state}

  # A part nothing streamed into does not exist, and completing it would put an
  # empty reasoning block on the page for every answer that needed no thinking.
  defp complete(event, state, chunk_type, type, text) do
    id = part_id(event, chunk_type)

    cond do
      not is_binary(text) or text == "" ->
        {[], state}

      MapSet.member?(state.opened, id) ->
        {[{:update, id, %{status: :complete, text: text}}], state}

      true ->
        open(id, type, seq(event), state, status: :complete, text: text)
    end
  end

  # ── reading an event ──────────────────────────────────────────────────────

  defp kind(event) do
    case field(event, :kind) do
      kind when is_atom(kind) -> kind
      kind when is_binary(kind) -> chunk_atom(kind)
      _ -> nil
    end
  end

  defp chunk(type) when is_atom(type), do: Map.get(@chunks, type)
  defp chunk(type) when is_binary(type), do: chunk(chunk_atom(type))
  defp chunk(_type), do: nil

  defp chunk_atom(name), do: Enum.find(@names, &(Atom.to_string(&1) == name))

  defp part_id(event, chunk_type) do
    case field(event, :llm_call_id) do
      id when is_binary(id) -> "#{id}:#{chunk_type}"
      _ -> nil
    end
  end

  defp tool_id(event) do
    case field(event, :tool_call_id) do
      id when is_binary(id) -> id
      _ -> nil
    end
  end

  defp tool_name(event, data), do: field(event, :tool_name) || field(data, :tool_name)

  defp seq(event) do
    case field(event, :seq) do
      n when is_integer(n) -> n
      _ -> 0
    end
  end

  # A ReAct tool returns an ordinary Elixir result, so failure is a tuple and
  # not a status string.
  defp status_of({:error, _reason}), do: :error
  defp status_of(_result), do: :complete

  defp message(error) when is_binary(error), do: error
  defp message(nil), do: "The run failed."
  defp message(error), do: field(error, :message) || inspect(error)
end
