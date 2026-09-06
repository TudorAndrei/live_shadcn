defmodule LiveShadcn.UI.Calendar do
  @moduledoc """
  A server-rendered port of shadcn's Calendar.

  The server owns the initial grid. `LiveBase.Calendar` owns native keyboard
  navigation and uncontrolled selection after mount. A host can make either
  value controlled with `on_select` and `on_month_change`.
  """

  use Phoenix.Component

  alias LiveBase.Calendar, as: CalendarHook

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "port/calendar/button_next" =>
      "cn-button group/button inline-flex shrink-0 items-center justify-center whitespace-nowrap transition-all outline-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 cn-button-variant-ghost cn-button-size-default size-(--cell-size) p-0 select-none aria-disabled:opacity-50 rdp-button_next",
    "port/calendar/button_previous" =>
      "cn-button group/button inline-flex shrink-0 items-center justify-center whitespace-nowrap transition-all outline-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 cn-button-variant-ghost cn-button-size-default size-(--cell-size) p-0 select-none aria-disabled:opacity-50 rdp-button_previous",
    "port/calendar/caption_label" =>
      "font-medium select-none cn-calendar-caption text-sm rdp-caption_label",
    "port/calendar/chevron_left" => "cn-rtl-flip size-4 rdp-chevron",
    "port/calendar/chevron_right" => "cn-rtl-flip size-4 rdp-chevron",
    "port/calendar/day" =>
      "group/day relative aspect-square h-full w-full rounded-(--cell-radius) p-0 text-center select-none [&:last-child[data-selected=true]_button]:rounded-r-(--cell-radius) [&:first-child[data-selected=true]_button]:rounded-l-(--cell-radius) rdp-day",
    "port/calendar/day_button" =>
      "cn-button group/button shrink-0 items-center justify-center whitespace-nowrap transition-all outline-none select-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 cn-button-variant-ghost cn-button-size-icon cn-calendar-day-button relative isolate z-10 flex aspect-square size-auto w-full min-w-(--cell-size) flex-col gap-1 border-0 leading-none font-normal group-data-[focused=true]/day:relative group-data-[focused=true]/day:z-10 group-data-[focused=true]/day:border-ring group-data-[focused=true]/day:ring-[3px] group-data-[focused=true]/day:ring-ring/50 data-[range-end=true]:rounded-(--cell-radius) data-[range-end=true]:rounded-r-(--cell-radius) data-[range-end=true]:bg-primary data-[range-end=true]:text-primary-foreground data-[range-middle=true]:rounded-none data-[range-middle=true]:bg-muted data-[range-middle=true]:text-foreground data-[range-start=true]:rounded-(--cell-radius) data-[range-start=true]:rounded-l-(--cell-radius) data-[range-start=true]:bg-primary data-[range-start=true]:text-primary-foreground data-[selected-single=true]:bg-primary data-[selected-single=true]:text-primary-foreground dark:hover:text-foreground [&>span]:text-xs [&>span]:opacity-70 rdp-day rdp-day_button",
    "port/calendar/month" => "flex w-full flex-col gap-4 rdp-month",
    "port/calendar/month_caption" =>
      "flex h-(--cell-size) w-full items-center justify-center px-(--cell-size) rdp-month_caption",
    "port/calendar/month_grid" => "w-full border-collapse rdp-month_grid",
    "port/calendar/months" => "relative flex flex-col gap-4 md:flex-row rdp-months",
    "port/calendar/nav" =>
      "absolute inset-x-0 top-0 flex w-full items-center justify-between gap-1 rdp-nav",
    "port/calendar/outside" =>
      "text-muted-foreground aria-selected:text-muted-foreground rdp-outside",
    "port/calendar/root" =>
      "w-fit rdp-root cn-calendar group/calendar bg-background in-data-[slot=card-content]:bg-transparent in-data-[slot=popover-content]:bg-transparent rtl:**:[.rdp-button\\_next>svg]:rotate-180 rtl:**:[.rdp-button\\_previous>svg]:rotate-180",
    "port/calendar/week" => "mt-2 flex w-full rdp-week",
    "port/calendar/weekday" =>
      "flex-1 rounded-(--cell-radius) text-[0.8rem] font-normal text-muted-foreground select-none rdp-weekday",
    "port/calendar/weekdays" => "flex rdp-weekdays"
  }

  # live-shadcn: upstream facts end

  @calendar_root_class @upstream_facts["port/calendar/root"]

  defp calendar_root_class("persian") do
    "w-fit rdp-root group/calendar bg-background p-3 [--cell-size:--spacing(8)] [[data-slot=card-content]_&]:bg-transparent [[data-slot=popover-content]_&]:bg-transparent rtl:**:[.rdp-button\\_next>svg]:rotate-180 rtl:**:[.rdp-button\\_previous>svg]:rotate-180"
  end

  defp calendar_root_class(_calendar), do: @calendar_root_class
  defp calendar_dir("persian", _dir), do: "rtl"
  defp calendar_dir(_calendar, dir), do: dir

  defp calendar_button_class(side),
    do: Map.fetch!(@upstream_facts, "port/calendar/button_#{side}")

  # react-day-picker gives a dropdown caption its implicit 100-year range,
  # ending on 31 December of the current year.
  defp nav_disabled?(_month, layout, _side) when layout != "dropdown", do: false

  defp nav_disabled?(month, "dropdown", "previous") do
    Date.compare(Date.add(month, -31), Date.new!(Date.utc_today().year - 100, 1, 1)) == :lt
  end

  defp nav_disabled?(month, "dropdown", "next") do
    Date.compare(Date.add(month, 31), Date.new!(Date.utc_today().year, 12, 1)) == :gt
  end

  defp calendar_day_button_class("persian") do
    "cn-button group/button shrink-0 items-center justify-center whitespace-nowrap transition-all outline-none select-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 cn-button-variant-ghost cn-button-size-icon flex aspect-square size-auto w-full min-w-(--cell-size) flex-col gap-1 leading-none font-normal group-data-[focused=true]/day:relative group-data-[focused=true]/day:z-10 group-data-[focused=true]/day:border-ring group-data-[focused=true]/day:ring-[3px] group-data-[focused=true]/day:ring-ring/50 data-[range-end=true]:rounded-md data-[range-end=true]:rounded-r-md data-[range-end=true]:bg-primary data-[range-end=true]:text-primary-foreground data-[range-middle=true]:rounded-none data-[range-middle=true]:bg-accent data-[range-middle=true]:text-accent-foreground data-[range-start=true]:rounded-md data-[range-start=true]:rounded-l-md data-[range-start=true]:bg-primary data-[range-start=true]:text-primary-foreground data-[selected-single=true]:bg-primary data-[selected-single=true]:text-primary-foreground dark:hover:text-accent-foreground [&>span]:text-xs [&>span]:opacity-70 rdp-day rdp-day_button"
  end

  defp calendar_day_button_class(_calendar),
    do: Map.fetch!(@upstream_facts, "port/calendar/day_button")

  defp calendar_chevron_class("persian"), do: "size-4 rdp-chevron"
  defp calendar_chevron_class(_calendar), do: "cn-rtl-flip size-4 rdp-chevron"

  defp calendar_caption_label_class("persian"),
    do: "font-medium select-none text-sm rdp-caption_label"

  defp calendar_caption_label_class(_calendar),
    do: "font-medium select-none cn-calendar-caption text-sm rdp-caption_label"

  defp calendar_weekday_class("persian"),
    do:
      "flex-1 rounded-md text-[0.8rem] font-normal text-muted-foreground select-none rdp-weekday"

  defp calendar_weekday_class(_calendar),
    do:
      "flex-1 rounded-(--cell-radius) text-[0.8rem] font-normal text-muted-foreground select-none rdp-weekday"

  defp calendar_day_base_class(_show_week_number, "persian", _day_group) do
    "group/day relative aspect-square h-full w-full p-0 text-center select-none [&:first-child[data-selected=true]_button]:rounded-l-md [&:last-child[data-selected=true]_button]:rounded-r-md rdp-day"
  end

  defp calendar_day_base_class(true, _calendar, day_group) do
    "#{if(day_group, do: "group/day ")}relative aspect-square h-full w-full rounded-(--cell-radius) p-0 text-center select-none [&:last-child[data-selected=true]_button]:rounded-r-(--cell-radius) rdp-day [&:nth-child(2)[data-selected=true]_button]:rounded-l-(--cell-radius)"
  end

  defp calendar_day_base_class(false, _calendar, day_group) do
    "#{if(day_group, do: "group/day ")}relative aspect-square h-full w-full rounded-(--cell-radius) p-0 text-center select-none [&:last-child[data-selected=true]_button]:rounded-r-(--cell-radius) [&:first-child[data-selected=true]_button]:rounded-l-(--cell-radius) rdp-day"
  end

  defp calendar_range_class(:start, "persian"), do: "rounded-l-md bg-accent"
  defp calendar_range_class(:middle, "persian"), do: "rounded-none"
  defp calendar_range_class(:end, "persian"), do: "rounded-r-md bg-accent"

  defp calendar_range_class(:start, _calendar),
    do:
      "relative isolate z-0 rounded-l-(--cell-radius) bg-muted after:absolute after:inset-y-0 after:right-0 after:w-4 after:bg-muted"

  defp calendar_range_class(:middle, _calendar), do: "rounded-none"

  defp calendar_range_class(:end, _calendar),
    do:
      "relative isolate z-0 rounded-r-(--cell-radius) bg-muted after:absolute after:inset-y-0 after:left-0 after:w-4 after:bg-muted"

  defp calendar_today_class("persian"),
    do: "rounded-md bg-accent text-accent-foreground data-[selected=true]:rounded-none rdp-today"

  defp calendar_today_class(_calendar),
    do:
      "rounded-(--cell-radius) bg-muted text-foreground data-[selected=true]:rounded-none rdp-today"

  @months ~w(January February March April May June July August September October November December)
  @persian_months ~w(فروردین اردیبهشت خرداد تیر مرداد شهریور مهر آبان آذر دی بهمن اسفند)
  @weekdays ~w(Su Mo Tu We Th Fr Sa)
  @persian_weekdays ~w(۱ش ۲ش ۳ش ۴ش ۵ش ج ش)
  @weekday_labels ~w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
  @arabic_weekday_labels ~w(الأحد الاثنين الثلاثاء الأربعاء الخميس الجمعة السبت)
  @persian_weekday_labels ~w(یکشنبه دوشنبه سه‌شنبه چهارشنبه پنجشنبه جمعه شنبه)

  @doc "Renders a calendar grid with the public DayPicker state contract."
  attr(:id, :string, required: true)
  attr(:mode, :string, default: "single", values: ["single", "multiple", "range"])
  attr(:month, Date, default: nil, doc: "The controlled visible Gregorian month.")
  attr(:default_month, Date, default: nil, doc: "The initial visible Gregorian month.")

  attr(:selected, :any,
    default: nil,
    doc: "A Date, date list, or `%{from: date, to: date}` range."
  )

  attr(:number_of_months, :integer, default: 1, values: 1..12)
  attr(:fixed_weeks, :boolean, default: false)
  attr(:show_outside_days, :boolean, default: true)
  attr(:show_week_number, :boolean, default: false)
  attr(:caption_layout, :string, default: "label", values: ["label", "dropdown"])
  attr(:caption_month_format, :string, default: "short", values: ["short", "long"])
  attr(:week_starts_on, :integer, default: 7, values: 1..7)
  attr(:disabled, :any, default: [])
  attr(:modifiers, :map, default: %{})
  attr(:modifiers_class_names, :map, default: %{})
  attr(:locale, :string, default: "en", values: ["en", "browser", "ar", "fa"])
  attr(:dir, :string, default: nil, values: [nil, "ltr", "rtl"])
  attr(:calendar, :string, default: "gregorian", values: ["gregorian", "persian"])
  attr(:on_select, :string, default: nil)
  attr(:on_select_js, :any, default: nil, doc: "A client command run after a day is selected.")

  attr(:return_focus, :string,
    default: nil,
    doc: "The element id that receives focus after a server-controlled selection patch."
  )

  attr(:on_month_change, :string, default: nil)
  attr(:day_extra, :string, default: nil, values: [nil, "price"])
  attr(:day_group, :boolean, default: true)
  attr(:day_group_after_select, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["aria-label", "data-slot"])

  slot(:day_content,
    doc:
      "Optional contents for a day button. The slot receives `date`, `outside`, and `selected`."
  )

  def calendar(assigns) do
    month = visible_month(assigns.month, assigns.default_month, assigns.selected)
    months = visible_months(month, assigns.number_of_months)

    focus_target =
      calendar_focus_target(
        months,
        assigns.selected,
        assigns.mode,
        assigns.disabled,
        assigns.fixed_weeks,
        assigns.show_outside_days,
        assigns.caption_layout,
        assigns.week_starts_on,
        assigns.calendar
      )

    assigns =
      assigns
      |> assign(month: month, months: months, focus_target: focus_target)
      |> assign(:previous_disabled, nav_disabled?(month, assigns.caption_layout, "previous"))
      |> assign(:next_disabled, nav_disabled?(month, assigns.caption_layout, "next"))

    ~H"""
    <div
      id={@id}
      phx-hook={CalendarHook.hook()}
      data-lb-calendar
      data-lb-calendar-mode={@mode}
      data-lb-calendar-month={Date.to_iso8601(@month)}
      data-lb-calendar-number-of-months={@number_of_months}
      data-lb-calendar-fixed-weeks={flag(@fixed_weeks)}
      data-lb-calendar-show-outside-days={flag(@show_outside_days)}
      data-lb-calendar-show-week-number={flag(@show_week_number)}
      data-lb-calendar-caption-layout={@caption_layout}
      data-lb-calendar-week-starts-on={@week_starts_on}
      data-lb-calendar-selected={selection_value(@selected, @mode)}
      data-lb-calendar-disabled={dates_value(@disabled)}
      data-lb-calendar-locale={@locale}
      data-lb-calendar-system={@calendar}
      data-lb-calendar-day-extra={@day_extra}
      data-lb-calendar-day-group-after-select={if(@day_group_after_select, do: "true")}
      data-lb-calendar-return-focus={@return_focus}
      data-lb-calendar-select-event={@on_select}
      data-lb-calendar-month-change-event={@on_month_change}
      data-slot={@rest[:"data-slot"] || "calendar"}
      dir={calendar_dir(@calendar, @dir)}
      class={LiveShadcn.Cn.merge([
        calendar_root_class(@calendar),
        @class
      ])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <div class="relative flex flex-col gap-4 md:flex-row rdp-months">
        <nav class="absolute inset-x-0 top-0 flex w-full items-center justify-between gap-1 rdp-nav">
          <button
            type="button"
            data-lb-calendar-nav="previous"
            aria-label="Go to the previous month"
            disabled={@previous_disabled}
            class={calendar_button_class("previous")}
          >
            <LiveShadcn.Icon.icon name="chevron-left" class={calendar_chevron_class(@calendar)} />
          </button>
          <button
            type="button"
            data-lb-calendar-nav="next"
            aria-label="Go to the next month"
            disabled={@next_disabled}
            class={calendar_button_class("next")}
          >
            <LiveShadcn.Icon.icon name="chevron-right" class={calendar_chevron_class(@calendar)} />
          </button>
        </nav>
        <.calendar_month
          :for={month <- @months}
          id={@id}
          month={month}
          mode={@mode}
          selected={@selected}
          focus_target={@focus_target}
          disabled={@disabled}
          modifiers={@modifiers}
          modifiers_class_names={@modifiers_class_names}
          fixed_weeks={@fixed_weeks}
          show_outside_days={@show_outside_days}
          show_week_number={@show_week_number}
          caption_layout={@caption_layout}
          caption_month_format={@caption_month_format}
          week_starts_on={@week_starts_on}
          locale={@locale}
          calendar={@calendar}
          day_extra={@day_extra}
          day_group={@day_group}
          day_content={@day_content}
          on_select_js={@on_select_js}
        />
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:month, Date, required: true)
  attr(:mode, :string, required: true)
  attr(:selected, :any, required: true)
  attr(:focus_target, :any, required: true)
  attr(:disabled, :any, required: true)
  attr(:modifiers, :map, required: true)
  attr(:modifiers_class_names, :map, required: true)
  attr(:fixed_weeks, :boolean, required: true)
  attr(:show_outside_days, :boolean, required: true)
  attr(:show_week_number, :boolean, required: true)
  attr(:caption_layout, :string, required: true)
  attr(:caption_month_format, :string, required: true)
  attr(:week_starts_on, :integer, required: true)
  attr(:locale, :string, required: true)
  attr(:calendar, :string, required: true)
  attr(:day_extra, :string, required: true)
  attr(:day_group, :boolean, required: true)
  attr(:day_content, :list, required: true)
  attr(:on_select_js, :any, required: true)

  defp calendar_month(assigns) do
    assigns =
      assigns
      |> assign(
        :weeks,
        month_weeks(assigns.month, assigns.week_starts_on, assigns.fixed_weeks, assigns.calendar)
      )
      |> assign(:month_label, month_label(assigns.month, assigns.locale, assigns.calendar))

    ~H"""
    <div data-lb-calendar-month={Date.to_iso8601(@month)} class="flex w-full flex-col gap-4 rdp-month">
      <div class="flex h-(--cell-size) w-full items-center justify-center px-(--cell-size) rdp-month_caption">
        <%= if @caption_layout == "dropdown" do %>
          <div class="flex h-(--cell-size) w-full items-center justify-center gap-1.5 text-sm font-medium rdp-dropdowns">
            <span class="cn-calendar-dropdown-root relative rounded-(--cell-radius) rdp-dropdown_root">
              <select data-lb-calendar-caption="month" aria-label={caption_dropdown_label("month", @locale)} class="absolute inset-0 bg-popover opacity-0 rdp-dropdown rdp-months_dropdown">
                <option :for={number <- 1..12} value={number - 1} selected={month_number(@month, @calendar) == number}>{caption_month(number, @caption_month_format, @locale, @calendar)}</option>
              </select>
              <span class="font-medium select-none cn-calendar-caption-label flex items-center gap-1 rounded-(--cell-radius) text-sm [&>svg]:size-3.5 [&>svg]:text-muted-foreground rdp-caption_label">{caption_month(month_number(@month, @calendar), @caption_month_format, @locale, @calendar)}<LiveShadcn.Icon.icon name="chevron-down" class="size-4 rdp-chevron" /></span>
            </span>
            <span class="cn-calendar-dropdown-root relative rounded-(--cell-radius) rdp-dropdown_root">
              <select data-lb-calendar-caption="year" aria-label={caption_dropdown_label("year", @locale)} class="absolute inset-0 bg-popover opacity-0 rdp-dropdown rdp-years_dropdown">
                <option :for={year <- year_options(@month, @calendar)} value={year} selected={display_year(@month, @calendar) == year}>{year_label(year, @calendar)}</option>
              </select>
              <span class="font-medium select-none cn-calendar-caption-label flex items-center gap-1 rounded-(--cell-radius) text-sm [&>svg]:size-3.5 [&>svg]:text-muted-foreground rdp-caption_label">{year_label(display_year(@month, @calendar), @calendar)}<LiveShadcn.Icon.icon name="chevron-down" class="size-4 rdp-chevron" /></span>
            </span>
            <span data-lb-calendar-caption-status role="status" aria-live="polite" class="sr-only">{@month_label}</span>
          </div>
        <% else %>
              <span data-lb-calendar-caption-status role="status" aria-live="polite" class={calendar_caption_label_class(@calendar)}>{@month_label}</span>
        <% end %>
      </div>
      <table
        class="w-full border-collapse rdp-month_grid"
        role="grid"
        aria-multiselectable={if(@mode in ["multiple", "range"], do: "true")}
        aria-label={@month_label}
      >
        <thead>
          <tr class="flex rdp-weekdays">
            <th :if={@show_week_number} aria-label="Week Number" class="w-(--cell-size) select-none rdp-week_number_header" scope="col"><span class="sr-only">Week Number</span></th>
            <th :for={{weekday, label} <- weekday_headers(@week_starts_on, @locale, @calendar)} aria-label={label} class={calendar_weekday_class(@calendar)} scope="col">{weekday}</th>
          </tr>
        </thead>
        <tbody class="rdp-weeks">
          <tr :for={week <- @weeks} class="mt-2 flex w-full rdp-week">
            <td
              :if={@show_week_number}
              aria-label={"Week #{week_number_value(List.first(week))}"}
              class="text-[0.8rem] text-muted-foreground select-none rdp-week_number"
              scope="row"
              role="rowheader"
            ><div class="flex size-(--cell-size) items-center justify-center text-center">{week_number(List.first(week))}</div></td>
            <.calendar_day
              :for={day <- week}
              day={day}
              month={@month}
              mode={@mode}
              selected={@selected}
              focus_target={@focus_target}
              disabled={@disabled}
              modifiers={@modifiers}
              modifiers_class_names={@modifiers_class_names}
              show_outside_days={@show_outside_days}
              show_week_number={@show_week_number}
              caption_layout={@caption_layout}
              locale={@locale}
              calendar={@calendar}
              day_extra={@day_extra}
              day_group={@day_group}
              day_content={@day_content}
              on_select_js={@on_select_js}
            />
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr(:day, Date, required: true)
  attr(:month, Date, required: true)
  attr(:mode, :string, required: true)
  attr(:selected, :any, required: true)
  attr(:focus_target, :any, required: true)
  attr(:disabled, :any, required: true)
  attr(:modifiers, :map, required: true)
  attr(:modifiers_class_names, :map, required: true)
  attr(:show_outside_days, :boolean, required: true)
  attr(:show_week_number, :boolean, required: true)
  attr(:caption_layout, :string, required: true)
  attr(:locale, :string, required: true)
  attr(:calendar, :string, required: true)
  attr(:day_extra, :string, required: true)
  attr(:day_group, :boolean, required: true)
  attr(:day_content, :list, required: true)
  attr(:on_select_js, :any, required: true)

  defp calendar_day(assigns) do
    outside =
      display_month(assigns.day, assigns.calendar) !=
        display_month(assigns.month, assigns.calendar)

    selected = selected?(assigns.day, assigns.selected, assigns.mode)
    range_state = range_state(assigns.day, assigns.selected, assigns.mode)
    disabled = disabled?(assigns.day, assigns.disabled)
    hidden = hidden?(assigns.day, outside, assigns.show_outside_days, assigns.caption_layout)

    assigns =
      assigns
      |> assign(:outside, outside)
      |> assign(:selected_day, selected)
      |> assign(:range_state, range_state)
      |> assign(:disabled_day, disabled)
      |> assign(:hidden_day, hidden)
      |> assign(
        :modifier_class,
        modifier_class(assigns.day, assigns.modifiers, assigns.modifiers_class_names)
      )

    ~H"""
    <td
      role="gridcell"
      data-day={Date.to_iso8601(@day)}
      data-selected={data_flag(@selected_day)}
      data-disabled={data_flag(@disabled_day)}
      data-hidden={data_flag(@hidden_day)}
      data-outside={data_flag(@outside)}
      data-today={data_flag(@day == Date.utc_today())}
      aria-selected={if(@selected_day, do: "true")}
      class={
        [
        calendar_day_base_class(@show_week_number, @calendar, @day_group),
        if(@selected_day, do: "rdp-selected"),
        if(@range_state == :start, do: calendar_range_class(:start, @calendar)),
        if(@range_state == :start, do: "rdp-range_start"),
        if(@range_state == :middle, do: calendar_range_class(:middle, @calendar)),
        if(@range_state == :middle, do: "rdp-range_middle"),
        if(@range_state == :end, do: calendar_range_class(:end, @calendar)),
        if(@range_state == :end, do: "rdp-range_end"),
        if(@day == Date.utc_today(), do: calendar_today_class(@calendar)),
        if(@hidden_day, do: "invisible rdp-hidden"),
        if(@outside, do: "text-muted-foreground aria-selected:text-muted-foreground rdp-outside"),
        if(@disabled_day, do: "text-muted-foreground opacity-50 rdp-disabled"),
        @modifier_class
        ]
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.join(" ")
      }
    >
      <button
        :if={not @hidden_day}
        type="button"
        data-slot="button"
        data-lb-calendar-day
        data-day={Date.to_iso8601(@day)}
        data-selected-single={data_flag(@selected_day and @range_state == nil)}
        data-range-start={data_flag(@range_state == :start)}
        data-range-end={data_flag(@range_state == :end)}
        data-range-middle={data_flag(@range_state == :middle)}
        aria-label={day_label(@day, @locale, @calendar)}
        aria-current={if(@day == Date.utc_today(), do: "date")}
        tabindex={if(@day == @focus_target and not @outside, do: "0", else: "-1")}
        disabled={@disabled_day}
        phx-click={@on_select_js}
        class={calendar_day_button_class(@calendar)}
      >
        <%= if @day_content == [] do %>
          {day_number(@day, @calendar)}
          <span :if={@day_extra == "price" and not @outside}>{if(Date.day_of_week(@day) in [6, 7], do: "$120", else: "$100")}</span>
        <% else %>
          {render_slot(@day_content, %{date: @day, outside: @outside, selected: @selected_day})}
        <% end %>
      </button>
    </td>
    """
  end

  defp visible_month(month, _default_month, _selected) when is_struct(month, Date),
    do: %{month | day: 1}

  defp visible_month(nil, default_month, _selected) when is_struct(default_month, Date),
    do: %{default_month | day: 1}

  defp visible_month(nil, nil, selected) do
    case first_selected(selected) do
      %Date{} = date -> %{date | day: 1}
      _ -> Date.utc_today() |> Map.put(:day, 1)
    end
  end

  defp visible_months(month, count),
    do: for(offset <- 0..(count - 1), do: add_gregorian_months(month, offset))

  defp month_weeks(month, starts_on, fixed, "persian"), do: persian_weeks(month, starts_on, fixed)

  defp month_weeks(month, starts_on, fixed, _calendar) do
    first = %{month | day: 1}
    offset = rem(Date.day_of_week(first) - starts_on + 7, 7)
    start = Date.add(first, -offset)
    weeks = if fixed, do: 6, else: div(offset + Date.days_in_month(month) + 6, 7)
    for week <- 0..(weeks - 1), do: for(day <- 0..6, do: Date.add(start, week * 7 + day))
  end

  defp calendar_focus_target(
         months,
         selected,
         mode,
         disabled,
         fixed_weeks,
         show_outside_days,
         caption_layout,
         week_starts_on,
         calendar
       ) do
    focusable_days =
      for month <- months,
          day <- List.flatten(month_weeks(month, week_starts_on, fixed_weeks, calendar)),
          display_month(day, calendar) == display_month(month, calendar),
          not disabled?(day, disabled),
          not hidden?(day, false, show_outside_days, caption_layout),
          do: day

    Enum.find(focusable_days, &selected?(&1, selected, mode)) ||
      Enum.find(focusable_days, &(&1 == Date.utc_today())) ||
      List.first(focusable_days)
  end

  defp persian_weeks(month, starts_on, fixed) do
    {year, month_number, _day} = gregorian_to_jalali(month)
    first = jalali_to_gregorian(year, month_number, 1)
    offset = rem(Date.day_of_week(first) - starts_on + 7, 7)
    start = Date.add(first, -offset)
    days = jalali_days_in_month(year, month_number)
    weeks = if fixed, do: 6, else: div(offset + days + 6, 7)
    for week <- 0..(weeks - 1), do: for(day <- 0..6, do: Date.add(start, week * 7 + day))
  end

  defp selected?(day, selected, "multiple") when is_list(selected), do: day in selected
  defp selected?(day, selected, "range"), do: range_state(day, selected, "range") != nil
  defp selected?(day, selected, _mode), do: day == selected

  defp range_state(day, selected, "range") do
    case range_dates(selected) do
      {from, to} when is_struct(from, Date) and is_struct(to, Date) ->
        if Date.compare(from, to) == :gt do
          nil
        else
          cond do
            day == from -> :start
            day == to -> :end
            Date.compare(day, from) == :gt and Date.compare(day, to) == :lt -> :middle
            true -> nil
          end
        end

      {from, nil} when is_struct(from, Date) and day == from ->
        :start

      _ ->
        nil
    end
  end

  defp range_state(_day, _selected, _mode), do: nil

  defp range_dates(%{from: from, to: to}), do: {from, to}
  defp range_dates(%{"from" => from, "to" => to}), do: {from, to}
  defp range_dates({from, to}), do: {from, to}
  defp range_dates(_), do: {nil, nil}

  defp disabled?(day, dates) when is_list(dates),
    do: Enum.any?(dates, &date_or_range_includes?(day, &1))

  defp disabled?(day, dates), do: date_or_range_includes?(day, dates)
  defp hidden?(_day, outside, false, _caption_layout), do: outside

  defp hidden?(day, _outside, _show_outside_days, "dropdown") do
    day.year < Date.utc_today().year - 100 or day.year > Date.utc_today().year
  end

  defp hidden?(_day, _outside, _show_outside_days, _caption_layout), do: false

  defp date_or_range_includes?(day, %Date{} = date), do: day == date
  defp date_or_range_includes?(day, %{from: from, to: to}), do: between?(day, from, to)
  defp date_or_range_includes?(day, %{"from" => from, "to" => to}), do: between?(day, from, to)
  defp date_or_range_includes?(_day, _), do: false

  defp between?(day, %Date{} = from, %Date{} = to),
    do: Date.compare(day, from) != :lt and Date.compare(day, to) != :gt

  defp between?(_day, _from, _to), do: false

  defp modifier_class(day, modifiers, class_names) do
    modifiers
    |> Enum.filter(fn {_name, dates} -> disabled?(day, dates) end)
    |> Enum.map_join(" ", fn {name, _dates} ->
      Map.get(class_names, name) || Map.get(class_names, to_string(name)) || ""
    end)
  end

  defp first_selected(%Date{} = selected), do: selected
  defp first_selected([%Date{} = selected | _]), do: selected
  defp first_selected(selected), do: elem(range_dates(selected), 0)

  defp selection_value(nil, _mode), do: nil
  defp selection_value(%Date{} = date, _mode), do: Date.to_iso8601(date)

  defp selection_value(dates, "multiple") when is_list(dates),
    do: Enum.map_join(dates, ",", &Date.to_iso8601/1)

  defp selection_value(selected, "range") do
    {from, to} = range_dates(selected)

    Enum.map_join([from, to], "/", fn date ->
      if is_struct(date, Date), do: Date.to_iso8601(date), else: ""
    end)
  end

  defp selection_value(_selected, _mode), do: nil

  defp dates_value(dates) when is_list(dates), do: Enum.map_join(dates, ",", &date_value/1)
  defp dates_value(date), do: date_value(date)
  defp date_value(%Date{} = date), do: Date.to_iso8601(date)
  defp date_value(%{from: from, to: to}), do: "#{Date.to_iso8601(from)}/#{Date.to_iso8601(to)}"
  defp date_value(_), do: nil

  defp display_month(date, "persian"),
    do: date |> gregorian_to_jalali() |> then(fn {year, month, _} -> {year, month} end)

  defp display_month(date, _calendar), do: {date.year, date.month}
  defp display_year(date, "persian"), do: date |> gregorian_to_jalali() |> elem(0)
  defp display_year(date, _calendar), do: date.year
  defp month_number(date, "persian"), do: date |> gregorian_to_jalali() |> elem(1)
  defp month_number(date, _calendar), do: date.month

  defp day_number(date, "persian"),
    do: date |> gregorian_to_jalali() |> elem(2) |> persian_digits()

  defp day_number(date, _calendar), do: date.day

  defp month_label(date, locale, calendar),
    do:
      "#{caption_month(month_number(date, calendar), "long", locale, calendar)} #{year_label(display_year(date, calendar), calendar)}"

  defp caption_dropdown_label("month", "ar"), do: "اختر الشهر"
  defp caption_dropdown_label("year", "ar"), do: "اختر السنة"
  defp caption_dropdown_label("month", "fa"), do: "ماه را انتخاب کنید"
  defp caption_dropdown_label("year", "fa"), do: "سال را انتخاب کنید"
  defp caption_dropdown_label("month", _locale), do: "Choose the Month"
  defp caption_dropdown_label("year", _locale), do: "Choose the Year"

  defp caption_month(number, "short", locale, calendar),
    do: caption_month_short(number, locale, calendar)

  defp caption_month(number, _format, _locale, "persian"),
    do: Enum.at(@persian_months, number - 1)

  defp caption_month(number, _format, "ar", _calendar),
    do:
      ~w(يناير فبراير مارس أبريل مايو يونيو يوليو أغسطس سبتمبر أكتوبر نوفمبر ديسمبر)
      |> Enum.at(number - 1)

  defp caption_month(number, _format, _locale, _calendar), do: Enum.at(@months, number - 1)
  defp caption_month_short(number, _locale, "persian"), do: Enum.at(@persian_months, number - 1)

  defp caption_month_short(number, "ar", _calendar),
    do:
      ~w(يناير فبراير مارس أبريل مايو يونيو يوليو أغسطس سبتمبر أكتوبر نوفمبر ديسمبر)
      |> Enum.at(number - 1)

  defp caption_month_short(number, _locale, _calendar),
    do: Enum.at(~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec), number - 1)

  defp year_label(year, "persian"), do: persian_digits(year)
  defp year_label(year, _calendar), do: Integer.to_string(year)

  defp weekday_headers(starts_on, _locale, "persian") do
    Enum.zip(@persian_weekdays, @persian_weekday_labels) |> rotate(rem(starts_on, 7))
  end

  defp weekday_headers(starts_on, "ar", _calendar) do
    Enum.zip(~w(أحد اثنين ثلاثاء أربعاء خميس جمعة سبت), @arabic_weekday_labels)
    |> rotate(rem(starts_on, 7))
  end

  defp weekday_headers(starts_on, _locale, _calendar) do
    Enum.zip(@weekdays, @weekday_labels) |> rotate(rem(starts_on, 7))
  end

  defp rotate(list, 0), do: list
  defp rotate(list, amount), do: Enum.drop(list, amount) ++ Enum.take(list, amount)

  defp day_label(date, locale, calendar),
    do: "#{day_number(date, calendar)} #{month_label(date, locale, calendar)}"

  defp week_number(date),
    do: date |> week_number_value() |> Integer.to_string() |> String.pad_leading(2, "0")

  defp week_number_value(date) do
    next_year = Date.new!(date.year + 1, 1, 1)
    next_start = Date.add(next_year, -rem(Date.day_of_week(next_year), 7))

    start =
      if Date.compare(date, next_start) != :lt do
        next_start
      else
        current = Date.new!(date.year, 1, 1)
        Date.add(current, -rem(Date.day_of_week(current), 7))
      end

    date |> Date.diff(start) |> div(7) |> Kernel.+(1)
  end

  defp year_options(month, calendar),
    do: (display_year(month, calendar) - 100)..display_year(month, calendar)

  defp data_flag(true), do: "true"
  defp data_flag(_), do: nil
  defp flag(true), do: ""
  defp flag(_), do: nil

  defp add_gregorian_months(date, offset) do
    index = date.year * 12 + date.month - 1 + offset
    Date.new!(div(index, 12), rem(index, 12) + 1, 1)
  end

  # The pinned Hijri sample uses `react-day-picker/persian`: it renders the
  # Jalali calendar while selections remain Gregorian dates. These conversion
  # functions avoid a new runtime dependency.
  defp gregorian_to_jalali(%Date{year: gy, month: gm, day: gd}) do
    g_days =
      365 * (gy - 1600) + div(gy - 1600 + 3, 4) - div(gy - 1600 + 99, 100) +
        div(gy - 1600 + 399, 400) + gregorian_days_before_month(gm, leap_gregorian?(gy)) + gd - 1

    jalali_from_days(g_days - 79)
  end

  defp jalali_to_gregorian(jy, jm, jd) do
    j_days =
      365 * (jy - 979) + div(jy - 979, 33) * 8 + div(rem(jy - 979, 33) + 3, 4) +
        jalali_days_before_month(jm) + jd - 1

    gregorian_from_days(j_days + 79)
  end

  defp jalali_from_days(days) do
    jy = 979 + 33 * div(days, 12_053)
    days = rem(days, 12_053)

    {jy, days} =
      if days >= 366, do: {jy + 4 * div(days - 1, 1461), rem(days - 1, 1461)}, else: {jy, days}

    {jy, days} = if days >= 365, do: {jy + div(days, 365), rem(days, 365)}, else: {jy, days}
    jm = if days < 186, do: div(days, 31) + 1, else: div(days - 186, 30) + 7
    jd = if days < 186, do: rem(days, 31) + 1, else: rem(days - 186, 30) + 1
    {jy, jm, jd}
  end

  defp gregorian_from_days(days) do
    gy = 1600 + 400 * div(days, 146_097)
    days = rem(days, 146_097)

    {gy, days} =
      if days >= 36_525,
        do: {gy + 100 * div(days - 1, 36_524), rem(days - 1, 36_524)},
        else: {gy, days}

    {gy, days} =
      if days >= 1461, do: {gy + 4 * div(days, 1461), rem(days, 1461)}, else: {gy, days}

    {gy, days} = if days >= 365, do: {gy + div(days, 365), rem(days, 365)}, else: {gy, days}
    gm = gregorian_month_from_days(days, leap_gregorian?(gy), 1)
    gd = days - gregorian_days_before_month(gm, leap_gregorian?(gy)) + 1
    Date.new!(gy, gm, gd)
  end

  defp gregorian_month_from_days(days, leap, month) when month < 12 do
    if days < gregorian_days_before_month(month + 1, leap),
      do: month,
      else: gregorian_month_from_days(days, leap, month + 1)
  end

  defp gregorian_month_from_days(_days, _leap, 12), do: 12

  defp gregorian_days_before_month(month, leap) do
    [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    |> Enum.at(month - 1)
    |> Kernel.+(if(leap and month > 2, do: 1, else: 0))
  end

  defp jalali_days_before_month(month) when month <= 6, do: (month - 1) * 31
  defp jalali_days_before_month(month), do: 186 + (month - 7) * 30
  defp jalali_days_in_month(_year, month) when month <= 6, do: 31
  defp jalali_days_in_month(_year, month) when month <= 11, do: 30

  defp jalali_days_in_month(year, 12),
    do: if(rem(year + 12, 33) in [1, 5, 9, 13, 17, 22, 26, 30], do: 30, else: 29)

  defp leap_gregorian?(year),
    do: rem(year, 4) == 0 and (rem(year, 100) != 0 or rem(year, 400) == 0)

  defp persian_digits(value), do: value |> to_string() |> String.replace(~r/\d/, &persian_digit/1)
  defp persian_digit("0"), do: "۰"
  defp persian_digit("1"), do: "۱"
  defp persian_digit("2"), do: "۲"
  defp persian_digit("3"), do: "۳"
  defp persian_digit("4"), do: "۴"
  defp persian_digit("5"), do: "۵"
  defp persian_digit("6"), do: "۶"
  defp persian_digit("7"), do: "۷"
  defp persian_digit("8"), do: "۸"
  defp persian_digit("9"), do: "۹"
end
