defmodule LiveShadcn.UI.Resizable do
  @moduledoc """
  Resizable.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/ResizableHandle/class/0" =>
      "cn-resizable-handle relative flex w-px items-center justify-center bg-border ring-offset-background after:absolute after:inset-y-0 after:left-1/2 after:w-1 after:-translate-x-1/2 focus-visible:ring-1 focus-visible:ring-ring focus-visible:outline-hidden aria-[orientation=horizontal]:h-px aria-[orientation=horizontal]:w-full aria-[orientation=horizontal]:after:left-0 aria-[orientation=horizontal]:after:h-1 aria-[orientation=horizontal]:after:w-full aria-[orientation=horizontal]:after:translate-x-0 aria-[orientation=horizontal]:after:-translate-y-1/2 [&[aria-orientation=horizontal]>div]:rotate-90",
    "jsx/ResizableHandle/class/1" => "cn-resizable-handle-icon z-10 flex shrink-0"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.Resizable

  @doc "The `resizable-handle` part."
  attr(:with_handle, :boolean, default: false)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)
  attr(:orientation, :string, default: "vertical", values: ["horizontal", "vertical"])
  attr(:value_now, :integer, default: 50)

  def resizable_handle(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "resizable-handle"}
      data-lb-resizable-handle
      role="separator"
      tabindex="0"
      aria-orientation={@orientation}
      aria-valuemin="0"
      aria-valuemax="100"
      aria-valuenow={to_string(@value_now)}
      style="flex: 0 0 auto; touch-action: none;"
      class={[
        upstream_fact("jsx/ResizableHandle/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <div :if={@with_handle} class={upstream_fact("jsx/ResizableHandle/class/1")} />
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `resizable-panel` part."
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)
  attr(:default_size, :string, default: nil)
  attr(:orientation, :string, default: "horizontal", values: ["horizontal", "vertical"])

  def resizable_panel(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "resizable-panel"}
      class={@class}
      style={panel_style(@default_size)}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <div style={panel_content_style(@orientation)}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc "The `resizable-panel-group` part."
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)
  attr(:id, :string, required: true)
  attr(:orientation, :string, default: "horizontal", values: ["horizontal", "vertical"])

  def resizable_panel_group(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "resizable-panel-group"}
      id={@id}
      phx-hook={Resizable.hook()}
      data-lb-orientation={@orientation}
      style={group_style(@orientation)}
      class={[
        "cn-resizable-panel-group flex h-full w-full aria-[orientation=vertical]:flex-col",
        @orientation == "vertical" && "flex-col",
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp panel_style(nil), do: nil

  defp panel_style(size) do
    number = String.trim_trailing(size, "%")

    "min-height: 0px; max-height: 100%; height: auto; min-width: 0px; " <>
      "max-width: 100%; width: auto; border: 0px; padding: 0px; margin: 0px; " <>
      "display: flex; flex: #{number} 1 0px; overflow: visible;"
  end

  defp panel_content_style("vertical"),
    do: "max-height: 100%; max-width: 100%; flex-grow: 1; overflow: auto; touch-action: pan-x;"

  defp panel_content_style(_orientation),
    do: "max-height: 100%; max-width: 100%; flex-grow: 1; overflow: auto; touch-action: pan-y;"

  defp group_style("vertical"),
    do:
      "height: 100%; width: 100%; overflow: hidden; display: flex; flex-flow: column; touch-action: pan-x;"

  defp group_style(_orientation),
    do:
      "height: 100%; width: 100%; overflow: hidden; display: flex; flex-flow: row; touch-action: pan-y;"
end
