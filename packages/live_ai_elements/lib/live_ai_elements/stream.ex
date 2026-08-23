defmodule LiveAiElements.Stream do
  @moduledoc """
  The reducer: provider events in, ordered parts and DOM patches out.

  This is the product. The components draw what it produces.

      state = LiveAiElements.Stream.new(adapter: LiveAiElements.Adapters.OpenResponses)
      {state, patches} = LiveAiElements.Stream.reduce(state, event)

  `reduce/2` is pure. The same state and the same event give the same result on
  every run, which is what makes a recorded stream a test rather than a demo.

  ## The three patches

  A patch is what the LiveView does next, and nothing more:

      {:insert_part, %LiveAiElements.Part{}}   a part appeared
      {:append_delta, id, chunk}               text arrived for a part
      {:set_state, %LiveAiElements.Part{}}     a part changed

  Both patches that carry a part carry the whole part, so the LiveView never
  reaches back into this state to render one.

  ## In a LiveView

      def handle_info({:ai_event, event}, socket) do
        {state, patches} = LiveAiElements.Stream.reduce(socket.assigns.ai, event)
        {:noreply, socket |> assign(:ai, state) |> apply_patches(patches)}
      end

      defp apply_patches(socket, patches) do
        Enum.reduce(patches, socket, fn
          {:insert_part, part}, socket -> stream_insert(socket, :parts, part)
          {:set_state, part}, socket -> stream_insert(socket, :parts, part)
          {:append_delta, id, chunk}, socket ->
            push_event(socket, LiveAiElements.Stream.delta_event(), %{id: id, chunk: chunk})
        end)
      end

  ## A delta never touches an assign

  This is the rule the whole design is built to keep, and it is enforced here
  rather than asked for in prose: **an event that carries only a delta returns
  a state equal to the one it was given.**

  `Phoenix.Component.assign/3` pin-matches the new value against the old one and
  returns the socket untouched when they match. So `assign(:ai, state)` after a
  delta marks nothing changed, no `render/1` runs, and the token reaches the
  browser as one `push_event` handled by the `LiveAiElements.Delta` hook.

  Keeping the rule means counting nothing. A sequence number remembered, a
  token tally, a "last event" field — any of them makes every delta a changed
  assign and a render, and none of them announces itself. So the reducer holds
  no per-event bookkeeping, and adapters return the state they were given for a
  delta rather than rebuilding it. `LiveAiElements.StreamTest` checks that,
  because a comment cannot.

  What this buys, and what it costs, is written out in `LiveAiElements.Part`
  under "Text arrives twice".

  ## Ordering

  Parts sort by `seq`, the provider's own ordering number when the part opened.
  Sorting rather than trusting arrival order matters because a provider may
  interleave two items — a tool call announced while a message is still
  streaming — and a reader expects them in the order the model produced them,
  not the order the socket delivered them.

  Ties break on `id`, so the order is total and a replay cannot shuffle.
  """

  alias LiveAiElements.Part

  @delta_event "live_ai_elements:delta"

  @type patch ::
          {:insert_part, Part.t()}
          | {:append_delta, String.t(), String.t()}
          | {:set_state, Part.t()}

  @type t :: %__MODULE__{
          adapter: module(),
          adapter_state: term(),
          parts: %{String.t() => Part.t()},
          order: [String.t()],
          status: Part.status()
        }

  @enforce_keys [:adapter]
  defstruct [:adapter, :adapter_state, parts: %{}, order: [], status: :pending]

  @doc """
  The `push_event/3` name the `LiveAiElements.Delta` client hook listens for.

  Server and hook have to agree on one string. It is defined here so neither
  side can be edited without the other failing a test.
  """
  @spec delta_event() :: String.t()
  def delta_event, do: @delta_event

  @doc """
  Starts a turn.

  ## Options

    * `:adapter` — required, a module implementing `LiveAiElements.Adapter`
    * `:adapter_opts` — passed to the adapter's `c:LiveAiElements.Adapter.init/1`
  """
  @spec new(keyword()) :: t()
  def new(opts) do
    adapter = Keyword.fetch!(opts, :adapter)

    %__MODULE__{
      adapter: adapter,
      adapter_state: adapter.init(Keyword.get(opts, :adapter_opts, []))
    }
  end

  @doc """
  Reads one provider event.

  Returns the new state and the patches the LiveView applies. Returns a state
  equal to the one it was given when the event carried only a delta — see "A
  delta never touches an assign".
  """
  @spec reduce(t(), term()) :: {t(), [patch()]}
  def reduce(%__MODULE__{} = state, event) do
    {ops, adapter_state} = state.adapter.normalize(event, state.adapter_state)

    state
    |> put_adapter_state(adapter_state)
    |> apply_ops(ops)
  end

  @doc """
  Reads a whole recorded stream.

  Returns the final state and every patch in order, which is what a golden test
  compares.
  """
  @spec reduce_all(t(), Enumerable.t()) :: {t(), [patch()]}
  def reduce_all(%__MODULE__{} = state, events) do
    {state, patches} =
      Enum.reduce(events, {state, []}, fn event, {state, acc} ->
        {state, patches} = reduce(state, event)
        {state, [patches | acc]}
      end)

    {state, acc_to_list(patches)}
  end

  @doc """
  The parts, in the order a reader sees them.
  """
  @spec parts(t()) :: [Part.t()]
  def parts(%__MODULE__{parts: parts}) do
    parts |> Map.values() |> Enum.sort_by(&{&1.seq, &1.id})
  end

  @doc """
  One part by id, or `nil`.
  """
  @spec get(t(), String.t()) :: Part.t() | nil
  def get(%__MODULE__{parts: parts}, id), do: Map.get(parts, id)

  # ── operations ────────────────────────────────────────────────────────────

  # Rebuilding the struct around an adapter state that did not move costs a
  # copy for nothing, on the one path that has to stay free. So compare first.
  defp put_adapter_state(state, adapter_state) do
    if adapter_state === state.adapter_state,
      do: state,
      else: %{state | adapter_state: adapter_state}
  end

  defp apply_ops(state, ops) do
    {state, patches} = Enum.reduce(ops, {state, []}, &apply_op/2)
    {state, Enum.reverse(patches)}
  end

  defp apply_op({:open, id, attrs}, {state, patches}) do
    case Map.fetch(state.parts, id) do
      # A provider may announce a part it already announced. Reopening it would
      # throw away everything that arrived in between.
      {:ok, _part} -> apply_op({:update, id, attrs}, {state, patches})
      :error -> insert(state, patches, build(id, attrs))
    end
  end

  defp apply_op({:delta, id, chunk}, {state, patches}) do
    # Deliberately no state change. See "A delta never touches an assign".
    if Map.has_key?(state.parts, id),
      do: {state, [{:append_delta, id, chunk} | patches]},
      else: {state, patches}
  end

  defp apply_op({:update, id, attrs}, {state, patches}) do
    with {:ok, part} <- Map.fetch(state.parts, id),
         updated = Part.update(part, attrs),
         false <- updated == part do
      {%{state | parts: Map.put(state.parts, id, updated)}, [{:set_state, updated} | patches]}
    else
      # Either no such part, or the event told us nothing we did not know. An
      # event that changes nothing must not cost a DOM patch.
      _ -> {state, patches}
    end
  end

  defp apply_op({:finish, status}, {state, patches}) do
    state.order
    |> Enum.reverse()
    |> Enum.reduce({%{state | status: status}, patches}, fn id, acc ->
      apply_op({:update, id, %{status: closing(status)}}, acc)
    end)
  end

  # A part that never got its own terminal event did not complete, whatever the
  # turn as a whole did. `Part.update/2` drops this for parts already terminal.
  defp closing(:complete), do: :incomplete
  defp closing(status), do: status

  defp build(id, attrs) do
    Part.new(id, Map.fetch!(attrs, :type),
      status: Map.get(attrs, :status, :pending),
      seq: Map.get(attrs, :seq, 0),
      text: Map.get(attrs, :text, ""),
      meta: Map.get(attrs, :meta, %{})
    )
  end

  # `order` is newest first, so an insert is a prepend. Nothing reads it in
  # order except the close at the end of a turn, which reverses it once.
  defp insert(state, patches, part) do
    state = %{state | parts: Map.put(state.parts, part.id, part), order: [part.id | state.order]}
    {state, [{:insert_part, part} | patches]}
  end

  defp acc_to_list(reversed_chunks), do: reversed_chunks |> Enum.reverse() |> List.flatten()
end
