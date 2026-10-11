defmodule StorybookWeb.AiCodeExamples do
  @moduledoc "LiveView versions of the pinned AI code examples."
  use Phoenix.LiveComponent

  alias LiveAiElements.Components.{
    CodeBlock,
    FileTree,
    SchemaDisplay,
    Snippet,
    StackTrace,
    Terminal,
    TestResults
  }

  alias LiveShadcn.UI.Collapsible
  alias Phoenix.LiveView.JS

  @variants %{
    "code-block" => ~w(dark),
    "file-tree" => ~w(basic expanded selection),
    "schema-display" => ~w(basic body nested params),
    "snippet" => ~w(plain),
    "stack-trace" => ~w(collapsed no-internal),
    "terminal" => ~w(basic clear streaming),
    "test-results" => ~w(basic errors suites)
  }

  @code """
  function MyComponent(props) {
    return (
      <div>
        <h1>Hello, {props.name}!</h1>
        <p>This is an example React component.</p>
      </div>
    );
  }\
  """

  @terminal_lines [
    "$ npm install",
    "Installing dependencies...",
    "✓ react@19.0.0",
    "✓ typescript@5.0.0",
    "✓ vite@5.0.0",
    "",
    "Done! Installed 3 packages in 1.2s"
  ]

  def all(component) do
    Enum.map(Map.get(@variants, component, []), fn variant ->
      %{
        id: variant,
        title: variant |> String.replace("-", " ") |> String.capitalize(),
        description: "The pinned #{component} #{variant} example.",
        render: fn assigns ->
          render_example(assign(assigns, component: component, variant: variant))
        end,
        snapshot_component: __MODULE__,
        snapshot_assigns: [
          id: "code-#{component}-#{variant}",
          component: component,
          variant: variant
        ]
      }
    end)
  end

  def render_example(assigns) do
    ~H"""
    <.live_component
      module={__MODULE__}
      id={"code-#{@component}-#{@variant}"}
      component={@component}
      variant={@variant}
    />
    """
  end

  @impl true
  def update(%{tick: true}, socket) do
    count = socket.assigns.line_count + 1
    streaming = count <= length(@terminal_lines)

    socket =
      assign(socket,
        line_count: count,
        output: @terminal_lines |> Enum.take(count) |> Enum.join("\n"),
        streaming: streaming
      )

    if streaming, do: tick(socket)
    {:ok, socket}
  end

  def update(assigns, socket) do
    initial = !Map.has_key?(socket.assigns, :output)

    socket =
      socket
      |> assign(assigns)
      |> assign_new(:selected_path, fn -> nil end)
      |> assign_new(:trace_open, fn -> assigns.variant != "collapsed" end)
      |> assign_new(:output, fn -> terminal_output(assigns.variant) end)
      |> assign_new(:streaming, fn ->
        assigns.component == "terminal" && assigns.variant == "streaming"
      end)
      |> assign_new(:line_count, fn -> 0 end)
      |> assign(:code, @code)
      |> assign(:schema, schema(assigns.variant))
      |> assign(:frames, frames(assigns.variant))
      |> assign(:summary, summary(assigns.variant))
      |> assign(:trace, trace(assigns.variant))

    if initial && socket.assigns.streaming && Phoenix.LiveView.connected?(socket),
      do: tick(socket)

    {:ok, socket}
  end

  defp tick(socket),
    do: Phoenix.LiveView.send_update_after(__MODULE__, %{id: socket.assigns.id, tick: true}, 500)

  @impl true
  def handle_event("select_path", %{"path" => path}, socket),
    do: {:noreply, assign(socket, selected_path: path)}

  def handle_event("toggle_trace", _, socket), do: {:noreply, update(socket, :trace_open, &(!&1))}

  def handle_event("clear", _, socket),
    do: {:noreply, assign(socket, output: "", streaming: false)}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full max-w-xl">
      <%= case @component do %>
        <% "code-block" -> %>
          <div class="dark">
            <CodeBlock.code_block code={@code} language="jsx">
              <CodeBlock.code_block_header>
                <CodeBlock.code_block_title>
                  <LiveShadcn.Icon.icon name="file" class="size-3.5" />
                  <CodeBlock.code_block_filename>MyComponent.jsx</CodeBlock.code_block_filename>
                </CodeBlock.code_block_title>
                <CodeBlock.code_block_actions>
                  <CodeBlock.code_block_copy_button
                    id={@id <> "-copy"}
                    code={@code}
                    aria-label="Copy code"
                  />
                </CodeBlock.code_block_actions>
              </CodeBlock.code_block_header>
            </CodeBlock.code_block>
          </div>
        <% "file-tree" -> %>
          <FileTree.file_tree aria-label="Project files">
            <FileTree.file_tree_folder
              id={@id <> "-src"}
              name="src"
              path="src"
              is_expanded={to_string(@variant == "expanded")}
            >
              <FileTree.file_tree_folder
                :if={@variant == "expanded"}
                id={@id <> "-components"}
                name="components"
                path="src/components"
                is_expanded="true"
              >
                <FileTree.file_tree_file name="button.tsx" path="src/components/button.tsx" />
                <FileTree.file_tree_file name="input.tsx" path="src/components/input.tsx" />
              </FileTree.file_tree_folder>
              <FileTree.file_tree_file
                :if={@variant == "selection"}
                name="app.tsx"
                path="src/app.tsx"
                is_selected={@selected_path == "src/app.tsx"}
                phx-click="select_path"
                phx-keydown="select_path"
                phx-key="Enter"
                phx-value-path="src/app.tsx"
                phx-target={@myself}
              />
              <FileTree.file_tree_file
                name="index.ts"
                path="src/index.ts"
                is_selected={@selected_path == "src/index.ts"}
                phx-click={if @variant == "selection", do: "select_path"}
                phx-keydown={if @variant == "selection", do: "select_path"}
                phx-key="Enter"
                phx-value-path="src/index.ts"
                phx-target={@myself}
              />
            </FileTree.file_tree_folder>
            <FileTree.file_tree_file
              :if={@variant != "expanded"}
              name="package.json"
              path="package.json"
              is_selected={@selected_path == "package.json"}
              phx-click={if @variant == "selection", do: "select_path"}
              phx-keydown={if @variant == "selection", do: "select_path"}
              phx-key="Enter"
              phx-value-path="package.json"
              phx-target={@myself}
            />
          </FileTree.file_tree>
        <% "schema-display" -> %>
          <SchemaDisplay.schema_display {@schema} />
        <% "snippet" -> %>
          <Snippet.snippet code="git clone https://github.com/user/repo">
            <Snippet.snippet_input
              code="git clone https://github.com/user/repo"
              aria-label="Clone command"
            />
            <Snippet.snippet_addon align="inline-end">
              <Snippet.snippet_copy_button
                id={@id <> "-copy"}
                code="git clone https://github.com/user/repo"
                aria-label="Copy command"
              />
            </Snippet.snippet_addon>
          </Snippet.snippet>
        <% "stack-trace" -> %>
          <StackTrace.stack_trace>
            <StackTrace.stack_trace_header>
              <StackTrace.stack_trace_error>
                <StackTrace.stack_trace_error_type>TypeError</StackTrace.stack_trace_error_type>
                <StackTrace.stack_trace_error_message>
                  Cannot read properties of undefined (reading 'map')
                </StackTrace.stack_trace_error_message>
              </StackTrace.stack_trace_error>
              <StackTrace.stack_trace_actions>
                <StackTrace.stack_trace_copy_button
                  id={@id <> "-copy"}
                  raw={@trace}
                  aria-label="Copy trace"
                />
                <StackTrace.stack_trace_expand_button
                  is_open={to_string(@trace_open)}
                  phx-click="toggle_trace"
                  phx-target={@myself}
                />
              </StackTrace.stack_trace_actions>
            </StackTrace.stack_trace_header>
            <StackTrace.stack_trace_frames
              :if={@trace_open}
              frames_to_show={@frames}
              show_internal_frames={@variant != "no-internal"}
            />
          </StackTrace.stack_trace>
        <% "terminal" -> %>
          <Terminal.terminal
            id={@id <> "-terminal"}
            output={@output}
            is_streaming={@streaming}
            on_clear={if @variant == "clear", do: JS.push("clear", target: @myself)}
          />
        <% "test-results" -> %>
          <TestResults.test_results summary={@summary}>
            <TestResults.test_results_header>
              <TestResults.test_results_summary summary={@summary} />
              <TestResults.test_results_duration :if={@variant == "basic"} summary={@summary} />
            </TestResults.test_results_header>
            <TestResults.test_results_content :if={@variant != "basic"}>
              <TestResults.test_suite>
                <Collapsible.collapsible
                  id={@id <> "-suite"}
                  title={if @variant == "errors", do: "API", else: "Auth"}
                  open={@variant == "errors"}
                >
                  <%= if @variant == "errors" do %>
                    <TestResults.test duration={45} name="should fetch data" status="passed" />
                    <TestResults.test duration={85} name="should update" status="failed" />
                    <TestResults.test_error>
                      <TestResults.test_error_message>
                        Expected 200, got 500
                      </TestResults.test_error_message>
                      <TestResults.test_error_stack phx-no-format>{"    at Object.<anonymous> (/app/src/api.test.ts:45:12)\n    at Module._compile (node:internal/modules/cjs/loader:1369:14)\n    at Module._extensions..js (node:internal/modules/cjs/loader:1427:10)"}</TestResults.test_error_stack>
                    </TestResults.test_error>
                  <% else %>
                    <TestResults.test duration={45} name="should login" status="passed" />
                    <TestResults.test duration={32} name="should logout" status="passed" />
                    <TestResults.test duration={73} name="should refresh token" status="passed" />
                  <% end %>
                </Collapsible.collapsible>
              </TestResults.test_suite>
            </TestResults.test_results_content>
          </TestResults.test_results>
      <% end %>
    </div>
    """
  end

  defp terminal_output("basic"), do: "npm install complete"

  defp terminal_output("clear"),
    do: "$ npm run build\nBuilding project...\n✓ Compiled successfully\n✓ Bundle size: 124kb"

  defp terminal_output(_), do: ""

  defp schema("basic"), do: %{method: "GET", path: "/api/users", description: "List all users"}

  defp schema("params"),
    do: %{
      method: "GET",
      path: "/api/users/{userId}",
      parameters: [
        %{location: "path", name: "userId", required: true, type: "string"},
        %{location: "query", name: "include", type: "string"}
      ]
    }

  defp schema("body"),
    do: %{
      method: "POST",
      path: "/api/posts",
      request_body: [
        %{name: "title", required: true, type: "string"},
        %{name: "content", required: true, type: "string"}
      ],
      response_body: [
        %{name: "id", required: true, type: "string"},
        %{name: "createdAt", required: true, type: "string"}
      ]
    }

  defp schema("nested"),
    do: %{
      method: "POST",
      path: "/api/posts",
      request_body: [
        %{
          name: "author",
          type: "object",
          properties: [%{name: "id", type: "string"}, %{name: "name", type: "string"}]
        },
        %{name: "title", required: true, type: "string"}
      ]
    }

  defp schema(_), do: %{}

  defp frames(variant) do
    user = [frame("UserList", "/app/src/components/UserList.tsx", 15, 23, false)]

    app =
      if variant == "no-internal", do: [frame("App", "/app/src/App.tsx", 42, 5, false)], else: []

    internal =
      Enum.map(
        [{"renderWithHooks", 14_985, 18}, {"mountIndeterminateComponent", 17_811, 13}],
        fn {name, line, column} ->
          frame(name, "node_modules/react-dom/cjs/react-dom.development.js", line, column, true)
        end
      )

    tail =
      if variant == "no-internal",
        do: [
          frame(
            "beginWork",
            "node_modules/react-dom/cjs/react-dom.development.js",
            19_049,
            16,
            true
          )
        ],
        else: []

    user ++ app ++ internal ++ tail
  end

  defp frame(name, file, line, column, internal),
    do: %{
      raw: "at #{name} (#{file}:#{line}:#{column})",
      functionName: name,
      filePath: file,
      lineNumber: line,
      columnNumber: column,
      isInternal: internal
    }

  defp trace(variant),
    do:
      "TypeError: Cannot read properties of undefined (reading 'map')\n" <>
        Enum.map_join(frames(variant), "\n", &"    #{&1.raw}")

  defp summary("basic"), do: %{duration: 3500, failed: 2, passed: 10, skipped: 1, total: 13}
  defp summary("errors"), do: %{duration: 130, failed: 1, passed: 1, skipped: 0, total: 2}
  defp summary(_), do: %{duration: 150, failed: 0, passed: 3, skipped: 0, total: 3}
end
