defmodule LiveAiElements.Components.Queue do
  @moduledoc """
  Queue. Built on `shadcn/scroll-area`.

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
    "jsx/Queue/class/0" => "flex flex-col gap-2 rounded-xl border border-border bg-background px-3 pt-2 pb-2 shadow-xs",
    "jsx/QueueItem/class/0" => "group flex flex-col gap-1 rounded-md px-3 py-1 text-sm transition-colors hover:bg-muted",
    "jsx/QueueItemAction/class/0" => "size-auto rounded p-1 text-muted-foreground opacity-0 transition-opacity hover:bg-muted-foreground/10 hover:text-foreground group-hover:opacity-100",
    "jsx/QueueItemActions/class/0" => "flex gap-1",
    "jsx/QueueItemAttachment/class/0" => "mt-1 flex flex-wrap gap-2",
    "jsx/QueueItemContent/class/0" => "line-clamp-1 grow break-words",
    "jsx/QueueItemContent/class/1" => "text-muted-foreground/50 line-through",
    "jsx/QueueItemContent/class/2" => "text-muted-foreground",
    "jsx/QueueItemDescription/class/0" => "ml-6 text-xs",
    "jsx/QueueItemDescription/class/1" => "text-muted-foreground/40 line-through",
    "jsx/QueueItemFile/class/0" => "flex items-center gap-1 rounded border bg-muted px-2 py-1 text-xs",
    "jsx/QueueItemFile/class/1" => "max-w-[100px] truncate",
    "jsx/QueueItemImage/class/0" => "h-8 w-8 rounded border object-cover",
    "jsx/QueueItemIndicator/class/0" => "mt-0.5 inline-block size-2.5 rounded-full border",
    "jsx/QueueItemIndicator/class/1" => "border-muted-foreground/20 bg-muted-foreground/10",
    "jsx/QueueItemIndicator/class/2" => "border-muted-foreground/50",
    "jsx/QueueList/class/1" => "max-h-40 pr-4",
    "jsx/QueueSectionLabel/class/0" => "flex items-center gap-2",
    "jsx/QueueSectionLabel/class/1" => "size-4 transition-transform group-data-[state=closed]:-rotate-90",
    "jsx/QueueSectionTrigger/class/0" => "group flex w-full items-center justify-between rounded-md bg-muted/40 px-3 py-2 text-left font-medium text-muted-foreground text-sm transition-colors hover:bg-muted",
    "jsx/ScrollArea/class/1" => "cn-scroll-area-viewport size-full rounded-[inherit] transition-[color,box-shadow] outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-1",
    "jsx/ScrollBar/class/0" => "cn-scroll-area-scrollbar flex touch-none p-px transition-colors select-none",
    "jsx/ScrollBar/class/1" => "cn-scroll-area-thumb relative flex-1 bg-border",
    "port/class/0" => "cn-scroll-area relative mt-2 -mb-1"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `queue_item` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def queue_item(assigns) do
    ~H"""
    <li
      class={[
        upstream_fact("jsx/QueueItem/class/0"),
        (@class || "")
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </li>
    """
  end

  @doc "The `queue_item_indicator` part."
  attr(:completed, :boolean, default: false)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def queue_item_indicator(assigns) do
    ~H"""
    <span
      class={[
        upstream_fact("jsx/QueueItemIndicator/class/0"),
        if(@completed,
          do: upstream_fact("jsx/QueueItemIndicator/class/1"),
          else: upstream_fact("jsx/QueueItemIndicator/class/2")
        ),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `queue_item_content` part."
  attr(:completed, :boolean, default: false)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def queue_item_content(assigns) do
    ~H"""
    <span
      class={[
        upstream_fact("jsx/QueueItemContent/class/0"),
        if(@completed, do: upstream_fact("jsx/QueueItemContent/class/1"), else: upstream_fact("jsx/QueueItemContent/class/2")),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `queue_item_description` part."
  attr(:completed, :boolean, default: false)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def queue_item_description(assigns) do
    ~H"""
    <div
      class={[
        upstream_fact("jsx/QueueItemDescription/class/0"),
        if(@completed, do: upstream_fact("jsx/QueueItemDescription/class/1"), else: upstream_fact("jsx/QueueItemContent/class/2")),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `queue_item_actions` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def queue_item_actions(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/QueueItemActions/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `queue_item_action` part."
  attr(:size, :string, default: "icon")
  attr(:variant, :string, default: "ghost")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def queue_item_action(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      type="button"
      size={@size}
      variant={@variant}
      class={[
        upstream_fact("jsx/QueueItemAction/class/0"),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Button.button>
    """
  end

  @doc "The `queue_item_attachment` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def queue_item_attachment(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/QueueItemAttachment/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `queue_item_image` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")

  attr(:rest, :global,
    include: [
      "data-slot",
      "src",
      "srcset",
      "sizes",
      "alt",
      "loading",
      "decoding",
      "width",
      "height"
    ]
  )

  def queue_item_image(assigns) do
    ~H"""
    <img
      alt=""
      height={32}
      width={32}
      class={[upstream_fact("jsx/QueueItemImage/class/0"), (@class || "")]}
      {@rest}
    />
    """
  end

  @doc "The `queue_item_file` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def queue_item_file(assigns) do
    ~H"""
    <span
      class={[upstream_fact("jsx/QueueItemFile/class/0"), (@class || "")]}
      {@rest}
    >
      <LiveShadcn.Icon.icon name="paperclip" width="12" height="12" /><span class={upstream_fact("jsx/QueueItemFile/class/1")}>{render_slot(
        @inner_block
      )}</span>
    </span>
    """
  end

  @doc "The `scroll-area` part."
  attr(:orientation, :string, default: "vertical")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def queue_list(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "scroll-area"}
      class={[upstream_fact("port/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <div
        data-slot="scroll-area-viewport"
        class={upstream_fact("jsx/ScrollArea/class/1")}
      >
        <div class={upstream_fact("jsx/QueueList/class/1")}>
          <ul>
            {render_slot(@inner_block)}
          </ul>
        </div>
      </div>
      <div
        data-slot={@rest[:"data-slot"] || "scroll-area-scrollbar"}
        data-orientation={@orientation}
        orientation={@orientation}
        class={[upstream_fact("jsx/ScrollBar/class/0"), (@class || "")]}
        {Map.drop(@rest, [:"data-slot"])}
      >
        <div data-slot="scroll-area-thumb" class={upstream_fact("jsx/ScrollBar/class/1")} />
      </div>
      <div />
    </div>
    """
  end

  @doc "The `queue_section_trigger` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def queue_section_trigger(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        upstream_fact("jsx/QueueSectionTrigger/class/0"),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "The `queue_section_label` part."
  attr(:count, :any, default: nil)
  attr(:icon, :string, default: nil)
  attr(:label, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def queue_section_label(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/QueueSectionLabel/class/0"), (@class || "")]} {@rest}>
      <LiveShadcn.Icon.icon
        name="chevron-down"
        class={upstream_fact("jsx/QueueSectionLabel/class/1")}
      />{@icon}<span>{@count}{@label}</span>{render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `queue` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def queue(assigns) do
    ~H"""
    <div
      class={[
        upstream_fact("jsx/Queue/class/0"),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
