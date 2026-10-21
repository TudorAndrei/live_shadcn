defmodule StorybookWeb.ShadcnAiExamples do
  @moduledoc "Native LiveView examples of the pinned shadcn Code Block and Trace parts."
  use Phoenix.LiveComponent
  alias LiveShadcn.UI.{Badge, Bubble, Button, CodeBlock, Dialog, Message, Sheet, Trace}
  alias StorybookWeb.ShadcnCodeBlockExamples, as: CodeExamples

  @variants %{
    "trace" =>
      ~w(default static status description collapsible open link dialog sheet group sources steps commit turn thinking tool-calls),
    "shadcn-code-block" =>
      ~w(default basic header actions floating-actions line-numbers start-line wrap highlighted-lines diff height show-more show-more-scroll size destructive trace tabs chat typeset rtl highlighting languages ansi streaming markdown)
  }

  def all(component) do
    Enum.map(Map.fetch!(@variants, component), fn variant ->
      %{
        id: variant,
        title: String.capitalize(String.replace(variant, "-", " ")),
        description: "The official #{component} #{variant} example.",
        render: fn assigns ->
          render_example(assign(assigns, component: component, variant: variant))
        end,
        snapshot_component: __MODULE__,
        snapshot_assigns: [
          id: "native-#{component}-#{variant}",
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
      id={"native-#{@component}-#{@variant}"}
      component={@component}
      variant={@variant}
    />
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:expanded, fn -> false end)
     |> assign_new(:phase, fn -> "initial" end)}
  end

  @impl true
  def handle_event("toggle", _, socket), do: {:noreply, update(socket, :expanded, &(!&1))}

  def handle_event("next", _, socket) do
    phase = if socket.assigns.phase == "initial", do: "messages-1", else: "initial"

    if phase == "messages-1",
      do:
        Phoenix.LiveView.send_update_after(
          __MODULE__,
          %{id: socket.assigns.id, phase: "messages-2"},
          600
        )

    {:noreply, assign(socket, :phase, phase)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="contents" data-phase={@phase} phx-hook="ShadcnCodeStreaming">
      <%= case {@component, @variant} do %>
        <% {"trace", "default"} -> %>
          <%= case @phase do %>
            <% "initial" -> %>
              <.trace_demo_initial {assigns} />
            <% "messages-1" -> %>
              <.trace_demo_messages_1 {assigns} />
            <% "messages-2" -> %>
              <.trace_demo_messages_2 {assigns} />
          <% end %>
        <% {"trace", "static"} -> %>
          <.trace_static_initial {assigns} />
        <% {"trace", "status"} -> %>
          <.trace_status_initial {assigns} />
        <% {"trace", "description"} -> %>
          <.trace_description_initial {assigns} />
        <% {"trace", "collapsible"} -> %>
          <.trace_collapsible_initial {assigns} />
        <% {"trace", "open"} -> %>
          <.trace_open_toggle :if={@expanded} {assigns} /><.trace_open_initial
            :if={not @expanded}
            {assigns}
          />
        <% {"trace", "link"} -> %>
          <.trace_link_initial {assigns} />
        <% {"trace", "dialog"} -> %>
          <.trace_dialog_initial {assigns} />
        <% {"trace", "sheet"} -> %>
          <.trace_sheet_initial {assigns} />
        <% {"trace", "group"} -> %>
          <.trace_group_initial {assigns} />
        <% {"trace", "sources"} -> %>
          <.trace_sources_initial {assigns} />
        <% {"trace", "steps"} -> %>
          <.trace_steps_initial {assigns} />
        <% {"trace", "commit"} -> %>
          <.trace_commit_initial {assigns} />
        <% {"trace", "turn"} -> %>
          <.trace_turn_initial {assigns} />
        <% {"trace", "thinking"} -> %>
          <%= case @phase do %>
            <% "initial" -> %>
              <.trace_thinking_initial {assigns} />
            <% "messages-1" -> %>
              <.trace_thinking_messages_1 {assigns} />
            <% "messages-2" -> %>
              <.trace_thinking_messages_2 {assigns} />
          <% end %>
        <% {"trace", "tool-calls"} -> %>
          <%= case @phase do %>
            <% "initial" -> %>
              <.trace_tool_calls_initial {assigns} />
            <% "messages-1" -> %>
              <.trace_tool_calls_messages_1 {assigns} />
            <% "messages-2" -> %>
              <.trace_tool_calls_messages_2 {assigns} />
          <% end %>
        <% {"shadcn-code-block", "default"} -> %>
          <CodeExamples.code_block_demo_toggle :if={@expanded} {assigns} /><CodeExamples.code_block_demo_initial
            :if={not @expanded}
            {assigns}
          />
        <% {"shadcn-code-block", "basic"} -> %>
          <CodeExamples.code_block_basic_initial {assigns} />
        <% {"shadcn-code-block", "header"} -> %>
          <CodeExamples.code_block_header_initial {assigns} />
        <% {"shadcn-code-block", "actions"} -> %>
          <CodeExamples.code_block_actions_initial {assigns} />
        <% {"shadcn-code-block", "floating-actions"} -> %>
          <CodeExamples.code_block_floating_actions_initial {assigns} />
        <% {"shadcn-code-block", "line-numbers"} -> %>
          <CodeExamples.code_block_line_numbers_initial {assigns} />
        <% {"shadcn-code-block", "start-line"} -> %>
          <CodeExamples.code_block_start_line_initial {assigns} />
        <% {"shadcn-code-block", "wrap"} -> %>
          <CodeExamples.code_block_wrap_initial {assigns} />
        <% {"shadcn-code-block", "highlighted-lines"} -> %>
          <CodeExamples.code_block_highlighted_lines_initial {assigns} />
        <% {"shadcn-code-block", "diff"} -> %>
          <CodeExamples.code_block_diff_initial {assigns} />
        <% {"shadcn-code-block", "height"} -> %>
          <CodeExamples.code_block_height_initial {assigns} />
        <% {"shadcn-code-block", "show-more"} -> %>
          <CodeExamples.code_block_show_more_toggle :if={@expanded} {assigns} /><CodeExamples.code_block_show_more_initial
            :if={not @expanded}
            {assigns}
          />
        <% {"shadcn-code-block", "show-more-scroll"} -> %>
          <CodeExamples.code_block_show_more_scroll_toggle :if={@expanded} {assigns} /><CodeExamples.code_block_show_more_scroll_initial
            :if={not @expanded}
            {assigns}
          />
        <% {"shadcn-code-block", "size"} -> %>
          <CodeExamples.code_block_size_initial {assigns} />
        <% {"shadcn-code-block", "destructive"} -> %>
          <CodeExamples.code_block_destructive_initial {assigns} />
        <% {"shadcn-code-block", "trace"} -> %>
          <CodeExamples.code_block_trace_initial {assigns} />
        <% {"shadcn-code-block", "tabs"} -> %>
          <CodeExamples.code_block_tabs_initial {assigns} />
        <% {"shadcn-code-block", "chat"} -> %>
          <CodeExamples.code_block_chat_initial {assigns} />
        <% {"shadcn-code-block", "typeset"} -> %>
          <CodeExamples.code_block_typeset_initial {assigns} />
        <% {"shadcn-code-block", "rtl"} -> %>
          <CodeExamples.code_block_rtl_initial {assigns} />
        <% {"shadcn-code-block", "highlighting"} -> %>
          <CodeExamples.code_block_highlighting_initial {assigns} />
        <% {"shadcn-code-block", "languages"} -> %>
          <CodeExamples.code_block_languages_initial {assigns} />
        <% {"shadcn-code-block", "ansi"} -> %>
          <CodeExamples.code_block_ansi_initial {assigns} />
        <% {"shadcn-code-block", "streaming"} -> %>
          <CodeExamples.code_block_streaming_initial {assigns} />
        <% {"shadcn-code-block", "markdown"} -> %>
          <%= case @phase do %>
            <% "initial" -> %>
              <CodeExamples.code_block_markdown_initial {assigns} />
            <% "messages-1" -> %>
              <CodeExamples.code_block_markdown_messages_1 {assigns} />
            <% "messages-2" -> %>
              <CodeExamples.code_block_markdown_messages_2 {assigns} />
          <% end %>
      <% end %>
    </div>
    """
  end

  defp trace_demo_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex min-h-72 w-full max-w-sm flex-col gap-4 py-6 text-sm",
        1 => "Why does pnpm install fail in CI?",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 => "end",
        8 => "muted",
        9 => "http://www.w3.org/2000/svg",
        10 => "24",
        11 => "0 0 24 24",
        12 => "none",
        13 => "currentColor",
        14 => "2",
        15 => "round",
        16 => "lucide lucide-circle-check",
        17 => "true",
        18 => "12",
        19 => "10",
        20 => "m9 12 2 2 4-4",
        21 => "Thought for 5s",
        22 => "trace-demo-trace-1",
        23 =>
          "CI installs with a frozen lockfile, so the install stops when package.json and pnpm-lock.yaml disagree. I should check what the last commit changed, then reproduce the install.",
        24 => "whitespace-pre-wrap",
        25 => "Ran pnpm --version",
        26 => "trace-demo-trace-2",
        27 => "max-h-64",
        28 => "10.18.0",
        29 => "sm",
        30 => "Ran git diff --stat HEAD~1 -- package.json pnpm-lock.yaml",
        31 => "trace-demo-trace-3",
        32 => " package.json | 2 +-\n 1 file changed, 1 insertion(+), 1 deletion(-)",
        33 => "lucide lucide-circle-alert",
        34 => "8",
        35 => "12.01",
        36 => "16",
        37 => "Failed to run pnpm install --frozen-lockfile",
        38 => "error",
        39 => "trace-demo-trace-4",
        40 =>
          "ERR_PNPM_OUTDATED_LOCKFILE  Cannot install with \"frozen-lockfile\" because pnpm-lock.yaml is not up to date with package.json",
        41 => "destructive",
        42 => "lucide lucide-globe",
        43 => "M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20",
        44 => "M2 12h20",
        45 => "Used 2 sources",
        46 => "trace-demo-trace-5",
        47 => "https://pnpm.io/cli/install#--frozen-lockfile",
        48 => "_blank",
        49 => "noreferrer",
        50 => "pnpm install | pnpm.io",
        51 => "sr-only",
        52 => " (opens in a new tab)",
        53 => "lucide lucide-arrow-up-right",
        54 => "M7 7h10v10",
        55 => "M7 17 17 7",
        56 => "https://pnpm.io/continuous-integration",
        57 => "Continuous Integration | pnpm.io",
        58 =>
          "The last commit bumped a version in package.json without updating pnpm-lock.yaml, so the frozen install fails. Run pnpm install locally and commit the lockfile.",
        59 => "gap-4",
        60 => "Replay",
        61 => "outline",
        62 => "mt-auto self-start"
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
        <Message.message_content class={@fixture[59]}>
          <Trace.trace>
            <Trace.trace_collapsible id={@fixture[22]} open={false}>
              <Trace.trace_collapsible_trigger
                for={@fixture[22]}
                open={false}
                phx-click="toggle"
                phx-target={@myself}
              >
                <Trace.trace_line>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[9]}
                      width={@fixture[10]}
                      height={@fixture[10]}
                      viewBox={@fixture[11]}
                      fill={@fixture[12]}
                      stroke={@fixture[13]}
                      stroke-width={@fixture[14]}
                      stroke-linecap={@fixture[15]}
                      stroke-linejoin={@fixture[15]}
                      class={@fixture[16]}
                      aria-hidden={@fixture[17]}
                    ><circle cx={@fixture[18]} cy={@fixture[18]} r={@fixture[19]}></circle><path d={
                      @fixture[20]
                    }>
                    </path></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[21]}</Trace.trace_title>
                </Trace.trace_line>
              </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
                phx-no-format
                class={@fixture[24]}
                for={@fixture[22]}
                open={false}
              >{@fixture[23]}</Trace.trace_collapsible_content>
            </Trace.trace_collapsible><Trace.trace_collapsible id={@fixture[26]} open={false}>
              <Trace.trace_collapsible_trigger for={@fixture[26]} open={false}>
                <Trace.trace_line>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[9]}
                      width={@fixture[10]}
                      height={@fixture[10]}
                      viewBox={@fixture[11]}
                      fill={@fixture[12]}
                      stroke={@fixture[13]}
                      stroke-width={@fixture[14]}
                      stroke-linecap={@fixture[15]}
                      stroke-linejoin={@fixture[15]}
                      class={@fixture[16]}
                      aria-hidden={@fixture[17]}
                    ><circle cx={@fixture[18]} cy={@fixture[18]} r={@fixture[19]}></circle><path d={
                      @fixture[20]
                    }>
                    </path></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[25]}</Trace.trace_title>
                </Trace.trace_line>
              </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
                phx-no-format
                for={@fixture[26]}
                open={false}
              >
                <CodeBlock.code_block size={@fixture[29]}>
                  <CodeBlock.code_block_content wrap={true} class={@fixture[27]} code={@fixture[28]} />
                </CodeBlock.code_block>
              </Trace.trace_collapsible_content>
            </Trace.trace_collapsible><Trace.trace_collapsible id={@fixture[31]} open={true}>
              <Trace.trace_collapsible_trigger for={@fixture[31]} open={true}>
                <Trace.trace_line>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[9]}
                      width={@fixture[10]}
                      height={@fixture[10]}
                      viewBox={@fixture[11]}
                      fill={@fixture[12]}
                      stroke={@fixture[13]}
                      stroke-width={@fixture[14]}
                      stroke-linecap={@fixture[15]}
                      stroke-linejoin={@fixture[15]}
                      class={@fixture[16]}
                      aria-hidden={@fixture[17]}
                    ><circle cx={@fixture[18]} cy={@fixture[18]} r={@fixture[19]}></circle><path d={
                      @fixture[20]
                    }>
                    </path></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[30]}</Trace.trace_title>
                </Trace.trace_line>
              </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
                phx-no-format
                for={@fixture[31]}
                open={true}
              >
                <CodeBlock.code_block size={@fixture[29]}>
                  <CodeBlock.code_block_content wrap={true} class={@fixture[27]} code={@fixture[32]} />
                </CodeBlock.code_block>
              </Trace.trace_collapsible_content>
            </Trace.trace_collapsible><Trace.trace_collapsible id={@fixture[39]} open={false}>
              <Trace.trace_collapsible_trigger for={@fixture[39]} open={false}>
                <Trace.trace_line status={@fixture[38]}>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[9]}
                      width={@fixture[10]}
                      height={@fixture[10]}
                      viewBox={@fixture[11]}
                      fill={@fixture[12]}
                      stroke={@fixture[13]}
                      stroke-width={@fixture[14]}
                      stroke-linecap={@fixture[15]}
                      stroke-linejoin={@fixture[15]}
                      class={@fixture[33]}
                      aria-hidden={@fixture[17]}
                    ><circle cx={@fixture[18]} cy={@fixture[18]} r={@fixture[19]}></circle><line
                      x1={@fixture[18]}
                      x2={@fixture[18]}
                      y1={@fixture[34]}
                      y2={@fixture[18]}
                    >
                    </line><line
                      x1={@fixture[18]}
                      x2={@fixture[35]}
                      y1={@fixture[36]}
                      y2={@fixture[36]}
                    >
                    </line></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[37]}</Trace.trace_title>
                </Trace.trace_line>
              </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
                phx-no-format
                for={@fixture[39]}
                open={false}
              >
                <CodeBlock.code_block size={@fixture[29]} variant={@fixture[41]}>
                  <CodeBlock.code_block_content wrap={true} class={@fixture[27]} code={@fixture[40]} />
                </CodeBlock.code_block>
              </Trace.trace_collapsible_content>
            </Trace.trace_collapsible><Trace.trace_collapsible id={@fixture[46]} open={false}>
              <Trace.trace_collapsible_trigger for={@fixture[46]} open={false}>
                <Trace.trace_line>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[9]}
                      width={@fixture[10]}
                      height={@fixture[10]}
                      viewBox={@fixture[11]}
                      fill={@fixture[12]}
                      stroke={@fixture[13]}
                      stroke-width={@fixture[14]}
                      stroke-linecap={@fixture[15]}
                      stroke-linejoin={@fixture[15]}
                      class={@fixture[42]}
                      aria-hidden={@fixture[17]}
                    ><circle cx={@fixture[18]} cy={@fixture[18]} r={@fixture[19]}></circle><path d={
                      @fixture[43]
                    }>
                    </path><path d={@fixture[44]}></path></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[45]}</Trace.trace_title>
                </Trace.trace_line>
              </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
                phx-no-format
                for={@fixture[46]}
                open={false}
              >
                <Trace.trace>
                  <a href={@fixture[47]} target={@fixture[48]} rel={@fixture[49]}><Trace.trace_line>
                    <Trace.trace_icon>
                      <svg
                        xmlns={@fixture[9]}
                        width={@fixture[10]}
                        height={@fixture[10]}
                        viewBox={@fixture[11]}
                        fill={@fixture[12]}
                        stroke={@fixture[13]}
                        stroke-width={@fixture[14]}
                        stroke-linecap={@fixture[15]}
                        stroke-linejoin={@fixture[15]}
                        class={@fixture[42]}
                        aria-hidden={@fixture[17]}
                      ><circle cx={@fixture[18]} cy={@fixture[18]} r={@fixture[19]}></circle><path d={
                        @fixture[43]
                      }>
                      </path><path d={@fixture[44]}></path></svg>
                    </Trace.trace_icon><Trace.trace_title>
                      {@fixture[50]}<span class={@fixture[51]}>{@fixture[52]}</span>
                    </Trace.trace_title><Trace.trace_icon>
                      <svg
                        xmlns={@fixture[9]}
                        width={@fixture[10]}
                        height={@fixture[10]}
                        viewBox={@fixture[11]}
                        fill={@fixture[12]}
                        stroke={@fixture[13]}
                        stroke-width={@fixture[14]}
                        stroke-linecap={@fixture[15]}
                        stroke-linejoin={@fixture[15]}
                        class={@fixture[53]}
                        aria-hidden={@fixture[17]}
                      ><path d={@fixture[54]}></path><path d={@fixture[55]}></path></svg>
                    </Trace.trace_icon>
                  </Trace.trace_line></a><a
                    href={@fixture[56]}
                    target={@fixture[48]}
                    rel={@fixture[49]}
                  ><Trace.trace_line>
                    <Trace.trace_icon>
                      <svg
                        xmlns={@fixture[9]}
                        width={@fixture[10]}
                        height={@fixture[10]}
                        viewBox={@fixture[11]}
                        fill={@fixture[12]}
                        stroke={@fixture[13]}
                        stroke-width={@fixture[14]}
                        stroke-linecap={@fixture[15]}
                        stroke-linejoin={@fixture[15]}
                        class={@fixture[42]}
                        aria-hidden={@fixture[17]}
                      ><circle cx={@fixture[18]} cy={@fixture[18]} r={@fixture[19]}></circle><path d={
                        @fixture[43]
                      }>
                      </path><path d={@fixture[44]}></path></svg>
                    </Trace.trace_icon><Trace.trace_title>
                      {@fixture[57]}<span class={@fixture[51]}>{@fixture[52]}</span>
                    </Trace.trace_title><Trace.trace_icon>
                      <svg
                        xmlns={@fixture[9]}
                        width={@fixture[10]}
                        height={@fixture[10]}
                        viewBox={@fixture[11]}
                        fill={@fixture[12]}
                        stroke={@fixture[13]}
                        stroke-width={@fixture[14]}
                        stroke-linecap={@fixture[15]}
                        stroke-linejoin={@fixture[15]}
                        class={@fixture[53]}
                        aria-hidden={@fixture[17]}
                      ><path d={@fixture[54]}></path><path d={@fixture[55]}></path></svg>
                    </Trace.trace_icon>
                  </Trace.trace_line></a>
                </Trace.trace>
              </Trace.trace_collapsible_content>
            </Trace.trace_collapsible>
          </Trace.trace><p>{@fixture[58]}</p>
        </Message.message_content>
      </Message.message><Button.button
        id={@id <> "-action-1"}
        variant={@fixture[61]}
        size={@fixture[29]}
        class={@fixture[62]}
        phx-click="next"
        phx-target={@myself}
      >{@fixture[60]}</Button.button>
    </div>
    """
  end

  defp trace_demo_messages_1(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex min-h-72 w-full max-w-sm flex-col gap-4 py-6 text-sm",
        1 => "Why does pnpm install fail in CI?",
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

  defp trace_demo_messages_2(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex min-h-72 w-full max-w-sm flex-col gap-4 py-6 text-sm",
        1 => "Why does pnpm install fail in CI?",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 => "end",
        8 => "muted",
        9 => "http://www.w3.org/2000/svg",
        10 => "24",
        11 => "0 0 24 24",
        12 => "none",
        13 => "currentColor",
        14 => "2",
        15 => "round",
        16 => "lucide lucide-circle-check",
        17 => "true",
        18 => "12",
        19 => "10",
        20 => "m9 12 2 2 4-4",
        21 => "Thought for 5s",
        22 => "trace-demo-trace-1",
        23 =>
          "CI installs with a frozen lockfile, so the install stops when package.json and pnpm-lock.yaml disagree. I should check what the last commit changed, then reproduce the install.",
        24 => "whitespace-pre-wrap",
        25 => "Ran pnpm --version",
        26 => "trace-demo-trace-2",
        27 => "max-h-64",
        28 => "10.18.0",
        29 => "sm",
        30 => "Ran git diff --stat HEAD~1 -- package.json pnpm-lock.yaml",
        31 => "trace-demo-trace-3",
        32 => " package.json | 2 +-\n 1 file changed, 1 insertion(+), 1 deletion(-)",
        33 => "lucide lucide-circle-alert",
        34 => "8",
        35 => "12.01",
        36 => "16",
        37 => "Failed to run pnpm install --frozen-lockfile",
        38 => "error",
        39 => "trace-demo-trace-4",
        40 =>
          "ERR_PNPM_OUTDATED_LOCKFILE  Cannot install with \"frozen-lockfile\" because pnpm-lock.yaml is not up to date with package.json",
        41 => "destructive",
        42 => "lucide lucide-globe",
        43 => "M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20",
        44 => "M2 12h20",
        45 => "Used 2 sources",
        46 => "trace-demo-trace-5",
        47 => "https://pnpm.io/cli/install#--frozen-lockfile",
        48 => "_blank",
        49 => "noreferrer",
        50 => "pnpm install | pnpm.io",
        51 => "sr-only",
        52 => " (opens in a new tab)",
        53 => "lucide lucide-arrow-up-right",
        54 => "M7 7h10v10",
        55 => "M7 17 17 7",
        56 => "https://pnpm.io/continuous-integration",
        57 => "Continuous Integration | pnpm.io",
        58 =>
          "The last commit bumped a version in package.json without updating pnpm-lock.yaml, so the frozen install fails. Run pnpm install locally and commit the lockfile.",
        59 => "gap-4",
        60 => "Replay",
        61 => "outline",
        62 => "mt-auto self-start"
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
        <Message.message_content class={@fixture[59]}>
          <Trace.trace>
            <Trace.trace_collapsible id={@fixture[22]} open={false}>
              <Trace.trace_collapsible_trigger
                for={@fixture[22]}
                open={false}
                phx-click="toggle"
                phx-target={@myself}
              >
                <Trace.trace_line>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[9]}
                      width={@fixture[10]}
                      height={@fixture[10]}
                      viewBox={@fixture[11]}
                      fill={@fixture[12]}
                      stroke={@fixture[13]}
                      stroke-width={@fixture[14]}
                      stroke-linecap={@fixture[15]}
                      stroke-linejoin={@fixture[15]}
                      class={@fixture[16]}
                      aria-hidden={@fixture[17]}
                    ><circle cx={@fixture[18]} cy={@fixture[18]} r={@fixture[19]}></circle><path d={
                      @fixture[20]
                    }>
                    </path></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[21]}</Trace.trace_title>
                </Trace.trace_line>
              </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
                phx-no-format
                class={@fixture[24]}
                for={@fixture[22]}
                open={false}
              >{@fixture[23]}</Trace.trace_collapsible_content>
            </Trace.trace_collapsible><Trace.trace_collapsible id={@fixture[26]} open={false}>
              <Trace.trace_collapsible_trigger for={@fixture[26]} open={false}>
                <Trace.trace_line>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[9]}
                      width={@fixture[10]}
                      height={@fixture[10]}
                      viewBox={@fixture[11]}
                      fill={@fixture[12]}
                      stroke={@fixture[13]}
                      stroke-width={@fixture[14]}
                      stroke-linecap={@fixture[15]}
                      stroke-linejoin={@fixture[15]}
                      class={@fixture[16]}
                      aria-hidden={@fixture[17]}
                    ><circle cx={@fixture[18]} cy={@fixture[18]} r={@fixture[19]}></circle><path d={
                      @fixture[20]
                    }>
                    </path></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[25]}</Trace.trace_title>
                </Trace.trace_line>
              </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
                phx-no-format
                for={@fixture[26]}
                open={false}
              >
                <CodeBlock.code_block size={@fixture[29]}>
                  <CodeBlock.code_block_content wrap={true} class={@fixture[27]} code={@fixture[28]} />
                </CodeBlock.code_block>
              </Trace.trace_collapsible_content>
            </Trace.trace_collapsible><Trace.trace_collapsible id={@fixture[31]} open={true}>
              <Trace.trace_collapsible_trigger for={@fixture[31]} open={true}>
                <Trace.trace_line>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[9]}
                      width={@fixture[10]}
                      height={@fixture[10]}
                      viewBox={@fixture[11]}
                      fill={@fixture[12]}
                      stroke={@fixture[13]}
                      stroke-width={@fixture[14]}
                      stroke-linecap={@fixture[15]}
                      stroke-linejoin={@fixture[15]}
                      class={@fixture[16]}
                      aria-hidden={@fixture[17]}
                    ><circle cx={@fixture[18]} cy={@fixture[18]} r={@fixture[19]}></circle><path d={
                      @fixture[20]
                    }>
                    </path></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[30]}</Trace.trace_title>
                </Trace.trace_line>
              </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
                phx-no-format
                for={@fixture[31]}
                open={true}
              >
                <CodeBlock.code_block size={@fixture[29]}>
                  <CodeBlock.code_block_content wrap={true} class={@fixture[27]} code={@fixture[32]} />
                </CodeBlock.code_block>
              </Trace.trace_collapsible_content>
            </Trace.trace_collapsible><Trace.trace_collapsible id={@fixture[39]} open={false}>
              <Trace.trace_collapsible_trigger for={@fixture[39]} open={false}>
                <Trace.trace_line status={@fixture[38]}>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[9]}
                      width={@fixture[10]}
                      height={@fixture[10]}
                      viewBox={@fixture[11]}
                      fill={@fixture[12]}
                      stroke={@fixture[13]}
                      stroke-width={@fixture[14]}
                      stroke-linecap={@fixture[15]}
                      stroke-linejoin={@fixture[15]}
                      class={@fixture[33]}
                      aria-hidden={@fixture[17]}
                    ><circle cx={@fixture[18]} cy={@fixture[18]} r={@fixture[19]}></circle><line
                      x1={@fixture[18]}
                      x2={@fixture[18]}
                      y1={@fixture[34]}
                      y2={@fixture[18]}
                    >
                    </line><line
                      x1={@fixture[18]}
                      x2={@fixture[35]}
                      y1={@fixture[36]}
                      y2={@fixture[36]}
                    >
                    </line></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[37]}</Trace.trace_title>
                </Trace.trace_line>
              </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
                phx-no-format
                for={@fixture[39]}
                open={false}
              >
                <CodeBlock.code_block size={@fixture[29]} variant={@fixture[41]}>
                  <CodeBlock.code_block_content wrap={true} class={@fixture[27]} code={@fixture[40]} />
                </CodeBlock.code_block>
              </Trace.trace_collapsible_content>
            </Trace.trace_collapsible><Trace.trace_collapsible id={@fixture[46]} open={false}>
              <Trace.trace_collapsible_trigger for={@fixture[46]} open={false}>
                <Trace.trace_line>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[9]}
                      width={@fixture[10]}
                      height={@fixture[10]}
                      viewBox={@fixture[11]}
                      fill={@fixture[12]}
                      stroke={@fixture[13]}
                      stroke-width={@fixture[14]}
                      stroke-linecap={@fixture[15]}
                      stroke-linejoin={@fixture[15]}
                      class={@fixture[42]}
                      aria-hidden={@fixture[17]}
                    ><circle cx={@fixture[18]} cy={@fixture[18]} r={@fixture[19]}></circle><path d={
                      @fixture[43]
                    }>
                    </path><path d={@fixture[44]}></path></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[45]}</Trace.trace_title>
                </Trace.trace_line>
              </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
                phx-no-format
                for={@fixture[46]}
                open={false}
              >
                <Trace.trace>
                  <a href={@fixture[47]} target={@fixture[48]} rel={@fixture[49]}><Trace.trace_line>
                    <Trace.trace_icon>
                      <svg
                        xmlns={@fixture[9]}
                        width={@fixture[10]}
                        height={@fixture[10]}
                        viewBox={@fixture[11]}
                        fill={@fixture[12]}
                        stroke={@fixture[13]}
                        stroke-width={@fixture[14]}
                        stroke-linecap={@fixture[15]}
                        stroke-linejoin={@fixture[15]}
                        class={@fixture[42]}
                        aria-hidden={@fixture[17]}
                      ><circle cx={@fixture[18]} cy={@fixture[18]} r={@fixture[19]}></circle><path d={
                        @fixture[43]
                      }>
                      </path><path d={@fixture[44]}></path></svg>
                    </Trace.trace_icon><Trace.trace_title>
                      {@fixture[50]}<span class={@fixture[51]}>{@fixture[52]}</span>
                    </Trace.trace_title><Trace.trace_icon>
                      <svg
                        xmlns={@fixture[9]}
                        width={@fixture[10]}
                        height={@fixture[10]}
                        viewBox={@fixture[11]}
                        fill={@fixture[12]}
                        stroke={@fixture[13]}
                        stroke-width={@fixture[14]}
                        stroke-linecap={@fixture[15]}
                        stroke-linejoin={@fixture[15]}
                        class={@fixture[53]}
                        aria-hidden={@fixture[17]}
                      ><path d={@fixture[54]}></path><path d={@fixture[55]}></path></svg>
                    </Trace.trace_icon>
                  </Trace.trace_line></a><a
                    href={@fixture[56]}
                    target={@fixture[48]}
                    rel={@fixture[49]}
                  ><Trace.trace_line>
                    <Trace.trace_icon>
                      <svg
                        xmlns={@fixture[9]}
                        width={@fixture[10]}
                        height={@fixture[10]}
                        viewBox={@fixture[11]}
                        fill={@fixture[12]}
                        stroke={@fixture[13]}
                        stroke-width={@fixture[14]}
                        stroke-linecap={@fixture[15]}
                        stroke-linejoin={@fixture[15]}
                        class={@fixture[42]}
                        aria-hidden={@fixture[17]}
                      ><circle cx={@fixture[18]} cy={@fixture[18]} r={@fixture[19]}></circle><path d={
                        @fixture[43]
                      }>
                      </path><path d={@fixture[44]}></path></svg>
                    </Trace.trace_icon><Trace.trace_title>
                      {@fixture[57]}<span class={@fixture[51]}>{@fixture[52]}</span>
                    </Trace.trace_title><Trace.trace_icon>
                      <svg
                        xmlns={@fixture[9]}
                        width={@fixture[10]}
                        height={@fixture[10]}
                        viewBox={@fixture[11]}
                        fill={@fixture[12]}
                        stroke={@fixture[13]}
                        stroke-width={@fixture[14]}
                        stroke-linecap={@fixture[15]}
                        stroke-linejoin={@fixture[15]}
                        class={@fixture[53]}
                        aria-hidden={@fixture[17]}
                      ><path d={@fixture[54]}></path><path d={@fixture[55]}></path></svg>
                    </Trace.trace_icon>
                  </Trace.trace_line></a>
                </Trace.trace>
              </Trace.trace_collapsible_content>
            </Trace.trace_collapsible>
          </Trace.trace><p>{@fixture[58]}</p>
        </Message.message_content>
      </Message.message><Button.button
        id={@id <> "-action-1"}
        variant={@fixture[61]}
        size={@fixture[29]}
        class={@fixture[62]}
        phx-click="next"
        phx-target={@myself}
      >{@fixture[60]}</Button.button>
    </div>
    """
  end

  defp trace_static_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "http://www.w3.org/2000/svg",
        1 => "24",
        2 => "0 0 24 24",
        3 => "none",
        4 => "currentColor",
        5 => "2",
        6 => "round",
        7 => "lucide lucide-git-branch",
        8 => "true",
        9 => "M15 6a9 9 0 0 0-9 9V3",
        10 => "18",
        11 => "6",
        12 => "3",
        13 => "__TOGGLE__",
        14 => "__TARGET__",
        15 => "__NEXT__",
        16 => "__DOWNLOAD__",
        17 => "__REPLAY__",
        18 => "Created branch fix/frozen-lockfile",
        19 => "max-w-sm"
      })

    ~H"""
    <Trace.trace class={@fixture[19]}>
      <Trace.trace_line>
        <Trace.trace_icon>
          <svg
            xmlns={@fixture[0]}
            width={@fixture[1]}
            height={@fixture[1]}
            viewBox={@fixture[2]}
            fill={@fixture[3]}
            stroke={@fixture[4]}
            stroke-width={@fixture[5]}
            stroke-linecap={@fixture[6]}
            stroke-linejoin={@fixture[6]}
            class={@fixture[7]}
            aria-hidden={@fixture[8]}
          ><path d={@fixture[9]}></path><circle cx={@fixture[10]} cy={@fixture[11]} r={@fixture[12]}>
          </circle><circle cx={@fixture[11]} cy={@fixture[10]} r={@fixture[12]}></circle></svg>
        </Trace.trace_icon><Trace.trace_title>{@fixture[18]}</Trace.trace_title>
      </Trace.trace_line>
    </Trace.trace>
    """
  end

  defp trace_status_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "http://www.w3.org/2000/svg",
        1 => "24",
        2 => "0 0 24 24",
        3 => "none",
        4 => "currentColor",
        5 => "2",
        6 => "round",
        7 => "lucide lucide-circle-check",
        8 => "true",
        9 => "12",
        10 => "10",
        11 => "m9 12 2 2 4-4",
        12 => "__TOGGLE__",
        13 => "__TARGET__",
        14 => "__NEXT__",
        15 => "__DOWNLOAD__",
        16 => "__REPLAY__",
        17 => "Ran pnpm install",
        18 => "lucide lucide-circle-alert",
        19 => "8",
        20 => "12.01",
        21 => "16",
        22 => "Failed to run pnpm lint",
        23 => "error",
        24 => "lucide lucide-loader-circle animate-spin",
        25 => "M21 12a9 9 0 1 1-6.219-8.56",
        26 => "Running pnpm build",
        27 => "running",
        28 => "lucide lucide-circle",
        29 => "Run pnpm test",
        30 => "pending",
        31 => "max-w-sm"
      })

    ~H"""
    <Trace.trace class={@fixture[31]}>
      <Trace.trace_line>
        <Trace.trace_icon>
          <svg
            xmlns={@fixture[0]}
            width={@fixture[1]}
            height={@fixture[1]}
            viewBox={@fixture[2]}
            fill={@fixture[3]}
            stroke={@fixture[4]}
            stroke-width={@fixture[5]}
            stroke-linecap={@fixture[6]}
            stroke-linejoin={@fixture[6]}
            class={@fixture[7]}
            aria-hidden={@fixture[8]}
          ><circle cx={@fixture[9]} cy={@fixture[9]} r={@fixture[10]}></circle><path d={@fixture[11]}>
          </path></svg>
        </Trace.trace_icon><Trace.trace_title>{@fixture[17]}</Trace.trace_title>
      </Trace.trace_line><Trace.trace_line status={@fixture[23]}>
        <Trace.trace_icon>
          <svg
            xmlns={@fixture[0]}
            width={@fixture[1]}
            height={@fixture[1]}
            viewBox={@fixture[2]}
            fill={@fixture[3]}
            stroke={@fixture[4]}
            stroke-width={@fixture[5]}
            stroke-linecap={@fixture[6]}
            stroke-linejoin={@fixture[6]}
            class={@fixture[18]}
            aria-hidden={@fixture[8]}
          ><circle cx={@fixture[9]} cy={@fixture[9]} r={@fixture[10]}></circle><line
            x1={@fixture[9]}
            x2={@fixture[9]}
            y1={@fixture[19]}
            y2={@fixture[9]}
          >
          </line><line x1={@fixture[9]} x2={@fixture[20]} y1={@fixture[21]} y2={@fixture[21]}></line></svg>
        </Trace.trace_icon><Trace.trace_title>{@fixture[22]}</Trace.trace_title>
      </Trace.trace_line><Trace.trace_line status={@fixture[27]}>
        <Trace.trace_icon>
          <svg
            xmlns={@fixture[0]}
            width={@fixture[1]}
            height={@fixture[1]}
            viewBox={@fixture[2]}
            fill={@fixture[3]}
            stroke={@fixture[4]}
            stroke-width={@fixture[5]}
            stroke-linecap={@fixture[6]}
            stroke-linejoin={@fixture[6]}
            class={@fixture[24]}
            aria-hidden={@fixture[8]}
          ><path d={@fixture[25]}></path></svg>
        </Trace.trace_icon><Trace.trace_title>{@fixture[26]}</Trace.trace_title>
      </Trace.trace_line><Trace.trace_line status={@fixture[30]}>
        <Trace.trace_icon>
          <svg
            xmlns={@fixture[0]}
            width={@fixture[1]}
            height={@fixture[1]}
            viewBox={@fixture[2]}
            fill={@fixture[3]}
            stroke={@fixture[4]}
            stroke-width={@fixture[5]}
            stroke-linecap={@fixture[6]}
            stroke-linejoin={@fixture[6]}
            class={@fixture[28]}
            aria-hidden={@fixture[8]}
          ><circle cx={@fixture[9]} cy={@fixture[9]} r={@fixture[10]}></circle></svg>
        </Trace.trace_icon><Trace.trace_title>{@fixture[29]}</Trace.trace_title>
      </Trace.trace_line>
    </Trace.trace>
    """
  end

  defp trace_description_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "http://www.w3.org/2000/svg",
        1 => "24",
        2 => "0 0 24 24",
        3 => "none",
        4 => "currentColor",
        5 => "2",
        6 => "round",
        7 => "lucide lucide-file-pen",
        8 => "true",
        9 =>
          "M12.659 22H18a2 2 0 0 0 2-2V8a2.4 2.4 0 0 0-.706-1.706l-3.588-3.588A2.4 2.4 0 0 0 14 2H6a2 2 0 0 0-2 2v9.34",
        10 => "M14 2v5a1 1 0 0 0 1 1h5",
        11 =>
          "M10.378 12.622a1 1 0 0 1 3 3.003L8.36 20.637a2 2 0 0 1-.854.506l-2.867.837a.5.5 0 0 1-.62-.62l.836-2.869a2 2 0 0 1 .506-.853z",
        12 => "__TOGGLE__",
        13 => "__TARGET__",
        14 => "__NEXT__",
        15 => "__DOWNLOAD__",
        16 => "__REPLAY__",
        17 => "Edited components/settings/notification-preferences-form.tsx",
        18 => "+48 −12",
        19 => "font-mono",
        20 => "lucide lucide-terminal",
        21 => "M12 19h8",
        22 => "m4 17 6-6-6-6",
        23 => "Ran pnpm test",
        24 => "14s",
        25 => "lucide lucide-search",
        26 => "m21 21-4.34-4.34",
        27 => "11",
        28 => "8",
        29 => "Searched for useChat",
        30 => "8 results",
        31 => "max-w-sm"
      })

    ~H"""
    <Trace.trace class={@fixture[31]}>
      <Trace.trace_line>
        <Trace.trace_icon>
          <svg
            xmlns={@fixture[0]}
            width={@fixture[1]}
            height={@fixture[1]}
            viewBox={@fixture[2]}
            fill={@fixture[3]}
            stroke={@fixture[4]}
            stroke-width={@fixture[5]}
            stroke-linecap={@fixture[6]}
            stroke-linejoin={@fixture[6]}
            class={@fixture[7]}
            aria-hidden={@fixture[8]}
          ><path d={@fixture[9]}></path><path d={@fixture[10]}></path><path d={@fixture[11]}></path></svg>
        </Trace.trace_icon><Trace.trace_title>{@fixture[17]}</Trace.trace_title><Trace.trace_description class={
          @fixture[19]
        }>
          {@fixture[18]}
        </Trace.trace_description>
      </Trace.trace_line><Trace.trace_line>
        <Trace.trace_icon>
          <svg
            xmlns={@fixture[0]}
            width={@fixture[1]}
            height={@fixture[1]}
            viewBox={@fixture[2]}
            fill={@fixture[3]}
            stroke={@fixture[4]}
            stroke-width={@fixture[5]}
            stroke-linecap={@fixture[6]}
            stroke-linejoin={@fixture[6]}
            class={@fixture[20]}
            aria-hidden={@fixture[8]}
          ><path d={@fixture[21]}></path><path d={@fixture[22]}></path></svg>
        </Trace.trace_icon><Trace.trace_title>{@fixture[23]}</Trace.trace_title><Trace.trace_description>
          {@fixture[24]}
        </Trace.trace_description>
      </Trace.trace_line><Trace.trace_line>
        <Trace.trace_icon>
          <svg
            xmlns={@fixture[0]}
            width={@fixture[1]}
            height={@fixture[1]}
            viewBox={@fixture[2]}
            fill={@fixture[3]}
            stroke={@fixture[4]}
            stroke-width={@fixture[5]}
            stroke-linecap={@fixture[6]}
            stroke-linejoin={@fixture[6]}
            class={@fixture[25]}
            aria-hidden={@fixture[8]}
          ><path d={@fixture[26]}></path><circle cx={@fixture[27]} cy={@fixture[27]} r={@fixture[28]}>
          </circle></svg>
        </Trace.trace_icon><Trace.trace_title>{@fixture[29]}</Trace.trace_title><Trace.trace_description>
          {@fixture[30]}
        </Trace.trace_description>
      </Trace.trace_line>
    </Trace.trace>
    """
  end

  defp trace_collapsible_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-sm",
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
        18 => "trace-collapsible-trace-1",
        19 => "max-h-64",
        20 => "$ node --version\nv24.18.0",
        21 => "sm"
      })

    ~H"""
    <div class={@fixture[0]}>
      <Trace.trace_collapsible id={@fixture[18]} open={false}>
        <Trace.trace_collapsible_trigger for={@fixture[18]} open={false}>
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
          open={false}
        >
          <CodeBlock.code_block size={@fixture[21]}>
            <CodeBlock.code_block_content wrap={true} class={@fixture[19]} code={@fixture[20]} />
          </CodeBlock.code_block>
        </Trace.trace_collapsible_content>
      </Trace.trace_collapsible>
    </div>
    """
  end

  defp trace_open_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex w-full max-w-sm flex-col items-start gap-4",
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
        18 => "trace-open-trace-1",
        19 => "max-h-64",
        20 => "$ node --version\nv24.18.0",
        21 => "sm",
        22 => "Ran pnpm --version",
        23 => "trace-open-trace-2",
        24 => "$ pnpm --version\n10.33.4",
        25 => "Show the pnpm output",
        26 => "outline"
      })

    ~H"""
    <div class={@fixture[0]}>
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
      </Trace.trace_collapsible><Trace.trace_collapsible id={@fixture[23]} controlled open={false}>
        <Trace.trace_collapsible_trigger
          for={@fixture[23]}
          controlled
          open={false}
          phx-click="toggle"
          phx-target={@myself}
        >
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
            </Trace.trace_icon><Trace.trace_title>{@fixture[22]}</Trace.trace_title>
          </Trace.trace_line>
        </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
          phx-no-format
          for={@fixture[23]}
          controlled
          open={false}
        >
          <CodeBlock.code_block size={@fixture[21]}>
            <CodeBlock.code_block_content wrap={true} class={@fixture[19]} code={@fixture[24]} />
          </CodeBlock.code_block>
        </Trace.trace_collapsible_content>
      </Trace.trace_collapsible><Button.button
        id={@id <> "-action-1"}
        variant={@fixture[26]}
        size={@fixture[21]}
        phx-click="toggle"
        phx-target={@myself}
      >{@fixture[25]}</Button.button>
    </div>
    """
  end

  defp trace_open_toggle(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex w-full max-w-sm flex-col items-start gap-4",
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
        18 => "trace-open-trace-1",
        19 => "max-h-64",
        20 => "$ node --version\nv24.18.0",
        21 => "sm",
        22 => "Ran pnpm --version",
        23 => "trace-open-trace-2",
        24 => "$ pnpm --version\n10.33.4",
        25 => "Hide the pnpm output",
        26 => "outline"
      })

    ~H"""
    <div class={@fixture[0]}>
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
      </Trace.trace_collapsible><Trace.trace_collapsible id={@fixture[23]} controlled open={true}>
        <Trace.trace_collapsible_trigger
          for={@fixture[23]}
          controlled
          open={true}
          phx-click="toggle"
          phx-target={@myself}
        >
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
            </Trace.trace_icon><Trace.trace_title>{@fixture[22]}</Trace.trace_title>
          </Trace.trace_line>
        </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
          phx-no-format
          for={@fixture[23]}
          controlled
          open={true}
        >
          <CodeBlock.code_block size={@fixture[21]}>
            <CodeBlock.code_block_content wrap={true} class={@fixture[19]} code={@fixture[24]} />
          </CodeBlock.code_block>
        </Trace.trace_collapsible_content>
      </Trace.trace_collapsible><Button.button
        id={@id <> "-action-1"}
        variant={@fixture[26]}
        size={@fixture[21]}
        phx-click="toggle"
        phx-target={@myself}
      >{@fixture[25]}</Button.button>
    </div>
    """
  end

  defp trace_link_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "#link",
        1 => "http://www.w3.org/2000/svg",
        2 => "24",
        3 => "0 0 24 24",
        4 => "none",
        5 => "currentColor",
        6 => "2",
        7 => "round",
        8 => "lucide lucide-file-text",
        9 => "true",
        10 =>
          "M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z",
        11 => "M14 2v5a1 1 0 0 0 1 1h5",
        12 => "M10 9H8",
        13 => "M16 13H8",
        14 => "M16 17H8",
        15 => "__TOGGLE__",
        16 => "__TARGET__",
        17 => "__NEXT__",
        18 => "__DOWNLOAD__",
        19 => "__REPLAY__",
        20 => "Read apps/v4/lib/docs.ts",
        21 => "lucide lucide-chevron-right",
        22 => "m9 18 6-6-6-6",
        23 => "https://docs.astro.build/en/install-and-setup/",
        24 => "_blank",
        25 => "noreferrer",
        26 => "lucide lucide-globe",
        27 => "12",
        28 => "10",
        29 => "M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20",
        30 => "M2 12h20",
        31 => "Install Astro | docs.astro.build",
        32 => "sr-only",
        33 => " (opens in a new tab)",
        34 => "lucide lucide-arrow-up-right",
        35 => "M7 7h10v10",
        36 => "M7 17 17 7",
        37 => "max-w-sm"
      })

    ~H"""
    <Trace.trace class={@fixture[37]}>
      <a href={@fixture[0]}><Trace.trace_line>
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
          ><path d={@fixture[10]}></path><path d={@fixture[11]}></path><path d={@fixture[12]}></path><path d={
            @fixture[13]
          }>
          </path><path d={@fixture[14]}></path></svg>
        </Trace.trace_icon><Trace.trace_title>{@fixture[20]}</Trace.trace_title><Trace.trace_icon>
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
            class={@fixture[21]}
            aria-hidden={@fixture[9]}
          ><path d={@fixture[22]}></path></svg>
        </Trace.trace_icon>
      </Trace.trace_line></a><a href={@fixture[23]} target={@fixture[24]} rel={@fixture[25]}><Trace.trace_line>
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
            class={@fixture[26]}
            aria-hidden={@fixture[9]}
          ><circle cx={@fixture[27]} cy={@fixture[27]} r={@fixture[28]}></circle><path d={
            @fixture[29]
          }>
          </path><path d={@fixture[30]}></path></svg>
        </Trace.trace_icon><Trace.trace_title>
          {@fixture[31]}<span class={@fixture[32]}>{@fixture[33]}</span>
        </Trace.trace_title><Trace.trace_icon>
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
            class={@fixture[34]}
            aria-hidden={@fixture[9]}
          ><path d={@fixture[35]}></path><path d={@fixture[36]}></path></svg>
        </Trace.trace_icon>
      </Trace.trace_line></a>
    </Trace.trace>
    """
  end

  defp trace_dialog_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "http://www.w3.org/2000/svg",
        1 => "24",
        2 => "0 0 24 24",
        3 => "none",
        4 => "currentColor",
        5 => "2",
        6 => "round",
        7 => "lucide lucide-globe",
        8 => "true",
        9 => "12",
        10 => "10",
        11 => "M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20",
        12 => "M2 12h20",
        13 => "__TOGGLE__",
        14 => "__TARGET__",
        15 => "__NEXT__",
        16 => "__DOWNLOAD__",
        17 => "__REPLAY__",
        18 => "Searched the web for cache keys",
        19 => "lucide lucide-chevron-right",
        20 => "m9 18 6-6-6-6",
        21 => "Three results were used in the response.",
        22 => "https://nextjs.org/docs/app/guides/caching",
        23 => "_blank",
        24 => "noreferrer",
        25 => "Caching build outputs",
        26 => "sr-only",
        27 => " (opens in a new tab)",
        28 => "lucide lucide-arrow-up-right",
        29 => "M7 7h10v10",
        30 => "M7 17 17 7",
        31 => "https://nextjs.org/docs/app/api-reference/components/image",
        32 => "Image optimization reference",
        33 => "https://vercel.com/docs/deploy-hooks",
        34 => "Deploy hooks and cache keys",
        35 => "trace-dialog-dialog-1",
        36 => "max-w-sm"
      })

    ~H"""
    <Trace.trace class={@fixture[36]}>
      <Dialog.dialog portal trigger_variant={nil} id={@fixture[35]}>
        <:trigger>
          <Trace.trace_line>
            <Trace.trace_icon>
              <svg
                xmlns={@fixture[0]}
                width={@fixture[1]}
                height={@fixture[1]}
                viewBox={@fixture[2]}
                fill={@fixture[3]}
                stroke={@fixture[4]}
                stroke-width={@fixture[5]}
                stroke-linecap={@fixture[6]}
                stroke-linejoin={@fixture[6]}
                class={@fixture[7]}
                aria-hidden={@fixture[8]}
              ><circle cx={@fixture[9]} cy={@fixture[9]} r={@fixture[10]}></circle><path d={
                @fixture[11]
              }>
              </path><path d={@fixture[12]}></path></svg>
            </Trace.trace_icon><Trace.trace_title>{@fixture[18]}</Trace.trace_title><Trace.trace_icon>
              <svg
                xmlns={@fixture[0]}
                width={@fixture[1]}
                height={@fixture[1]}
                viewBox={@fixture[2]}
                fill={@fixture[3]}
                stroke={@fixture[4]}
                stroke-width={@fixture[5]}
                stroke-linecap={@fixture[6]}
                stroke-linejoin={@fixture[6]}
                class={@fixture[19]}
                aria-hidden={@fixture[8]}
              ><path d={@fixture[20]}></path></svg>
            </Trace.trace_icon>
          </Trace.trace_line>
        </:trigger><:title>{@fixture[18]}</:title><:description>{@fixture[21]}</:description><Trace.trace>
          <a href={@fixture[22]} target={@fixture[23]} rel={@fixture[24]}><Trace.trace_line>
            <Trace.trace_icon>
              <svg
                xmlns={@fixture[0]}
                width={@fixture[1]}
                height={@fixture[1]}
                viewBox={@fixture[2]}
                fill={@fixture[3]}
                stroke={@fixture[4]}
                stroke-width={@fixture[5]}
                stroke-linecap={@fixture[6]}
                stroke-linejoin={@fixture[6]}
                class={@fixture[7]}
                aria-hidden={@fixture[8]}
              ><circle cx={@fixture[9]} cy={@fixture[9]} r={@fixture[10]}></circle><path d={
                @fixture[11]
              }>
              </path><path d={@fixture[12]}></path></svg>
            </Trace.trace_icon><Trace.trace_title>
              {@fixture[25]}<span class={@fixture[26]}>{@fixture[27]}</span>
            </Trace.trace_title><Trace.trace_icon>
              <svg
                xmlns={@fixture[0]}
                width={@fixture[1]}
                height={@fixture[1]}
                viewBox={@fixture[2]}
                fill={@fixture[3]}
                stroke={@fixture[4]}
                stroke-width={@fixture[5]}
                stroke-linecap={@fixture[6]}
                stroke-linejoin={@fixture[6]}
                class={@fixture[28]}
                aria-hidden={@fixture[8]}
              ><path d={@fixture[29]}></path><path d={@fixture[30]}></path></svg>
            </Trace.trace_icon>
          </Trace.trace_line></a><a href={@fixture[31]} target={@fixture[23]} rel={@fixture[24]}><Trace.trace_line>
            <Trace.trace_icon>
              <svg
                xmlns={@fixture[0]}
                width={@fixture[1]}
                height={@fixture[1]}
                viewBox={@fixture[2]}
                fill={@fixture[3]}
                stroke={@fixture[4]}
                stroke-width={@fixture[5]}
                stroke-linecap={@fixture[6]}
                stroke-linejoin={@fixture[6]}
                class={@fixture[7]}
                aria-hidden={@fixture[8]}
              ><circle cx={@fixture[9]} cy={@fixture[9]} r={@fixture[10]}></circle><path d={
                @fixture[11]
              }>
              </path><path d={@fixture[12]}></path></svg>
            </Trace.trace_icon><Trace.trace_title>
              {@fixture[32]}<span class={@fixture[26]}>{@fixture[27]}</span>
            </Trace.trace_title><Trace.trace_icon>
              <svg
                xmlns={@fixture[0]}
                width={@fixture[1]}
                height={@fixture[1]}
                viewBox={@fixture[2]}
                fill={@fixture[3]}
                stroke={@fixture[4]}
                stroke-width={@fixture[5]}
                stroke-linecap={@fixture[6]}
                stroke-linejoin={@fixture[6]}
                class={@fixture[28]}
                aria-hidden={@fixture[8]}
              ><path d={@fixture[29]}></path><path d={@fixture[30]}></path></svg>
            </Trace.trace_icon>
          </Trace.trace_line></a><a href={@fixture[33]} target={@fixture[23]} rel={@fixture[24]}><Trace.trace_line>
            <Trace.trace_icon>
              <svg
                xmlns={@fixture[0]}
                width={@fixture[1]}
                height={@fixture[1]}
                viewBox={@fixture[2]}
                fill={@fixture[3]}
                stroke={@fixture[4]}
                stroke-width={@fixture[5]}
                stroke-linecap={@fixture[6]}
                stroke-linejoin={@fixture[6]}
                class={@fixture[7]}
                aria-hidden={@fixture[8]}
              ><circle cx={@fixture[9]} cy={@fixture[9]} r={@fixture[10]}></circle><path d={
                @fixture[11]
              }>
              </path><path d={@fixture[12]}></path></svg>
            </Trace.trace_icon><Trace.trace_title>
              {@fixture[34]}<span class={@fixture[26]}>{@fixture[27]}</span>
            </Trace.trace_title><Trace.trace_icon>
              <svg
                xmlns={@fixture[0]}
                width={@fixture[1]}
                height={@fixture[1]}
                viewBox={@fixture[2]}
                fill={@fixture[3]}
                stroke={@fixture[4]}
                stroke-width={@fixture[5]}
                stroke-linecap={@fixture[6]}
                stroke-linejoin={@fixture[6]}
                class={@fixture[28]}
                aria-hidden={@fixture[8]}
              ><path d={@fixture[29]}></path><path d={@fixture[30]}></path></svg>
            </Trace.trace_icon>
          </Trace.trace_line></a>
        </Trace.trace>
      </Dialog.dialog>
    </Trace.trace>
    """
  end

  defp trace_sheet_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "http://www.w3.org/2000/svg",
        1 => "24",
        2 => "0 0 24 24",
        3 => "none",
        4 => "currentColor",
        5 => "2",
        6 => "round",
        7 => "lucide lucide-folder-search",
        8 => "true",
        9 =>
          "M10.7 20H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h3.9a2 2 0 0 1 1.69.9l.81 1.2a2 2 0 0 0 1.67.9H20a2 2 0 0 1 2 2v4.1",
        10 => "m21 21-1.9-1.9",
        11 => "17",
        12 => "3",
        13 => "__TOGGLE__",
        14 => "__TARGET__",
        15 => "__NEXT__",
        16 => "__DOWNLOAD__",
        17 => "__REPLAY__",
        18 => "Explored 4 files",
        19 => "lucide lucide-chevron-right",
        20 => "m9 18 6-6-6-6",
        21 => "Files read while preparing the response.",
        22 => "flex flex-col gap-2 px-6 font-mono text-xs",
        23 => "apps/v4/lib/docs.ts",
        24 => "apps/v4/lib/components.ts",
        25 => "apps/v4/next.config.mjs",
        26 => "apps/v4/package.json",
        27 => "trace-sheet-sheet-1",
        28 => "default",
        29 => "max-w-sm"
      })

    ~H"""
    <Trace.trace class={@fixture[29]}>
      <Sheet.sheet portal trigger_variant={nil} id={@fixture[27]} trigger_size={@fixture[28]}>
        <:trigger>
          <Trace.trace_line>
            <Trace.trace_icon>
              <svg
                xmlns={@fixture[0]}
                width={@fixture[1]}
                height={@fixture[1]}
                viewBox={@fixture[2]}
                fill={@fixture[3]}
                stroke={@fixture[4]}
                stroke-width={@fixture[5]}
                stroke-linecap={@fixture[6]}
                stroke-linejoin={@fixture[6]}
                class={@fixture[7]}
                aria-hidden={@fixture[8]}
              ><path d={@fixture[9]}></path><path d={@fixture[10]}></path><circle
                cx={@fixture[11]}
                cy={@fixture[11]}
                r={@fixture[12]}
              >
              </circle></svg>
            </Trace.trace_icon><Trace.trace_title>{@fixture[18]}</Trace.trace_title><Trace.trace_icon>
              <svg
                xmlns={@fixture[0]}
                width={@fixture[1]}
                height={@fixture[1]}
                viewBox={@fixture[2]}
                fill={@fixture[3]}
                stroke={@fixture[4]}
                stroke-width={@fixture[5]}
                stroke-linecap={@fixture[6]}
                stroke-linejoin={@fixture[6]}
                class={@fixture[19]}
                aria-hidden={@fixture[8]}
              ><path d={@fixture[20]}></path></svg>
            </Trace.trace_icon>
          </Trace.trace_line>
        </:trigger><:title>{@fixture[18]}</:title><:description>{@fixture[21]}</:description><ul class={
          @fixture[22]
        }>
          <li>{@fixture[23]}</li><li>{@fixture[24]}</li><li>{@fixture[25]}</li><li>{@fixture[26]}</li>
        </ul>
      </Sheet.sheet>
    </Trace.trace>
    """
  end

  defp trace_group_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "http://www.w3.org/2000/svg",
        1 => "24",
        2 => "0 0 24 24",
        3 => "none",
        4 => "currentColor",
        5 => "2",
        6 => "round",
        7 => "lucide lucide-search",
        8 => "true",
        9 => "m21 21-4.34-4.34",
        10 => "11",
        11 => "8",
        12 => "__TOGGLE__",
        13 => "__TARGET__",
        14 => "__NEXT__",
        15 => "__DOWNLOAD__",
        16 => "__REPLAY__",
        17 => "Searched for minimumReleaseAge",
        18 => "lucide lucide-file-text",
        19 =>
          "M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z",
        20 => "M14 2v5a1 1 0 0 0 1 1h5",
        21 => "M10 9H8",
        22 => "M16 13H8",
        23 => "M16 17H8",
        24 => "Read pnpm-workspace.yaml",
        25 => "lucide lucide-terminal",
        26 => "M12 19h8",
        27 => "m4 17 6-6-6-6",
        28 => "Ran pnpm install",
        29 => "max-w-sm"
      })

    ~H"""
    <Trace.trace class={@fixture[29]}>
      <Trace.trace_line>
        <Trace.trace_icon>
          <svg
            xmlns={@fixture[0]}
            width={@fixture[1]}
            height={@fixture[1]}
            viewBox={@fixture[2]}
            fill={@fixture[3]}
            stroke={@fixture[4]}
            stroke-width={@fixture[5]}
            stroke-linecap={@fixture[6]}
            stroke-linejoin={@fixture[6]}
            class={@fixture[7]}
            aria-hidden={@fixture[8]}
          ><path d={@fixture[9]}></path><circle cx={@fixture[10]} cy={@fixture[10]} r={@fixture[11]}>
          </circle></svg>
        </Trace.trace_icon><Trace.trace_title>{@fixture[17]}</Trace.trace_title>
      </Trace.trace_line><Trace.trace_line>
        <Trace.trace_icon>
          <svg
            xmlns={@fixture[0]}
            width={@fixture[1]}
            height={@fixture[1]}
            viewBox={@fixture[2]}
            fill={@fixture[3]}
            stroke={@fixture[4]}
            stroke-width={@fixture[5]}
            stroke-linecap={@fixture[6]}
            stroke-linejoin={@fixture[6]}
            class={@fixture[18]}
            aria-hidden={@fixture[8]}
          ><path d={@fixture[19]}></path><path d={@fixture[20]}></path><path d={@fixture[21]}></path><path d={
            @fixture[22]
          }>
          </path><path d={@fixture[23]}></path></svg>
        </Trace.trace_icon><Trace.trace_title>{@fixture[24]}</Trace.trace_title>
      </Trace.trace_line><Trace.trace_line>
        <Trace.trace_icon>
          <svg
            xmlns={@fixture[0]}
            width={@fixture[1]}
            height={@fixture[1]}
            viewBox={@fixture[2]}
            fill={@fixture[3]}
            stroke={@fixture[4]}
            stroke-width={@fixture[5]}
            stroke-linecap={@fixture[6]}
            stroke-linejoin={@fixture[6]}
            class={@fixture[25]}
            aria-hidden={@fixture[8]}
          ><path d={@fixture[26]}></path><path d={@fixture[27]}></path></svg>
        </Trace.trace_icon><Trace.trace_title>{@fixture[28]}</Trace.trace_title>
      </Trace.trace_line>
    </Trace.trace>
    """
  end

  defp trace_sources_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-sm",
        1 => "http://www.w3.org/2000/svg",
        2 => "24",
        3 => "0 0 24 24",
        4 => "none",
        5 => "currentColor",
        6 => "2",
        7 => "round",
        8 => "lucide lucide-globe",
        9 => "true",
        10 => "12",
        11 => "10",
        12 => "M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20",
        13 => "M2 12h20",
        14 => "__TOGGLE__",
        15 => "__TARGET__",
        16 => "__NEXT__",
        17 => "__DOWNLOAD__",
        18 => "__REPLAY__",
        19 => "Used 3 sources",
        20 => "trace-sources-trace-1",
        21 => "https://docs.astro.build/en/install-and-setup/",
        22 => "_blank",
        23 => "noreferrer",
        24 => "Install Astro | docs.astro.build",
        25 => "sr-only",
        26 => " (opens in a new tab)",
        27 => "lucide lucide-arrow-up-right",
        28 => "M7 7h10v10",
        29 => "M7 17 17 7",
        30 => "https://www.npmjs.com/package/create-astro",
        31 => "create-astro | npmjs.com",
        32 => "https://pnpm.io/settings#minimumreleaseage",
        33 => "Settings: minimumReleaseAge | pnpm.io"
      })

    ~H"""
    <div class={@fixture[0]}>
      <Trace.trace_collapsible id={@fixture[20]} open={true}>
        <Trace.trace_collapsible_trigger for={@fixture[20]} open={true}>
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
              ><circle cx={@fixture[10]} cy={@fixture[10]} r={@fixture[11]}></circle><path d={
                @fixture[12]
              }>
              </path><path d={@fixture[13]}></path></svg>
            </Trace.trace_icon><Trace.trace_title>{@fixture[19]}</Trace.trace_title>
          </Trace.trace_line>
        </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
          phx-no-format
          for={@fixture[20]}
          open={true}
        >
          <Trace.trace>
            <a href={@fixture[21]} target={@fixture[22]} rel={@fixture[23]}><Trace.trace_line>
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
                ><circle cx={@fixture[10]} cy={@fixture[10]} r={@fixture[11]}></circle><path d={
                  @fixture[12]
                }>
                </path><path d={@fixture[13]}></path></svg>
              </Trace.trace_icon><Trace.trace_title>
                {@fixture[24]}<span class={@fixture[25]}>{@fixture[26]}</span>
              </Trace.trace_title><Trace.trace_icon>
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
                  class={@fixture[27]}
                  aria-hidden={@fixture[9]}
                ><path d={@fixture[28]}></path><path d={@fixture[29]}></path></svg>
              </Trace.trace_icon>
            </Trace.trace_line></a><a href={@fixture[30]} target={@fixture[22]} rel={@fixture[23]}><Trace.trace_line>
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
                ><circle cx={@fixture[10]} cy={@fixture[10]} r={@fixture[11]}></circle><path d={
                  @fixture[12]
                }>
                </path><path d={@fixture[13]}></path></svg>
              </Trace.trace_icon><Trace.trace_title>
                {@fixture[31]}<span class={@fixture[25]}>{@fixture[26]}</span>
              </Trace.trace_title><Trace.trace_icon>
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
                  class={@fixture[27]}
                  aria-hidden={@fixture[9]}
                ><path d={@fixture[28]}></path><path d={@fixture[29]}></path></svg>
              </Trace.trace_icon>
            </Trace.trace_line></a><a href={@fixture[32]} target={@fixture[22]} rel={@fixture[23]}><Trace.trace_line>
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
                ><circle cx={@fixture[10]} cy={@fixture[10]} r={@fixture[11]}></circle><path d={
                  @fixture[12]
                }>
                </path><path d={@fixture[13]}></path></svg>
              </Trace.trace_icon><Trace.trace_title>
                {@fixture[33]}<span class={@fixture[25]}>{@fixture[26]}</span>
              </Trace.trace_title><Trace.trace_icon>
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
                  class={@fixture[27]}
                  aria-hidden={@fixture[9]}
                ><path d={@fixture[28]}></path><path d={@fixture[29]}></path></svg>
              </Trace.trace_icon>
            </Trace.trace_line></a>
          </Trace.trace>
        </Trace.trace_collapsible_content>
      </Trace.trace_collapsible>
    </div>
    """
  end

  defp trace_steps_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-sm",
        1 => "Looking into the slow deploy",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 => "running",
        8 => "trace-steps-trace-1",
        9 => "http://www.w3.org/2000/svg",
        10 => "24",
        11 => "0 0 24 24",
        12 => "none",
        13 => "currentColor",
        14 => "2",
        15 => "round",
        16 => "lucide lucide-search",
        17 => "true",
        18 => "m21 21-4.34-4.34",
        19 => "11",
        20 => "8",
        21 => "Searched for the checkout build log",
        22 => "trace-steps-trace-2",
        23 => "vercel.com",
        24 => "secondary",
        25 => "github.com",
        26 => "flex flex-wrap gap-1.5",
        27 => "#steps",
        28 => "lucide lucide-file-text",
        29 =>
          "M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z",
        30 => "M14 2v5a1 1 0 0 0 1 1h5",
        31 => "M10 9H8",
        32 => "M16 13H8",
        33 => "M16 17H8",
        34 => "Read the last twelve deploys",
        35 => "lucide lucide-chevron-right",
        36 => "m9 18 6-6-6-6",
        37 => "Searching for the cache key",
        38 => "trace-steps-trace-3",
        39 => "max-h-64",
        40 => "cache key image optimization",
        41 => "sm"
      })

    ~H"""
    <div class={@fixture[0]}>
      <Trace.trace_collapsible id={@fixture[8]} open={true}>
        <Trace.trace_collapsible_trigger for={@fixture[8]} open={true}>
          <Trace.trace_line status={@fixture[7]}>
            <Trace.trace_title>{@fixture[1]}</Trace.trace_title>
          </Trace.trace_line>
        </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
          phx-no-format
          for={@fixture[8]}
          open={true}
        >
          <Trace.trace>
            <Trace.trace_collapsible id={@fixture[22]} open={false}>
              <Trace.trace_collapsible_trigger for={@fixture[22]} open={false}>
                <Trace.trace_line>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[9]}
                      width={@fixture[10]}
                      height={@fixture[10]}
                      viewBox={@fixture[11]}
                      fill={@fixture[12]}
                      stroke={@fixture[13]}
                      stroke-width={@fixture[14]}
                      stroke-linecap={@fixture[15]}
                      stroke-linejoin={@fixture[15]}
                      class={@fixture[16]}
                      aria-hidden={@fixture[17]}
                    ><path d={@fixture[18]}></path><circle
                      cx={@fixture[19]}
                      cy={@fixture[19]}
                      r={@fixture[20]}
                    >
                    </circle></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[21]}</Trace.trace_title>
                </Trace.trace_line>
              </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content phx-no-format
                class={@fixture[26]}
                for={@fixture[22]}
                open={false}
              >
                <Badge.badge variant={@fixture[24]}>{@fixture[23]}</Badge.badge><Badge.badge variant={
                  @fixture[24]
                }>
                  {@fixture[25]}
                </Badge.badge>
              </Trace.trace_collapsible_content>
            </Trace.trace_collapsible><a href={@fixture[27]}><Trace.trace_line>
              <Trace.trace_icon>
                <svg
                  xmlns={@fixture[9]}
                  width={@fixture[10]}
                  height={@fixture[10]}
                  viewBox={@fixture[11]}
                  fill={@fixture[12]}
                  stroke={@fixture[13]}
                  stroke-width={@fixture[14]}
                  stroke-linecap={@fixture[15]}
                  stroke-linejoin={@fixture[15]}
                  class={@fixture[28]}
                  aria-hidden={@fixture[17]}
                ><path d={@fixture[29]}></path><path d={@fixture[30]}></path><path d={@fixture[31]}>
                </path><path d={@fixture[32]}></path><path d={@fixture[33]}></path></svg>
              </Trace.trace_icon><Trace.trace_title>{@fixture[34]}</Trace.trace_title><Trace.trace_icon>
                <svg
                  xmlns={@fixture[9]}
                  width={@fixture[10]}
                  height={@fixture[10]}
                  viewBox={@fixture[11]}
                  fill={@fixture[12]}
                  stroke={@fixture[13]}
                  stroke-width={@fixture[14]}
                  stroke-linecap={@fixture[15]}
                  stroke-linejoin={@fixture[15]}
                  class={@fixture[35]}
                  aria-hidden={@fixture[17]}
                ><path d={@fixture[36]}></path></svg>
              </Trace.trace_icon>
            </Trace.trace_line></a><Trace.trace_collapsible id={@fixture[38]} open={false}>
              <Trace.trace_collapsible_trigger for={@fixture[38]} open={false}>
                <Trace.trace_line status={@fixture[7]}>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[9]}
                      width={@fixture[10]}
                      height={@fixture[10]}
                      viewBox={@fixture[11]}
                      fill={@fixture[12]}
                      stroke={@fixture[13]}
                      stroke-width={@fixture[14]}
                      stroke-linecap={@fixture[15]}
                      stroke-linejoin={@fixture[15]}
                      class={@fixture[16]}
                      aria-hidden={@fixture[17]}
                    ><path d={@fixture[18]}></path><circle
                      cx={@fixture[19]}
                      cy={@fixture[19]}
                      r={@fixture[20]}
                    >
                    </circle></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[37]}</Trace.trace_title>
                </Trace.trace_line>
              </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content phx-no-format
                for={@fixture[38]}
                open={false}
              >
                <CodeBlock.code_block size={@fixture[41]}>
                  <CodeBlock.code_block_content wrap={true} class={@fixture[39]} code={@fixture[40]} />
                </CodeBlock.code_block>
              </Trace.trace_collapsible_content>
            </Trace.trace_collapsible>
          </Trace.trace>
        </Trace.trace_collapsible_content>
      </Trace.trace_collapsible>
    </div>
    """
  end

  defp trace_commit_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "http://www.w3.org/2000/svg",
        1 => "24",
        2 => "0 0 24 24",
        3 => "none",
        4 => "currentColor",
        5 => "2",
        6 => "round",
        7 => "lucide lucide-git-commit-horizontal",
        8 => "true",
        9 => "12",
        10 => "3",
        11 => "9",
        12 => "15",
        13 => "21",
        14 => "__TOGGLE__",
        15 => "__TARGET__",
        16 => "__NEXT__",
        17 => "__DOWNLOAD__",
        18 => "__REPLAY__",
        19 => "Committed a1b2c3: Fix the login redirect",
        20 => "trace-commit-trace-1",
        21 => "lucide lucide-file-pen",
        22 =>
          "M12.659 22H18a2 2 0 0 0 2-2V8a2.4 2.4 0 0 0-.706-1.706l-3.588-3.588A2.4 2.4 0 0 0 14 2H6a2 2 0 0 0-2 2v9.34",
        23 => "M14 2v5a1 1 0 0 0 1 1h5",
        24 =>
          "M10.378 12.622a1 1 0 0 1 3 3.003L8.36 20.637a2 2 0 0 1-.854.506l-2.867.837a.5.5 0 0 1-.62-.62l.836-2.869a2 2 0 0 1 .506-.853z",
        25 => "Edited app/login/page.tsx",
        26 => "+2 −2",
        27 => "font-mono",
        28 => "lucide lucide-chevron-right",
        29 => "m9 18 6-6-6-6",
        30 => "app/login/page.tsx",
        31 => "2 additions, 2 deletions",
        32 => [
          %{
            "variant" => "default",
            "class" => "text-muted-foreground",
            "tokens" => [
              %{
                "text" => "@@ -14,7 +14,7 @@ export default async function LoginPage({",
                "class" => nil,
                "style" => nil
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [%{"text" => "  searchParams,", "class" => nil, "style" => nil}]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [%{"text" => "}) {", "class" => nil, "style" => nil}]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{"text" => "  const { next } = await searchParams", "class" => nil, "style" => nil}
            ]
          },
          %{
            "variant" => "removed",
            "class" => nil,
            "tokens" => [%{"text" => "  const redirectTo =", "class" => nil, "style" => nil}]
          },
          %{
            "variant" => "removed",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "    next && next.startsWith(\"/\") ? next : \"/\"",
                "class" => nil,
                "style" => nil
              }
            ]
          },
          %{
            "variant" => "added",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  const redirectTo = safeRedirect(next)",
                "class" => nil,
                "style" => nil
              }
            ]
          },
          %{"variant" => "added", "class" => nil, "tokens" => []},
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  return <LoginForm redirectTo={redirectTo} />",
                "class" => nil,
                "style" => nil
              }
            ]
          },
          %{
            "variant" => "default",
            "class" => nil,
            "tokens" => [%{"text" => "}", "class" => nil, "style" => nil}]
          }
        ],
        33 => "mx-6 mb-6 w-auto",
        34 => "trace-commit-sheet-2",
        35 => "default",
        36 => "lucide lucide-file-plus",
        37 =>
          "M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z",
        38 => "M9 15h6",
        39 => "M12 18v-6",
        40 => "Added lib/auth/redirect.ts",
        41 => "+7 −0",
        42 => "lib/auth/redirect.ts",
        43 => "7 additions, 0 deletions",
        44 => [
          %{
            "variant" => "default",
            "class" => "text-muted-foreground",
            "tokens" => [%{"text" => "@@ -0,0 +1,7 @@", "class" => nil, "style" => nil}]
          },
          %{
            "variant" => "added",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "export function safeRedirect(next: string | undefined) {",
                "class" => nil,
                "style" => nil
              }
            ]
          },
          %{
            "variant" => "added",
            "class" => nil,
            "tokens" => [
              %{
                "text" => "  if (!next || !next.startsWith(\"/\") || next.startsWith(\"//\")) {",
                "class" => nil,
                "style" => nil
              }
            ]
          },
          %{
            "variant" => "added",
            "class" => nil,
            "tokens" => [%{"text" => "    return \"/\"", "class" => nil, "style" => nil}]
          },
          %{
            "variant" => "added",
            "class" => nil,
            "tokens" => [%{"text" => "  }", "class" => nil, "style" => nil}]
          },
          %{"variant" => "added", "class" => nil, "tokens" => []},
          %{
            "variant" => "added",
            "class" => nil,
            "tokens" => [%{"text" => "  return next", "class" => nil, "style" => nil}]
          },
          %{
            "variant" => "added",
            "class" => nil,
            "tokens" => [%{"text" => "}", "class" => nil, "style" => nil}]
          }
        ],
        45 => "trace-commit-sheet-3",
        46 => "max-w-sm"
      })

    ~H"""
    <Trace.trace class={@fixture[46]}>
      <Trace.trace_collapsible id={@fixture[20]} open={true}>
        <Trace.trace_collapsible_trigger for={@fixture[20]} open={true}>
          <Trace.trace_line>
            <Trace.trace_icon>
              <svg
                xmlns={@fixture[0]}
                width={@fixture[1]}
                height={@fixture[1]}
                viewBox={@fixture[2]}
                fill={@fixture[3]}
                stroke={@fixture[4]}
                stroke-width={@fixture[5]}
                stroke-linecap={@fixture[6]}
                stroke-linejoin={@fixture[6]}
                class={@fixture[7]}
                aria-hidden={@fixture[8]}
              ><circle cx={@fixture[9]} cy={@fixture[9]} r={@fixture[10]}></circle><line
                x1={@fixture[10]}
                x2={@fixture[11]}
                y1={@fixture[9]}
                y2={@fixture[9]}
              >
              </line><line x1={@fixture[12]} x2={@fixture[13]} y1={@fixture[9]} y2={@fixture[9]}>
              </line></svg>
            </Trace.trace_icon><Trace.trace_title>{@fixture[19]}</Trace.trace_title>
          </Trace.trace_line>
        </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
          phx-no-format
          for={@fixture[20]}
          open={true}
        >
          <Trace.trace>
            <Sheet.sheet portal trigger_variant={nil} id={@fixture[34]} trigger_size={@fixture[35]} title_class={@fixture[27]}>
              <:trigger>
                <Trace.trace_line>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[0]}
                      width={@fixture[1]}
                      height={@fixture[1]}
                      viewBox={@fixture[2]}
                      fill={@fixture[3]}
                      stroke={@fixture[4]}
                      stroke-width={@fixture[5]}
                      stroke-linecap={@fixture[6]}
                      stroke-linejoin={@fixture[6]}
                      class={@fixture[21]}
                      aria-hidden={@fixture[8]}
                    ><path d={@fixture[22]}></path><path d={@fixture[23]}></path><path d={
                      @fixture[24]
                    }>
                    </path></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[25]}</Trace.trace_title><Trace.trace_description class={
                    @fixture[27]
                  }>
                    {@fixture[26]}
                  </Trace.trace_description><Trace.trace_icon>
                    <svg
                      xmlns={@fixture[0]}
                      width={@fixture[1]}
                      height={@fixture[1]}
                      viewBox={@fixture[2]}
                      fill={@fixture[3]}
                      stroke={@fixture[4]}
                      stroke-width={@fixture[5]}
                      stroke-linecap={@fixture[6]}
                      stroke-linejoin={@fixture[6]}
                      class={@fixture[28]}
                      aria-hidden={@fixture[8]}
                    ><path d={@fixture[29]}></path></svg>
                  </Trace.trace_icon>
                </Trace.trace_line>
              </:trigger><:title>{@fixture[30]}</:title><:description>{@fixture[31]}</:description><CodeBlock.code_block class={
                @fixture[33]
              }>
                <CodeExamples.highlighted_content lines={@fixture[32]} />
              </CodeBlock.code_block>
            </Sheet.sheet><Sheet.sheet portal trigger_variant={nil}
              id={@fixture[45]}
              trigger_size={@fixture[35]}
              title_class={@fixture[27]}
            >
              <:trigger>
                <Trace.trace_line>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[0]}
                      width={@fixture[1]}
                      height={@fixture[1]}
                      viewBox={@fixture[2]}
                      fill={@fixture[3]}
                      stroke={@fixture[4]}
                      stroke-width={@fixture[5]}
                      stroke-linecap={@fixture[6]}
                      stroke-linejoin={@fixture[6]}
                      class={@fixture[36]}
                      aria-hidden={@fixture[8]}
                    ><path d={@fixture[37]}></path><path d={@fixture[23]}></path><path d={
                      @fixture[38]
                    }>
                    </path><path d={@fixture[39]}></path></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[40]}</Trace.trace_title><Trace.trace_description class={
                    @fixture[27]
                  }>
                    {@fixture[41]}
                  </Trace.trace_description><Trace.trace_icon>
                    <svg
                      xmlns={@fixture[0]}
                      width={@fixture[1]}
                      height={@fixture[1]}
                      viewBox={@fixture[2]}
                      fill={@fixture[3]}
                      stroke={@fixture[4]}
                      stroke-width={@fixture[5]}
                      stroke-linecap={@fixture[6]}
                      stroke-linejoin={@fixture[6]}
                      class={@fixture[28]}
                      aria-hidden={@fixture[8]}
                    ><path d={@fixture[29]}></path></svg>
                  </Trace.trace_icon>
                </Trace.trace_line>
              </:trigger><:title>{@fixture[42]}</:title><:description>{@fixture[43]}</:description><CodeBlock.code_block class={
                @fixture[33]
              }>
                <CodeExamples.highlighted_content lines={@fixture[44]} />
              </CodeBlock.code_block>
            </Sheet.sheet>
          </Trace.trace>
        </Trace.trace_collapsible_content>
      </Trace.trace_collapsible>
    </Trace.trace>
    """
  end

  defp trace_turn_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "w-full max-w-sm",
        1 => "Worked for 2m 4s, 1 command failed",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 => "error",
        8 => "trace-turn-trace-1",
        9 => "http://www.w3.org/2000/svg",
        10 => "24",
        11 => "0 0 24 24",
        12 => "none",
        13 => "currentColor",
        14 => "2",
        15 => "round",
        16 => "lucide lucide-brain",
        17 => "true",
        18 => "M12 18V5",
        19 => "M15 13a4.17 4.17 0 0 1-3-4 4.17 4.17 0 0 1-3 4",
        20 => "M17.598 6.5A3 3 0 1 0 12 5a3 3 0 1 0-5.598 1.5",
        21 => "M17.997 5.125a4 4 0 0 1 2.526 5.77",
        22 => "M18 18a4 4 0 0 0 2-7.464",
        23 => "M19.967 17.483A4 4 0 1 1 12 18a4 4 0 1 1-7.967-.517",
        24 => "M6 18a4 4 0 0 1-2-7.464",
        25 => "M6.003 5.125a4 4 0 0 0-2.526 5.77",
        26 => "Thought",
        27 => "12s",
        28 => "trace-turn-trace-2",
        29 => "I should check which package managers are installed before I scaffold anything.",
        30 => "whitespace-pre-wrap",
        31 => "lucide lucide-terminal",
        32 => "M12 19h8",
        33 => "m4 17 6-6-6-6",
        34 => "Ran 2 commands, 1 failed",
        35 => "trace-turn-trace-3",
        36 => "Ran node --version",
        37 => "Failed to run pnpm --version",
        38 => "trace-turn-trace-4",
        39 => "max-h-64",
        40 => "command not found: pnpm",
        41 => "sm",
        42 => "destructive",
        43 => "Node is installed and pnpm is not. Reading the docs config.",
        44 => "#turn",
        45 => "lucide lucide-file-text",
        46 =>
          "M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z",
        47 => "M14 2v5a1 1 0 0 0 1 1h5",
        48 => "M10 9H8",
        49 => "M16 13H8",
        50 => "M16 17H8",
        51 => "Read apps/v4/lib/docs.ts",
        52 => "lucide lucide-chevron-right",
        53 => "m9 18 6-6-6-6",
        54 => "flex flex-col gap-2"
      })

    ~H"""
    <div class={@fixture[0]}>
      <Trace.trace_collapsible id={@fixture[8]} open={true}>
        <Trace.trace_collapsible_trigger for={@fixture[8]} open={true}>
          <Trace.trace_line status={@fixture[7]}>
            <Trace.trace_title>{@fixture[1]}</Trace.trace_title>
          </Trace.trace_line>
        </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
          phx-no-format
          class={@fixture[54]}
          for={@fixture[8]}
          open={true}
        >
          <Trace.trace>
            <Trace.trace_collapsible id={@fixture[28]} open={false}>
              <Trace.trace_collapsible_trigger for={@fixture[28]} open={false}>
                <Trace.trace_line>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[9]}
                      width={@fixture[10]}
                      height={@fixture[10]}
                      viewBox={@fixture[11]}
                      fill={@fixture[12]}
                      stroke={@fixture[13]}
                      stroke-width={@fixture[14]}
                      stroke-linecap={@fixture[15]}
                      stroke-linejoin={@fixture[15]}
                      class={@fixture[16]}
                      aria-hidden={@fixture[17]}
                    ><path d={@fixture[18]}></path><path d={@fixture[19]}></path><path d={
                      @fixture[20]
                    }>
                    </path><path d={@fixture[21]}></path><path d={@fixture[22]}></path><path d={
                      @fixture[23]
                    }>
                    </path><path d={@fixture[24]}></path><path d={@fixture[25]}></path></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[26]}</Trace.trace_title><Trace.trace_description>
                    {@fixture[27]}
                  </Trace.trace_description>
                </Trace.trace_line>
              </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content phx-no-format
                class={@fixture[30]}
                for={@fixture[28]}
                open={false}
              >{@fixture[29]}</Trace.trace_collapsible_content>
            </Trace.trace_collapsible><Trace.trace_collapsible id={@fixture[35]} open={true}>
              <Trace.trace_collapsible_trigger for={@fixture[35]} open={true}>
                <Trace.trace_line status={@fixture[7]}>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[9]}
                      width={@fixture[10]}
                      height={@fixture[10]}
                      viewBox={@fixture[11]}
                      fill={@fixture[12]}
                      stroke={@fixture[13]}
                      stroke-width={@fixture[14]}
                      stroke-linecap={@fixture[15]}
                      stroke-linejoin={@fixture[15]}
                      class={@fixture[31]}
                      aria-hidden={@fixture[17]}
                    ><path d={@fixture[32]}></path><path d={@fixture[33]}></path></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[34]}</Trace.trace_title>
                </Trace.trace_line>
              </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content phx-no-format
                for={@fixture[35]}
                open={true}
              >
                <Trace.trace>
                  <Trace.trace_line>
                    <Trace.trace_icon>
                      <svg
                        xmlns={@fixture[9]}
                        width={@fixture[10]}
                        height={@fixture[10]}
                        viewBox={@fixture[11]}
                        fill={@fixture[12]}
                        stroke={@fixture[13]}
                        stroke-width={@fixture[14]}
                        stroke-linecap={@fixture[15]}
                        stroke-linejoin={@fixture[15]}
                        class={@fixture[31]}
                        aria-hidden={@fixture[17]}
                      ><path d={@fixture[32]}></path><path d={@fixture[33]}></path></svg>
                    </Trace.trace_icon><Trace.trace_title>{@fixture[36]}</Trace.trace_title>
                  </Trace.trace_line><Trace.trace_collapsible id={@fixture[38]} open={false}>
                    <Trace.trace_collapsible_trigger for={@fixture[38]} open={false}>
                      <Trace.trace_line status={@fixture[7]}>
                        <Trace.trace_icon>
                          <svg
                            xmlns={@fixture[9]}
                            width={@fixture[10]}
                            height={@fixture[10]}
                            viewBox={@fixture[11]}
                            fill={@fixture[12]}
                            stroke={@fixture[13]}
                            stroke-width={@fixture[14]}
                            stroke-linecap={@fixture[15]}
                            stroke-linejoin={@fixture[15]}
                            class={@fixture[31]}
                            aria-hidden={@fixture[17]}
                          ><path d={@fixture[32]}></path><path d={@fixture[33]}></path></svg>
                        </Trace.trace_icon><Trace.trace_title>{@fixture[37]}</Trace.trace_title>
                      </Trace.trace_line>
                    </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content phx-no-format
                      for={@fixture[38]}
                      open={false}
                    >
                      <CodeBlock.code_block size={@fixture[41]} variant={@fixture[42]}>
                        <CodeBlock.code_block_content
                          wrap={true}
                          class={@fixture[39]}
                          code={@fixture[40]}
                        />
                      </CodeBlock.code_block>
                    </Trace.trace_collapsible_content>
                  </Trace.trace_collapsible>
                </Trace.trace>
              </Trace.trace_collapsible_content>
            </Trace.trace_collapsible>
          </Trace.trace><p>{@fixture[43]}</p><Trace.trace>
            <a href={@fixture[44]}><Trace.trace_line>
              <Trace.trace_icon>
                <svg
                  xmlns={@fixture[9]}
                  width={@fixture[10]}
                  height={@fixture[10]}
                  viewBox={@fixture[11]}
                  fill={@fixture[12]}
                  stroke={@fixture[13]}
                  stroke-width={@fixture[14]}
                  stroke-linecap={@fixture[15]}
                  stroke-linejoin={@fixture[15]}
                  class={@fixture[45]}
                  aria-hidden={@fixture[17]}
                ><path d={@fixture[46]}></path><path d={@fixture[47]}></path><path d={@fixture[48]}>
                </path><path d={@fixture[49]}></path><path d={@fixture[50]}></path></svg>
              </Trace.trace_icon><Trace.trace_title>{@fixture[51]}</Trace.trace_title><Trace.trace_icon>
                <svg
                  xmlns={@fixture[9]}
                  width={@fixture[10]}
                  height={@fixture[10]}
                  viewBox={@fixture[11]}
                  fill={@fixture[12]}
                  stroke={@fixture[13]}
                  stroke-width={@fixture[14]}
                  stroke-linecap={@fixture[15]}
                  stroke-linejoin={@fixture[15]}
                  class={@fixture[52]}
                  aria-hidden={@fixture[17]}
                ><path d={@fixture[53]}></path></svg>
              </Trace.trace_icon>
            </Trace.trace_line></a>
          </Trace.trace>
        </Trace.trace_collapsible_content>
      </Trace.trace_collapsible>
    </div>
    """
  end

  defp trace_thinking_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex min-h-72 w-full max-w-sm flex-col gap-4 py-6 text-sm",
        1 => "Send message",
        2 => "outline",
        3 => "sm",
        4 => "mt-auto self-start",
        5 => "__NEXT__",
        6 => "__TARGET__",
        7 => "__TOGGLE__",
        8 => "__DOWNLOAD__",
        9 => "__REPLAY__"
      })

    ~H"""
    <div class={@fixture[0]}>
      <Button.button
        id={@id <> "-action-1"}
        variant={@fixture[2]}
        size={@fixture[3]}
        class={@fixture[4]}
        phx-click="next"
        phx-target={@myself}
      >{@fixture[1]}</Button.button>
    </div>
    """
  end

  defp trace_thinking_messages_1(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex min-h-72 w-full max-w-sm flex-col gap-4 py-6 text-sm",
        1 => "Why is the checkout deploy so slow?",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 => "end",
        8 => "muted",
        9 => "Reset",
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

  defp trace_thinking_messages_2(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex min-h-72 w-full max-w-sm flex-col gap-4 py-6 text-sm",
        1 => "Why is the checkout deploy so slow?",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 => "end",
        8 => "muted",
        9 => "http://www.w3.org/2000/svg",
        10 => "24",
        11 => "0 0 24 24",
        12 => "none",
        13 => "currentColor",
        14 => "2",
        15 => "round",
        16 => "lucide lucide-brain",
        17 => "true",
        18 => "M12 18V5",
        19 => "M15 13a4.17 4.17 0 0 1-3-4 4.17 4.17 0 0 1-3 4",
        20 => "M17.598 6.5A3 3 0 1 0 12 5a3 3 0 1 0-5.598 1.5",
        21 => "M17.997 5.125a4 4 0 0 1 2.526 5.77",
        22 => "M18 18a4 4 0 0 0 2-7.464",
        23 => "M19.967 17.483A4 4 0 1 1 12 18a4 4 0 1 1-7.967-.517",
        24 => "M6 18a4 4 0 0 1-2-7.464",
        25 => "M6.003 5.125a4 4 0 0 0-2.526 5.77",
        26 => "Thought",
        27 => "trace-thinking-trace-1",
        28 =>
          "The build log shows install and compile finish in under a minute. Image optimization takes almost four, and it reruns on every deploy because the cache key includes the commit hash.",
        29 => "whitespace-pre-wrap",
        30 =>
          "Image optimization is the bottleneck. Key its cache on the lockfile and the image directory instead of the commit hash.",
        31 => "gap-4",
        32 => "Reset",
        33 => "outline",
        34 => "sm",
        35 => "mt-auto self-start"
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
        <Message.message_content class={@fixture[31]}>
          <Trace.trace>
            <Trace.trace_collapsible id={@fixture[27]} open={false}>
              <Trace.trace_collapsible_trigger
                for={@fixture[27]}
                open={false}
                phx-click="toggle"
                phx-target={@myself}
              >
                <Trace.trace_line>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[9]}
                      width={@fixture[10]}
                      height={@fixture[10]}
                      viewBox={@fixture[11]}
                      fill={@fixture[12]}
                      stroke={@fixture[13]}
                      stroke-width={@fixture[14]}
                      stroke-linecap={@fixture[15]}
                      stroke-linejoin={@fixture[15]}
                      class={@fixture[16]}
                      aria-hidden={@fixture[17]}
                    ><path d={@fixture[18]}></path><path d={@fixture[19]}></path><path d={
                      @fixture[20]
                    }>
                    </path><path d={@fixture[21]}></path><path d={@fixture[22]}></path><path d={
                      @fixture[23]
                    }>
                    </path><path d={@fixture[24]}></path><path d={@fixture[25]}></path></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[26]}</Trace.trace_title>
                </Trace.trace_line>
              </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
                phx-no-format
                class={@fixture[29]}
                for={@fixture[27]}
                open={false}
              >{@fixture[28]}</Trace.trace_collapsible_content>
            </Trace.trace_collapsible>
          </Trace.trace><p>{@fixture[30]}</p>
        </Message.message_content>
      </Message.message><Button.button
        id={@id <> "-action-1"}
        variant={@fixture[33]}
        size={@fixture[34]}
        class={@fixture[35]}
        phx-click="next"
        phx-target={@myself}
      >{@fixture[32]}</Button.button>
    </div>
    """
  end

  defp trace_tool_calls_initial(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex min-h-72 w-full max-w-sm flex-col gap-4 py-6 text-sm",
        1 => "Send message",
        2 => "outline",
        3 => "sm",
        4 => "mt-auto self-start",
        5 => "__NEXT__",
        6 => "__TARGET__",
        7 => "__TOGGLE__",
        8 => "__DOWNLOAD__",
        9 => "__REPLAY__"
      })

    ~H"""
    <div class={@fixture[0]}>
      <Button.button
        id={@id <> "-action-1"}
        variant={@fixture[2]}
        size={@fixture[3]}
        class={@fixture[4]}
        phx-click="next"
        phx-target={@myself}
      >{@fixture[1]}</Button.button>
    </div>
    """
  end

  defp trace_tool_calls_messages_1(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex min-h-72 w-full max-w-sm flex-col gap-4 py-6 text-sm",
        1 => "Which package managers are installed?",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 => "end",
        8 => "muted",
        9 => "Reset",
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

  defp trace_tool_calls_messages_2(assigns) do
    assigns =
      assign(assigns, :fixture, %{
        0 => "flex min-h-72 w-full max-w-sm flex-col gap-4 py-6 text-sm",
        1 => "Which package managers are installed?",
        2 => "__TOGGLE__",
        3 => "__TARGET__",
        4 => "__NEXT__",
        5 => "__DOWNLOAD__",
        6 => "__REPLAY__",
        7 => "end",
        8 => "muted",
        9 => "http://www.w3.org/2000/svg",
        10 => "24",
        11 => "0 0 24 24",
        12 => "none",
        13 => "currentColor",
        14 => "2",
        15 => "round",
        16 => "lucide lucide-terminal",
        17 => "true",
        18 => "M12 19h8",
        19 => "m4 17 6-6-6-6",
        20 => "Ran node --version",
        21 => "trace-tool-calls-trace-1",
        22 => "max-h-64",
        23 => "v24.18.0",
        24 => "sm",
        25 => "Ran npm --version",
        26 => "trace-tool-calls-trace-2",
        27 => "11.6.2",
        28 => "Failed to run pnpm --version",
        29 => "error",
        30 => "trace-tool-calls-trace-3",
        31 => "command not found: pnpm",
        32 => "Node 24 and npm 11 are installed. pnpm is not.",
        33 => "gap-4",
        34 => "Reset",
        35 => "outline",
        36 => "mt-auto self-start"
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
        <Message.message_content class={@fixture[33]}>
          <Trace.trace>
            <Trace.trace_collapsible id={@fixture[21]} open={false}>
              <Trace.trace_collapsible_trigger for={@fixture[21]} open={false}>
                <Trace.trace_line>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[9]}
                      width={@fixture[10]}
                      height={@fixture[10]}
                      viewBox={@fixture[11]}
                      fill={@fixture[12]}
                      stroke={@fixture[13]}
                      stroke-width={@fixture[14]}
                      stroke-linecap={@fixture[15]}
                      stroke-linejoin={@fixture[15]}
                      class={@fixture[16]}
                      aria-hidden={@fixture[17]}
                    ><path d={@fixture[18]}></path><path d={@fixture[19]}></path></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[20]}</Trace.trace_title>
                </Trace.trace_line>
              </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
                phx-no-format
                for={@fixture[21]}
                open={false}
              >
                <CodeBlock.code_block size={@fixture[24]}>
                  <CodeBlock.code_block_content wrap={true} class={@fixture[22]} code={@fixture[23]} />
                </CodeBlock.code_block>
              </Trace.trace_collapsible_content>
            </Trace.trace_collapsible><Trace.trace_collapsible id={@fixture[26]} open={false}>
              <Trace.trace_collapsible_trigger for={@fixture[26]} open={false}>
                <Trace.trace_line>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[9]}
                      width={@fixture[10]}
                      height={@fixture[10]}
                      viewBox={@fixture[11]}
                      fill={@fixture[12]}
                      stroke={@fixture[13]}
                      stroke-width={@fixture[14]}
                      stroke-linecap={@fixture[15]}
                      stroke-linejoin={@fixture[15]}
                      class={@fixture[16]}
                      aria-hidden={@fixture[17]}
                    ><path d={@fixture[18]}></path><path d={@fixture[19]}></path></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[25]}</Trace.trace_title>
                </Trace.trace_line>
              </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
                phx-no-format
                for={@fixture[26]}
                open={false}
              >
                <CodeBlock.code_block size={@fixture[24]}>
                  <CodeBlock.code_block_content wrap={true} class={@fixture[22]} code={@fixture[27]} />
                </CodeBlock.code_block>
              </Trace.trace_collapsible_content>
            </Trace.trace_collapsible><Trace.trace_collapsible id={@fixture[30]} open={false}>
              <Trace.trace_collapsible_trigger for={@fixture[30]} open={false}>
                <Trace.trace_line status={@fixture[29]}>
                  <Trace.trace_icon>
                    <svg
                      xmlns={@fixture[9]}
                      width={@fixture[10]}
                      height={@fixture[10]}
                      viewBox={@fixture[11]}
                      fill={@fixture[12]}
                      stroke={@fixture[13]}
                      stroke-width={@fixture[14]}
                      stroke-linecap={@fixture[15]}
                      stroke-linejoin={@fixture[15]}
                      class={@fixture[16]}
                      aria-hidden={@fixture[17]}
                    ><path d={@fixture[18]}></path><path d={@fixture[19]}></path></svg>
                  </Trace.trace_icon><Trace.trace_title>{@fixture[28]}</Trace.trace_title>
                </Trace.trace_line>
              </Trace.trace_collapsible_trigger><Trace.trace_collapsible_content
                phx-no-format
                for={@fixture[30]}
                open={false}
              >
                <CodeBlock.code_block size={@fixture[24]}>
                  <CodeBlock.code_block_content wrap={true} class={@fixture[22]} code={@fixture[31]} />
                </CodeBlock.code_block>
              </Trace.trace_collapsible_content>
            </Trace.trace_collapsible>
          </Trace.trace><p>{@fixture[32]}</p>
        </Message.message_content>
      </Message.message><Button.button
        id={@id <> "-action-1"}
        variant={@fixture[35]}
        size={@fixture[24]}
        class={@fixture[36]}
        phx-click="next"
        phx-target={@myself}
      >{@fixture[34]}</Button.button>
    </div>
    """
  end
end
