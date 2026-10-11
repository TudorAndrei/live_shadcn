defmodule LiveAiElements.Components.Checkpoint do
  @moduledoc """
  Checkpoint. Built on `shadcn/tooltip`.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  alias LiveAiElements.Shadcn

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
      <LiveShadcn.UI.Separator.separator role="none" />
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

  @doc "The checkpoint action. Set a stable `id` when a tooltip is present."
  attr(:id, :string, default: nil)
  attr(:disabled, :boolean, default: false)
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
    if assigns.tooltip && is_nil(assigns.id) do
      raise ArgumentError, "checkpoint_trigger with a tooltip requires an id"
    end

    ~H"""
    <LiveShadcn.UI.Tooltip.tooltip
      :if={@tooltip}
      id={@id}
      align={@align}
      align_offset={@align_offset}
      side={@side}
      side_offset={@side_offset}
      trigger_variant={@variant}
      trigger_size={@size}
      trigger_class={["!gap-1.5", @class]}
      trigger_click={@rest[:"phx-click"]}
      trigger_attrs={Map.drop(@rest, [:"phx-click", :"data-slot"])}
      trigger_slot={@rest[:"data-slot"] || "tooltip-trigger"}
      disabled={@disabled}
    >
      <:trigger>{render_slot(@inner_block)}</:trigger>
      {@tooltip}
    </LiveShadcn.UI.Tooltip.tooltip>
    <button
      :if={!@tooltip}
      id={@id}
      data-slot={@rest[:"data-slot"] || "button"}
      type="button"
      disabled={@disabled}
      class={[Shadcn.button_class(@size, @variant), "!gap-1.5", @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end
