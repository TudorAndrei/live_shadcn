defmodule LiveAiElements.Adapters.JidoTest do
  use ExUnit.Case, async: true

  alias LiveAiElements.Adapters.Jido
  alias LiveAiElements.Stream

  defp new, do: Stream.new(adapter: Jido)

  defp replay(events), do: Stream.reduce_all(new(), events)

  defp delta(call, chunk_type, text, seq \\ 1) do
    %{seq: seq, kind: :llm_delta, llm_call_id: call, data: %{chunk_type: chunk_type, delta: text}}
  end

  describe "events it does not model" do
    test "cost nothing and change nothing" do
      state = new()

      for event <- [
            %{seq: 1, kind: :request_started, data: %{}},
            %{seq: 2, kind: :llm_started, llm_call_id: "c", data: %{model: "gpt-5"}},
            %{seq: 3, kind: :checkpoint, data: %{token: "rt2_abc"}},
            %{seq: 4, kind: :something_new, data: %{}},
            %{},
            "not an event"
          ] do
        assert {^state, []} = Stream.reduce(state, event)
      end
    end

    test "include a chunk type this package has no part for" do
      state = new()

      assert {^state, []} = Stream.reduce(state, delta("c", :audio, "..."))
    end
  end

  describe "a token" do
    test "opens its part on the first one and costs nothing after that" do
      {opened, patches} = Stream.reduce(new(), delta("c", :content, "one", 4))

      assert [{:insert_part, part}, {:append_delta, "c:content", "one"}] = patches
      assert %{id: "c:content", type: :text, status: :streaming, seq: 4} = part

      {next, patches} = Stream.reduce(opened, delta("c", :content, "two"))

      assert next == opened
      assert patches == [{:append_delta, "c:content", "two"}]
    end

    test "goes to the thinking part or the content part, never both" do
      {state, _patches} =
        replay([delta("c", :thinking, "why", 1), delta("c", :content, "because", 2)])

      assert Enum.map(Stream.parts(state), &{&1.id, &1.type}) ==
               [{"c:thinking", :reasoning}, {"c:content", :text}]
    end

    test "with no call id is dropped rather than pooled with another call's" do
      state = new()

      assert {^state, []} =
               Stream.reduce(state, %{
                 seq: 1,
                 kind: :llm_delta,
                 data: %{chunk_type: :content, delta: "x"}
               })
    end
  end

  describe "the end of an LLM call" do
    test "takes the authoritative copy of each text" do
      {state, _patches} =
        replay([
          delta("c", :thinking, "half a thought", 1),
          delta("c", :content, "half an answer", 2),
          %{
            seq: 3,
            kind: :llm_completed,
            llm_call_id: "c",
            data: %{text: "a whole answer", thinking_content: "a whole thought"}
          }
        ])

      assert %{status: :complete, text: "a whole thought"} = Stream.get(state, "c:thinking")
      assert %{status: :complete, text: "a whole answer"} = Stream.get(state, "c:content")
    end

    test "opens a part that never streamed, when there is text for it" do
      # A run may answer without streaming, and the answer still has to appear.
      {state, patches} =
        replay([
          %{seq: 1, kind: :llm_completed, llm_call_id: "c", data: %{text: "the answer"}}
        ])

      assert [{:insert_part, %{id: "c:content", status: :complete, text: "the answer"}}] = patches
      assert Stream.parts(state) |> length() == 1
    end

    test "puts no empty reasoning block on the page" do
      {state, _patches} =
        replay([
          %{
            seq: 1,
            kind: :llm_completed,
            llm_call_id: "c",
            data: %{text: "the answer", thinking_content: nil}
          }
        ])

      assert Enum.map(Stream.parts(state), & &1.id) == ["c:content"]
    end
  end

  describe "a tool" do
    test "starts running, because Jido does not stream its input" do
      {state, patches} =
        replay([
          %{
            seq: 2,
            kind: :tool_started,
            tool_call_id: "t",
            tool_name: "add",
            data: %{params: %{a: 1}}
          }
        ])

      assert [{:insert_part, %{status: :running}}] = patches

      assert %{type: :tool_call, text: "", meta: %{tool: "add", input: %{a: 1}}} =
               Stream.get(state, "t")
    end

    test "fails on an error tuple, because a Jido tool returns an Elixir result" do
      {state, _patches} =
        replay([
          %{seq: 1, kind: :tool_started, tool_call_id: "t", tool_name: "read", data: %{}},
          %{seq: 2, kind: :tool_completed, tool_call_id: "t", data: %{result: {:error, :enoent}}}
        ])

      assert %{status: :error, meta: %{output: {:error, :enoent}}} = Stream.get(state, "t")
    end
  end

  describe "the end of a run" do
    test "is the status the runtime reported" do
      for {kind, status} <- [
            {:request_completed, :complete},
            {:request_cancelled, :incomplete},
            {:request_failed, :error}
          ] do
        {state, _patches} = replay([%{seq: 1, kind: kind, data: %{error: "gone"}}])

        assert state.status == status
      end
    end

    test "says what failed, whether the error was a string or a term" do
      for {error, text} <- [
            {"plain words", "plain words"},
            {%{message: "a map with a message"}, "a map with a message"},
            {nil, "The run failed."}
          ] do
        {state, _patches} =
          replay([
            %{seq: 1, kind: :request_failed, data: %{error: error, error_type: :tool_error}}
          ])

        assert [%{type: :error, text: ^text, meta: %{code: :tool_error}}] = Stream.parts(state)
      end
    end
  end

  test "reads a kind that crossed a JSON boundary as a string" do
    {state, _patches} =
      replay([
        %{
          "seq" => 1,
          "kind" => "llm_delta",
          "llm_call_id" => "c",
          "data" => %{"chunk_type" => "content", "delta" => "hello"}
        },
        %{"seq" => 2, "kind" => "request_completed", "data" => %{}}
      ])

    assert %{id: "c:content", type: :text} = Stream.get(state, "c:content")
    assert state.status == :complete
  end

  test "converts no atom a recording did not already name" do
    # A stream is input. Reading a kind off it with String.to_atom/1 would let a
    # provider — or anything that can reach the socket — grow the atom table.
    before = :erlang.system_info(:atom_count)

    {state, []} = Stream.reduce(new(), %{"kind" => "a_kind_that_was_never_compiled", "seq" => 1})

    assert state == new()
    assert :erlang.system_info(:atom_count) == before
  end
end
