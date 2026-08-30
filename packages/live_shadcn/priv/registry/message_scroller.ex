defmodule LiveShadcn.UI.MessageScroller do
  @moduledoc """
  Message scroller.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/MessageScroller/class/0" =>
      "cn-message-scroller group/message-scroller relative flex size-full min-h-0 flex-col overflow-hidden",
    "jsx/MessageScrollerButton/class/0" =>
      "cn-message-scroller-button absolute inset-s-1/2 -translate-x-1/2 border-border bg-background text-foreground transition-[translate,scale,opacity] duration-200 hover:bg-muted hover:text-foreground data-[active=false]:pointer-events-none data-[active=false]:scale-95 data-[active=false]:opacity-0 data-[active=false]:duration-400 data-[active=false]:ease-[cubic-bezier(0.7,0,0.84,0)] data-[active=true]:translate-y-0 data-[active=true]:scale-100 data-[active=true]:opacity-100 data-[active=true]:ease-[cubic-bezier(0.23,1,0.32,1)] data-[direction=end]:bottom-4 data-[direction=end]:data-[active=false]:translate-y-full data-[direction=start]:top-4 data-[direction=start]:data-[active=false]:-translate-y-full rtl:translate-x-1/2 data-[direction=start]:[&_svg]:rotate-180",
    "jsx/MessageScrollerButton/class/1" => "sr-only",
    "jsx/MessageScrollerContent/class/0" =>
      "cn-message-scroller-content flex h-max min-h-full flex-col",
    "jsx/MessageScrollerItem/class/0" =>
      "cn-message-scroller-item min-w-0 shrink-0 [contain-intrinsic-size:auto_10rem] [content-visibility:auto]",
    "jsx/MessageScrollerViewport/class/0" =>
      "cn-message-scroller-viewport size-full min-h-0 min-w-0 scroll-fade-b scrollbar-thin scrollbar-gutter-stable overflow-y-auto overscroll-contain contain-content data-autoscrolling:scrollbar-thumb-transparent data-autoscrolling:scrollbar-track-transparent"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `message_scroller_provider` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_scroller_provider(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  @doc "The `message-scroller` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_scroller(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "message-scroller"}
      class={[
        upstream_fact("jsx/MessageScroller/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `message-scroller-viewport` part."

  attr(:id, :string, required: true, doc: "The hook needs one to be found by.")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_scroller_viewport(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "message-scroller-viewport"}
      role="region"
      id={@id}
      data-lb-scroller
      data-lb-stick-to-bottom
      tabindex="0"
      phx-hook={LiveBase.Scroller.hook()}
      phx-mounted={LiveBase.Scroller.owned_attributes()}
      class={[
        upstream_fact("jsx/MessageScrollerViewport/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `message-scroller-content` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_scroller_content(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "message-scroller-content"}
      role="log"
      class={[upstream_fact("jsx/MessageScrollerContent/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `message-scroller-item` part."
  attr(:scroll_anchor, :boolean, default: false)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_scroller_item(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "message-scroller-item"}
      class={[
        upstream_fact("jsx/MessageScrollerItem/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `message-scroller-button` part."
  attr(:direction, :string, default: "end")
  attr(:size, :string, default: "icon-sm")
  attr(:variant, :string, default: "secondary")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def message_scroller_button(assigns) do
    ~H"""
    <button
      data-slot={@rest[:"data-slot"] || "message-scroller-button"}
      data-direction={@direction}
      data-variant={@variant}
      data-size={@size}
      class={[
        upstream_fact("jsx/MessageScrollerButton/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <%= if @inner_block == [] do %>
        <LiveShadcn.Icon.icon name="arrow-down" /><span class={upstream_fact("jsx/MessageScrollerButton/class/1")}>{if(@direction == "end",
          do: "Scroll to end",
          else: "Scroll to start"
        )}</span>
      <% end %>
      {render_slot(@inner_block)}
    </button>
    """
  end
end
