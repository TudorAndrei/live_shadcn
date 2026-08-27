defmodule LiveAiElements.Components.Connection do
  @moduledoc """
  Connection.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Connection/class/0" => "animated"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `connection` part."
  attr(:from_x, :any, default: nil)
  attr(:from_y, :any, default: nil)
  attr(:to_x, :any, default: nil)
  attr(:to_y, :any, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def connection(assigns) do
    ~H"""
    <g>
      <path
        d={"M#{@from_x},#{@from_y} C #{@from_x + ((@to_x - @from_x) * 0.5)},#{@from_y} #{@from_x + ((@to_x - @from_x) * 0.5)},#{@to_y} #{@to_x},#{@to_y}"}
        fill="none"
        stroke="var(--color-ring)"
        stroke-width={1}
        class={upstream_fact("jsx/Connection/class/0")}
      />
      <circle cx={@to_x} cy={@to_y} fill="#fff" r={3} stroke="var(--color-ring)" stroke-width={1} />
      {render_slot(@inner_block)}
    </g>
    """
  end
end
