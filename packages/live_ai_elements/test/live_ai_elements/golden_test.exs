defmodule LiveAiElements.GoldenTest do
  @moduledoc """
  The exit criterion for M4: a recorded Open Responses stream replays to the
  same part list every time.

  "Every time" is two claims, and each is a test below. The part list has to
  match a committed one, so a change to the reducer is visible in a diff. And
  replaying the same recording twice has to agree with itself — which a reducer
  that counted anything, or that keyed a part on a position rather than on
  something the provider sent, would not.

  Jido's recordings are here for a third reason. The reducer must produce the
  same kind of part list out of a provider shaped nothing like the first one,
  and if reading Jido had needed a fifth operation or a sixth part field, this
  is the file that would have said so.
  """

  use ExUnit.Case, async: true

  alias LiveAiElements.Adapters.Jido
  alias LiveAiElements.Adapters.OpenResponses
  alias LiveAiElements.Golden
  alias LiveAiElements.Stream

  @recordings [
    {"open_responses/answer", OpenResponses},
    {"open_responses/interrupted", OpenResponses},
    {"open_responses/failed", OpenResponses},
    {"jido/react_loop", Jido},
    {"jido/tool_failed", Jido}
  ]

  for {fixture, adapter} <- @recordings do
    test "#{fixture} replays to its golden part list" do
      {state, _patches} = Golden.replay(unquote(fixture), unquote(adapter))
      parts = Stream.parts(state)

      assert parts == Golden.expected(unquote(fixture), parts)
    end

    test "#{fixture} replays the same way twice" do
      {first, first_patches} = Golden.replay(unquote(fixture), unquote(adapter))
      {second, second_patches} = Golden.replay(unquote(fixture), unquote(adapter))

      assert Stream.parts(first) == Stream.parts(second)
      assert first_patches == second_patches
    end
  end

  describe "an Open Responses turn" do
    test "costs one DOM operation per part, plus one per token" do
      {_state, patches} = Golden.replay("open_responses/answer", OpenResponses)

      assert Enum.map(patches, &Golden.summarize/1) == [
               "insert rs_1:s0",
               "delta rs_1:s0",
               "delta rs_1:s0",
               "set rs_1:s0 complete",
               "insert ws_1",
               # Twice: the tool started, and then it reported which phase it is
               # in. The status is the same and `meta.phase` is not, and what a
               # reader is shown is the phase.
               "set ws_1 running",
               "set ws_1 running",
               "set ws_1 complete",
               "insert msg_1:0",
               "delta msg_1:0",
               "delta msg_1:0",
               "insert msg_1:0:a0",
               "set msg_1:0 complete",
               "insert fc_1",
               "delta fc_1",
               "delta fc_1",
               "set fc_1 running",
               "set fc_1 complete"
             ]
    end

    test "spends no patch on an event that repeats what is already known" do
      # `response.web_search_call.completed` completes the tool. The
      # `response.output_item.done` that follows says the same thing, and a
      # second `stream_insert` for it would replace a node for nothing.
      {_state, patches} = Golden.replay("open_responses/answer", OpenResponses)

      assert Enum.count(patches, &match?({:set_state, %{id: "ws_1", status: :complete}}, &1)) == 1
    end

    test "leaves a part still open at the end incomplete, and empty" do
      {state, _patches} = Golden.replay("open_responses/interrupted", OpenResponses)

      # The text was streaming and never got its own done event, so the server
      # never received the authoritative copy of it.
      assert %{status: :incomplete, text: ""} = Stream.get(state, "msg_2:0")
    end

    test "keeps what the provider said went wrong" do
      {state, _patches} = Golden.replay("open_responses/failed", OpenResponses)

      assert %{type: :error, status: :error, text: "Rate limit reached."} =
               error = state |> Stream.parts() |> List.last()

      assert error.meta.code == "rate_limit_exceeded"
      assert %{status: :error} = Stream.get(state, "fc_3")
    end
  end

  describe "a Jido ReAct run" do
    test "gives each pass of the loop its own parts, in the order it ran" do
      {state, _patches} = Golden.replay("jido/react_loop", Jido)

      assert Enum.map(Stream.parts(state), &{&1.id, &1.type}) == [
               {"call_1:thinking", :reasoning},
               {"tc_1", :tool_call},
               {"call_2:thinking", :reasoning},
               {"call_2:content", :text}
             ]
    end

    test "opens a part on its first token, because nothing announces one" do
      {_state, patches} = Golden.replay("jido/react_loop", Jido)

      assert Enum.map(patches, &Golden.summarize/1) == [
               "insert call_1:thinking",
               "delta call_1:thinking",
               "delta call_1:thinking",
               "set call_1:thinking complete",
               "insert tc_1",
               "set tc_1 complete",
               "insert call_2:thinking",
               "delta call_2:thinking",
               "insert call_2:content",
               "delta call_2:content",
               "delta call_2:content",
               "set call_2:content complete",
               "set call_2:thinking complete"
             ]
    end

    test "starts a tool already running, because its input did not stream" do
      {state, _patches} = Golden.replay("jido/react_loop", Jido)

      assert %{type: :tool_call, status: :complete, text: ""} = tool = Stream.get(state, "tc_1")
      assert tool.meta == %{tool: "add", input: %{a: 19, b: 23}, output: %{sum: 42}}
    end

    test "reads a tool's failure out of the ordinary Elixir result it returns" do
      {state, _patches} = Golden.replay("jido/tool_failed", Jido)

      assert %{status: :error, meta: %{output: {:error, :enoent}}} = Stream.get(state, "tc_1")
    end
  end

  test "a turn ends in the status the provider reported" do
    for {fixture, adapter, status} <- [
          {"open_responses/answer", OpenResponses, :complete},
          {"open_responses/interrupted", OpenResponses, :incomplete},
          {"open_responses/failed", OpenResponses, :error},
          {"jido/react_loop", Jido, :complete},
          {"jido/tool_failed", Jido, :error}
        ] do
      {state, _patches} = Golden.replay(fixture, adapter)
      assert state.status == status, "#{fixture} ended #{state.status}, not #{status}"
    end
  end
end
