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
