defmodule LiveShadcn.UI.CalendarTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Calendar

  test "declares return_focus in the public component metadata" do
    attributes = Calendar.__components__().calendar.attrs

    assert %{name: :return_focus, type: :string, opts: opts} =
             Enum.find(attributes, &(&1.name == :return_focus))

    assert opts[:default] == nil
  end

  test "the root declares one patch-safe controller and the public state contract" do
    html =
      render_component(&Calendar.calendar/1, %{
        id: "release-calendar",
        mode: "range",
        month: ~D[2026-01-01],
        selected: %{from: ~D[2026-01-12], to: ~D[2026-02-11]},
        number_of_months: 2,
        caption_layout: "dropdown",
        fixed_weeks: true,
        show_week_number: true,
        on_select: "calendar_select",
        return_focus: "release-date-input",
        on_month_change: "calendar_month_change",
        inner_block: []
      })

    document = Floki.parse_fragment!(html)
    [root] = Floki.find(document, "[data-slot='calendar']")

    assert Floki.attribute([root], "phx-hook") == ["LiveBase.Calendar"]
    assert Floki.attribute([root], "data-lb-calendar-mode") == ["range"]
    assert Floki.attribute([root], "data-lb-calendar-selected") == ["2026-01-12/2026-02-11"]
    assert Floki.attribute([root], "data-lb-calendar-number-of-months") == ["2"]
    assert Floki.attribute([root], "data-lb-calendar-fixed-weeks") == [""]
    assert Floki.attribute([root], "data-lb-calendar-show-week-number") == [""]
    assert Floki.attribute([root], "data-lb-calendar-select-event") == ["calendar_select"]
    assert Floki.attribute([root], "data-lb-calendar-return-focus") == ["release-date-input"]

    assert Floki.attribute([root], "data-lb-calendar-month-change-event") == [
             "calendar_month_change"
           ]

    assert [_, _] = Floki.find(document, ".rdp-month")
    assert [_, _] = Floki.find(document, "select[data-lb-calendar-caption='month']")

    assert [_, _, _, _, _, _, _, _, _, _, _, _] =
             Floki.find(document, "td.rdp-week_number")
  end

  test "range, disabled, and modifier states are placed on the pinned day parts" do
    html =
      render_component(&Calendar.calendar/1, %{
        id: "booked-calendar",
        mode: "range",
        month: ~D[2026-01-01],
        selected: %{from: ~D[2026-01-12], to: ~D[2026-01-15]},
        disabled: [~D[2026-01-13]],
        modifiers: %{booked: [~D[2026-01-13]]},
        modifiers_class_names: %{booked: "[&>button]:line-through opacity-100"},
        inner_block: []
      })

    document = Floki.parse_fragment!(html)
    [start] = Floki.find(document, "td[data-day='2026-01-12']")
    [middle] = Floki.find(document, "td[data-day='2026-01-14']")
    [ending] = Floki.find(document, "td[data-day='2026-01-15']")
    [booked] = Floki.find(document, "td[data-day='2026-01-13']")

    assert Floki.attribute([start], "data-selected") == ["true"]
    assert Floki.find([start], "[data-range-start]") != []
    assert Floki.find([middle], "[data-range-middle]") != []
    assert Floki.find([ending], "[data-range-end]") != []
    assert Floki.attribute([booked], "data-disabled") == ["true"]
    assert Floki.find([booked], "button[disabled]") != []
    assert Floki.attribute([booked], "class") |> List.first() =~ "line-through"
  end

  test "range grids report multi-selection to assistive technology" do
    html =
      render_component(&Calendar.calendar/1, %{
        id: "range-grid-calendar",
        mode: "range",
        month: ~D[2026-01-01],
        selected: %{from: ~D[2026-01-12], to: ~D[2026-01-15]}
      })

    document = Floki.parse_fragment!(html)
    [grid] = Floki.find(document, "table[role='grid']")

    assert Floki.attribute([grid], "aria-multiselectable") == ["true"]
  end

  test "week-number headers have the DayPicker accessible name and readable text" do
    html =
      render_component(&Calendar.calendar/1, %{
        id: "week-number-header-calendar",
        show_week_number: true,
        inner_block: []
      })

    document = Floki.parse_fragment!(html)
    [header] = Floki.find(document, "th.rdp-week_number_header")

    assert Floki.attribute([header], "aria-label") == ["Week Number"]
    assert Floki.attribute([header], "scope") == ["col"]
    assert Floki.text([header]) == "Week Number"
  end

  test "day group rendering can match a pinned Calendar style without changing the default" do
    compact_html =
      render_component(&Calendar.calendar/1, %{
        id: "compact-day-calendar",
        day_group: false,
        inner_block: []
      })

    default_html =
      render_component(&Calendar.calendar/1, %{
        id: "default-day-calendar",
        inner_block: []
      })

    compact_day = Floki.find(Floki.parse_fragment!(compact_html), "td.rdp-day") |> List.first()
    default_day = Floki.find(Floki.parse_fragment!(default_html), "td.rdp-day") |> List.first()

    refute String.contains?(List.first(Floki.attribute([compact_day], "class")), "group/day")
    assert String.contains?(List.first(Floki.attribute([default_day], "class")), "group/day")
  end

  test "dropdown captions use DayPicker zero-based month values while dates stay one-based" do
    html =
      render_component(&Calendar.calendar/1, %{
        id: "dropdown-calendar",
        month: ~D[2026-12-01],
        caption_layout: "dropdown",
        inner_block: []
      })

    document = Floki.parse_fragment!(html)
    options = Floki.find(document, "select[data-lb-calendar-caption='month'] option")

    assert Floki.attribute([hd(options)], "value") == ["0"]
    assert Floki.attribute([List.last(options)], "value") == ["11"]

    assert Floki.attribute(
             Floki.find(document, "select[data-lb-calendar-caption='month'] option[selected]"),
             "value"
           ) == ["11"]
  end

  test "captions and navigation use the DayPicker accessible names for each locale" do
    labels = %{
      "en" =>
        {"Choose the Month", "Choose the Year", "Go to the Previous Month",
         "Go to the Next Month", "Navigation bar"},
      "browser" =>
        {"Choose the Month", "Choose the Year", "Go to the Previous Month",
         "Go to the Next Month", "Navigation bar"},
      "ar" =>
        {"اختر الشهر", "اختر السنة", "اذهب إلى الشهر السابق", "اذهب إلى الشهر التالي",
         "شريط التنقل"},
      "fa" =>
        {"ماه را انتخاب کنید", "سال را انتخاب کنید", "رفتن به ماه قبل", "رفتن به ماه بعد",
         "نوار ناوبری"}
    }

    for {locale, {month_label, year_label, previous_label, next_label, navigation_label}} <-
          labels do
      html =
        render_component(&Calendar.calendar/1, %{
          id: "#{locale}-dropdown-calendar",
          month: ~D[2026-01-01],
          locale: locale,
          caption_layout: "dropdown",
          inner_block: []
        })

      document = Floki.parse_fragment!(html)

      assert Floki.attribute(Floki.find(document, "nav.rdp-nav"), "aria-label") == [
               navigation_label
             ]

      assert Floki.attribute(
               Floki.find(document, "select[data-lb-calendar-caption='month']"),
               "aria-label"
             ) == [month_label]

      assert Floki.attribute(
               Floki.find(document, "select[data-lb-calendar-caption='year']"),
               "aria-label"
             ) == [year_label]

      assert Floki.attribute(
               Floki.find(document, "button[data-lb-calendar-nav='previous']"),
               "aria-label"
             ) == [previous_label]

      assert Floki.attribute(
               Floki.find(document, "button[data-lb-calendar-nav='next']"),
               "aria-label"
             ) == [next_label]
    end
  end

  test "captions and weekday headers keep the DayPicker live and accessible names" do
    label_html =
      render_component(&Calendar.calendar/1, %{
        id: "accessible-label-calendar",
        month: ~D[2026-01-01],
        inner_block: []
      })

    dropdown_html =
      render_component(&Calendar.calendar/1, %{
        id: "accessible-dropdown-calendar",
        month: ~D[2026-01-01],
        caption_layout: "dropdown",
        inner_block: []
      })

    label_document = Floki.parse_fragment!(label_html)
    dropdown_document = Floki.parse_fragment!(dropdown_html)

    [label_status] =
      Floki.find(label_document, ".rdp-caption_label[role='status'][aria-live='polite']")

    [dropdown_status] =
      Floki.find(
        dropdown_document,
        "[data-lb-calendar-caption-status][role='status'][aria-live='polite']"
      )

    assert Floki.text([label_status]) == "January 2026"
    assert Floki.text([dropdown_status]) == "January 2026"

    assert Enum.map(
             Floki.find(label_document, "th.rdp-weekday"),
             &Floki.attribute([&1], "aria-label")
           ) == [
             ["Sunday"],
             ["Monday"],
             ["Tuesday"],
             ["Wednesday"],
             ["Thursday"],
             ["Friday"],
             ["Saturday"]
           ]
  end

  test "Gregorian Calendar buttons preserve the exact upstream class token order" do
    html =
      render_component(&Calendar.calendar/1, %{
        id: "class-calendar",
        month: ~D[2026-12-01],
        caption_layout: "dropdown",
        inner_block: []
      })

    document = Floki.parse_fragment!(html)
    [previous] = Floki.find(document, "button[data-lb-calendar-nav='previous']")
    [day | _] = Floki.find(document, "button[data-lb-calendar-day]")

    assert Floki.attribute([previous], "class") == [
             "cn-button group/button inline-flex shrink-0 items-center justify-center whitespace-nowrap transition-all outline-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 cn-button-size-default cn-button-variant-ghost size-(--cell-size) p-0 select-none aria-disabled:opacity-50 rdp-button_previous"
           ]

    assert Floki.attribute([day], "class") == [
             "cn-button group/button shrink-0 items-center justify-center whitespace-nowrap transition-all outline-none select-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 cn-button-size-icon cn-button-variant-ghost cn-calendar-day-button relative isolate z-10 flex aspect-square size-auto w-full min-w-(--cell-size) flex-col gap-1 border-0 leading-none font-normal group-data-[focused=true]/day:relative group-data-[focused=true]/day:z-10 group-data-[focused=true]/day:border-ring group-data-[focused=true]/day:ring-[3px] group-data-[focused=true]/day:ring-ring/50 data-[range-end=true]:rounded-(--cell-radius) data-[range-end=true]:rounded-r-(--cell-radius) data-[range-end=true]:bg-primary data-[range-end=true]:text-primary-foreground data-[range-middle=true]:rounded-none data-[range-middle=true]:bg-muted data-[range-middle=true]:text-foreground data-[range-start=true]:rounded-(--cell-radius) data-[range-start=true]:rounded-l-(--cell-radius) data-[range-start=true]:bg-primary data-[range-start=true]:text-primary-foreground data-[selected-single=true]:bg-primary data-[selected-single=true]:text-primary-foreground dark:hover:text-foreground [&>span]:text-xs [&>span]:opacity-70 rdp-day rdp-day_button"
           ]
  end

  test "custom range day content keeps one upstream focus target" do
    html =
      render_component(&Calendar.calendar/1, %{
        id: "custom-range-calendar",
        mode: "range",
        month: ~D[2025-12-01],
        selected: %{from: ~D[2025-12-08], to: ~D[2025-12-18]},
        day_content: [slot(:day_content, "Custom rate")]
      })

    document = Floki.parse_fragment!(html)
    [focus_target] = Floki.find(document, "button[tabindex='0']")

    assert Floki.attribute([focus_target], "data-day") == ["2025-12-08"]
    assert Floki.find(document, "button[tabindex='0']") == [focus_target]
  end

  test "custom day content renders beside the Persian RTL calendar state" do
    html =
      render_component(&Calendar.calendar/1, %{
        id: "persian-calendar",
        month: ~D[2025-06-12],
        selected: ~D[2025-06-12],
        calendar: "persian",
        locale: "fa",
        dir: "rtl",
        day_content: [slot(:day_content, "Custom rate")]
      })

    document = Floki.parse_fragment!(html)
    [root] = Floki.find(document, "#persian-calendar")
    [caption] = Floki.find(document, ".rdp-caption_label")

    assert Floki.attribute([root], "dir") == ["rtl"]
    assert Floki.attribute([root], "data-lb-calendar-system") == ["persian"]
    assert Floki.text([caption]) =~ "خرداد"
    assert Floki.text(document) =~ "Custom rate"
  end

  test "multiple selection serializes ISO dates and keeps native grid semantics" do
    html =
      render_component(&Calendar.calendar/1, %{
        id: "multiple-calendar",
        mode: "multiple",
        month: ~D[2026-01-01],
        selected: [~D[2026-01-05], ~D[2026-01-07]],
        show_outside_days: false
      })

    document = Floki.parse_fragment!(html)
    [root] = Floki.find(document, "#multiple-calendar")
    [selected_cell] = Floki.find(document, "td[data-day='2026-01-05']")
    [selected] = Floki.find([selected_cell], "button")

    assert Floki.attribute([root], "data-lb-calendar-selected") == ["2026-01-05,2026-01-07"]
    assert Floki.attribute([selected_cell], "aria-selected") == ["true"]
    assert Floki.attribute([selected], "aria-pressed") == []
    assert Floki.attribute([selected], "data-selected-single") == ["true"]
    assert Floki.find(document, "td[data-outside].invisible") != []
  end

  test "dropdown captions disable navigation outside react-day-picker's implicit range" do
    current_year = Date.utc_today().year

    html =
      render_component(&Calendar.calendar/1, %{
        id: "bounded-calendar",
        month: Date.new!(current_year, 12, 1),
        caption_layout: "dropdown"
      })

    document = Floki.parse_fragment!(html)

    assert Floki.find(document, "[data-lb-calendar-nav='previous'][disabled]") == []
    assert Floki.find(document, "[data-lb-calendar-nav='next'][disabled]") != []
  end

  defp slot(name, text), do: %{__slot__: name, inner_block: fn _, _ -> text end}
end
