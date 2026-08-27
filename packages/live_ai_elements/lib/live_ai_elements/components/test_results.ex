defmodule LiveAiElements.Components.TestResults do
  @moduledoc """
  Test results. Built on `shadcn/collapsible`.

  Upstream exports 2 more parts, each a thin
  wrapper around a part of `<.collapsible>`. That component is one
  function here — its parts have to agree about which one they belong to,
  and an id repeated is an id to mistype — so it is what to compose inside
  this, and there is nothing for the wrappers to wrap.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Test/class/0" => "flex items-center gap-2 px-4 py-2 text-sm",
    "jsx/TestDuration/class/0" => "ml-auto text-muted-foreground text-xs",
    "jsx/TestError/class/0" => "mt-2 rounded-md bg-red-50 p-3 dark:bg-red-900/20",
    "jsx/TestErrorMessage/class/0" => "font-medium text-red-700 text-sm dark:text-red-400",
    "jsx/TestErrorStack/class/0" =>
      "mt-2 overflow-auto font-mono text-red-600 text-xs dark:text-red-400",
    "jsx/TestName/class/0" => "flex-1",
    "jsx/TestResults/class/0" => "rounded-lg border bg-background",
    "jsx/TestResultsContent/class/0" => "space-y-2 p-4",
    "jsx/TestResultsDuration/class/0" => "text-muted-foreground text-sm",
    "jsx/TestResultsHeader/class/0" => "flex items-center justify-between border-b px-4 py-3",
    "jsx/TestResultsProgress/class/0" => "space-y-2",
    "jsx/TestResultsProgress/class/1" => "flex h-2 overflow-hidden rounded-full bg-muted",
    "jsx/TestResultsProgress/class/2" => "bg-green-500 transition-all",
    "jsx/TestResultsProgress/class/3" => "bg-red-500 transition-all",
    "jsx/TestResultsProgress/class/4" => "flex justify-between text-muted-foreground text-xs",
    "jsx/TestResultsSummary/class/0" => "flex items-center gap-3",
    "jsx/TestResultsSummary/class/1" =>
      "gap-1 bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400",
    "jsx/TestResultsSummary/class/2" => "size-3",
    "jsx/TestResultsSummary/class/3" =>
      "gap-1 bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
    "jsx/TestResultsSummary/class/5" =>
      "gap-1 bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400",
    "jsx/TestStatus/class/0" => "shrink-0",
    "jsx/TestSuite/class/0" => "rounded-lg border",
    "jsx/TestSuiteStats/class/0" => "ml-auto flex items-center gap-2 text-xs",
    "jsx/TestSuiteStats/class/1" => "text-green-600 dark:text-green-400",
    "jsx/TestSuiteStats/class/2" => "text-red-600 dark:text-red-400",
    "jsx/TestSuiteStats/class/3" => "text-yellow-600 dark:text-yellow-400",
    "jsx/anonymous/class/0" => "size-4",
    "jsx/anonymous/class/2" => "size-4 animate-pulse"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `test_results_header` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def test_results_header(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/TestResultsHeader/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `test_results_duration` part."
  attr(:summary, :any, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def test_results_duration(assigns) do
    ~H"""
    <span :if={@summary.duration} class={[upstream_fact("jsx/TestResultsDuration/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        {"#{:erlang.float_to_binary(@summary.duration / 1000 / 1, decimals: 2)}s"}
      <% end %>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `test_results_summary` part."
  attr(:summary, :any, default: nil)
  attr(:variant, :string, default: "secondary")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def test_results_summary(assigns) do
    ~H"""
    <div :if={@summary} class={[upstream_fact("jsx/TestResultsSummary/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        <LiveShadcn.UI.Badge.badge
          variant={@variant}
          class={upstream_fact("jsx/TestResultsSummary/class/1")}
        >
          <LiveShadcn.Icon.icon name="circle-check" class={upstream_fact("jsx/TestResultsSummary/class/2")} />{@summary.passed} passed
        </LiveShadcn.UI.Badge.badge>
        <LiveShadcn.UI.Badge.badge
          :if={@summary.failed > 0}
          variant={@variant}
          class={upstream_fact("jsx/TestResultsSummary/class/3")}
        >
          <LiveShadcn.Icon.icon name="circle-x" class={upstream_fact("jsx/TestResultsSummary/class/2")} />{@summary.failed} failed
        </LiveShadcn.UI.Badge.badge>
        <LiveShadcn.UI.Badge.badge
          :if={@summary.skipped > 0}
          variant={@variant}
          class={upstream_fact("jsx/TestResultsSummary/class/5")}
        >
          <LiveShadcn.Icon.icon name="circle" class={upstream_fact("jsx/TestResultsSummary/class/2")} />{@summary.skipped} skipped
        </LiveShadcn.UI.Badge.badge>
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `test_results` part."
  attr(:summary, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def test_results(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/TestResults/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        <.test_results_header :if={@summary}>
          <.test_results_summary summary={@summary} />
          <.test_results_duration summary={@summary} />
        </.test_results_header>
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `test_results_progress` part."
  attr(:failed_percent, :string, default: nil)
  attr(:passed_percent, :any, default: nil)
  attr(:summary, :any, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def test_results_progress(assigns) do
    ~H"""
    <div :if={@summary} class={[upstream_fact("jsx/TestResultsProgress/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        <div class={upstream_fact("jsx/TestResultsProgress/class/1")}>
          <div style={"width: #{"#{@passed_percent}%"}"} class={upstream_fact("jsx/TestResultsProgress/class/2")} />
          <div style={"width: #{"#{@failed_percent}%"}"} class={upstream_fact("jsx/TestResultsProgress/class/3")} />
        </div>
        <div class={upstream_fact("jsx/TestResultsProgress/class/4")}>
          <span>{@summary.passed}/{@summary.total} tests passed</span><span>{:erlang.float_to_binary(
            @passed_percent / 1, decimals: 0)}%</span>
        </div>
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `test_results_content` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def test_results_content(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/TestResultsContent/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `test_suite` part."
  attr(:name, :string, default: nil)
  attr(:status, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def test_suite(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "collapsible"}
      class={[upstream_fact("jsx/TestSuite/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `test_suite_stats` part."
  attr(:failed, :any, default: 0)
  attr(:passed, :any, default: 0)
  attr(:skipped, :any, default: 0)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def test_suite_stats(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/TestSuiteStats/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        <span :if={@passed > 0} class={upstream_fact("jsx/TestSuiteStats/class/1")}>
          {@passed} passed
        </span>
        <span :if={@failed > 0} class={upstream_fact("jsx/TestSuiteStats/class/2")}>
          {@failed} failed
        </span>
        <span :if={@skipped > 0} class={upstream_fact("jsx/TestSuiteStats/class/3")}>
          {@skipped} skipped
        </span>
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `test_name` part."
  attr(:name, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def test_name(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/TestName/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        {@name}
      <% end %>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `test_duration` part."
  attr(:duration, :any, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def test_duration(assigns) do
    ~H"""
    <span :if={!is_nil(@duration)} class={[upstream_fact("jsx/TestDuration/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        {"#{@duration}ms"}
      <% end %>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `test_status` part."
  attr(:status, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def test_status(assigns) do
    ~H"""
    <span
      class={[
        upstream_fact("jsx/TestStatus/class/0"),
        if(@status == "failed", do: upstream_fact("jsx/TestSuiteStats/class/2"), else: nil),
        if(@status == "passed", do: upstream_fact("jsx/TestSuiteStats/class/1"), else: nil),
        if(@status == "running", do: "text-blue-600 dark:text-blue-400", else: nil),
        if(@status == "skipped", do: upstream_fact("jsx/TestSuiteStats/class/3"), else: nil),
        (@class || "")
      ]}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        <LiveShadcn.Icon.icon :if={@status == "failed"} name="circle-x" class={upstream_fact("jsx/anonymous/class/0")} />
        <LiveShadcn.Icon.icon :if={@status == "passed"} name="circle-check" class={upstream_fact("jsx/anonymous/class/0")} />
        <LiveShadcn.Icon.icon
          :if={@status == "running"}
          name="circle-dot"
          class={upstream_fact("jsx/anonymous/class/2")}
        />
        <LiveShadcn.Icon.icon :if={@status == "skipped"} name="circle" class={upstream_fact("jsx/anonymous/class/0")} />
      <% end %>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `test` part."
  attr(:duration, :any, default: nil)
  attr(:name, :string, default: nil)
  attr(:status, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def test(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/Test/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        <.test_status status={@status} />
        <.test_name name={@name} />
        <.test_duration :if={not is_nil(@duration)} duration={@duration} />
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `test_error` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def test_error(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/TestError/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `test_error_message` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def test_error_message(assigns) do
    ~H"""
    <p class={[upstream_fact("jsx/TestErrorMessage/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc "The `test_error_stack` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def test_error_stack(assigns) do
    ~H"""
    <pre
      phx-no-format
      class={[upstream_fact("jsx/TestErrorStack/class/0"), (@class || "")]}
      {@rest}
    >{render_slot(@inner_block)}</pre>
    """
  end
end
