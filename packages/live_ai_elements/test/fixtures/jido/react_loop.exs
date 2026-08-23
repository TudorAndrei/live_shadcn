# A recorded Jido ReAct run: think, call a tool, think again, answer.
#
# The events are plain maps rather than `%Jido.AI.Reasoning.ReAct.Event{}`
# structs, because this package must not depend on Jido to read Jido. A struct
# is a map with one extra key, and the adapter reads neither the key nor the
# module.
[
  %{seq: 1, iteration: 1, kind: :request_started, data: %{}},
  %{
    seq: 2,
    iteration: 1,
    kind: :llm_started,
    llm_call_id: "call_1",
    data: %{call_id: "call_1", model: "gpt-5", message_count: 2}
  },
  %{
    seq: 3,
    iteration: 1,
    kind: :llm_delta,
    llm_call_id: "call_1",
    data: %{chunk_type: :thinking, delta: "The reader is asking "}
  },
  %{
    seq: 4,
    iteration: 1,
    kind: :llm_delta,
    llm_call_id: "call_1",
    data: %{chunk_type: :thinking, delta: "for a sum. Use the tool."}
  },
  %{
    seq: 5,
    iteration: 1,
    kind: :llm_completed,
    llm_call_id: "call_1",
    data: %{
      call_id: "call_1",
      turn_type: :tool_calls,
      text: nil,
      thinking_content: "The reader is asking for a sum. Use the tool.",
      tool_calls: [%{id: "tc_1", name: "add"}],
      usage: %{input_tokens: 42, output_tokens: 11}
    }
  },
  %{
    seq: 6,
    iteration: 1,
    kind: :tool_started,
    tool_call_id: "tc_1",
    tool_name: "add",
    data: %{tool_name: "add", params: %{a: 19, b: 23}}
  },
  %{
    seq: 7,
    iteration: 1,
    kind: :tool_completed,
    tool_call_id: "tc_1",
    tool_name: "add",
    data: %{tool_call_id: "tc_1", tool_name: "add", result: %{sum: 42}}
  },
  %{
    seq: 8,
    iteration: 2,
    kind: :llm_started,
    llm_call_id: "call_2",
    data: %{call_id: "call_2", model: "gpt-5", message_count: 4}
  },
  %{
    seq: 9,
    iteration: 2,
    kind: :llm_delta,
    llm_call_id: "call_2",
    data: %{chunk_type: :thinking, delta: "The tool answered 42."}
  },
  %{
    seq: 10,
    iteration: 2,
    kind: :llm_delta,
    llm_call_id: "call_2",
    data: %{chunk_type: :content, delta: "19 + 23 "}
  },
  %{
    seq: 11,
    iteration: 2,
    kind: :llm_delta,
    llm_call_id: "call_2",
    data: %{chunk_type: :content, delta: "is 42."}
  },
  %{
    seq: 12,
    iteration: 2,
    kind: :llm_completed,
    llm_call_id: "call_2",
    data: %{
      call_id: "call_2",
      turn_type: :final_answer,
      text: "19 + 23 is 42.",
      thinking_content: "The tool answered 42.",
      tool_calls: [],
      usage: %{input_tokens: 88, output_tokens: 9}
    }
  },
  %{seq: 13, iteration: 2, kind: :checkpoint, data: %{token: "rt2_abc"}},
  %{
    seq: 14,
    iteration: 2,
    kind: :request_completed,
    data: %{
      result: "19 + 23 is 42.",
      termination_reason: :final_answer,
      usage: %{input_tokens: 130, output_tokens: 20}
    }
  }
]
