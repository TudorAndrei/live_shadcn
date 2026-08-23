[
  %LiveAiElements.Part{
    id: "call_1:thinking",
    type: :reasoning,
    status: :complete,
    seq: 3,
    text: "The reader is asking for a sum. Use the tool.",
    meta: %{}
  },
  %LiveAiElements.Part{
    id: "tc_1",
    type: :tool_call,
    status: :complete,
    seq: 6,
    text: "",
    meta: %{input: %{a: 19, b: 23}, output: %{sum: 42}, tool: "add"}
  },
  %LiveAiElements.Part{
    id: "call_2:thinking",
    type: :reasoning,
    status: :complete,
    seq: 9,
    text: "The tool answered 42.",
    meta: %{}
  },
  %LiveAiElements.Part{
    id: "call_2:content",
    type: :text,
    status: :complete,
    seq: 10,
    text: "19 + 23 is 42.",
    meta: %{}
  }
]
