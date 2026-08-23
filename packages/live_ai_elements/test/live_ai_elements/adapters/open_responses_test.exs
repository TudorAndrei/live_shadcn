defmodule LiveAiElements.Adapters.OpenResponsesTest do
  use ExUnit.Case, async: true

  alias LiveAiElements.Adapters.OpenResponses
  alias LiveAiElements.Stream

  defp new, do: Stream.new(adapter: OpenResponses)

  defp replay(events), do: Stream.reduce_all(new(), events)

  describe "events it does not model" do
    test "cost nothing and change nothing" do
      state = new()

      for event <- [
            %{"type" => "response.created", "response" => %{"id" => "r"}},
            %{"type" => "response.in_progress"},
            %{"type" => "response.queued"},
            %{"type" => "response.content_part.done", "item_id" => "m", "content_index" => 0},
            %{"type" => "response.image_generation_call.partial_image", "item_id" => "i"}
          ] do
        assert {^state, []} = Stream.reduce(state, event)
      end
    end

    test "include ones that do not exist yet" do
      # A provider adds event types. A conversation that crashes on the first
      # one is worse than one that ignores it.
      state = new()

      assert {^state, []} = Stream.reduce(state, %{"type" => "response.something.new"})
      assert {^state, []} = Stream.reduce(state, %{"type" => "not an event at all"})
      assert {^state, []} = Stream.reduce(state, %{})
      assert {^state, []} = Stream.reduce(state, "a bare string")
    end
  end

  test "reads a map with atom keys as readily as one with string keys" do
    atoms = [
      %{
        type: "response.content_part.added",
        sequence_number: 1,
        item_id: "msg",
        content_index: 0,
        part: %{type: "output_text"}
      },
      %{type: "response.output_text.delta", item_id: "msg", content_index: 0, delta: "hello"},
      %{type: "response.output_text.done", item_id: "msg", content_index: 0, text: "hello there"}
    ]

    {state, patches} = replay(atoms)

    assert %{id: "msg:0", type: :text, status: :complete, text: "hello there"} =
             Stream.get(state, "msg:0")

    assert Enum.any?(patches, &match?({:append_delta, "msg:0", "hello"}, &1))
  end

  describe "a delta whose part was never announced" do
    test "opens the part rather than losing the token" do
      {state, patches} =
        replay([
          %{
            "type" => "response.output_text.delta",
            "sequence_number" => 4,
            "item_id" => "msg",
            "content_index" => 0,
            "delta" => "joined late"
          }
        ])

      assert [{:insert_part, part}, {:append_delta, "msg:0", "joined late"}] = patches
      assert %{id: "msg:0", type: :text, status: :streaming, seq: 4} = part
      assert Stream.get(state, "msg:0")
    end

    test "only for the first token, so every one after it is still free" do
      events =
        for chunk <- ~w(one two three) do
          %{
            "type" => "response.output_text.delta",
            "item_id" => "m",
            "content_index" => 0,
            "delta" => chunk
          }
        end

      {opened, _patches} = Stream.reduce(new(), hd(events))
      {after_second, _patches} = Stream.reduce(opened, Enum.at(events, 1))

      assert after_second == opened
    end
  end

  describe "tool calls" do
    test "open on the item and stream their input" do
      {state, _patches} =
        replay([
          %{
            "type" => "response.output_item.added",
            "sequence_number" => 2,
            "item" => %{
              "id" => "fc",
              "type" => "function_call",
              "name" => "lookup",
              "call_id" => "c1"
            }
          },
          %{
            "type" => "response.function_call_arguments.delta",
            "item_id" => "fc",
            "delta" => "{}"
          },
          %{
            "type" => "response.function_call_arguments.done",
            "item_id" => "fc",
            "arguments" => "{\"q\":1}"
          }
        ])

      part = Stream.get(state, "fc")

      # `:running` is `input-available` in AI Elements, which the badge shows
      # as "Running": the input is complete and the tool has not answered.
      assert %{type: :tool_call, status: :running, text: "{\"q\":1}", seq: 2} = part
      assert part.meta == %{tool: "lookup", kind: "function_call", call_id: "c1"}
    end

    test "name themselves after the built-in tool when the item has no name" do
      {state, _patches} =
        replay([
          %{
            "type" => "response.output_item.added",
            "sequence_number" => 1,
            "item" => %{"id" => "fs", "type" => "file_search_call"}
          }
        ])

      assert Stream.get(state, "fs").meta.tool == "file_search"
    end

    test "report the phase a built-in tool is in" do
      {state, _patches} =
        replay([
          %{
            "type" => "response.output_item.added",
            "sequence_number" => 1,
            "item" => %{"id" => "ci", "type" => "code_interpreter_call"}
          },
          %{"type" => "response.code_interpreter_call.interpreting", "item_id" => "ci"},
          %{"type" => "response.code_interpreter_call.completed", "item_id" => "ci"}
        ])

      assert %{status: :complete, meta: %{phase: "interpreting"}} = Stream.get(state, "ci")
    end

    test "keep the output the finished item carried" do
      {state, _patches} =
        replay([
          %{
            "type" => "response.output_item.added",
            "sequence_number" => 1,
            "item" => %{"id" => "mcp", "type" => "mcp_call", "server_label" => "files"}
          },
          %{
            "type" => "response.output_item.done",
            "item" => %{
              "id" => "mcp",
              "type" => "mcp_call",
              "status" => "completed",
              "output" => "two files"
            }
          }
        ])

      assert %{status: :complete, meta: %{tool: "files", output: "two files"}} =
               Stream.get(state, "mcp")
    end

    test "fail when the item did" do
      {state, _patches} =
        replay([
          %{
            "type" => "response.output_item.added",
            "sequence_number" => 1,
            "item" => %{"id" => "fc", "type" => "function_call", "name" => "lookup"}
          },
          %{
            "type" => "response.output_item.done",
            "item" => %{
              "id" => "fc",
              "type" => "function_call",
              "status" => "failed",
              "error" => "no route"
            }
          }
        ])

      assert %{status: :error, meta: %{error: "no route"}} = Stream.get(state, "fc")
    end
  end

  describe "part identity" do
    test "separates the content parts of one item" do
      {state, _patches} =
        replay([
          content_added("msg", 0, 1),
          content_added("msg", 1, 2),
          %{
            "type" => "response.output_text.done",
            "item_id" => "msg",
            "content_index" => 0,
            "text" => "first"
          },
          %{
            "type" => "response.output_text.done",
            "item_id" => "msg",
            "content_index" => 1,
            "text" => "second"
          }
        ])

      assert Enum.map(Stream.parts(state), &{&1.id, &1.text}) ==
               [{"msg:0", "first"}, {"msg:1", "second"}]
    end

    test "separates a reasoning summary from reasoning text" do
      {state, _patches} =
        replay([
          %{
            "type" => "response.reasoning_summary_part.added",
            "sequence_number" => 1,
            "item_id" => "rs",
            "summary_index" => 0,
            "part" => %{"type" => "summary_text"}
          },
          %{
            "type" => "response.reasoning_text.delta",
            "sequence_number" => 2,
            "item_id" => "rs",
            "content_index" => 0,
            "delta" => "raw"
          }
        ])

      assert Enum.map(Stream.parts(state), & &1.id) == ["rs:s0", "rs:r0"]
      assert Enum.all?(Stream.parts(state), &(&1.type == :reasoning))
    end
  end

  test "a refusal is its own kind of part, not prose" do
    {state, _patches} =
      replay([
        %{
          "type" => "response.content_part.added",
          "sequence_number" => 1,
          "item_id" => "msg",
          "content_index" => 0,
          "part" => %{"type" => "refusal"}
        },
        %{
          "type" => "response.refusal.done",
          "item_id" => "msg",
          "content_index" => 0,
          "refusal" => "I cannot."
        }
      ])

    assert %{type: :refusal, status: :complete, text: "I cannot."} = Stream.get(state, "msg:0")
  end

  test "a top-level error event ends the turn with something a reader can read" do
    {state, _patches} =
      replay([
        %{
          "type" => "error",
          "sequence_number" => 2,
          "code" => "server_error",
          "message" => "Upstream is down."
        }
      ])

    assert state.status == :error

    assert [%{type: :error, text: "Upstream is down.", meta: %{code: "server_error"}}] =
             Stream.parts(state)
  end

  defp content_added(item, index, seq) do
    %{
      "type" => "response.content_part.added",
      "sequence_number" => seq,
      "item_id" => item,
      "content_index" => index,
      "part" => %{"type" => "output_text"}
    }
  end
end
