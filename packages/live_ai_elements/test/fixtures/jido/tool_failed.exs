# A recorded Jido ReAct run whose tool failed and whose request failed with it.
[
  %{seq: 1, iteration: 1, kind: :request_started, data: %{}},
  %{
    seq: 2,
    iteration: 1,
    kind: :llm_delta,
    llm_call_id: "call_1",
    data: %{chunk_type: :thinking, delta: "Fetch the file."}
  },
  %{
    seq: 3,
    iteration: 1,
    kind: :tool_started,
    tool_call_id: "tc_1",
    tool_name: "read_file",
    data: %{tool_name: "read_file", params: %{path: "/missing"}}
  },
  %{
    seq: 4,
    iteration: 1,
    kind: :tool_completed,
    tool_call_id: "tc_1",
    tool_name: "read_file",
    data: %{tool_call_id: "tc_1", tool_name: "read_file", result: {:error, :enoent}}
  },
  %{
    seq: 5,
    iteration: 1,
    kind: :request_failed,
    data: %{error: "The tool could not read the file.", error_type: :tool_error}
  }
]
