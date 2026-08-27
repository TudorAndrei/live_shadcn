defmodule LiveShadcn.UI.Chart do
  @moduledoc """
  Chart.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/ChartContainer/class/0" => "cn-chart flex aspect-video justify-center text-xs [&_.recharts-cartesian-axis-tick_text]:fill-muted-foreground [&_.recharts-cartesian-grid_line[stroke='#ccc']]:stroke-border/50 [&_.recharts-curve.recharts-tooltip-cursor]:stroke-border [&_.recharts-dot[stroke='#fff']]:stroke-transparent [&_.recharts-layer]:outline-hidden [&_.recharts-polar-grid_[stroke='#ccc']]:stroke-border [&_.recharts-radial-bar-background-sector]:fill-muted [&_.recharts-rectangle.recharts-tooltip-cursor]:fill-muted [&_.recharts-reference-line_[stroke='#ccc']]:stroke-border [&_.recharts-sector]:outline-hidden [&_.recharts-sector[stroke='#fff']]:stroke-transparent [&_.recharts-surface]:outline-hidden",
    "jsx/ChartLegendContent/class/0" => "flex items-center justify-center gap-4",
    "jsx/ChartLegendContent/class/1" => "pb-3",
    "jsx/ChartLegendContent/class/2" => "pt-3",
    "jsx/ChartLegendContent/class/3" => "flex items-center gap-1.5 [&>svg]:h-3 [&>svg]:w-3 [&>svg]:text-muted-foreground",
    "jsx/ChartTooltipContent/class/0" => "font-medium",
    "jsx/ChartTooltipContent/class/10" => "grid gap-1.5",
    "jsx/ChartTooltipContent/class/11" => "text-muted-foreground",
    "jsx/ChartTooltipContent/class/12" => "font-mono font-medium text-foreground tabular-nums",
    "jsx/ChartTooltipContent/class/2" => "cn-chart-tooltip grid min-w-32 items-start",
    "port/class/0" => "flex items-center justify-between gap-2"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

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
      class={[
        upstream_fact("jsx/ChartContainer/class/0"),
        (@class || "")
      ]}
      {@rest}
    >
      <%!-- `<%= %>` rather than `{…}`. A `<style>` is a raw-text element and
            HEEx does not interpolate a curly expression inside one, so this
            shipped a stylesheet whose entire content was the seven
            characters `{@chart_style}` — the same defect class as the
            textarea whose newlines were its value. --%>
      <style :if={map_size(@config) > 0}>
        <%= @chart_style %>
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
    <div data-slot="chart-tooltip" class={[upstream_fact("jsx/ChartTooltipContent/class/2"), (@class || "")]}>
      <p :if={@label} class={upstream_fact("jsx/ChartTooltipContent/class/0")}>{@label}</p>
      <div class={upstream_fact("jsx/ChartTooltipContent/class/10")}>
        <div :for={item <- @item} class={upstream_fact("port/class/0")}>
          <span class={upstream_fact("jsx/ChartTooltipContent/class/11")}>{item[:label]}</span><span class={upstream_fact("jsx/ChartTooltipContent/class/12")}>{render_slot(
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
        upstream_fact("jsx/ChartLegendContent/class/0"),
        if(@vertical_align == "top", do: upstream_fact("jsx/ChartLegendContent/class/1"), else: upstream_fact("jsx/ChartLegendContent/class/2")),
        (@class || "")
      ]}
    >
      <span
        :for={item <- @item}
        class={upstream_fact("jsx/ChartLegendContent/class/3")}
      ><span class="size-2 rounded-sm" style={"background: " <> (item[:color] || "currentColor")}></span>{render_slot(
        item
      )}</span>
    </div>
    """
  end

  # One `--color-<key>` per configured series, per theme.
  #
  # This is the whole of what upstream's `<style>` block does, and it is
  # data: the caller's config says which series exist and what colour each
  # one is, and the component writes the rules. It returned `""` before, so
  # `config` reached the markup and produced nothing — every
  # `stroke="var(--color-…)"` a caller wrote resolved to nothing and the
  # plot was drawn in no colour at all.
  @themes [{"light", ""}, {"dark", ".dark"}]

  defp chart_style(id, config) do
    Enum.map_join(@themes, "\n", fn {theme, prefix} ->
      rules =
        config
        |> Enum.sort_by(fn {key, _} -> to_string(key) end)
        |> Enum.flat_map(fn {key, item} ->
          case colour(item, theme) do
            nil -> []
            colour -> ["  --color-#{key}: #{colour};"]
          end
        end)

      if rules == [],
        do: "",
        else: "#{prefix} [data-chart=#{id}] {\n#{Enum.join(rules, "\n")}\n}\n"
    end)
  end

  defp colour(item, theme) do
    case item[:theme] || item["theme"] do
      %{} = per_theme -> per_theme[theme] || per_theme[String.to_existing_atom(theme)]
      _none -> item[:color] || item["color"]
    end
  end
end