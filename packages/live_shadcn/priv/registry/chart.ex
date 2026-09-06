defmodule LiveShadcn.UI.Chart do
  @moduledoc """
  Chart.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/ChartContainer/class/0" =>
      "cn-chart flex aspect-video justify-center text-xs [&_.recharts-cartesian-axis-tick_text]:fill-muted-foreground [&_.recharts-cartesian-grid_line[stroke='#ccc']]:stroke-border/50 [&_.recharts-curve.recharts-tooltip-cursor]:stroke-border [&_.recharts-dot[stroke='#fff']]:stroke-transparent [&_.recharts-layer]:outline-hidden [&_.recharts-polar-grid_[stroke='#ccc']]:stroke-border [&_.recharts-radial-bar-background-sector]:fill-muted [&_.recharts-rectangle.recharts-tooltip-cursor]:fill-muted [&_.recharts-reference-line_[stroke='#ccc']]:stroke-border [&_.recharts-sector]:outline-hidden [&_.recharts-sector[stroke='#fff']]:stroke-transparent [&_.recharts-surface]:outline-hidden",
    "jsx/ChartLegendContent/class/0" => "flex items-center justify-center gap-4",
    "jsx/ChartLegendContent/class/1" => "pb-3",
    "jsx/ChartLegendContent/class/2" => "pt-3",
    "jsx/ChartLegendContent/class/3" =>
      "flex items-center gap-1.5 [&>svg]:h-3 [&>svg]:w-3 [&>svg]:text-muted-foreground",
    "jsx/ChartLegendContent/class/4" => "h-2 w-2 shrink-0 rounded-[2px]",
    "jsx/ChartTooltipContent/class/0" => "font-medium",
    "jsx/ChartTooltipContent/class/1" => "font-medium",
    "jsx/ChartTooltipContent/class/10" => "grid gap-1.5",
    "jsx/ChartTooltipContent/class/11" => "text-muted-foreground",
    "jsx/ChartTooltipContent/class/12" => "font-mono font-medium text-foreground tabular-nums",
    "jsx/ChartTooltipContent/class/2" => "cn-chart-tooltip grid min-w-32 items-start",
    "jsx/ChartTooltipContent/class/3" => "grid gap-1.5",
    "jsx/ChartTooltipContent/class/4" =>
      "flex w-full flex-wrap items-stretch gap-2 [&>svg]:h-2.5 [&>svg]:w-2.5 [&>svg]:text-muted-foreground",
    "jsx/ChartTooltipContent/class/5" => "items-center",
    "jsx/ChartTooltipContent/class/6" =>
      "shrink-0 rounded-[2px] border-(--color-border) bg-(--color-bg)",
    "jsx/ChartTooltipContent/class/7" => "flex flex-1 justify-between leading-none",
    "jsx/ChartTooltipContent/class/8" => "items-end",
    "jsx/ChartTooltipContent/class/9" => "items-center"
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
      class={LiveShadcn.Cn.merge([
        upstream_fact("jsx/ChartContainer/class/0"),
        @class || ""
      ])}
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
  attr(:indicator, :string, default: "dot", values: ["dot", "line", "dashed"])
  attr(:hide_label, :boolean, default: false)
  attr(:hide_indicator, :boolean, default: false)
  attr(:label_class, :any, default: nil)
  attr(:class, :any, default: nil)

  slot(:item) do
    attr(:label, :string)
    attr(:color, :string)
  end

  def chart_tooltip_content(assigns) do
    assigns =
      assign(assigns, :nest_label, length(assigns.item) == 1 and assigns.indicator != "dot")

    ~H"""
    <div class={
      LiveShadcn.Cn.merge([upstream_fact("jsx/ChartTooltipContent/class/2"), @class || ""])
    }>
      <div
        :if={@label && !@hide_label && !@nest_label}
        class={
          LiveShadcn.Cn.merge([
            upstream_fact("jsx/ChartTooltipContent/class/0"),
            @label_class
          ])
        }
      >
        {@label}
      </div>
      <div class={upstream_fact("jsx/ChartTooltipContent/class/3")}>
        <div
          :for={item <- @item}
          class={LiveShadcn.Cn.merge([
            upstream_fact("jsx/ChartTooltipContent/class/4"),
            @indicator == "dot" && upstream_fact("jsx/ChartTooltipContent/class/5")
          ])}
        >
          <div
            :if={!@hide_indicator}
            class={LiveShadcn.Cn.merge([
              upstream_fact("jsx/ChartTooltipContent/class/6"),
              @indicator == "dot" && "h-2.5 w-2.5",
              @indicator == "line" && "w-1",
              @indicator == "dashed" && "w-0 border-[1.5px] border-dashed bg-transparent",
              @nest_label && @indicator == "dashed" && "my-0.5"
            ])}
            style={"--color-bg: #{item[:color]}; --color-border: #{item[:color]};"}
          />
          <div class={LiveShadcn.Cn.merge([
            upstream_fact("jsx/ChartTooltipContent/class/7"),
            if(@nest_label,
              do: upstream_fact("jsx/ChartTooltipContent/class/8"),
              else: upstream_fact("jsx/ChartTooltipContent/class/9")
            )
          ])}>
            <div class={upstream_fact("jsx/ChartTooltipContent/class/10")}>
              <div
                :if={@label && !@hide_label && @nest_label}
                class={
                  LiveShadcn.Cn.merge([
                    upstream_fact("jsx/ChartTooltipContent/class/1"),
                    @label_class
                  ])
                }
              >
                {@label}
              </div>
              <span class={upstream_fact("jsx/ChartTooltipContent/class/11")}>{item[:label]}</span>
            </div>
            <span class={upstream_fact("jsx/ChartTooltipContent/class/12")}>{render_slot(item)}</span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:vertical_align, :string, default: "bottom", values: ["top", "bottom"])
  attr(:class, :any, default: nil)

  slot(:item) do
    attr(:color, :string)
  end

  def chart_legend_content(assigns) do
    ~H"""
    <div class={LiveShadcn.Cn.merge([
      upstream_fact("jsx/ChartLegendContent/class/0"),
      if(@vertical_align == "top",
        do: upstream_fact("jsx/ChartLegendContent/class/1"),
        else: upstream_fact("jsx/ChartLegendContent/class/2")
      ),
      @class || ""
    ])}>
      <span
        :for={item <- @item}
        class={upstream_fact("jsx/ChartLegendContent/class/3")}
      >
        <span
          class={upstream_fact("jsx/ChartLegendContent/class/4")}
          style={"background-color: " <> (item[:color] || "currentColor")}
        />{render_slot(item)}
      </span>
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
