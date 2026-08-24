defmodule LiveShadcn.UI.Chart do
  @moduledoc """
  Chart.
  """

  use Phoenix.Component

  attr(:id, :string, required: true)
  attr(:config, :map, default: %{})
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block, required: true)

  def chart_container(assigns) do
    assigns = assign(assigns, :chart_style, chart_style("chart-" <> assigns.id, assigns.config))

    ~H"""
    <div
      data-slot="chart"
      data-chart={"chart-" <> @id}
      class={["cn-chart flex aspect-video justify-center text-xs", @class]}
      {@rest}
    >
      <style :if={map_size(@config) > 0}>
        {@chart_style}
      </style>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:label, :string, default: nil)
  attr(:class, :any, default: nil)
  slot(:item)

  def chart_tooltip_content(assigns) do
    ~H"""
    <div data-slot="chart-tooltip" class={["cn-chart-tooltip grid min-w-32 items-start", @class]}>
      <p :if={@label} class="font-medium">{@label}</p>
      <div class="grid gap-1.5">
        <div :for={item <- @item} class="flex items-center justify-between gap-2">
          <span class="text-muted-foreground">{item[:label]}</span><span class="font-mono font-medium tabular-nums">{render_slot(
            item
          )}</span>
        </div>
      </div>
    </div>
    """
  end

  attr(:vertical_align, :string, default: "bottom", values: ["top", "bottom"])
  attr(:class, :any, default: nil)
  slot(:item)

  def chart_legend_content(assigns) do
    ~H"""
    <div
      data-slot="chart-legend"
      class={[
        "flex items-center justify-center gap-4",
        if(@vertical_align == "top", do: "pb-3", else: "pt-3"),
        @class
      ]}
    >
      <span :for={item <- @item} class="flex items-center gap-1.5"><span
        class="size-2 rounded-sm"
        style={"background: " <> (item[:color] || "currentColor")}
      ></span>{render_slot(item)}</span>
    </div>
    """
  end

  defp chart_style(_id, _config), do: ""
end
