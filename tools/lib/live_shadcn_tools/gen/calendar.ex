defmodule LiveShadcnTools.Gen.Calendar do
  @moduledoc "The server-side calendar grid recipe."

  alias LiveShadcnTools.Gen.Heex

  # Which way each nav button points. That is this recipe's decision — upstream
  # chooses by an `orientation` prop react-day-picker passes at render, and a
  # server-rendered month grid has two buttons that never change direction.
  #
  # The icons themselves are not a decision: they are the ones the `components`
  # override names, read into the spec, and asking for one that is no longer
  # there fails generation rather than drawing nothing.
  @back "chevron-left"
  @forward "chevron-right"

  @doc "The module source for one calendar component."
  def module(spec, opts) do
    classes = spec["classes"]
    back = @back
    forward = @forward

    """
    defmodule #{inspect(Keyword.fetch!(opts, :module))} do
    #{moduledoc(spec)}

      use Phoenix.Component

      alias LiveBase.Calendar, as: CalendarHook

      @doc "A deterministic month grid. The server owns the dates and selection."
      attr :month, Date, default: Date.utc_today()
      attr :selected, Date, default: nil
      attr :week_starts_on, :integer, default: 7, values: 1..7
      attr :id, :string, required: true
      attr :locale, :string, default: "en", values: ["en", "browser"]
      attr :class, :any, default: nil
      attr :rest, :global, include: ["aria-label", "data-slot"]

      def calendar(assigns) do
        assigns = assign(assigns, :weeks, month_weeks(assigns.month, assigns.week_starts_on))

        ~H\"\"\"
        <section id={@id} phx-hook={if @locale == "browser", do: CalendarHook.hook()} data-lb-calendar-locale={@locale} data-slot="calendar" class={[#{inspect(classes["root"])}, @class]} {@rest}>
          <%!-- Every class string below is upstream's, read out of the
                `classNames` prop shadcn hands react-day-picker and out of the
                `<Button>` its day cell renders. None of the twenty-six is
                typed here. --%>
          <div class=#{inspect(classes["months"])}>
            <%!-- The nav is a sibling of the month, positioned over it, not a
                  child of the caption. That is how upstream builds it, and
                  putting the buttons inside the caption instead is what made
                  our month grid a pixel shorter than React's. --%>
            <nav class=#{inspect(classes["nav"])}>
              <%!-- The chevrons upstream draws, not the `‹` and `›` characters
                    that used to stand in for them — a glyph from the font is a
                    different shape, a different size and a different colour
                    from an SVG. Both the icon and its class are read out of the
                    `components` prop shadcn hands react-day-picker. --%>
              <button type="button" aria-label="Go to the previous month" class=#{inspect(classes["button_previous"])}>
                <LiveShadcn.Icon.icon name=#{inspect(back)} class=#{inspect(chevron!(classes, back))} />
              </button>
              <button type="button" aria-label="Go to the next month" class=#{inspect(classes["button_next"])}>
                <LiveShadcn.Icon.icon name=#{inspect(forward)} class=#{inspect(chevron!(classes, forward))} />
              </button>
            </nav>
          <div class=#{inspect(classes["month"])}>
          <div class=#{inspect(classes["month_caption"])}>
            <span data-lb-calendar-month={Date.to_iso8601(@month)} class=#{inspect(classes["caption_label"])}>{Calendar.strftime(@month, "%B %Y")}</span>
          </div>
          <table class=#{inspect(classes["month_grid"])} role="grid" aria-label={Calendar.strftime(@month, "%B %Y")}>
            <thead>
              <tr class=#{inspect(classes["weekdays"])}>
                <%!-- No width. The cells carry none upstream either: the grid is
                      seven `flex-1` columns and the heading text is what decides
                      how wide they settle. A width typed here was this recipe
                      laying the grid out itself, and it drew the columns 8.5px
                      wider than React's because the heading said `Sun` where
                      react-day-picker says `Su`. --%>
                <th :for={day <- weekday_dates(@week_starts_on)} data-lb-calendar-weekday={Date.to_iso8601(day)} class=#{inspect(classes["weekday"])} scope="col">{weekday_name(day)}</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={week <- @weeks} class=#{inspect(classes["week"])}>
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
                  class={[#{inspect(classes["day"])}, day.month != @month.month && #{inspect(classes["outside"])}]}
                >
                  <button
                    type="button"
                    data-slot="button"
                    data-day={Date.to_iso8601(day)}
                    data-selected-single={day == @selected && "true"}
                    class=#{inspect(classes["day_button"])}
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
        \"\"\"
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
    end
    """
  end

  defp chevron!(classes, icon) do
    case get_in(classes, ["chevrons", icon]) do
      nil ->
        raise "calendar draws #{icon}, and its spec records no chevron by that name" <>
                " (it has #{classes |> Map.get("chevrons", %{}) |> Map.keys() |> Enum.join(", ")})"

      class ->
        class
    end
  end

  defp moduledoc(spec) do
    """
      @moduledoc \"\"\"
      #{Heex.headline(spec)}

      Generated by `mix ui.gen` from `#{Heex.spec_ref(spec)}`.
      \"\"\"\\
    """
  end
end
