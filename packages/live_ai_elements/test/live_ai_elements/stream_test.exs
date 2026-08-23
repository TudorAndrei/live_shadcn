defmodule LiveAiElements.StreamTest do
  use ExUnit.Case, async: true

  alias LiveAiElements.Part
  alias LiveAiElements.Stream

  defmodule Echo do
    @moduledoc "An adapter whose events are the operations, so a test can say exactly what arrives."
    @behaviour LiveAiElements.Adapter

    @impl true
    def init(_opts), do: :no_state

    @impl true
    def normalize(ops, state) when is_list(ops), do: {ops, state}
    def normalize(op, state), do: {[op], state}
  end

  defp new, do: Stream.new(adapter: Echo)

  defp opened(id \\ "a", type \\ :text, attrs \\ %{}) do
    {state, _patches} =
      Stream.reduce(new(), {:open, id, Map.merge(%{type: type, status: :streaming}, attrs)})

    state
  end

  describe "a delta never touches an assign" do
    test "an event carrying only a delta returns a state equal to the one given" do
      state = opened()

      {next, patches} = Stream.reduce(state, {:delta, "a", "token"})

      assert next == state
      assert patches == [{:append_delta, "a", "token"}]
    end

    test "and that holds for every token of a long part" do
      state = opened()

      next =
        Enum.reduce(1..500, state, fn n, acc ->
          {acc, _patches} = Stream.reduce(acc, {:delta, "a", "token #{n}"})
          acc
        end)

      # If anything were counted — a sequence number, a token tally — this is
      # where it would show. `assign/3` pin-matches, so equal is enough and
      # unequal is one render per token.
      assert next == state
    end

    test "a delta for a part nobody announced is dropped rather than buffered" do
      state = new()

      assert {^state, []} = Stream.reduce(state, {:delta, "ghost", "token"})
    end
  end

  describe "opening a part" do
    test "gives an insert patch carrying the whole part" do
      {state, patches} = Stream.reduce(new(), {:open, "a", %{type: :text, seq: 7}})

      assert [{:insert_part, %Part{id: "a", type: :text, seq: 7, status: :pending}}] = patches
      assert %Part{id: "a"} = Stream.get(state, "a")
    end

    test "twice does not throw away what arrived in between" do
      state = opened("a", :text)
      {state, _patches} = Stream.reduce(state, {:update, "a", %{text: "kept"}})

      {state, patches} = Stream.reduce(state, {:open, "a", %{type: :text, status: :streaming}})

      assert patches == []
      assert Stream.get(state, "a").text == "kept"
    end
  end

  describe "updating a part" do
    test "gives a set_state patch carrying the whole part" do
      state = opened()

      {_state, patches} = Stream.reduce(state, {:update, "a", %{status: :complete, text: "done"}})

      assert [{:set_state, %Part{id: "a", status: :complete, text: "done"}}] = patches
    end

    test "that changes nothing costs no patch" do
      state = opened("a", :text, %{status: :complete, text: "done"})

      assert {^state, []} = Stream.reduce(state, {:update, "a", %{status: :complete}})
    end

    test "nobody announced is dropped" do
      state = new()

      assert {^state, []} = Stream.reduce(state, {:update, "ghost", %{status: :complete}})
    end
  end

  describe "ending a turn" do
    test "closes every part still open" do
      state = opened("a", :text)
      {state, _patches} = Stream.reduce(state, {:open, "b", %{type: :reasoning, seq: 2}})

      {state, patches} = Stream.reduce(state, {:finish, :complete})

      assert state.status == :complete

      assert Enum.map(patches, fn {:set_state, part} -> {part.id, part.status} end) ==
               [{"a", :incomplete}, {"b", :incomplete}]
    end

    test "leaves a part that had already completed alone" do
      state = opened("a", :text, %{status: :complete})

      assert {%{status: :complete}, []} = Stream.reduce(state, {:finish, :complete})
    end

    test "marks open parts with the failure, not with incompleteness" do
      state = opened("a", :tool_call)

      {_state, patches} = Stream.reduce(state, {:finish, :error})

      assert [{:set_state, %Part{status: :error}}] = patches
    end
  end

  describe "ordering" do
    test "is the provider's ordering number, not the order events arrived" do
      {state, _patches} =
        Stream.reduce_all(new(), [
          {:open, "late", %{type: :text, seq: 9}},
          {:open, "early", %{type: :reasoning, seq: 2}}
        ])

      assert Enum.map(Stream.parts(state), & &1.id) == ["early", "late"]
    end

    test "breaks a tie on the id, so a replay cannot shuffle" do
      {state, _patches} =
        Stream.reduce_all(new(), [
          {:open, "b", %{type: :text, seq: 1}},
          {:open, "a", %{type: :text, seq: 1}}
        ])

      assert Enum.map(Stream.parts(state), & &1.id) == ["a", "b"]
    end
  end

  test "the hook and the server agree on one event name" do
    assert Stream.delta_event() == "live_ai_elements:delta"

    hook = File.read!(Path.expand("../../assets/js/delta.js", __DIR__))
    assert hook =~ ~s|DELTA_EVENT = "#{Stream.delta_event()}"|
  end
end
