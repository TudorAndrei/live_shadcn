defmodule LiveAiElements.Components.Edge do
  @moduledoc """
  Edge.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Temporary/class/0" => "stroke-1 stroke-ring"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `edge_animated` part."
  attr(:edge_path, :string, default: nil)
  attr(:id, :string, default: nil)
  attr(:marker_end, :string, default: nil)
  attr(:source, :string, default: nil)
  attr(:source_node, :string, default: nil)
  attr(:style, :string, default: nil)
  attr(:target, :string, default: nil)
  attr(:target_node, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def edge_animated(assigns) do
    ~H"""
    <path
      :if={@source_node && @target_node}
      fill="none"
      id={@id}
      marker-end={@marker_end}
      d={@edge_path}
      style={@style}
      class={@class}
      {@rest}
    />
    <circle :if={@source_node && @target_node} fill="var(--primary)" r="4">
      <animateMotion dur="2s" path={@edge_path} repeatCount="indefinite" />
    </circle>
    {render_slot(@inner_block)}
    """
  end

  @doc "The `edge_temporary` part."
  attr(:edge_path, :string, default: nil)
  attr(:id, :string, default: nil)
  attr(:source_position, :string, default: nil)
  attr(:source_x, :string, default: nil)
  attr(:source_y, :string, default: nil)
  attr(:target_position, :string, default: nil)
  attr(:target_x, :string, default: nil)
  attr(:target_y, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def edge_temporary(assigns) do
    ~H"""
    <path
      fill="none"
      id={@id}
      d={@edge_path}
      style="stroke-dasharray: 5, 5"
      class={upstream_fact("jsx/Temporary/class/0")}
    >
      {render_slot(@inner_block)}
    </path>
    """
  end
end
