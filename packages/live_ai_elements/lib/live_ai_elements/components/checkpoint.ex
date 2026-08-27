defmodule LiveAiElements.Components.Checkpoint do
  @moduledoc """
  Checkpoint. Built on `shadcn/tooltip`.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Checkpoint/class/0" => "flex items-center gap-0.5 overflow-hidden text-muted-foreground",
    "jsx/CheckpointIcon/class/0" => "size-4 shrink-0",
    "jsx/TooltipContent/class/0" => "isolate z-50",
    "jsx/TooltipContent/class/1" =>
      "cn-tooltip-content cn-tooltip-content-logical z-50 w-fit max-w-xs origin-(--transform-origin) bg-foreground text-background",
    "jsx/TooltipContent/class/2" =>
      "cn-tooltip-arrow cn-tooltip-arrow-logical z-50 bg-foreground fill-foreground data-[side=bottom]:top-1 data-[side=left]:top-1/2! data-[side=left]:-right-1 data-[side=left]:-translate-y-1/2 data-[side=right]:top-1/2! data-[side=right]:-left-1 data-[side=right]:-translate-y-1/2 data-[side=top]:-bottom-2.5"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `checkpoint` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def checkpoint(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/Checkpoint/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
      <LiveShadcn.UI.Separator.separator />
    </div>
    """
  end

  @doc "The `checkpoint_icon` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def checkpoint_icon(assigns) do
    ~H"""
    <%= if @inner_block == [] do %>
      <LiveShadcn.Icon.icon name="bookmark" class={[upstream_fact("jsx/CheckpointIcon/class/0"), (@class || "")]} {@rest} />
    <% end %>
    {render_slot(@inner_block)}
    """
  end

  @doc "The `checkpoint_trigger` part."
  attr(:align, :string, default: "start")
  attr(:align_offset, :string, default: "0")
  attr(:side, :string, default: "bottom")
  attr(:side_offset, :string, default: "4")
  attr(:size, :string, default: "sm")
  attr(:tooltip, :string, default: nil)
  attr(:variant, :string, default: "ghost")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def checkpoint_trigger(assigns) do
    ~H"""
    <button
      :if={@tooltip}
      data-slot={@rest[:"data-slot"] || "tooltip-trigger"}
      type="button"
      size={@size}
      variant={@variant}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </button>
    <div :if={@tooltip}>
      <div
        align={@align}
        alignOffset={@align_offset}
        side={@side}
        sideOffset={@side_offset}
        class={upstream_fact("jsx/TooltipContent/class/0")}
      >
        <div
          data-slot={@rest[:"data-slot"] || "tooltip-content"}
          class={[
            upstream_fact("jsx/TooltipContent/class/1"),
            (@class || "")
          ]}
          {Map.drop(@rest, [:"data-slot"])}
        >
          {@tooltip}
          <div class={upstream_fact("jsx/TooltipContent/class/2")} />
        </div>
      </div>
    </div>
    <LiveShadcn.UI.Button.button :if={!@tooltip} type="button" size={@size} variant={@variant} {@rest}>
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Button.button>
    """
  end
end
