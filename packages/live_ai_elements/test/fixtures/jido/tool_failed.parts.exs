[
  %LiveAiElements.Part{
    id: "call_1:thinking",
    type: :reasoning,
    status: :error,
    seq: 2,
    text: "",
    meta: %{}
  },
  %LiveAiElements.Part{
    id: "tc_1",
    type: :tool_call,
    status: :error,
    seq: 3,
    text: "",
    meta: %{
      input: %{path: "/missing"},
      output: {:error, :enoent},
      tool: "read_file"
    }
  },
  %LiveAiElements.Part{
    id: "error:5",
    type: :error,
    status: :error,
    seq: 5,
    text: "The tool could not read the file.",
    meta: %{code: :tool_error}
  }
]
