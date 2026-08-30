defmodule LiveAiElements.Components.StackTrace do
  @moduledoc """
  Stack trace.

  Upstream exports 1 more part, each a thin
  wrapper around a part of `<.collapsible>`. That component is one
  function here — its parts have to agree about which one they belong to,
  and an id repeated is an id to mistype — so it is what to compose inside
  this, and there is nothing for the wrappers to wrap.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  alias LiveAiElements.Shadcn

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/anonymous/class/0" =>
      "not-prose w-full overflow-hidden rounded-lg border bg-background font-mono text-sm",
    "jsx/anonymous/class/1" =>
      "flex w-full cursor-pointer items-center gap-3 p-3 text-left transition-colors hover:bg-muted/50",
    "jsx/anonymous/class/10" => "rotate-180",
    "jsx/anonymous/class/11" => "rotate-0",
    "jsx/anonymous/class/14" => "underline decoration-dotted hover:text-primary",
    "jsx/anonymous/class/15" => "cursor-pointer",
    "jsx/anonymous/class/16" => "space-y-1 p-3",
    "jsx/anonymous/class/17" => "text-xs",
    "jsx/anonymous/class/18" => "text-muted-foreground/50",
    "jsx/anonymous/class/19" => "text-foreground/90",
    "jsx/anonymous/class/2" => "flex flex-1 items-center gap-2 overflow-hidden",
    "jsx/anonymous/class/20" => "text-muted-foreground",
    "jsx/anonymous/class/23" => "text-muted-foreground text-xs",
    "jsx/anonymous/class/3" => "size-4 shrink-0 text-destructive",
    "jsx/anonymous/class/4" => "shrink-0 font-semibold text-destructive",
    "jsx/anonymous/class/5" => "truncate text-foreground",
    "jsx/anonymous/class/6" => "flex shrink-0 items-center gap-1",
    "jsx/anonymous/class/7" => "size-7",
    "jsx/anonymous/class/8" => "flex size-7 items-center justify-center",
    "jsx/anonymous/class/9" => "size-4 text-muted-foreground transition-transform"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `stack_trace` part."
  attr(:default_open, :boolean, default: false)
  attr(:open, :boolean, default: nil)
  attr(:trace, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def stack_trace(assigns) do
    ~H"""
    <div
      class={[
        upstream_fact("jsx/anonymous/class/0"),
        (@class || "")
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `stack_trace_header` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def stack_trace_header(assigns) do
    ~H"""
    <div data-slot="collapsible" data-state="open">
      <div
        data-slot="collapsible-trigger"
        data-state="open"
        aria-expanded="true"
        class={[
          upstream_fact("jsx/anonymous/class/1"),
          (@class || "")
        ]}
        {@rest}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc "The `stack_trace_error` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def stack_trace_error(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/anonymous/class/2"), (@class || "")]} {@rest}>
      <LiveShadcn.Icon.icon name="triangle-alert" class={upstream_fact("jsx/anonymous/class/3")} />{render_slot(
        @inner_block
      )}
    </div>
    """
  end

  @doc "The `stack_trace_error_type` part."
  attr(:trace, :any, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def stack_trace_error_type(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/anonymous/class/4"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        {@trace.errorType}
      <% end %>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `stack_trace_error_message` part."
  attr(:trace, :any, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def stack_trace_error_message(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/anonymous/class/5"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        {@trace.errorMessage}
      <% end %>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `stack_trace_actions` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def stack_trace_actions(assigns) do
    ~H"""
    <div role="group" class={[upstream_fact("jsx/anonymous/class/6"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `stack_trace_copy_button` part."
  attr(:size, :string, default: "icon")
  attr(:timeout, :any, default: 2000)
  attr(:variant, :string, default: "ghost")
  attr(:id, :string, required: true, doc: "The hook needs one to be found by.")
  attr(:raw, :string, required: true, doc: "The stack trace the button copies.")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def stack_trace_copy_button(assigns) do
    ~H"""
    <button
      data-slot={@rest[:"data-slot"] || "button"}
      type="button"
      id={@id}
      phx-hook={LiveBase.Clipboard.hook()}
      phx-mounted={LiveBase.Clipboard.owned_attributes()}
      data-lb-clipboard={@raw}
      data-lb-timeout={@timeout}
      class={[Shadcn.button_class(@size, @variant), upstream_fact("jsx/anonymous/class/7"), "!size-7", @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <%= if @inner_block == [] do %>
        <LiveShadcn.Icon.icon data-lb-state="copied" hidden name="check" width="14" height="14" />
        <LiveShadcn.Icon.icon data-lb-state="idle" name="copy" width="14" height="14" />
      <% end %>
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "The `stack_trace_expand_button` part."
  attr(:is_open, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def stack_trace_expand_button(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/anonymous/class/8"), (@class || "")]} {@rest}>
      <LiveShadcn.Icon.icon
        name="chevron-down"
        class={[
          upstream_fact("jsx/anonymous/class/9"),
          if(@is_open, do: upstream_fact("jsx/anonymous/class/10"), else: upstream_fact("jsx/anonymous/class/11"))
        ]}
      />{render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `stack_trace_frames` part."
  attr(:frame, :any, default: nil)
  attr(:frames_to_show, :any, default: nil)
  attr(:show_internal_frames, :boolean, default: true)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def stack_trace_frames(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/anonymous/class/16"), (@class || "")]} {@rest}>
      <div
        :for={frame <- @frames_to_show}
        class={[
          upstream_fact("jsx/anonymous/class/17"),
          if(frame.isInternal, do: upstream_fact("jsx/anonymous/class/18"), else: upstream_fact("jsx/anonymous/class/19"))
        ]}
      >
        <span class={upstream_fact("jsx/anonymous/class/20")}>
          at
        </span>
        <span :if={frame.functionName} class={[if(frame.isInternal, do: "", else: "text-foreground")]}>
          {frame.functionName}
        </span>
        <span :if={frame.filePath} class={upstream_fact("jsx/anonymous/class/20")}>(</span><button
          :if={frame.filePath}
          type="button"
          class={[upstream_fact("jsx/anonymous/class/14"), upstream_fact("jsx/anonymous/class/15")]}
        >{frame.filePath}{if(not is_nil(frame.lineNumber), do: ":#{frame.lineNumber}")}{if(
          not is_nil(frame.columnNumber), do: ":#{frame.columnNumber}")}</button><span
          :if={frame.filePath}
          class={upstream_fact("jsx/anonymous/class/20")}
        >)</span>
        <span :if={!(frame.filePath || frame.functionName)}>
          {String.replace(frame.raw, ~r/^at\s+/, "", global: false)}
        </span>
      </div>
      <div :if={length(@frames_to_show) == 0} class={upstream_fact("jsx/anonymous/class/23")}>
        No stack frames
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
