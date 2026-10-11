defmodule StorybookWeb.AiCodeContracts do
  @moduledoc "Executable examples for the supported AI code component contracts."
  use Phoenix.LiveComponent

  alias LiveAiElements.Components.{
    Agent,
    Artifact,
    CodeBlock,
    JsxPreview,
    PackageInfo,
    Sandbox,
    SchemaDisplay,
    StackTrace,
    Terminal,
    TestResults
  }

  alias LiveShadcn.UI.{Accordion, Collapsible, Tabs}
  alias Phoenix.LiveView.JS

  def render_example(assigns) do
    ~H"""
    <.live_component module={__MODULE__} id={"code-contract-#{@component}"} component={@component} />
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       artifact_open: true,
       artifact_version: 1,
       package_updated: false,
       jsx_error: false,
       trace_open: true,
       show_internal_frames: false,
       frame_selection: nil,
       frames: [
         %{
           raw: "at parse (parser.ex:42:7)",
           functionName: "parse",
           filePath: "parser.ex",
           lineNumber: 42,
           columnNumber: 7,
           isInternal: false
         },
         %{
           raw: "at node:internal/task:95:5",
           functionName: nil,
           filePath: "node:internal/task",
           lineNumber: 95,
           columnNumber: 5,
           isInternal: true
         }
       ],
       terminal_lines: 40,
       terminal_scroll: true,
       summary: %{total: 4, passed: 2, failed: 1, skipped: 1, duration: 1250},
       code: "<script>alert(\"example\")</script>\n\n  return value;\n",
       tokens: [
         %{
           tokens: [
             %{token: %{content: "const", color: "#0000ff", fontStyle: 2}},
             %{token: %{content: " count = 1;"}}
           ]
         }
       ],
       parameters: [
         %{
           name: "id",
           type: "string",
           location: "path",
           required: true,
           description: "The person identifier."
         }
       ],
       request_body: [
         %{
           name: "profile",
           type: "object",
           required: true,
           properties: [%{name: "display_name", type: "string", description: "The public name."}]
         }
       ],
       response_body: [
         %{
           name: "people",
           type: "array",
           items: %{
             type: "object",
             properties: [%{name: "email", type: "string", description: "The contact address."}]
           }
         }
       ]
     )}
  end

  @impl true
  def handle_event("close_artifact", _, socket),
    do: {:noreply, assign(socket, artifact_open: false)}

  def handle_event("restore_artifact", _, socket),
    do: {:noreply, assign(socket, artifact_open: true)}

  def handle_event("revise_artifact", _, socket),
    do: {:noreply, update(socket, :artifact_version, &(&1 + 1))}

  def handle_event("update_package", _, socket),
    do: {:noreply, assign(socket, package_updated: true)}

  def handle_event("jsx_error", _, socket), do: {:noreply, assign(socket, jsx_error: true)}
  def handle_event("jsx_recover", _, socket), do: {:noreply, assign(socket, jsx_error: false)}

  def handle_event("toggle_trace", _, socket), do: {:noreply, update(socket, :trace_open, &(!&1))}

  def handle_event("show_internal_frames", _, socket),
    do: {:noreply, assign(socket, show_internal_frames: true)}

  def handle_event("select_frame", params, socket),
    do:
      {:noreply,
       assign(socket, frame_selection: "#{params["path"]}:#{params["line"]}:#{params["column"]}")}

  def handle_event("append_terminal", _, socket),
    do: {:noreply, update(socket, :terminal_lines, &(&1 + 20))}

  def handle_event("clear_terminal", _, socket), do: {:noreply, assign(socket, terminal_lines: 0)}

  def handle_event("disable_terminal_scroll", _, socket),
    do: {:noreply, assign(socket, terminal_scroll: false)}

  def handle_event("empty_results", _, socket),
    do:
      {:noreply,
       assign(socket, summary: %{total: 0, passed: 0, failed: 0, skipped: 0, duration: 0})}

  def handle_event("finish_results", _, socket),
    do:
      {:noreply,
       assign(socket, summary: %{total: 4, passed: 4, failed: 0, skipped: 0, duration: 130})}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full max-w-xl space-y-4">
      <%= case @component do %>
        <% "agent" -> %>
          <Agent.agent>
            <Agent.agent_header name="Code reviewer" model="review-model" />
            <Agent.agent_content>
              <Agent.agent_instructions>
                Report defects with a file and line number.
              </Agent.agent_instructions>
              <Agent.agent_tools>
                <Accordion.accordion id="review-tools">
                  <:item id="read-file-tool" title="read_file">
                    <p>Read a file from the selected repository.</p>
                    <CodeBlock.code_block code="{ path: string }" language="typescript" />
                  </:item>
                </Accordion.accordion>
              </Agent.agent_tools>
              <Agent.agent_output schema="{ findings: string[] }" />
            </Agent.agent_content>
          </Agent.agent>
        <% "artifact" -> %>
          <Artifact.artifact :if={@artifact_open} id="review-artifact">
            <Artifact.artifact_header>
              <div>
                <Artifact.artifact_title>review.txt</Artifact.artifact_title>
                <Artifact.artifact_description>
                  Review version {@artifact_version}
                </Artifact.artifact_description>
              </div>
              <Artifact.artifact_actions>
                <Artifact.artifact_action
                  icon="refresh-cw"
                  tooltip="Revise review"
                  phx-click="revise_artifact"
                  phx-target={@myself}
                />
                <Artifact.artifact_close phx-click="close_artifact" phx-target={@myself} />
              </Artifact.artifact_actions>
            </Artifact.artifact_header>
            <Artifact.artifact_content>Review content {@artifact_version}</Artifact.artifact_content>
          </Artifact.artifact>
          <button
            :if={!@artifact_open}
            type="button"
            phx-click="restore_artifact"
            phx-target={@myself}
          >Open review</button>
        <% "code-block" -> %>
          <CodeBlock.code_block id="plain-code" code={@code} language="html" show_line_numbers>
            <CodeBlock.code_block_header>
              <CodeBlock.code_block_filename>example.html</CodeBlock.code_block_filename>
              <CodeBlock.code_block_copy_button
                id="copy-plain-code"
                code={@code}
                aria-label="Copy source"
              />
            </CodeBlock.code_block_header>
          </CodeBlock.code_block>
          <CodeBlock.code_block_content
            id="highlighted-code"
            keyed_lines={@tokens}
            language="javascript"
          />
        <% "jsx-preview" -> %>
          <JsxPreview.jsx_preview>
            <JsxPreview.jsx_preview_content :if={!@jsx_error}>
              <article aria-label="Compiled preview">
                <h3>Account card</h3><p>This content comes from compiled HEEx.</p>
              </article>
            </JsxPreview.jsx_preview_content>
            <JsxPreview.jsx_preview_error error={
              if @jsx_error, do: %{message: "The closing tag is missing."}
            } />
          </JsxPreview.jsx_preview>
          <button type="button" phx-click="jsx_error" phx-target={@myself}>Show compilation error</button>
          <button type="button" phx-click="jsx_recover" phx-target={@myself}>Restore compiled preview</button>
          <JsxPreview.jsx_preview_error id="custom-preview-error" error="Compile failed">
            <p>Custom error details</p>
          </JsxPreview.jsx_preview_error>
        <% "package-info" -> %>
          <PackageInfo.package_info
            id="package-change"
            name="live_ai_elements"
            current_version="0.1.0"
            new_version={if @package_updated, do: "0.2.0", else: "0.1.1"}
            change_type={if @package_updated, do: "minor", else: "patch"}
          />
          <PackageInfo.package_info>
            <PackageInfo.package_info_header>
              <PackageInfo.package_info_name name="review-tools" />
            </PackageInfo.package_info_header>
            <PackageInfo.package_info_description>
              Tools for a code review.
            </PackageInfo.package_info_description>
            <PackageInfo.package_info_content>
              <PackageInfo.package_info_dependencies>
                <PackageInfo.package_info_dependency name="phoenix_live_view" version="~> 1.2" />
                <PackageInfo.package_info_dependency name="jason" version="~> 1.4" />
              </PackageInfo.package_info_dependencies>
            </PackageInfo.package_info_content>
          </PackageInfo.package_info>
          <button type="button" phx-click="update_package" phx-target={@myself}>Use minor update</button>
        <% "sandbox" -> %>
          <Collapsible.collapsible id="code-sandbox" title="Generated application" open>
            <Sandbox.sandbox_tabs_bar>
              <Tabs.tabs id="sandbox-files" value="source">
                <:tab value="source" label="Source">
                  <CodeBlock.code_block code="export default function App() {}" language="javascript" />
                </:tab>
                <:tab value="output" label="Output">
                  <p>Application ready.</p>
                </:tab>
              </Tabs.tabs>
            </Sandbox.sandbox_tabs_bar>
          </Collapsible.collapsible>
        <% "schema-display" -> %>
          <SchemaDisplay.schema_display
            id="person-schema"
            method="POST"
            path="/people/{id}"
            description="Update one person."
            parameters={@parameters}
            request_body={@request_body}
            response_body={@response_body}
          />
          <SchemaDisplay.schema_display_path
            id="escaped-path"
            path="/search/<script>unsafe</script>/{term}"
          />
        <% "test-results" -> %>
          <TestResults.test_results>
            <TestResults.test_results_header>
              <TestResults.test_results_summary summary={@summary} />
              <TestResults.test_results_duration id="run-duration" summary={@summary} />
            </TestResults.test_results_header>
            <TestResults.test_results_content>
              <TestResults.test_results_progress id="test-progress" summary={@summary} />
              <TestResults.test_suite name="Parser" status="failed">
                <Collapsible.collapsible id="parser-suite" title="Parser results">
                  <TestResults.test name="parses a valid record" status="passed" duration={14} />
                  <TestResults.test name="rejects invalid input" status="failed" duration={7} />
                  <TestResults.test_error>
                    <TestResults.test_error_message>
                      Expected a validation error.
                    </TestResults.test_error_message>
                    <TestResults.test_error_stack>parser_test.exs:42</TestResults.test_error_stack>
                  </TestResults.test_error>
                </Collapsible.collapsible>
              </TestResults.test_suite>
            </TestResults.test_results_content>
          </TestResults.test_results>
          <button type="button" phx-click="finish_results" phx-target={@myself}>Finish test run</button>
          <button type="button" phx-click="empty_results" phx-target={@myself}>Clear test results</button>
        <% "stack-trace" -> %>
          <StackTrace.stack_trace>
            <StackTrace.stack_trace_header>
              <StackTrace.stack_trace_error>
                <StackTrace.stack_trace_error_type>ParseError</StackTrace.stack_trace_error_type>
                <StackTrace.stack_trace_error_message>
                  Invalid record
                </StackTrace.stack_trace_error_message>
              </StackTrace.stack_trace_error>
              <StackTrace.stack_trace_expand_button
                is_open={to_string(@trace_open)}
                phx-click="toggle_trace"
                phx-target={@myself}
              />
            </StackTrace.stack_trace_header>
            <StackTrace.stack_trace_frames
              :if={@trace_open}
              id="trace-frames"
              frames_to_show={@frames}
              show_internal_frames={@show_internal_frames}
              on_select={JS.push("select_frame", target: @myself)}
            />
          </StackTrace.stack_trace>
          <button type="button" phx-click="show_internal_frames" phx-target={@myself}>Include internal frames</button>
          <p :if={@frame_selection} role="status">Selected {@frame_selection}</p>
          <StackTrace.stack_trace_frames id="empty-trace" />
        <% "terminal" -> %>
          <Terminal.terminal
            id="streaming-terminal"
            output={terminal_output(@terminal_lines)}
            is_streaming={@terminal_lines > 0}
            auto_scroll={@terminal_scroll}
            on_clear={JS.push("clear_terminal", target: @myself)}
          />
          <button type="button" phx-click="append_terminal" phx-target={@myself}>Append output</button>
          <button type="button" phx-click="disable_terminal_scroll" phx-target={@myself}>Keep scroll position</button>
      <% end %>
    </div>
    """
  end

  defp terminal_output(0), do: ""

  defp terminal_output(lines),
    do: Enum.map_join(1..lines, "\n", &"Build line #{&1}") <> "\nBuild error"
end
