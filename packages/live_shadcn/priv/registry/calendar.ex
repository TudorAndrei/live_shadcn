defmodule LiveShadcn.UI.Calendar do
  @moduledoc """
  Calendar.

  Reviewed from shadcn/ui. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  alias LiveBase.Calendar, as: CalendarHook

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "port/calendar/button_next" => "cn-button group/button inline-flex shrink-0 items-center justify-center whitespace-nowrap transition-all outline-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 cn-button-size-default cn-button-variant-ghost size-(--cell-size) p-0 select-none aria-disabled:opacity-50 rdp-button_next",
    "port/calendar/button_previous" => "cn-button group/button inline-flex shrink-0 items-center justify-center whitespace-nowrap transition-all outline-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 cn-button-size-default cn-button-variant-ghost size-(--cell-size) p-0 select-none aria-disabled:opacity-50 rdp-button_previous",
    "port/calendar/caption_label" => "font-medium select-none cn-calendar-caption text-sm rdp-caption_label",
    "port/calendar/chevron_left" => "cn-rtl-flip size-4 rdp-chevron",
    "port/calendar/chevron_right" => "cn-rtl-flip size-4 rdp-chevron",
    "port/calendar/day" => "group/day relative aspect-square h-full w-full rounded-(--cell-radius) p-0 text-center select-none [&:last-child[data-selected=true]_button]:rounded-r-(--cell-radius) [&:first-child[data-selected=true]_button]:rounded-l-(--cell-radius) rdp-day",
    "port/calendar/day_button" => "cn-button group/button shrink-0 items-center justify-center whitespace-nowrap transition-all outline-none select-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 cn-button-size-icon cn-button-variant-ghost cn-calendar-day-button relative isolate z-10 flex aspect-square size-auto w-full min-w-(--cell-size) flex-col gap-1 border-0 leading-none font-normal group-data-[focused=true]/day:relative group-data-[focused=true]/day:z-10 group-data-[focused=true]/day:border-ring group-data-[focused=true]/day:ring-[3px] group-data-[focused=true]/day:ring-ring/50 data-[range-end=true]:rounded-(--cell-radius) data-[range-end=true]:rounded-r-(--cell-radius) data-[range-end=true]:bg-primary data-[range-end=true]:text-primary-foreground data-[range-middle=true]:rounded-none data-[range-middle=true]:bg-muted data-[range-middle=true]:text-foreground data-[range-start=true]:rounded-(--cell-radius) data-[range-start=true]:rounded-l-(--cell-radius) data-[range-start=true]:bg-primary data-[range-start=true]:text-primary-foreground data-[selected-single=true]:bg-primary data-[selected-single=true]:text-primary-foreground dark:hover:text-foreground [&>span]:text-xs [&>span]:opacity-70 rdp-day_button",
    "port/calendar/month" => "flex w-full flex-col gap-4 rdp-month",
    "port/calendar/month_caption" => "flex h-(--cell-size) w-full items-center justify-center px-(--cell-size) rdp-month_caption",
    "port/calendar/month_grid" => "w-full border-collapse rdp-month_grid",
    "port/calendar/months" => "relative flex flex-col gap-4 md:flex-row rdp-months",
    "port/calendar/nav" => "absolute inset-x-0 top-0 flex w-full items-center justify-between gap-1 rdp-nav",
    "port/calendar/outside" => "text-muted-foreground aria-selected:text-muted-foreground rdp-outside",
    "port/calendar/root" => "w-fit rdp-root cn-calendar group/calendar bg-background in-data-[slot=card-content]:bg-transparent in-data-[slot=popover-content]:bg-transparent rtl:**:[.rdp-button\\_next>svg]:rotate-180 rtl:**:[.rdp-button\\_previous>svg]:rotate-180",
    "port/calendar/week" => "mt-2 flex w-full rdp-week",
    "port/calendar/weekday" => "flex-1 rounded-(--cell-radius) text-[0.8rem] font-normal text-muted-foreground select-none rdp-weekday",
    "port/calendar/weekdays" => "flex rdp-weekdays"
  }
  # live-shadcn: upstream facts end

  @doc "A deterministic month grid. The server owns the dates and selection."
  attr(:month, Date, default: Date.utc_today())
  attr(:selected, Date, default: nil)
  attr(:week_starts_on, :integer, default: 7, values: 1..7)
  attr(:id, :string, required: true)
  attr(:locale, :string, default: "en", values: ["en", "browser"])
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["aria-label", "data-slot"])

  def calendar(assigns) do
    assigns = assign(assigns, :weeks, month_weeks(assigns.month, assigns.week_starts_on))

    ~H"""
    <section
      id={@id}
      phx-hook={if @locale == "browser", do: CalendarHook.hook()}
      data-lb-calendar-locale={@locale}
      data-slot="calendar"
      class={[
        upstream_fact("port/calendar/root"),
        @class
      ]}
      {@rest}
    >
      <%!-- Every class string below is upstream's, read out of the
            `classNames` prop shadcn hands react-day-picker and out of the
            `<Button>` its day cell renders. None of the twenty-six is
            typed here. --%>
      <div class={upstream_fact("port/calendar/months")}>
        <%!-- The nav is a sibling of the month, positioned over it, not a
              child of the caption. That is how upstream builds it, and
              putting the buttons inside the caption instead is what made
              our month grid a pixel shorter than React's. --%>
        <nav class={upstream_fact("port/calendar/nav")}>
          <%!-- The chevrons upstream draws, not the `‹` and `›` characters
                that used to stand in for them — a glyph from the font is a
                different shape, a different size and a different colour
                from an SVG. Both the icon and its class are read out of the
                `components` prop shadcn hands react-day-picker. --%>
          <button
            type="button"
            aria-label="Go to the previous month"
            class={upstream_fact("port/calendar/button_previous")}
          >
            <LiveShadcn.Icon.icon
              name="chevron-left"
              class={upstream_fact("port/calendar/chevron_left")}
            />
          </button>
          <button
            type="button"
            aria-label="Go to the next month"
            class={upstream_fact("port/calendar/button_next")}
          >
            <LiveShadcn.Icon.icon
              name="chevron-right"
              class={upstream_fact("port/calendar/chevron_right")}
            />
          </button>
        </nav>
        <div class={upstream_fact("port/calendar/month")}>
          <div class={upstream_fact("port/calendar/month_caption")}>
            <span
              data-lb-calendar-month={Date.to_iso8601(@month)}
              class={upstream_fact("port/calendar/caption_label")}
            >{Calendar.strftime(@month, "%B %Y")}</span>
          </div>
          <table
            class={upstream_fact("port/calendar/month_grid")}
            role="grid"
            aria-label={Calendar.strftime(@month, "%B %Y")}
          >
            <thead>
              <tr class={upstream_fact("port/calendar/weekdays")}>
                <%!-- No width. The cells carry none upstream either: the grid is
                  seven `flex-1` columns and the heading text is what decides
                  how wide they settle. A width typed here was this recipe
                  laying the grid out itself, and it drew the columns 8.5px
                  wider than React's because the heading said `Sun` where
                  react-day-picker says `Su`. --%>
                <th
                  :for={day <- weekday_dates(@week_starts_on)}
                  data-lb-calendar-weekday={Date.to_iso8601(day)}
                  class={upstream_fact("port/calendar/weekday")}
                  scope="col"
                >
                  {weekday_name(day)}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr :for={week <- @weeks} class={upstream_fact("port/calendar/week")}>
                <%!-- `data-selected` belongs to the cell and `data-selected-single`
                  to the button, because that is which element each class
                  string asks about: the cell's `[&:last-child[data-selected=true]_button]`
                  rounds a run of days, and the button's
                  `data-[selected-single=true]:bg-primary` fills one. --%>
                <td
                  :for={day <- week}
                  role="gridcell"
                  data-day={Date.to_iso8601(day)}
                  data-selected={day == @selected && "true"}
                  aria-selected={day == @selected && "true"}
                  class={[
                    upstream_fact("port/calendar/day"),
                    (day.month != @month.month &&
                       upstream_fact("port/calendar/outside")) || ""
                  ]}
                >
                  <button
                    type="button"
                    data-slot="button"
                    data-day={Date.to_iso8601(day)}
                    data-selected-single={day == @selected && "true"}
                    class={upstream_fact("port/calendar/day_button")}
                  >
                    {day.day}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>
    """
  end

  defp month_weeks(month, week_starts_on) do
    first = %{month | day: 1}
    offset = rem(Date.day_of_week(first) - week_starts_on + 7, 7)
    start = Date.add(first, -offset)
    last = Date.end_of_month(month)
    weeks = div(offset + last.day + 6, 7)
    for week <- 0..(weeks - 1), do: for(day <- 0..6, do: Date.add(start, week * 7 + day))
  end

  defp weekday_dates(week_starts_on) do
    first = ~D[2023-01-02]
    start = Date.add(first, rem(week_starts_on - 1, 7))
    for day <- 0..6, do: Date.add(start, day)
  end

  # Two letters, because that is what upstream draws.
  #
  # react-day-picker formats a weekday heading with date-fns `cccccc` — the
  # narrow form, `Su Mo Tu We Th Fr Sa`. `%a` is the three-letter one, and
  # three letters made every heading 1.14px wider than React's. Times seven
  # columns in an auto-laid-out table, that is the 8px the parity check kept
  # reporting on the calendar's width and nowhere else.
  defp weekday_name(day), do: day |> Calendar.strftime("%a") |> String.slice(0, 2)
  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)
end
