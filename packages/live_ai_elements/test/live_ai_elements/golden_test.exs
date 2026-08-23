defmodule LiveAiElements.GoldenTest do
  @moduledoc """
  The exit criterion for M4: a recorded Open Responses stream replays to the
  same part list every time.

  "Every time" is two claims, and each is a test below. The part list has to
  match a committed one, so a change to the reducer is visible. And replaying
  the same recording twice, and replaying it one event at a time against
  replaying it in one call, all have to agree — because a reducer that counts
  anything would not.
  """

  use ExUnit.Case, async: true

  alias LiveAiElements.Adapters.OpenResponses
  alias LiveAiElements.Golden
  alias LiveAiElements.Stream

  @fixtures ~w(open_responses/answer open_responses/interrupted open_responses/failed)

  for fixture <- @fixtures do
    test "#{fixture} replays to its golden part list" do
      {state, _patches} = Golden.replay(unquote(fixture), OpenResponses)
      parts = Stream.parts(state)

      assert Enum.map(parts, &Golden.encode/1) == Golden.expected(unquote(fixture), parts)
    end

    test "#{fixture} replays the same way twice" do
      {first, first_patches} = Golden.replay(unquote(fixture), OpenResponses)
      {second, second_patches} = Golden.replay(unquote(fixture), OpenResponses)

      assert Stream.parts(first) == Stream.parts(second)
      assert first_patches == second_patches
    end
  end

  test "the answer turn costs one DOM operation per part, plus one per token" do
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

  test "an event that repeats what is already known costs no patch" do
    # `response.web_search_call.completed` completes the tool. The
    # `response.output_item.done` that follows says the same thing, and a
    # second `stream_insert` for it would replace a node for nothing.
    {_state, patches} = Golden.replay("open_responses/answer", OpenResponses)

    assert Enum.count(patches, &match?({:set_state, %{id: "ws_1", status: :complete}}, &1)) == 1
  end

  test "the turn ends in the status the provider reported" do
    for {fixture, status} <- [
          {"open_responses/answer", :complete},
          {"open_responses/interrupted", :incomplete},
          {"open_responses/failed", :error}
        ] do
      {state, _patches} = Golden.replay(fixture, OpenResponses)
      assert state.status == status
    end
  end

  test "a part still open when the turn ends does not complete" do
    {state, _patches} = Golden.replay("open_responses/interrupted", OpenResponses)

    # The text was streaming and never got its own done event, so the server
    # never received the authoritative copy of it.
    assert %{status: :incomplete, text: ""} = Stream.get(state, "msg_2:0")
  end

  test "a failed turn keeps what the provider said went wrong" do
    {state, _patches} = Golden.replay("open_responses/failed", OpenResponses)

    assert %{type: :error, status: :error, text: "Rate limit reached."} =
             error = state |> Stream.parts() |> List.last()

    assert error.meta.code == "rate_limit_exceeded"
    assert %{status: :error} = Stream.get(state, "fc_3")
  end
end
