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
      "cn-message-scroller-viewport size-full min-h-0 min-w-0 scroll-fade-b scrollbar-thin scrollbar-gutter-stable overflow-y-auto overscroll-contain contain-content data-autoscrolling:scrollbar-thumb-transparent data-autoscrolling:scrollbar-track-transparent data-pending-scroll:invisible"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `message_scroller_provider` part."
  attr(:auto_scroll, :boolean, default: false)
  attr(:default_scroll_position, :string, default: "end", values: ["start", "end", "last-anchor"])
  attr(:scroll_edge_threshold, :integer, default: 8)
  attr(:scroll_margin, :integer, default: 0)
  attr(:scroll_previous_item_peek, :integer, default: 64)

  slot(:inner_block,
    doc:
      "The message scroller. Bind `:let={config}` to pass the provider scroll settings to `message_scroller/1`."
  )

  def message_scroller_provider(assigns) do
    assigns =
      assign(assigns, :config, %{
        auto_scroll: assigns.auto_scroll,
        default_scroll_position: assigns.default_scroll_position,
        scroll_edge_threshold: assigns.scroll_edge_threshold,
        scroll_margin: assigns.scroll_margin,
        scroll_previous_item_peek: assigns.scroll_previous_item_peek
      })

    ~H"""
    {render_slot(@inner_block, @config)}
    """
  end

  @doc "The `message-scroller` part."

  attr(:id, :string, default: nil)
  attr(:auto_scroll, :boolean, default: false)
  attr(:default_scroll_position, :string, default: "end", values: ["start", "end", "last-anchor"])
  attr(:scroll_edge_threshold, :integer, default: 8)
  attr(:scroll_margin, :integer, default: 0)
  attr(:scroll_previous_item_peek, :integer, default: 64)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_scroller(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "message-scroller"}
      id={@id}
      data-lb-message-scroller
      data-lb-message-controller={@id}
      data-lb-message-auto-scroll={to_string(@auto_scroll)}
      data-lb-message-default-position={@default_scroll_position}
      data-lb-message-scroll-edge-threshold={@scroll_edge_threshold}
      data-lb-message-scroll-margin={@scroll_margin}
      data-lb-message-previous-peek={@scroll_previous_item_peek}
      data-pending-scroll={if @default_scroll_position in ["end", "last-anchor"], do: ""}
      phx-mounted={
        LiveBase.Scroller.message_attributes(:root)
        |> LiveBase.Scroller.pending_attributes()
      }
      class={[
        upstream_fact("jsx/MessageScroller/class/0"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `message-scroller-viewport` part."

  attr(:id, :string, required: true, doc: "The hook needs one to be found by.")
  attr(:controller, :string, default: nil)

  attr(:default_scroll_position, :string,
    default: "end",
    values: ["start", "end", "last-anchor"]
  )

  attr(:preserve_scroll_on_prepend, :boolean, default: true)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "aria-label"])
  slot(:inner_block)

  def message_scroller_viewport(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "message-scroller-viewport"}
      role="region"
      aria-label={@rest[:"aria-label"] || "Messages"}
      id={@id}
      data-lb-scroller
      data-lb-message-scroller-viewport
      data-lb-message-controller={@controller || @id}
      data-lb-message-preserve-prepend={to_string(@preserve_scroll_on_prepend)}
      data-pending-scroll={if @default_scroll_position in ["end", "last-anchor"], do: ""}
      tabindex="0"
      phx-hook={LiveBase.Scroller.hook()}
      phx-mounted={
        LiveBase.Scroller.owned_attributes()
        |> LiveBase.Scroller.message_attributes(:viewport)
        |> LiveBase.Scroller.pending_attributes()
      }
      class={[
        upstream_fact("jsx/MessageScrollerViewport/class/0"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot", :"aria-label"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `message-scroller-content` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "aria-relevant"])
  slot(:inner_block)

  def message_scroller_content(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "message-scroller-content"}
      role="log"
      aria-relevant={@rest[:"aria-relevant"] || "additions"}
      class={[upstream_fact("jsx/MessageScrollerContent/class/0"), @class]}
      {Map.drop(@rest, [:"data-slot", :"aria-relevant"])}
    >
      {render_slot(@inner_block)}
      <div data-message-scroller-spacer aria-hidden="true" hidden />
    </div>
    """
  end

  @doc "The `message-scroller-item` part."
  attr(:message_id, :string, default: nil)
  attr(:scroll_anchor, :boolean, default: false)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_scroller_item(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "message-scroller-item"}
      data-message-id={@message_id}
      data-scroll-anchor={to_string(@scroll_anchor)}
      data-lb-message-intrinsic-size="auto 10rem"
      class={[
        upstream_fact("jsx/MessageScrollerItem/class/0"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `message-scroller-button` part."
  attr(:direction, :string, default: "end")
  attr(:behavior, :string, default: "smooth", values: ["auto", "smooth"])
  attr(:size, :string, default: "icon-sm")
  attr(:variant, :string, default: "secondary")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def message_scroller_button(assigns) do
    ~H"""
    <button
      data-slot={@rest[:"data-slot"] || "message-scroller-button"}
      type={@rest[:type] || "button"}
      data-direction={@direction}
      data-lb-message-scroll-behavior={@behavior}
      data-variant={@variant}
      data-size={@size}
      data-active="false"
      tabindex="-1"
      inert
      phx-mounted={LiveBase.Scroller.message_attributes(:button)}
      class={[
        message_button_class(@variant, @size),
        upstream_fact("jsx/MessageScrollerButton/class/0"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot", :type, :disabled])}
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

  # MessageScrollerButton falls back to shadcn's Button in the pinned React
  # component. Keep that fallback local so a copied registry file has no
  # dependency on the separately copied Button component.
  defp message_button_class(variant, size) do
    LiveShadcn.Cn.merge([
      "cn-button group/button inline-flex shrink-0 items-center justify-center whitespace-nowrap outline-none select-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0",
      "cn-button-variant-#{variant}",
      "cn-button-size-#{size}"
    ])
  end
end
