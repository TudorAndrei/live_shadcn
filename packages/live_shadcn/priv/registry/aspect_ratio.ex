defmodule LiveShadcn.UI.AspectRatio do
  @moduledoc """
  Aspect ratio.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/AspectRatio/class/0" => "relative aspect-(--ratio)"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `aspect-ratio` part."
  attr(:ratio, :any, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def aspect_ratio(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "aspect-ratio"}
      style={"--ratio: #{@ratio}"}
      class={[upstream_fact("jsx/AspectRatio/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end