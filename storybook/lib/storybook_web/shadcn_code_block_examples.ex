defmodule StorybookWeb.ShadcnCodeBlockExamples do
  @moduledoc "Native examples of the pinned shadcn Code Block parts."
  use Phoenix.Component
  alias LiveShadcn.UI.{Bubble, Button, CodeBlock, Message, Tabs, Trace}

  @chat_route_lines [
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "import",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " { streamText } ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "from",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "\"ai\"",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
        }
      ]
    },
    %{"variant" => "default", "class" => nil, "tokens" => []},
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "export",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "async",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "function",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "POST",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "(",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "request",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#E36209;--shiki-dark:#FFAB70"
        },
        %{
          "text" => ":",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "Request",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => ") {",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "  ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "const",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " { ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "messages",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
        },
        %{
          "text" => " } ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "=",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "await",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " request.",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "json",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "()",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{"variant" => "default", "class" => nil, "tokens" => []},
    %{
      "variant" => "highlighted",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "  ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "const",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "result",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "=",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "streamText",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "({",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "highlighted",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "    model: ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "\"anthropic/claude-sonnet-4.5\"",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
        },
        %{
          "text" => ",",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "highlighted",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "    system: ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "\"You are a helpful assistant. Answer in one short paragraph.\"",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
        },
        %{
          "text" => ",",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "highlighted",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "    messages,",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "highlighted",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "  })",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{"variant" => "default", "class" => nil, "tokens" => []},
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "  ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "return",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " result.",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "toUIMessageStreamResponse",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "()",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "}",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    }
  ]

  @chat_component_lines [
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "\"use client\"",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
        }
      ]
    },
    %{"variant" => "default", "class" => nil, "tokens" => []},
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "import",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "*",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "as",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " React ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "from",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "\"react\"",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "import",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " { useChat } ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "from",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "\"@ai-sdk/react\"",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
        }
      ]
    },
    %{"variant" => "default", "class" => nil, "tokens" => []},
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "import",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " { Button } ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "from",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "\"@/components/ui/button\"",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "import",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " { Input } ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "from",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "\"@/components/ui/input\"",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
        }
      ]
    },
    %{"variant" => "default", "class" => nil, "tokens" => []},
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "export",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "function",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "Chat",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "() {",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "  ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "const",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " [",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "input",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
        },
        %{
          "text" => ", ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "setInput",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
        },
        %{
          "text" => "] ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "=",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " React.",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "useState",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "(",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "\"\"",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
        },
        %{
          "text" => ")",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "  ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "const",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " { ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "messages",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
        },
        %{
          "text" => ", ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "sendMessage",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
        },
        %{
          "text" => ", ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "status",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
        },
        %{
          "text" => " } ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "=",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "useChat",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "()",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{"variant" => "default", "class" => nil, "tokens" => []},
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "  ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "return",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " (",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "    <",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "div",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#22863A;--shiki-dark:#85E89D"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "className",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "=",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => "\"flex flex-col gap-4\"",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
        },
        %{
          "text" => ">",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "      {messages.",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "map",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "((",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "message",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#E36209;--shiki-dark:#FFAB70"
        },
        %{
          "text" => ") ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "=>",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " (",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "        <",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "div",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#22863A;--shiki-dark:#85E89D"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "key",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "=",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => "{message.id}>",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "          {message.parts.",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "map",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "((",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "part",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#E36209;--shiki-dark:#FFAB70"
        },
        %{
          "text" => ", ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "index",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#E36209;--shiki-dark:#FFAB70"
        },
        %{
          "text" => ") ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "=>",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "            part.type ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "===",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "\"text\"",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "?",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " <",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "p",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#22863A;--shiki-dark:#85E89D"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "key",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "=",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => "{index}>{part.text}</",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "p",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#22863A;--shiki-dark:#85E89D"
        },
        %{
          "text" => "> ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => ":",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "null",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "          )}",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "        </",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "div",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#22863A;--shiki-dark:#85E89D"
        },
        %{
          "text" => ">",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "      ))}",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "      <",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "form",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#22863A;--shiki-dark:#85E89D"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "        ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "onSubmit",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "=",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => "{(",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "event",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#E36209;--shiki-dark:#FFAB70"
        },
        %{
          "text" => ") ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "=>",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " {",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "          event.",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "preventDefault",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "()",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "          ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "sendMessage",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "({ text: input })",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "          ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "setInput",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "(",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "\"\"",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
        },
        %{
          "text" => ")",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "        }}",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "      >",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "        <",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "Input",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "value",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "=",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => "{input} ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "onChange",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "=",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => "{(",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "event",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#E36209;--shiki-dark:#FFAB70"
        },
        %{
          "text" => ") ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "=>",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "setInput",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "(event.target.value)} />",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "        <",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "Button",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "disabled",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "=",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => "{status ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "!==",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "\"ready\"",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
        },
        %{
          "text" => "}>Send</",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "Button",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
        },
        %{
          "text" => ">",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "      </",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "form",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#22863A;--shiki-dark:#85E89D"
        },
        %{
          "text" => ">",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "    </",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "div",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#22863A;--shiki-dark:#85E89D"
        },
        %{
          "text" => ">",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "  )",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "}",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    }
  ]

  @chat_route_compact_lines [
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "import",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " { streamText } ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "from",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "\"ai\"",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
        }
      ]
    },
    %{"variant" => "default", "class" => nil, "tokens" => []},
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "export",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "async",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "function",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "POST",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "(",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "request",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#E36209;--shiki-dark:#FFAB70"
        },
        %{
          "text" => ":",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "Request",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => ") {",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "  ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "const",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " { ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "messages",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
        },
        %{
          "text" => " } ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "=",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "await",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " request.",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "json",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "()",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "  ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "const",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "result",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "=",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "streamText",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "({ model: ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "\"anthropic/claude-sonnet-4.5\"",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
        },
        %{
          "text" => ", messages })",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{"variant" => "default", "class" => nil, "tokens" => []},
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "  ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "return",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " result.",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "toUIMessageStreamResponse",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "()",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "}",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    }
  ]

  @api_key_lines [
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "AI_GATEWAY_API_KEY",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "=",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => "your-api-key",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
        }
      ]
    }
  ]

  @debounce_lines [
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "export",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "function",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "useDebounce",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "<",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "T",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => ">(",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "value",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#E36209;--shiki-dark:#FFAB70"
        },
        %{
          "text" => ":",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "T",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => ", ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "delay",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#E36209;--shiki-dark:#FFAB70"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "=",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "300",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
        },
        %{
          "text" => ") {",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "  ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "const",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " [",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "debounced",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
        },
        %{
          "text" => ", ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "setDebounced",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
        },
        %{
          "text" => "] ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "=",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " React.",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "useState",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "(value)",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{"variant" => "default", "class" => nil, "tokens" => []},
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "  React.",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "useEffect",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "(() ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "=>",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " {",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "    ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "const",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "timeout",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "=",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "setTimeout",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "(() ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "=>",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "setDebounced",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "(value), delay)",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "    ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "return",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " () ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "=>",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "clearTimeout",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
        },
        %{
          "text" => "(timeout)",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "  }, [value, delay])",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{"variant" => "default", "class" => nil, "tokens" => []},
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "  ",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        },
        %{
          "text" => "return",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
        },
        %{
          "text" => " debounced",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    },
    %{
      "variant" => "default",
      "class" => nil,
      "tokens" => [
        %{
          "text" => "}",
          "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
          "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
        }
      ]
    }
  ]

  attr(:lines, :list, required: true)
  attr(:wrap, :boolean, default: false)
  attr(:line_numbers, :boolean, default: false)
  attr(:start_line, :integer, default: 1)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def highlighted_content(assigns) do
    ~H"""
    <CodeBlock.code_block_content
      phx-no-format
      wrap={@wrap}
      line_numbers={@line_numbers}
      start_line={@start_line}
      class={@class}
      {@rest}
    ><CodeBlock.code_block_line :for={line <- @lines} variant={line["variant"]} class={line["class"]} value={if line["tokens"] == [], do: "", else: nil}><span :for={token <- line["tokens"]} style={token["style"]} class={token["class"]}>{token["text"]}</span></CodeBlock.code_block_line></CodeBlock.code_block_content>
    """
  end

  def code_block_demo_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-lg",
        1 => "http://www.w3.org/2000/svg",
        2 => "24",
        3 => "0 0 24 24",
        4 => "none",
        5 => "currentColor",
        6 => "2",
        7 => "round",
        8 => "lucide lucide-file-code",
        9 => "true",
        10 =>
          "M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z",
        11 => "M14 2v5a1 1 0 0 0 1 1h5",
        12 => "M10 12.5 8 15l2 2.5",
        13 => "m14 12.5 2 2.5-2 2.5",
        14 => "app/api/chat/route.ts",
        15 => "__TOGGLE__",
        16 => "__TARGET__",
        17 => "__NEXT__",
        18 => "__DOWNLOAD__",
        19 => "__REPLAY__",
        20 => "lucide lucide-text-wrap",
        21 => "m16 16-3 3 3 3",
        22 => "M3 12h14.5a1 1 0 0 1 0 7H13",
        23 => "M3 19h6",
        24 => "M3 5h18",
        25 => "ghost",
        26 => "icon-xs",
        27 => "Wrap lines",
        28 => "aria-pressed:text-foreground",
        29 => "lucide lucide-download",
        30 => "M12 15V3",
        31 => "M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4",
        32 => "m7 10 5 5 5-5",
        33 => "Download",
        34 =>
          "import { streamText } from \"ai\"\n\nexport async function POST(request: Request) {\n  const { messages } = await request.json()\n\n  const result = streamText({\n    model: \"anthropic/claude-sonnet-4.5\",\n    system: \"You are a helpful assistant. Answer in one short paragraph.\",\n    messages,\n  })\n\n  return result.toUIMessageStreamResponse()\n}",
        35 => "route.ts",
        36 => "code-block-demo-copy-1",
        37 => @chat_route_lines
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>
            <svg
              xmlns={@fixture[1]}
              width={@fixture[2]}
              height={@fixture[2]}
              viewBox={@fixture[3]}
              fill={@fixture[4]}
              stroke={@fixture[5]}
              stroke-width={@fixture[6]}
              stroke-linecap={@fixture[7]}
              stroke-linejoin={@fixture[7]}
              class={@fixture[8]}
              aria-hidden={@fixture[9]}
            ><path d={@fixture[10]}></path><path d={@fixture[11]}></path><path d={@fixture[12]}></path><path d={@fixture[13]}></path></svg>{@fixture[
              14
            ]}
          </CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <Button.button
              id={@id <> "-action-1"}
              variant={@fixture[25]}
              size={@fixture[26]}
              aria-label={@fixture[27]}
              aria-pressed="false"
              class={@fixture[28]}
              phx-click="toggle"
              phx-target={@myself}
            ><svg
              xmlns={@fixture[1]}
              width={@fixture[2]}
              height={@fixture[2]}
              viewBox={@fixture[3]}
              fill={@fixture[4]}
              stroke={@fixture[5]}
              stroke-width={@fixture[6]}
              stroke-linecap={@fixture[7]}
              stroke-linejoin={@fixture[7]}
              class={@fixture[20]}
              aria-hidden={@fixture[9]}
            ><path d={@fixture[21]}></path><path d={@fixture[22]}></path><path d={@fixture[23]}>
            </path><path d={@fixture[24]}></path></svg></Button.button><Button.button
              id={@id <> "-action-2"}
              variant={@fixture[25]}
              size={@fixture[26]}
              aria-label={@fixture[33]}
              phx-click={Phoenix.LiveView.JS.dispatch("storybook:download")}
              data-download-value={@fixture[34]}
              data-download-name={@fixture[35]}
            ><svg
              xmlns={@fixture[1]}
              width={@fixture[2]}
              height={@fixture[2]}
              viewBox={@fixture[3]}
              fill={@fixture[4]}
              stroke={@fixture[5]}
              stroke-width={@fixture[6]}
              stroke-linecap={@fixture[7]}
              stroke-linejoin={@fixture[7]}
              class={@fixture[29]}
              aria-hidden={@fixture[9]}
            ><path d={@fixture[30]}></path><path d={@fixture[31]}></path><path d={@fixture[32]}>
            </path></svg></Button.button><CodeBlock.code_block_copy_button
              value={@fixture[34]}
              id={@fixture[36]}
            />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><.highlighted_content
          wrap={false}
          line_numbers={true}
          lines={@fixture[37]}
        />
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_demo_toggle(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-lg",
        1 => "http://www.w3.org/2000/svg",
        2 => "24",
        3 => "0 0 24 24",
        4 => "none",
        5 => "currentColor",
        6 => "2",
        7 => "round",
        8 => "lucide lucide-file-code",
        9 => "true",
        10 =>
          "M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z",
        11 => "M14 2v5a1 1 0 0 0 1 1h5",
        12 => "M10 12.5 8 15l2 2.5",
        13 => "m14 12.5 2 2.5-2 2.5",
        14 => "app/api/chat/route.ts",
        15 => "__TOGGLE__",
        16 => "__TARGET__",
        17 => "__NEXT__",
        18 => "__DOWNLOAD__",
        19 => "__REPLAY__",
        20 => "lucide lucide-text-wrap",
        21 => "m16 16-3 3 3 3",
        22 => "M3 12h14.5a1 1 0 0 1 0 7H13",
        23 => "M3 19h6",
        24 => "M3 5h18",
        25 => "ghost",
        26 => "icon-xs",
        27 => "Wrap lines",
        28 => "aria-pressed:text-foreground",
        29 => "lucide lucide-download",
        30 => "M12 15V3",
        31 => "M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4",
        32 => "m7 10 5 5 5-5",
        33 => "Download",
        34 =>
          "import { streamText } from \"ai\"\n\nexport async function POST(request: Request) {\n  const { messages } = await request.json()\n\n  const result = streamText({\n    model: \"anthropic/claude-sonnet-4.5\",\n    system: \"You are a helpful assistant. Answer in one short paragraph.\",\n    messages,\n  })\n\n  return result.toUIMessageStreamResponse()\n}",
        35 => "route.ts",
        36 => "code-block-demo-copy-1",
        37 => @chat_route_lines
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>
            <svg
              xmlns={@fixture[1]}
              width={@fixture[2]}
              height={@fixture[2]}
              viewBox={@fixture[3]}
              fill={@fixture[4]}
              stroke={@fixture[5]}
              stroke-width={@fixture[6]}
              stroke-linecap={@fixture[7]}
              stroke-linejoin={@fixture[7]}
              class={@fixture[8]}
              aria-hidden={@fixture[9]}
            ><path d={@fixture[10]}></path><path d={@fixture[11]}></path><path d={@fixture[12]}></path><path d={@fixture[13]}></path></svg>{@fixture[
              14
            ]}
          </CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <Button.button
              id={@id <> "-action-1"}
              variant={@fixture[25]}
              size={@fixture[26]}
              aria-label={@fixture[27]}
              aria-pressed="true"
              class={@fixture[28]}
              phx-click="toggle"
              phx-target={@myself}
            ><svg
              xmlns={@fixture[1]}
              width={@fixture[2]}
              height={@fixture[2]}
              viewBox={@fixture[3]}
              fill={@fixture[4]}
              stroke={@fixture[5]}
              stroke-width={@fixture[6]}
              stroke-linecap={@fixture[7]}
              stroke-linejoin={@fixture[7]}
              class={@fixture[20]}
              aria-hidden={@fixture[9]}
            ><path d={@fixture[21]}></path><path d={@fixture[22]}></path><path d={@fixture[23]}>
            </path><path d={@fixture[24]}></path></svg></Button.button><Button.button
              id={@id <> "-action-2"}
              variant={@fixture[25]}
              size={@fixture[26]}
              aria-label={@fixture[33]}
              phx-click={Phoenix.LiveView.JS.dispatch("storybook:download")}
              data-download-value={@fixture[34]}
              data-download-name={@fixture[35]}
            ><svg
              xmlns={@fixture[1]}
              width={@fixture[2]}
              height={@fixture[2]}
              viewBox={@fixture[3]}
              fill={@fixture[4]}
              stroke={@fixture[5]}
              stroke-width={@fixture[6]}
              stroke-linecap={@fixture[7]}
              stroke-linejoin={@fixture[7]}
              class={@fixture[29]}
              aria-hidden={@fixture[9]}
            ><path d={@fixture[30]}></path><path d={@fixture[31]}></path><path d={@fixture[32]}>
            </path></svg></Button.button><CodeBlock.code_block_copy_button
              value={@fixture[34]}
              id={@fixture[36]}
            />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><.highlighted_content
          wrap={true}
          line_numbers={true}
          lines={@fixture[37]}
        />
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_basic_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-md",
        1 =>
          "$ pnpm build\n> next build\n\n ✓ Compiled successfully in 4.2s\n ✓ Generating static pages (12/12)\n\nRoute (app)                Size  First Load JS\n┌ ○ /                    1.9 kB         112 kB\n├ ○ /_not-found           993 B         103 kB\n└ ƒ /api/chat             141 B         102 kB",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__"
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block><CodeBlock.code_block_content code={@fixture[1]} /></CodeBlock.code_block>
    </div>
    """
  end

  def code_block_header_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-md",
        1 => "http://www.w3.org/2000/svg",
        2 => "24",
        3 => "0 0 24 24",
        4 => "none",
        5 => "currentColor",
        6 => "2",
        7 => "round",
        8 => "lucide lucide-terminal",
        9 => "true",
        10 => "M12 19h8",
        11 => "m4 17 6-6-6-6",
        12 => "Terminal",
        13 => "__TOGGLE__",
        14 => "__TARGET__",
        15 => "__NEXT__",
        16 => "__DOWNLOAD__",
        17 => "__REPLAY__",
        18 => "pnpm add ai @ai-sdk/react zod",
        19 => "code-block-header-copy-1",
        20 =>
          "$ pnpm add ai @ai-sdk/react zod\nPackages: +14\nProgress: resolved 412, reused 398, downloaded 14, added 14, done\nDone in 2.8s using pnpm v10.18.0"
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>
            <svg
              xmlns={@fixture[1]}
              width={@fixture[2]}
              height={@fixture[2]}
              viewBox={@fixture[3]}
              fill={@fixture[4]}
              stroke={@fixture[5]}
              stroke-width={@fixture[6]}
              stroke-linecap={@fixture[7]}
              stroke-linejoin={@fixture[7]}
              class={@fixture[8]}
              aria-hidden={@fixture[9]}
            ><path d={@fixture[10]}></path><path d={@fixture[11]}></path></svg>{@fixture[12]}
          </CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <CodeBlock.code_block_copy_button value={@fixture[18]} id={@fixture[19]} />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><CodeBlock.code_block_content code={@fixture[20]} />
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_actions_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-md",
        1 => "http://www.w3.org/2000/svg",
        2 => "24",
        3 => "0 0 24 24",
        4 => "none",
        5 => "currentColor",
        6 => "2",
        7 => "round",
        8 => "lucide lucide-terminal",
        9 => "true",
        10 => "M12 19h8",
        11 => "m4 17 6-6-6-6",
        12 => "Terminal",
        13 => "__TOGGLE__",
        14 => "__TARGET__",
        15 => "__NEXT__",
        16 => "__DOWNLOAD__",
        17 => "__REPLAY__",
        18 => "lucide lucide-text-wrap",
        19 => "m16 16-3 3 3 3",
        20 => "M3 12h14.5a1 1 0 0 1 0 7H13",
        21 => "M3 19h6",
        22 => "M3 5h18",
        23 => "ghost",
        24 => "icon-xs",
        25 => "Wrap lines",
        26 => "aria-pressed:text-foreground",
        27 => "lucide lucide-download",
        28 => "M12 15V3",
        29 => "M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4",
        30 => "m7 10 5 5 5-5",
        31 => "Download",
        32 =>
          "$ pnpm lint\napps/web/components/message-list.tsx\n  18:22  error  'messages' is possibly 'undefined'. Add a guard before calling map  @typescript-eslint/no-unsafe-call\n  42:7   warning  React Hook React.useEffect has a missing dependency: 'scrollToBottom'  react-hooks/exhaustive-deps\n\n✖ 2 problems (1 error, 1 warning)",
        33 => "lint.log",
        34 => "code-block-actions-copy-1"
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>
            <svg
              xmlns={@fixture[1]}
              width={@fixture[2]}
              height={@fixture[2]}
              viewBox={@fixture[3]}
              fill={@fixture[4]}
              stroke={@fixture[5]}
              stroke-width={@fixture[6]}
              stroke-linecap={@fixture[7]}
              stroke-linejoin={@fixture[7]}
              class={@fixture[8]}
              aria-hidden={@fixture[9]}
            ><path d={@fixture[10]}></path><path d={@fixture[11]}></path></svg>{@fixture[12]}
          </CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <Button.button
              id={@id <> "-action-1"}
              variant={@fixture[23]}
              size={@fixture[24]}
              aria-label={@fixture[25]}
              aria-pressed={to_string(not @expanded)}
              class={@fixture[26]}
              phx-click="toggle"
              phx-target={@myself}
            ><svg
              xmlns={@fixture[1]}
              width={@fixture[2]}
              height={@fixture[2]}
              viewBox={@fixture[3]}
              fill={@fixture[4]}
              stroke={@fixture[5]}
              stroke-width={@fixture[6]}
              stroke-linecap={@fixture[7]}
              stroke-linejoin={@fixture[7]}
              class={@fixture[18]}
              aria-hidden={@fixture[9]}
            ><path d={@fixture[19]}></path><path d={@fixture[20]}></path><path d={@fixture[21]}>
            </path><path d={@fixture[22]}></path></svg></Button.button><Button.button
              id={@id <> "-action-2"}
              variant={@fixture[23]}
              size={@fixture[24]}
              aria-label={@fixture[31]}
              phx-click={Phoenix.LiveView.JS.dispatch("storybook:download")}
              data-download-value={@fixture[32]}
              data-download-name={@fixture[33]}
            ><svg
              xmlns={@fixture[1]}
              width={@fixture[2]}
              height={@fixture[2]}
              viewBox={@fixture[3]}
              fill={@fixture[4]}
              stroke={@fixture[5]}
              stroke-width={@fixture[6]}
              stroke-linecap={@fixture[7]}
              stroke-linejoin={@fixture[7]}
              class={@fixture[27]}
              aria-hidden={@fixture[9]}
            ><path d={@fixture[28]}></path><path d={@fixture[29]}></path><path d={@fixture[30]}>
            </path></svg></Button.button><CodeBlock.code_block_copy_button
              value={@fixture[32]}
              id={@fixture[34]}
            />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><CodeBlock.code_block_content
          wrap={not @expanded}
          code={@fixture[32]}
        />
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_floating_actions_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-md",
        1 =>
          "$ pnpm add ai @ai-sdk/react zod\nProgress: resolved 412, reused 398, downloaded 14, added 14, done\ndependencies:\n+ @ai-sdk/react 3.0.12\n+ ai 6.0.12\n+ zod 4.1.12\nDone in 2.8s using pnpm v10.18.0",
        2 => "code-block-floating-actions-copy-1",
        3 => "__TOGGLE__",
        4 => "__TARGET__",
        5 => "__NEXT__",
        6 => "__DOWNLOAD__",
        7 => "__REPLAY__"
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <CodeBlock.code_block_actions>
          <CodeBlock.code_block_copy_button value={@fixture[1]} id={@fixture[2]} />
        </CodeBlock.code_block_actions><CodeBlock.code_block_content code={@fixture[1]} />
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_line_numbers_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-md",
        1 =>
          "{\n  \"name\": \"chat\",\n  \"private\": true,\n  \"scripts\": {\n    \"dev\": \"next dev\",\n    \"build\": \"next build\"\n  }\n}",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__"
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <CodeBlock.code_block_content line_numbers={true} code={@fixture[1]} />
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_start_line_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-md",
        1 => "app/dashboard/page.tsx",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 => [
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "if",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " (",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "!",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => "session) {",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "    ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "redirect",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "(",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "\"/login\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              },
              %{
                "text" => ")",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  }",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{"variant" => "default", "class" => nil, "tokens" => []},
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "const",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "projects",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "=",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "await",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " db.project.",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "findMany",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "({",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "    where: { ownerId: session.user.id },",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "    orderBy: { updatedAt: ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "\"desc\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              },
              %{
                "text" => " },",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  })",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{"variant" => "default", "class" => nil, "tokens" => []},
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "return",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " <",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "ProjectList",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "projects",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "=",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => "{projects} />",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "}",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          }
        ]
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>{@fixture[1]}</CodeBlock.code_block_title>
        </CodeBlock.code_block_header><.highlighted_content
          line_numbers={true}
          start_line={995}
          lines={@fixture[7]}
        />
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_wrap_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex w-full max-w-md flex-col gap-4",
        1 =>
          "Error: The model \"anthropic/claude-sonnet-4.5\" returned an error: Request too large. The prompt is 212,431 tokens and the context window is 200,000 tokens. Remove some messages or summarize the conversation and try again.",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__"
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block><CodeBlock.code_block_content code={@fixture[1]} /></CodeBlock.code_block><CodeBlock.code_block>
        <CodeBlock.code_block_content wrap={true} code={@fixture[1]} />
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_highlighted_lines_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-md",
        1 => [
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [%{"text" => "export default {", "class" => nil, "style" => nil}]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [%{"text" => "  experimental: {", "class" => nil, "style" => nil}]
          },
          %{
            "variant" => "highlighted",
            "class" => nil,
            "tokens" => [%{"text" => "    reactCompiler: true,", "class" => nil, "style" => nil}]
          },
          %{
            "variant" => "highlighted",
            "class" => nil,
            "tokens" => [%{"text" => "    viewTransition: true,", "class" => nil, "style" => nil}]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [%{"text" => "  },", "class" => nil, "style" => nil}]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [%{"text" => "  images: {", "class" => nil, "style" => nil}]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" =>
                  "    remotePatterns: [{ hostname: \"avatars.githubusercontent.com\" }],",
                "class" => nil,
                "style" => nil
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [%{"text" => "  },", "class" => nil, "style" => nil}]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [%{"text" => "}", "class" => nil, "style" => nil}]
          }
        ],
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__"
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <.highlighted_content line_numbers={true} lines={@fixture[1]} />
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_diff_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-md",
        1 => "components/greeting.tsx",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 =>
          " export function Greeting({ name }: { name: string }) {\n-  return <p>Hello, {name}</p>\n+  return <p className=\"text-sm text-muted-foreground\">\n+    Hello, {name}!\n+  </p>\n }",
        8 => "code-block-diff-copy-1",
        9 => [
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "export function Greeting({ name }: { name: string }) {",
                "class" => nil,
                "style" => nil
              }
            ]
          },
          %{
            "variant" => "removed",
            "class" => nil,
            "tokens" => [
              %{"text" => "  return <p>Hello, {name}</p>", "class" => nil, "style" => nil}
            ]
          },
          %{
            "variant" => "added",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  return <p className=\"text-sm text-muted-foreground\">",
                "class" => nil,
                "style" => nil
              }
            ]
          },
          %{
            "variant" => "added",
            "class" => nil,
            "tokens" => [%{"text" => "    Hello, {name}!", "class" => nil, "style" => nil}]
          },
          %{
            "variant" => "added",
            "class" => nil,
            "tokens" => [%{"text" => "  </p>", "class" => nil, "style" => nil}]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [%{"text" => "}", "class" => nil, "style" => nil}]
          }
        ]
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>{@fixture[1]}</CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <CodeBlock.code_block_copy_button value={@fixture[7]} id={@fixture[8]} />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><.highlighted_content lines={@fixture[9]} />
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_height_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-md",
        1 => "Logs",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 =>
          "[01] GET /api/chat 200 in 12ms\n[02] GET /api/chat 200 in 19ms\n[03] GET /api/chat 200 in 26ms\n[04] GET /api/chat 200 in 33ms\n[05] GET /api/chat 200 in 40ms\n[06] GET /api/chat 200 in 47ms\n[07] GET /api/chat 200 in 14ms\n[08] GET /api/chat 200 in 21ms\n[09] GET /api/chat 200 in 28ms\n[10] GET /api/chat 200 in 35ms\n[11] GET /api/chat 200 in 42ms\n[12] GET /api/chat 200 in 49ms\n[13] GET /api/chat 200 in 16ms\n[14] GET /api/chat 200 in 23ms\n[15] GET /api/chat 200 in 30ms\n[16] GET /api/chat 200 in 37ms\n[17] GET /api/chat 200 in 44ms\n[18] GET /api/chat 200 in 51ms\n[19] GET /api/chat 200 in 18ms\n[20] GET /api/chat 200 in 25ms\n[21] GET /api/chat 200 in 32ms\n[22] GET /api/chat 200 in 39ms\n[23] GET /api/chat 200 in 46ms\n[24] GET /api/chat 200 in 13ms\n[25] GET /api/chat 200 in 20ms\n[26] GET /api/chat 200 in 27ms\n[27] GET /api/chat 200 in 34ms\n[28] GET /api/chat 200 in 41ms\n[29] GET /api/chat 200 in 48ms\n[30] GET /api/chat 200 in 15ms\n[31] GET /api/chat 200 in 22ms\n[32] GET /api/chat 200 in 29ms\n[33] GET /api/chat 200 in 36ms\n[34] GET /api/chat 200 in 43ms\n[35] GET /api/chat 200 in 50ms\n[36] GET /api/chat 200 in 17ms\n[37] GET /api/chat 200 in 24ms\n[38] GET /api/chat 200 in 31ms\n[39] GET /api/chat 200 in 38ms\n[40] GET /api/chat 200 in 45ms",
        8 => "code-block-height-copy-1",
        9 => "max-h-48 scroll-fade-y"
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>{@fixture[1]}</CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <CodeBlock.code_block_copy_button value={@fixture[7]} id={@fixture[8]} />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><CodeBlock.code_block_content
          class={@fixture[9]}
          code={@fixture[7]}
        />
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_show_more_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-md",
        1 => "components/chat.tsx",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 =>
          "\"use client\"\n\nimport * as React from \"react\"\nimport { useChat } from \"@ai-sdk/react\"\n\nimport { Button } from \"@/components/ui/button\"\nimport { Input } from \"@/components/ui/input\"\n\nexport function Chat() {\n  const [input, setInput] = React.useState(\"\")\n  const { messages, sendMessage, status } = useChat()\n\n  return (\n    <div className=\"flex flex-col gap-4\">\n      {messages.map((message) => (\n        <div key={message.id}>\n          {message.parts.map((part, index) =>\n            part.type === \"text\" ? <p key={index}>{part.text}</p> : null\n          )}\n        </div>\n      ))}\n      <form\n        onSubmit={(event) => {\n          event.preventDefault()\n          sendMessage({ text: input })\n          setInput(\"\")\n        }}\n      >\n        <Input value={input} onChange={(event) => setInput(event.target.value)} />\n        <Button disabled={status !== \"ready\"}>Send</Button>\n      </form>\n    </div>\n  )\n}",
        8 => "code-block-show-more-copy-1",
        9 => assigns.id <> "-_R_0_",
        10 => "max-h-64 scroll-fade-y overflow-y-hidden",
        11 => @chat_component_lines,
        12 => "http://www.w3.org/2000/svg",
        13 => "24",
        14 => "0 0 24 24",
        15 => "none",
        16 => "currentColor",
        17 => "2",
        18 => "round",
        19 => "lucide lucide-chevron-down transition-transform in-aria-expanded:rotate-180",
        20 => "true",
        21 => "m6 9 6 6 6-6",
        22 => "Show more",
        23 => "ghost",
        24 => "xs",
        25 => "justify-center"
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>{@fixture[1]}</CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <CodeBlock.code_block_copy_button value={@fixture[7]} id={@fixture[8]} />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><.highlighted_content
          id={@fixture[9]}
          line_numbers={true}
          class={@fixture[10]}
          lines={@fixture[11]}
        /><CodeBlock.code_block_footer class={@fixture[25]}>
          <Button.button
            id={@id <> "-action-1"}
            variant={@fixture[23]}
            size={@fixture[24]}
            aria-expanded="false"
            aria-controls={@fixture[9]}
            phx-click="toggle"
            phx-target={@myself}
          ><svg
            xmlns={@fixture[12]}
            width={@fixture[13]}
            height={@fixture[13]}
            viewBox={@fixture[14]}
            fill={@fixture[15]}
            stroke={@fixture[16]}
            stroke-width={@fixture[17]}
            stroke-linecap={@fixture[18]}
            stroke-linejoin={@fixture[18]}
            class={@fixture[19]}
            aria-hidden={@fixture[20]}
          ><path d={@fixture[21]}></path></svg>{@fixture[22]}</Button.button>
        </CodeBlock.code_block_footer>
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_show_more_toggle(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-md",
        1 => "components/chat.tsx",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 =>
          "\"use client\"\n\nimport * as React from \"react\"\nimport { useChat } from \"@ai-sdk/react\"\n\nimport { Button } from \"@/components/ui/button\"\nimport { Input } from \"@/components/ui/input\"\n\nexport function Chat() {\n  const [input, setInput] = React.useState(\"\")\n  const { messages, sendMessage, status } = useChat()\n\n  return (\n    <div className=\"flex flex-col gap-4\">\n      {messages.map((message) => (\n        <div key={message.id}>\n          {message.parts.map((part, index) =>\n            part.type === \"text\" ? <p key={index}>{part.text}</p> : null\n          )}\n        </div>\n      ))}\n      <form\n        onSubmit={(event) => {\n          event.preventDefault()\n          sendMessage({ text: input })\n          setInput(\"\")\n        }}\n      >\n        <Input value={input} onChange={(event) => setInput(event.target.value)} />\n        <Button disabled={status !== \"ready\"}>Send</Button>\n      </form>\n    </div>\n  )\n}",
        8 => "code-block-show-more-copy-1",
        9 => assigns.id <> "-_R_0_",
        10 => @chat_component_lines,
        11 => "http://www.w3.org/2000/svg",
        12 => "24",
        13 => "0 0 24 24",
        14 => "none",
        15 => "currentColor",
        16 => "2",
        17 => "round",
        18 => "lucide lucide-chevron-down transition-transform in-aria-expanded:rotate-180",
        19 => "true",
        20 => "m6 9 6 6 6-6",
        21 => "Show less",
        22 => "ghost",
        23 => "xs",
        24 => "justify-center"
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>{@fixture[1]}</CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <CodeBlock.code_block_copy_button value={@fixture[7]} id={@fixture[8]} />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><.highlighted_content
          id={@fixture[9]}
          line_numbers={true}
          lines={@fixture[10]}
        /><CodeBlock.code_block_footer class={@fixture[24]}>
          <Button.button
            id={@id <> "-action-1"}
            variant={@fixture[22]}
            size={@fixture[23]}
            aria-expanded="true"
            aria-controls={@fixture[9]}
            phx-click="toggle"
            phx-target={@myself}
          ><svg
            xmlns={@fixture[11]}
            width={@fixture[12]}
            height={@fixture[12]}
            viewBox={@fixture[13]}
            fill={@fixture[14]}
            stroke={@fixture[15]}
            stroke-width={@fixture[16]}
            stroke-linecap={@fixture[17]}
            stroke-linejoin={@fixture[17]}
            class={@fixture[18]}
            aria-hidden={@fixture[19]}
          ><path d={@fixture[20]}></path></svg>{@fixture[21]}</Button.button>
        </CodeBlock.code_block_footer>
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_show_more_scroll_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-md",
        1 => "components/chat.tsx",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 =>
          "\"use client\"\n\nimport * as React from \"react\"\nimport { useChat } from \"@ai-sdk/react\"\n\nimport { Button } from \"@/components/ui/button\"\nimport { Input } from \"@/components/ui/input\"\n\nexport function Chat() {\n  const [input, setInput] = React.useState(\"\")\n  const { messages, sendMessage, status } = useChat()\n\n  return (\n    <div className=\"flex flex-col gap-4\">\n      {messages.map((message) => (\n        <div key={message.id}>\n          {message.parts.map((part, index) =>\n            part.type === \"text\" ? <p key={index}>{part.text}</p> : null\n          )}\n        </div>\n      ))}\n      <form\n        onSubmit={(event) => {\n          event.preventDefault()\n          sendMessage({ text: input })\n          setInput(\"\")\n        }}\n      >\n        <Input value={input} onChange={(event) => setInput(event.target.value)} />\n        <Button disabled={status !== \"ready\"}>Send</Button>\n      </form>\n    </div>\n  )\n}",
        8 => "code-block-show-more-scroll-copy-1",
        9 => assigns.id <> "-_R_0_",
        10 => "max-h-64 scroll-fade-y overflow-y-hidden",
        11 => @chat_component_lines,
        12 => "http://www.w3.org/2000/svg",
        13 => "24",
        14 => "0 0 24 24",
        15 => "none",
        16 => "currentColor",
        17 => "2",
        18 => "round",
        19 => "lucide lucide-chevron-down transition-transform in-aria-expanded:rotate-180",
        20 => "true",
        21 => "m6 9 6 6 6-6",
        22 => "Show more",
        23 => "ghost",
        24 => "xs",
        25 => "justify-center"
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>{@fixture[1]}</CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <CodeBlock.code_block_copy_button value={@fixture[7]} id={@fixture[8]} />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><.highlighted_content
          id={@fixture[9]}
          line_numbers={true}
          class={@fixture[10]}
          lines={@fixture[11]}
        /><CodeBlock.code_block_footer class={@fixture[25]}>
          <Button.button
            id={@id <> "-action-1"}
            variant={@fixture[23]}
            size={@fixture[24]}
            aria-expanded="false"
            aria-controls={@fixture[9]}
            phx-click="toggle"
            phx-target={@myself}
          ><svg
            xmlns={@fixture[12]}
            width={@fixture[13]}
            height={@fixture[13]}
            viewBox={@fixture[14]}
            fill={@fixture[15]}
            stroke={@fixture[16]}
            stroke-width={@fixture[17]}
            stroke-linecap={@fixture[18]}
            stroke-linejoin={@fixture[18]}
            class={@fixture[19]}
            aria-hidden={@fixture[20]}
          ><path d={@fixture[21]}></path></svg>{@fixture[22]}</Button.button>
        </CodeBlock.code_block_footer>
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_show_more_scroll_toggle(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-md",
        1 => "components/chat.tsx",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 =>
          "\"use client\"\n\nimport * as React from \"react\"\nimport { useChat } from \"@ai-sdk/react\"\n\nimport { Button } from \"@/components/ui/button\"\nimport { Input } from \"@/components/ui/input\"\n\nexport function Chat() {\n  const [input, setInput] = React.useState(\"\")\n  const { messages, sendMessage, status } = useChat()\n\n  return (\n    <div className=\"flex flex-col gap-4\">\n      {messages.map((message) => (\n        <div key={message.id}>\n          {message.parts.map((part, index) =>\n            part.type === \"text\" ? <p key={index}>{part.text}</p> : null\n          )}\n        </div>\n      ))}\n      <form\n        onSubmit={(event) => {\n          event.preventDefault()\n          sendMessage({ text: input })\n          setInput(\"\")\n        }}\n      >\n        <Input value={input} onChange={(event) => setInput(event.target.value)} />\n        <Button disabled={status !== \"ready\"}>Send</Button>\n      </form>\n    </div>\n  )\n}",
        8 => "code-block-show-more-scroll-copy-1",
        9 => assigns.id <> "-_R_0_",
        10 => "max-h-96 scroll-fade-y",
        11 => @chat_component_lines,
        12 => "http://www.w3.org/2000/svg",
        13 => "24",
        14 => "0 0 24 24",
        15 => "none",
        16 => "currentColor",
        17 => "2",
        18 => "round",
        19 => "lucide lucide-chevron-down transition-transform in-aria-expanded:rotate-180",
        20 => "true",
        21 => "m6 9 6 6 6-6",
        22 => "Show less",
        23 => "ghost",
        24 => "xs",
        25 => "justify-center"
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>{@fixture[1]}</CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <CodeBlock.code_block_copy_button value={@fixture[7]} id={@fixture[8]} />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><.highlighted_content
          id={@fixture[9]}
          line_numbers={true}
          class={@fixture[10]}
          lines={@fixture[11]}
        /><CodeBlock.code_block_footer class={@fixture[25]}>
          <Button.button
            id={@id <> "-action-1"}
            variant={@fixture[23]}
            size={@fixture[24]}
            aria-expanded="true"
            aria-controls={@fixture[9]}
            phx-click="toggle"
            phx-target={@myself}
          ><svg
            xmlns={@fixture[12]}
            width={@fixture[13]}
            height={@fixture[13]}
            viewBox={@fixture[14]}
            fill={@fixture[15]}
            stroke={@fixture[16]}
            stroke-width={@fixture[17]}
            stroke-linecap={@fixture[18]}
            stroke-linejoin={@fixture[18]}
            class={@fixture[19]}
            aria-hidden={@fixture[20]}
          ><path d={@fixture[21]}></path></svg>{@fixture[22]}</Button.button>
        </CodeBlock.code_block_footer>
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_size_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex w-full max-w-md flex-col gap-4",
        1 => "http://www.w3.org/2000/svg",
        2 => "24",
        3 => "0 0 24 24",
        4 => "none",
        5 => "currentColor",
        6 => "2",
        7 => "round",
        8 => "lucide lucide-terminal",
        9 => "true",
        10 => "M12 19h8",
        11 => "m4 17 6-6-6-6",
        12 => "Terminal",
        13 => "__TOGGLE__",
        14 => "__TARGET__",
        15 => "__NEXT__",
        16 => "__DOWNLOAD__",
        17 => "__REPLAY__",
        18 =>
          "$ pnpm add ai @ai-sdk/react zod\nProgress: resolved 412, reused 398, downloaded 14, added 14, done\nDone in 2.8s using pnpm v10.18.0",
        19 => "code-block-size-copy-1",
        20 => "code-block-size-copy-2",
        21 => "sm"
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>
            <svg
              xmlns={@fixture[1]}
              width={@fixture[2]}
              height={@fixture[2]}
              viewBox={@fixture[3]}
              fill={@fixture[4]}
              stroke={@fixture[5]}
              stroke-width={@fixture[6]}
              stroke-linecap={@fixture[7]}
              stroke-linejoin={@fixture[7]}
              class={@fixture[8]}
              aria-hidden={@fixture[9]}
            ><path d={@fixture[10]}></path><path d={@fixture[11]}></path></svg>{@fixture[12]}
          </CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <CodeBlock.code_block_copy_button value={@fixture[18]} id={@fixture[19]} />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><CodeBlock.code_block_content wrap={true} code={@fixture[18]} />
      </CodeBlock.code_block><CodeBlock.code_block size={@fixture[21]}>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>
            <svg
              xmlns={@fixture[1]}
              width={@fixture[2]}
              height={@fixture[2]}
              viewBox={@fixture[3]}
              fill={@fixture[4]}
              stroke={@fixture[5]}
              stroke-width={@fixture[6]}
              stroke-linecap={@fixture[7]}
              stroke-linejoin={@fixture[7]}
              class={@fixture[8]}
              aria-hidden={@fixture[9]}
            ><path d={@fixture[10]}></path><path d={@fixture[11]}></path></svg>{@fixture[12]}
          </CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <CodeBlock.code_block_copy_button value={@fixture[18]} id={@fixture[20]} />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><CodeBlock.code_block_content wrap={true} code={@fixture[18]} />
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_destructive_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-md",
        1 => "Error",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 =>
          "TypeError: Cannot read properties of undefined (reading 'map')\n    at MessageList (components/message-list.tsx:18:22)\n    at renderWithHooks (react-dom.development.js:16305:18)",
        8 => "code-block-destructive-copy-1",
        9 => "destructive"
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block variant={@fixture[9]}>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>{@fixture[1]}</CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <CodeBlock.code_block_copy_button value={@fixture[7]} id={@fixture[8]} />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><CodeBlock.code_block_content wrap={true} code={@fixture[7]} />
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_trace_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-md",
        1 => "http://www.w3.org/2000/svg",
        2 => "24",
        3 => "0 0 24 24",
        4 => "none",
        5 => "currentColor",
        6 => "2",
        7 => "round",
        8 => "lucide lucide-terminal",
        9 => "true",
        10 => "M12 19h8",
        11 => "m4 17 6-6-6-6",
        12 => "__TOGGLE__",
        13 => "__TARGET__",
        14 => "__NEXT__",
        15 => "__DOWNLOAD__",
        16 => "__REPLAY__",
        17 => "Ran node --version",
        18 => "code-block-trace-trace-1",
        19 => "max-h-64",
        20 => "$ node --version\nv24.18.0",
        21 => "sm",
        22 => "Failed to run pnpm dev",
        23 => "error",
        24 => "code-block-trace-trace-2",
        25 =>
          "$ pnpm dev\nError: listen EADDRINUSE: address already in use :::3000\n    at Server.setupListenHandle [as _listen2] (node:net:1908:16)",
        26 => "destructive"
      })

    ~H"""
    <div class={@fixture[0]}>
      <Trace.trace>
        <Trace.trace_collapsible id={@fixture[18]} open={true}>
          <Trace.trace_collapsible_trigger for={@fixture[18]} open={true}>
            <Trace.trace_line>
              <Trace.trace_icon>
                <svg
                  xmlns={@fixture[1]}
                  width={@fixture[2]}
                  height={@fixture[2]}
                  viewBox={@fixture[3]}
                  fill={@fixture[4]}
                  stroke={@fixture[5]}
                  stroke-width={@fixture[6]}
                  stroke-linecap={@fixture[7]}
                  stroke-linejoin={@fixture[7]}
                  class={@fixture[8]}
                  aria-hidden={@fixture[9]}
                ><path d={@fixture[10]}></path><path d={@fixture[11]}></path></svg>
              </Trace.trace_icon><Trace.trace_title>{@fixture[17]}</Trace.trace_title>
            </Trace.trace_line>
          </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
            phx-no-format
            for={@fixture[18]}
            open={true}
          >
            <CodeBlock.code_block size={@fixture[21]}>
              <CodeBlock.code_block_content wrap={true} class={@fixture[19]} code={@fixture[20]} />
            </CodeBlock.code_block>
          </Trace.trace_collapsible_content>
        </Trace.trace_collapsible><Trace.trace_collapsible id={@fixture[24]} open={true}>
          <Trace.trace_collapsible_trigger for={@fixture[24]} open={true}>
            <Trace.trace_line status={@fixture[23]}>
              <Trace.trace_icon>
                <svg
                  xmlns={@fixture[1]}
                  width={@fixture[2]}
                  height={@fixture[2]}
                  viewBox={@fixture[3]}
                  fill={@fixture[4]}
                  stroke={@fixture[5]}
                  stroke-width={@fixture[6]}
                  stroke-linecap={@fixture[7]}
                  stroke-linejoin={@fixture[7]}
                  class={@fixture[8]}
                  aria-hidden={@fixture[9]}
                ><path d={@fixture[10]}></path><path d={@fixture[11]}></path></svg>
              </Trace.trace_icon><Trace.trace_title>{@fixture[22]}</Trace.trace_title>
            </Trace.trace_line>
          </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
            phx-no-format
            for={@fixture[24]}
            open={true}
          >
            <CodeBlock.code_block size={@fixture[21]} variant={@fixture[26]}>
              <CodeBlock.code_block_content wrap={true} class={@fixture[19]} code={@fixture[25]} />
            </CodeBlock.code_block>
          </Trace.trace_collapsible_content>
        </Trace.trace_collapsible>
      </Trace.trace>
    </div>
    """
  end

  def code_block_tabs_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "route",
        1 => "route.ts",
        2 => "app/api/chat/route.ts",
        3 => "__TOGGLE__",
        4 => "__TARGET__",
        5 => "__NEXT__",
        6 => "__DOWNLOAD__",
        7 => "__REPLAY__",
        8 =>
          "import { streamText } from \"ai\"\n\nexport async function POST(request: Request) {\n  const { messages } = await request.json()\n  const result = streamText({ model: \"anthropic/claude-sonnet-4.5\", messages })\n\n  return result.toUIMessageStreamResponse()\n}",
        9 => "code-block-tabs-copy-2",
        10 => @chat_route_compact_lines,
        11 => "chat",
        12 => "chat.tsx",
        13 => "components/chat.tsx",
        14 =>
          "\"use client\"\n\nimport { useChat } from \"@ai-sdk/react\"\n\nexport function Chat() {\n  const { messages } = useChat()\n\n  return <MessageList messages={messages} />\n}",
        15 => "code-block-tabs-copy-3",
        16 => [
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "\"use client\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              }
            ]
          },
          %{"variant" => "default", "class" => nil, "tokens" => []},
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "import",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " { useChat } ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "from",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "\"@ai-sdk/react\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              }
            ]
          },
          %{"variant" => "default", "class" => nil, "tokens" => []},
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "export",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "function",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "Chat",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "() {",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "const",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " { ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "messages",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => " } ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "=",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "useChat",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "()",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{"variant" => "default", "class" => nil, "tokens" => []},
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "return",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " <",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "MessageList",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "messages",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "=",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => "{messages} />",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "}",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          }
        ],
        17 => "env",
        18 => ".env.local",
        19 => "AI_GATEWAY_API_KEY=your-api-key",
        20 => "code-block-tabs-copy-4",
        21 => @api_key_lines,
        22 => "w-full max-w-md",
        23 => "code-block-tabs-tabs-1"
      })

    ~H"""
    <Tabs.tabs class={@fixture[22]} id={@id <> "-tabs"} value={@fixture[0]}>
      <:tab value={@fixture[0]} label={@fixture[1]}>
        <CodeBlock.code_block>
          <CodeBlock.code_block_header>
            <CodeBlock.code_block_title>{@fixture[2]}</CodeBlock.code_block_title><CodeBlock.code_block_actions>
              <CodeBlock.code_block_copy_button value={@fixture[8]} id={@fixture[9]} />
            </CodeBlock.code_block_actions>
          </CodeBlock.code_block_header><.highlighted_content
            line_numbers={true}
            lines={@fixture[10]}
          />
        </CodeBlock.code_block>
      </:tab><:tab value={@fixture[11]} label={@fixture[12]}>
        <CodeBlock.code_block>
          <CodeBlock.code_block_header>
            <CodeBlock.code_block_title>{@fixture[13]}</CodeBlock.code_block_title><CodeBlock.code_block_actions>
              <CodeBlock.code_block_copy_button value={@fixture[14]} id={@fixture[15]} />
            </CodeBlock.code_block_actions>
          </CodeBlock.code_block_header><.highlighted_content
            line_numbers={true}
            lines={@fixture[16]}
          />
        </CodeBlock.code_block>
      </:tab><:tab value={@fixture[17]} label={@fixture[18]}>
        <CodeBlock.code_block>
          <CodeBlock.code_block_header>
            <CodeBlock.code_block_title>{@fixture[18]}</CodeBlock.code_block_title><CodeBlock.code_block_actions>
              <CodeBlock.code_block_copy_button value={@fixture[19]} id={@fixture[20]} />
            </CodeBlock.code_block_actions>
          </CodeBlock.code_block_header><.highlighted_content
            line_numbers={true}
            lines={@fixture[21]}
          />
        </CodeBlock.code_block>
      </:tab>
    </Tabs.tabs>
    """
  end

  def code_block_chat_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex w-full max-w-md flex-col gap-4 text-sm",
        1 => "How do I stream a response?",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 => "muted",
        8 => "end",
        9 => "Create a route handler that returns the stream:",
        10 => "app/api/chat/route.ts",
        11 =>
          "import { streamText } from \"ai\"\n\nexport async function POST(request: Request) {\n  const { messages } = await request.json()\n\n  const result = streamText({\n    model: \"anthropic/claude-sonnet-4.5\",\n    messages,\n  })\n\n  return result.toUIMessageStreamResponse()\n}",
        12 => "code-block-chat-copy-1",
        13 => [
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "import",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " { streamText } ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "from",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "\"ai\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              }
            ]
          },
          %{"variant" => "default", "class" => nil, "tokens" => []},
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "export",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "async",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "function",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "POST",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "(",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "request",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#E36209;--shiki-dark:#FFAB70"
              },
              %{
                "text" => ":",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "Request",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => ") {",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "const",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " { ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "messages",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => " } ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "=",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "await",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " request.",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "json",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "()",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{"variant" => "default", "class" => nil, "tokens" => []},
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "const",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "result",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "=",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "streamText",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "({",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "    model: ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "\"anthropic/claude-sonnet-4.5\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              },
              %{
                "text" => ",",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "    messages,",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  })",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{"variant" => "default", "class" => nil, "tokens" => []},
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "return",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " result.",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "toUIMessageStreamResponse",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "()",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "}",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          }
        ],
        14 => "The client reads it with useChat.",
        15 => "gap-3"
      })

    ~H"""
    <div class={@fixture[0]}>
      <Message.message align={@fixture[8]}>
        <Message.message_content>
          <Bubble.bubble variant={@fixture[7]}>
            <Bubble.bubble_content>{@fixture[1]}</Bubble.bubble_content>
          </Bubble.bubble>
        </Message.message_content>
      </Message.message><Message.message>
        <Message.message_content class={@fixture[15]}>
          <p>{@fixture[9]}</p><CodeBlock.code_block>
            <CodeBlock.code_block_header>
              <CodeBlock.code_block_title>{@fixture[10]}</CodeBlock.code_block_title><CodeBlock.code_block_actions>
                <CodeBlock.code_block_copy_button value={@fixture[11]} id={@fixture[12]} />
              </CodeBlock.code_block_actions>
            </CodeBlock.code_block_header><.highlighted_content lines={@fixture[13]} />
          </CodeBlock.code_block><p>{@fixture[14]}</p>
        </Message.message_content>
      </Message.message>
    </div>
    """
  end

  def code_block_typeset_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "typeset w-full max-w-md",
        1 => "Stream a response",
        2 => "Create a route handler that calls ",
        3 => "streamText",
        4 => " and returns the stream to the client.",
        5 => "http://www.w3.org/2000/svg",
        6 => "24",
        7 => "0 0 24 24",
        8 => "none",
        9 => "currentColor",
        10 => "2",
        11 => "round",
        12 => "lucide lucide-file-code",
        13 => "true",
        14 =>
          "M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z",
        15 => "M14 2v5a1 1 0 0 0 1 1h5",
        16 => "M10 12.5 8 15l2 2.5",
        17 => "m14 12.5 2 2.5-2 2.5",
        18 => "app/api/chat/route.ts",
        19 => "__TOGGLE__",
        20 => "__TARGET__",
        21 => "__NEXT__",
        22 => "__DOWNLOAD__",
        23 => "__REPLAY__",
        24 =>
          "import { streamText } from \"ai\"\n\nexport async function POST(request: Request) {\n  const { messages } = await request.json()\n  const result = streamText({ model: \"anthropic/claude-sonnet-4.5\", messages })\n\n  return result.toUIMessageStreamResponse()\n}",
        25 => "code-block-typeset-copy-1",
        26 => @chat_route_compact_lines,
        27 => "The ",
        28 => "useChat",
        29 => " hook reads the stream on the client and renders the answer while it is written."
      })

    ~H"""
    <div class={@fixture[0]}>
      <h3>{@fixture[1]}</h3><p>{@fixture[2]}<code>{@fixture[3]}</code>{@fixture[4]}</p><CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>
            <svg
              xmlns={@fixture[5]}
              width={@fixture[6]}
              height={@fixture[6]}
              viewBox={@fixture[7]}
              fill={@fixture[8]}
              stroke={@fixture[9]}
              stroke-width={@fixture[10]}
              stroke-linecap={@fixture[11]}
              stroke-linejoin={@fixture[11]}
              class={@fixture[12]}
              aria-hidden={@fixture[13]}
            ><path d={@fixture[14]}></path><path d={@fixture[15]}></path><path d={@fixture[16]}></path><path d={@fixture[17]}></path></svg>{@fixture[
              18
            ]}
          </CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <CodeBlock.code_block_copy_button value={@fixture[24]} id={@fixture[25]} />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><.highlighted_content line_numbers={true} lines={@fixture[26]} />
      </CodeBlock.code_block><p>{@fixture[27]}<code>{@fixture[28]}</code>{@fixture[29]}</p>
    </div>
    """
  end

  def code_block_rtl_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex w-full max-w-md flex-col gap-3 text-sm",
        1 => "rtl",
        2 => "ثبّت الحزم، ثم شغّل خادم التطوير.",
        3 => "http://www.w3.org/2000/svg",
        4 => "24",
        5 => "0 0 24 24",
        6 => "none",
        7 => "currentColor",
        8 => "2",
        9 => "round",
        10 => "lucide lucide-terminal",
        11 => "true",
        12 => "M12 19h8",
        13 => "m4 17 6-6-6-6",
        14 => "الطرفية",
        15 => "__TOGGLE__",
        16 => "__TARGET__",
        17 => "__NEXT__",
        18 => "__DOWNLOAD__",
        19 => "__REPLAY__",
        20 => "pnpm add ai @ai-sdk/react zod\npnpm dev",
        21 => "code-block-rtl-copy-1",
        22 => [
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "pnpm",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "add",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "ai",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "@ai-sdk/react",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "zod",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "pnpm",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "dev",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              }
            ]
          }
        ]
      })

    ~H"""
    <div class={@fixture[0]} dir={@fixture[1]}>
      <p>{@fixture[2]}</p><CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>
            <svg
              xmlns={@fixture[3]}
              width={@fixture[4]}
              height={@fixture[4]}
              viewBox={@fixture[5]}
              fill={@fixture[6]}
              stroke={@fixture[7]}
              stroke-width={@fixture[8]}
              stroke-linecap={@fixture[9]}
              stroke-linejoin={@fixture[9]}
              class={@fixture[10]}
              aria-hidden={@fixture[11]}
            ><path d={@fixture[12]}></path><path d={@fixture[13]}></path></svg>{@fixture[14]}
          </CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <CodeBlock.code_block_copy_button value={@fixture[20]} id={@fixture[21]} />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><.highlighted_content line_numbers={true} lines={@fixture[22]} />
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_highlighting_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-md",
        1 => "getWeather output",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 => [
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "{",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "\"location\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => ": ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "\"San Francisco\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              },
              %{
                "text" => ",",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "\"temperature\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => ": ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "18",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => ",",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "\"unit\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => ": ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "\"celsius\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              },
              %{
                "text" => ",",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "\"conditions\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => ": [",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "\"fog\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              },
              %{
                "text" => ", ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "\"wind\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              },
              %{
                "text" => "]",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "}",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          }
        ]
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>{@fixture[1]}</CodeBlock.code_block_title>
        </CodeBlock.code_block_header><.highlighted_content lines={@fixture[7]} />
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_languages_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex w-full max-w-md flex-col gap-4",
        1 => "app/globals.css",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 => [
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "@import",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "\"tailwindcss\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              },
              %{
                "text" => ";",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{"variant" => "default", "class" => nil, "tokens" => []},
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => ":root",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => " {",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "--radius",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#E36209;--shiki-dark:#FFAB70"
              },
              %{
                "text" => ": ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "0.625",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => "rem",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => ";",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "}",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          }
        ],
        8 => "main.py",
        9 => [
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "def",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "greet",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "(name: ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "str",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => ") -> ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "str",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => ":",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "    ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "return",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "f",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => "\"Hello, ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              },
              %{
                "text" => "{",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => "name",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "}",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => "!\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              }
            ]
          }
        ],
        10 => "notes.txt",
        11 => [
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "A language that is not in the list renders as plain text.",
                "class" => nil,
                "style" => nil
              }
            ]
          }
        ]
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>{@fixture[1]}</CodeBlock.code_block_title>
        </CodeBlock.code_block_header><.highlighted_content lines={@fixture[7]} />
      </CodeBlock.code_block><CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>{@fixture[8]}</CodeBlock.code_block_title>
        </CodeBlock.code_block_header><.highlighted_content lines={@fixture[9]} />
      </CodeBlock.code_block><CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>{@fixture[10]}</CodeBlock.code_block_title>
        </CodeBlock.code_block_header><.highlighted_content lines={@fixture[11]} />
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_ansi_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-md",
        1 => "http://www.w3.org/2000/svg",
        2 => "24",
        3 => "0 0 24 24",
        4 => "none",
        5 => "currentColor",
        6 => "2",
        7 => "round",
        8 => "lucide lucide-terminal",
        9 => "true",
        10 => "M12 19h8",
        11 => "m4 17 6-6-6-6",
        12 => "Terminal",
        13 => "__TOGGLE__",
        14 => "__TARGET__",
        15 => "__NEXT__",
        16 => "__DOWNLOAD__",
        17 => "__REPLAY__",
        18 =>
          "$ pnpm test\n✓ src/format.test.ts (4 tests)\n✓ src/parse.test.ts (7 tests)\n✗ src/stream.test.ts (3 tests | 1 failed)\n\nAssertionError: expected 'hello' to be 'hello world'\n\nTests  1 failed | 13 passed (14)",
        19 => "code-block-ansi-copy-1",
        20 => [
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "$ pnpm test",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292e;--shiki-dark:#e1e4e8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "✓",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#28a745;--shiki-dark:#34d058"
              },
              %{
                "text" => " src/format.test.ts ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292e;--shiki-dark:#e1e4e8"
              },
              %{
                "text" => "(4 tests)",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292e80;--shiki-dark:#e1e4e880"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "✓",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#28a745;--shiki-dark:#34d058"
              },
              %{
                "text" => " src/parse.test.ts ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292e;--shiki-dark:#e1e4e8"
              },
              %{
                "text" => "(7 tests)",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292e80;--shiki-dark:#e1e4e880"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "✗",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#d73a49;--shiki-dark:#ea4a5a"
              },
              %{
                "text" => " src/stream.test.ts ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292e;--shiki-dark:#e1e4e8"
              },
              %{
                "text" => "(3 tests | 1 failed)",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292e80;--shiki-dark:#e1e4e880"
              }
            ]
          },
          %{"variant" => "default", "class" => nil, "tokens" => []},
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "AssertionError: expected 'hello' to be 'hello world'",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#d73a49;--shiki-dark:#ea4a5a"
              }
            ]
          },
          %{"variant" => "default", "class" => nil, "tokens" => []},
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "Tests  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292e;--shiki-dark:#e1e4e8"
              },
              %{
                "text" => "1 failed",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#d73a49;--shiki-dark:#ea4a5a"
              },
              %{
                "text" => " | ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292e;--shiki-dark:#e1e4e8"
              },
              %{
                "text" => "13 passed",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#28a745;--shiki-dark:#34d058"
              },
              %{
                "text" => " (14)",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292e;--shiki-dark:#e1e4e8"
              }
            ]
          }
        ]
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>
            <svg
              xmlns={@fixture[1]}
              width={@fixture[2]}
              height={@fixture[2]}
              viewBox={@fixture[3]}
              fill={@fixture[4]}
              stroke={@fixture[5]}
              stroke-width={@fixture[6]}
              stroke-linecap={@fixture[7]}
              stroke-linejoin={@fixture[7]}
              class={@fixture[8]}
              aria-hidden={@fixture[9]}
            ><path d={@fixture[10]}></path><path d={@fixture[11]}></path></svg>{@fixture[12]}
          </CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <CodeBlock.code_block_copy_button value={@fixture[18]} id={@fixture[19]} />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><.highlighted_content wrap={true} lines={@fixture[20]} />
      </CodeBlock.code_block>
    </div>
    """
  end

  def code_block_streaming_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex w-full max-w-md flex-col gap-4",
        1 => "hooks/use-debounce.ts",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 =>
          "export function useDebounce<T>(value: T, delay = 300) {\n  const [debounced, setDebounced] = React.useState(value)\n\n  React.useEffect(() => {\n    const timeout = setTimeout(() => setDebounced(value), delay)\n    return () => clearTimeout(timeout)\n  }, [value, delay])\n\n  return debounced\n}",
        8 => "code-block-streaming-copy-1",
        9 => @debounce_lines,
        10 => [
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "pnpm",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "dlx",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "shadcn@latest",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "add",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "code-block",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              }
            ]
          }
        ],
        11 => "components/search.tsx",
        12 =>
          "export function Search() {\n  const [query, setQuery] = React.useState(\"\")\n  const results = useSearch(query)\n  const debounced = useDebounce(query, 300)\n  const results = useSearch(debounced)\n\n  return <SearchResults results={results} />\n}",
        13 => "code-block-streaming-copy-2",
        14 => [
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "export",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "function",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "Search",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "() {",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "const",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " [",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "query",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => ", ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "setQuery",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => "] ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "=",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " React.",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "useState",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "(",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "\"\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              },
              %{
                "text" => ")",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "removed",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "const",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "results",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "=",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "useSearch",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "(query)",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "added",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "const",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "debounced",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "=",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "useDebounce",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "(query, ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "300",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => ")",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "added",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "const",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "results",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "=",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "useSearch",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "(debounced)",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{"variant" => "default", "class" => nil, "tokens" => []},
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "return",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " <",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "SearchResults",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "results",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "=",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => "{results} />",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "}",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          }
        ],
        15 => "app/api/chat/route.ts",
        16 =>
          "import { streamText } from \"ai\"\n\nexport async function POST(request: Request) {\n  const { messages } = await request.json()\n\n  const result = streamText({\n    model: \"anthropic/claude-sonnet-4.5\",\n    messages,\n  })\n\n  return result.toUIMessageStreamResponse()\n}",
        17 => "code-block-streaming-copy-3",
        18 => [
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "import",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " { streamText } ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "from",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "\"ai\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              }
            ]
          },
          %{"variant" => "default", "class" => nil, "tokens" => []},
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "export",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "async",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "function",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "POST",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "(",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "request",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#E36209;--shiki-dark:#FFAB70"
              },
              %{
                "text" => ":",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "Request",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => ") {",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "const",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " { ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "messages",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => " } ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "=",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "await",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " request.",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "json",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "()",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{"variant" => "default", "class" => nil, "tokens" => []},
          %{
            "variant" => "highlighted",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "const",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "result",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#005CC5;--shiki-dark:#79B8FF"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "=",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "streamText",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "({",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "highlighted",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "    model: ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "\"anthropic/claude-sonnet-4.5\"",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#032F62;--shiki-dark:#9ECBFF"
              },
              %{
                "text" => ",",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "highlighted",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "    messages,",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "highlighted",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  })",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{"variant" => "default", "class" => nil, "tokens" => []},
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  ",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "return",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#D73A49;--shiki-dark:#F97583"
              },
              %{
                "text" => " result.",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              },
              %{
                "text" => "toUIMessageStreamResponse",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#6F42C1;--shiki-dark:#B392F0"
              },
              %{
                "text" => "()",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "}",
                "class" => "text-(--shiki-light) dark:text-(--shiki-dark)",
                "style" => "--shiki-light:#24292E;--shiki-dark:#E1E4E8"
              }
            ]
          }
        ],
        19 => ".env.local",
        20 => "AI_GATEWAY_API_KEY=your-api-key",
        21 => "code-block-streaming-copy-4",
        22 => @api_key_lines,
        23 => "http://www.w3.org/2000/svg",
        24 => "24",
        25 => "0 0 24 24",
        26 => "none",
        27 => "currentColor",
        28 => "2",
        29 => "round",
        30 => "lucide lucide-rotate-ccw",
        31 => "true",
        32 => "M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8",
        33 => "M3 3v5h5",
        34 => "Replay",
        35 => "outline",
        36 => "sm",
        37 => "self-start"
      })

    ~H"""
    <div class={@fixture[0]}>
      <CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>{@fixture[1]}</CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <CodeBlock.code_block_copy_button value={@fixture[7]} disabled={false} id={@fixture[8]} />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><.highlighted_content line_numbers={true} lines={@fixture[9]} />
      </CodeBlock.code_block><CodeBlock.code_block>
        <.highlighted_content lines={@fixture[10]} />
      </CodeBlock.code_block><CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>{@fixture[11]}</CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <CodeBlock.code_block_copy_button value={@fixture[12]} disabled={false} id={@fixture[13]} />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><.highlighted_content line_numbers={true} lines={@fixture[14]} />
      </CodeBlock.code_block><CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>{@fixture[15]}</CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <CodeBlock.code_block_copy_button value={@fixture[16]} disabled={false} id={@fixture[17]} />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><.highlighted_content line_numbers={true} lines={@fixture[18]} />
      </CodeBlock.code_block><CodeBlock.code_block>
        <CodeBlock.code_block_header>
          <CodeBlock.code_block_title>{@fixture[19]}</CodeBlock.code_block_title><CodeBlock.code_block_actions>
            <CodeBlock.code_block_copy_button value={@fixture[20]} disabled={false} id={@fixture[21]} />
          </CodeBlock.code_block_actions>
        </CodeBlock.code_block_header><.highlighted_content lines={@fixture[22]} />
      </CodeBlock.code_block><Button.button
        id={@id <> "-action-1"}
        variant={@fixture[35]}
        size={@fixture[36]}
        class={@fixture[37]}
        disabled={false}
        phx-click={Phoenix.LiveView.JS.dispatch("storybook:stream-replay", to: "#" <> @id)}
      ><svg
        xmlns={@fixture[23]}
        width={@fixture[24]}
        height={@fixture[24]}
        viewBox={@fixture[25]}
        fill={@fixture[26]}
        stroke={@fixture[27]}
        stroke-width={@fixture[28]}
        stroke-linecap={@fixture[29]}
        stroke-linejoin={@fixture[29]}
        class={@fixture[30]}
        aria-hidden={@fixture[31]}
      ><path d={@fixture[32]}></path><path d={@fixture[33]}></path></svg>{@fixture[34]}</Button.button>
    </div>
    """
  end

  def code_block_markdown_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex min-h-112 w-full max-w-md flex-col gap-4 py-6 text-sm",
        1 => "How do I debounce a search input in React?",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 => "end",
        8 => "muted",
        9 => "space-y-4 whitespace-normal [&>*:first-child]:mt-0 [&>*:last-child]:mb-0",
        10 => "Wrap the value in a ",
        11 => "rounded-sm bg-muted px-1 py-0.5 font-mono text-[0.9em]",
        12 => "useDebounce",
        13 => " hook. It returns the latest value once it stops changing for ",
        14 => "delay",
        15 => " milliseconds.",
        16 => "tsx",
        17 =>
          "export function useDebounce<T>(value: T, delay = 300) {\n  const [debounced, setDebounced] = React.useState(value)\n\n  React.useEffect(() => {\n    const timeout = setTimeout(() => setDebounced(value), delay)\n    return () => clearTimeout(timeout)\n  }, [value, delay])\n\n  return debounced\n}\n",
        18 => "code-block-markdown-copy-1",
        19 => @debounce_lines,
        20 => "Pass the debounced value to your fetch instead of the raw input.",
        21 => "Replay",
        22 => "outline",
        23 => "sm",
        24 => "mt-auto self-start"
      })

    ~H"""
    <div class={@fixture[0]}>
      <Message.message align={@fixture[7]}>
        <Message.message_content>
          <Bubble.bubble align={@fixture[7]} variant={@fixture[8]}>
            <Bubble.bubble_content>{@fixture[1]}</Bubble.bubble_content>
          </Bubble.bubble>
        </Message.message_content>
      </Message.message><Message.message>
        <Message.message_content>
          <div class={@fixture[9]}>
            <p>
              {@fixture[10]}<code class={@fixture[11]}>{@fixture[12]}</code>{@fixture[13]}<code class={
                @fixture[11]
              }>{@fixture[14]}</code>{@fixture[15]}
            </p><CodeBlock.code_block>
              <CodeBlock.code_block_header>
                <CodeBlock.code_block_title>{@fixture[16]}</CodeBlock.code_block_title><CodeBlock.code_block_actions>
                  <CodeBlock.code_block_copy_button
                    value={@fixture[17]}
                    disabled={false}
                    id={@fixture[18]}
                  />
                </CodeBlock.code_block_actions>
              </CodeBlock.code_block_header><.highlighted_content lines={@fixture[19]} />
            </CodeBlock.code_block><p>{@fixture[20]}</p>
          </div>
        </Message.message_content>
      </Message.message><Button.button
        id={@id <> "-action-1"}
        variant={@fixture[22]}
        size={@fixture[23]}
        class={@fixture[24]}
        phx-click="next"
        phx-target={@myself}
      >{@fixture[21]}</Button.button>
    </div>
    """
  end

  def code_block_markdown_messages_1(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex min-h-112 w-full max-w-md flex-col gap-4 py-6 text-sm",
        1 => "How do I debounce a search input in React?",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 => "end",
        8 => "muted",
        9 => "Replay",
        10 => "outline",
        11 => "sm",
        12 => "mt-auto self-start"
      })

    ~H"""
    <div class={@fixture[0]}>
      <Message.message align={@fixture[7]}>
        <Message.message_content>
          <Bubble.bubble align={@fixture[7]} variant={@fixture[8]}>
            <Bubble.bubble_content>{@fixture[1]}</Bubble.bubble_content>
          </Bubble.bubble>
        </Message.message_content>
      </Message.message><Button.button
        :if={false}
        id={@id <> "-action-1"}
        variant={@fixture[10]}
        size={@fixture[11]}
        class={@fixture[12]}
        phx-click="next"
        phx-target={@myself}
      >{@fixture[9]}</Button.button>
    </div>
    """
  end

  def code_block_markdown_messages_2(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex min-h-112 w-full max-w-md flex-col gap-4 py-6 text-sm",
        1 => "How do I debounce a search input in React?",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 => "end",
        8 => "muted",
        9 => "space-y-4 whitespace-normal [&>*:first-child]:mt-0 [&>*:last-child]:mb-0",
        10 => "Wrap the value in a ",
        11 => "rounded-sm bg-muted px-1 py-0.5 font-mono text-[0.9em]",
        12 => "useDebounce",
        13 => " hook. It returns the latest value once it stops changing for ",
        14 => "delay",
        15 => " milliseconds.",
        16 => "tsx",
        17 =>
          "export function useDebounce<T>(value: T, delay = 300) {\n  const [debounced, setDebounced] = React.useState(value)\n\n  React.useEffect(() => {\n    const timeout = setTimeout(() => setDebounced(value), delay)\n    return () => clearTimeout(timeout)\n  }, [value, delay])\n\n  return debounced\n}\n",
        18 => "code-block-markdown-copy-1",
        19 => @debounce_lines,
        20 => "Pass the debounced value to your fetch instead of the raw input.",
        21 => "Replay",
        22 => "outline",
        23 => "sm",
        24 => "mt-auto self-start"
      })

    ~H"""
    <div class={@fixture[0]}>
      <Message.message align={@fixture[7]}>
        <Message.message_content>
          <Bubble.bubble align={@fixture[7]} variant={@fixture[8]}>
            <Bubble.bubble_content>{@fixture[1]}</Bubble.bubble_content>
          </Bubble.bubble>
        </Message.message_content>
      </Message.message><Message.message>
        <Message.message_content>
          <div class={@fixture[9]}>
            <p>
              {@fixture[10]}<code class={@fixture[11]}>{@fixture[12]}</code>{@fixture[13]}<code class={
                @fixture[11]
              }>{@fixture[14]}</code>{@fixture[15]}
            </p><CodeBlock.code_block>
              <CodeBlock.code_block_header>
                <CodeBlock.code_block_title>{@fixture[16]}</CodeBlock.code_block_title><CodeBlock.code_block_actions>
                  <CodeBlock.code_block_copy_button
                    value={@fixture[17]}
                    disabled={false}
                    id={@fixture[18]}
                  />
                </CodeBlock.code_block_actions>
              </CodeBlock.code_block_header><.highlighted_content lines={@fixture[19]} />
            </CodeBlock.code_block><p>{@fixture[20]}</p>
          </div>
        </Message.message_content>
      </Message.message><Button.button
        id={@id <> "-action-1"}
        variant={@fixture[22]}
        size={@fixture[23]}
        class={@fixture[24]}
        phx-click="next"
        phx-target={@myself}
      >{@fixture[21]}</Button.button>
    </div>
    """
  end
end
