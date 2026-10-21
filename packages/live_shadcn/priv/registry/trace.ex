defmodule LiveShadcn.UI.Trace do
  @moduledoc """
  Reviewed trace parts from the pinned shadcn source.

  The marked facts follow upstream. The component body implements the LiveView API.
  """
  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Trace/class/0" =>
      "cn-trace flex w-full min-w-0 flex-col *:has-[>[data-slot=trace-line]]:flex *:has-[>[data-slot=trace-line]]:w-fit *:has-[>[data-slot=trace-line]]:max-w-full *:has-[>[data-slot=trace-line]]:min-w-0 *:has-[>[data-slot=trace-line]]:text-left *:has-[>[data-slot=trace-line]]:outline-none",
    "jsx/TraceCollapsible/class/0" => "cn-trace-collapsible flex w-full min-w-0 flex-col",
    "jsx/TraceCollapsibleContent/class/0" =>
      "cn-trace-collapsible-content h-(--collapsible-panel-height) min-w-0 overflow-hidden transition-[height] data-ending-style:h-0 data-starting-style:h-0",
    "jsx/TraceCollapsibleContent/class/1" =>
      "cn-trace-collapsible-content-inner min-w-0 wrap-break-word text-muted-foreground",
    "jsx/TraceCollapsibleTrigger/class/0" =>
      "cn-trace-collapsible-trigger group/trace-collapsible-trigger flex w-fit max-w-full min-w-0 cursor-pointer items-center text-left text-muted-foreground transition-colors outline-none hover:text-foreground has-[[data-status=error]]:text-destructive",
    "jsx/TraceCollapsibleTrigger/class/1" =>
      "transition-transform group-aria-expanded/trace-collapsible-trigger:rotate-90",
    "jsx/TraceDescription/class/0" =>
      "cn-trace-description shrink-0 text-muted-foreground/70 tabular-nums",
    "jsx/TraceIcon/class/0" =>
      "cn-trace-icon flex shrink-0 items-center justify-center [&_svg]:pointer-events-none",
    "jsx/TraceLine/class/0" =>
      "cn-trace-line flex w-fit max-w-full min-w-0 items-center text-muted-foreground transition-colors in-[a,button]:cursor-pointer in-[a:hover,button:hover]:text-foreground data-[status=error]:text-destructive data-[status=error]:in-[a:hover,button:hover]:text-destructive data-[status=pending]:opacity-60 data-[status=running]:*:data-[slot=trace-title]:shimmer",
    "jsx/TraceTitle/class/0" => "cn-trace-title min-w-0 truncate motion-reduce:shimmer-none"
  }
  # live-shadcn: upstream facts end

  defp fact(key), do: Map.fetch!(@upstream_facts, key)
  defp classes(values), do: LiveShadcn.Cn.merge(values)

  @doc "Renders the trace part."
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def trace(assigns) do
    ~H"""
    <div data-slot="trace" class={classes([fact("jsx/Trace/class/0"), @class])}  {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc "Renders the trace line part."
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)
  attr(:status, :string, default: nil, values: [nil, "running", "error", "pending"])

  def trace_line(assigns) do
    ~H"""
    <span data-slot="trace-line" class={classes([fact("jsx/TraceLine/class/0"), @class])} data-status={@status} {@rest}>{render_slot(@inner_block)}</span>
    """
  end

  @doc "Renders the trace icon part."
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def trace_icon(assigns) do
    ~H"""
    <span data-slot="trace-icon" class={classes([fact("jsx/TraceIcon/class/0"), @class])} aria-hidden="true" {@rest}>{render_slot(@inner_block)}</span>
    """
  end

  @doc "Renders the trace title part."
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def trace_title(assigns) do
    ~H"""
    <span data-slot="trace-title" class={classes([fact("jsx/TraceTitle/class/0"), @class])}  {@rest}>{render_slot(@inner_block)}</span>
    """
  end

  @doc "Renders the trace description part."
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def trace_description(assigns) do
    ~H"""
    <span data-slot="trace-description" class={classes([fact("jsx/TraceDescription/class/0"), @class])}  {@rest}>{render_slot(@inner_block)}</span>
    """
  end

  @doc "Groups a trace trigger and its expandable content."
  attr(:id, :string, required: true)
  attr(:controlled, :boolean, default: false)
  attr(:open, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def trace_collapsible(assigns) do
    ~H"""
    <LiveShadcn.UI.Collapsible.collapsible id={@id} open={@open} controlled={@controlled} composed data-slot="trace-collapsible" class={classes([fact("jsx/TraceCollapsible/class/0"), @class])} {@rest}>{render_slot(@inner_block)}</LiveShadcn.UI.Collapsible.collapsible>
    """
  end

  @doc "Renders a trace disclosure trigger with its state indicator."
  attr(:for, :string, required: true)
  attr(:controlled, :boolean, default: false)
  attr(:open, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def trace_collapsible_trigger(assigns) do
    ~H"""
    <LiveShadcn.UI.Collapsible.collapsible_trigger for={@for} open={@open} controlled={@controlled} disabled={@disabled} data-slot="trace-collapsible-trigger" class={classes([fact("jsx/TraceCollapsibleTrigger/class/0"), @class])} {@rest}>
      {render_slot(@inner_block)}
      <.trace_icon class={fact("jsx/TraceCollapsibleTrigger/class/1")}><LiveShadcn.Icon.icon name="chevron-right" /></.trace_icon>
    </LiveShadcn.UI.Collapsible.collapsible_trigger>
    """
  end

  @doc "Renders trace details. The class applies to the inner content."
  attr(:for, :string, required: true)
  attr(:controlled, :boolean, default: false)
  attr(:open, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def trace_collapsible_content(assigns) do
    ~H"""
    <LiveShadcn.UI.Collapsible.collapsible_content for={@for} open={@open} controlled={@controlled} data-slot="trace-collapsible-content" class={fact("jsx/TraceCollapsibleContent/class/0")} {@rest}><div data-lb-resize-target data-slot="trace-collapsible-content-inner" class={classes([fact("jsx/TraceCollapsibleContent/class/1"), @class])}>{render_slot(@inner_block)}</div></LiveShadcn.UI.Collapsible.collapsible_content>
    """
  end
end
