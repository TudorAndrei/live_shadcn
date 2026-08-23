[
  %LiveAiElements.Part{
    id: "rs_1:s0",
    type: :reasoning,
    status: :complete,
    seq: 3,
    text: "The reader wants today's weather.",
    meta: %{}
  },
  %LiveAiElements.Part{
    id: "ws_1",
    type: :tool_call,
    status: :complete,
    seq: 9,
    text: "",
    meta: %{kind: "web_search_call", phase: "searching", tool: "web_search"}
  },
  %LiveAiElements.Part{
    id: "msg_1:0",
    type: :text,
    status: :complete,
    seq: 15,
    text: "It is 18°C and clear in Cluj.",
    meta: %{}
  },
  %LiveAiElements.Part{
    id: "msg_1:0:a0",
    type: :source,
    status: :complete,
    seq: 18,
    text: "Cluj weather",
    meta: %{
      title: "Cluj weather",
      kind: "url_citation",
      url: "https://example.com/cluj"
    }
  },
  %LiveAiElements.Part{
    id: "fc_1",
    type: :tool_call,
    status: :complete,
    seq: 22,
    text: "{\"text\":\"clear\"}",
    meta: %{kind: "function_call", tool: "save_note", call_id: "call_1"}
  }
]
