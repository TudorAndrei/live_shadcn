defmodule LiveShadcnTools.Gen.Calendar do
  @moduledoc "The server-side calendar grid recipe."

  alias LiveShadcnTools.Gen.Heex

  @doc "The module source for one calendar component."
  def module(spec, opts) do
    classes = spec["classes"]

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
                `classNames` prop shadcn hands react-day-picker. There were
                twenty typed here, and the calendar drew 8,077 pixels
                differently from upstream because of it. --%>
          <div class=#{inspect(classes["months"])}>
            <%!-- The nav is a sibling of the month, positioned over it, not a
                  child of the caption. That is how upstream builds it, and
                  putting the buttons inside the caption instead is what made
                  our month grid a pixel shorter than React's. --%>
            <nav class=#{inspect(classes["nav"])}>
              <%!-- The chevrons upstream draws, not the `‹` and `›` characters
                    that used to stand in for them. shadcn renders an
                    `IconPlaceholder` here with `cn-rtl-flip size-4`, so the
                    generated component names the same lucide icon and carries
                    the same class — a glyph from the font is a different shape,
                    a different size and a different colour from an SVG. --%>
              <button type="button" aria-label="Go to the previous month" class=#{inspect(classes["previous_button"])}>
                <LiveShadcn.Icon.icon name="chevron-left" class="cn-rtl-flip size-4" />
              </button>
              <button type="button" aria-label="Go to the next month" class=#{inspect(classes["next_button"])}>
                <LiveShadcn.Icon.icon name="chevron-right" class="cn-rtl-flip size-4" />
              </button>
            </nav>
          <div class=#{inspect(classes["month"])}>
          <div class=#{inspect(classes["month_caption"])}>
            <span data-lb-calendar-month={Date.to_iso8601(@month)} class=#{inspect(classes["caption_label"])}>{Calendar.strftime(@month, "%B %Y")}</span>
          </div>
          <table class=#{inspect(classes["month_grid"])} role="grid" aria-label={Calendar.strftime(@month, "%B %Y")}>
            <thead>
              <tr class=#{inspect(classes["weekdays"])}>
                <%!-- The one measurement still typed here, and the comment is
                      the finding rather than the number. Upstream's cells carry
                      no width: react-day-picker's own layout settles them at
                      19.22px, ours at 22.2, and seven of those is 22px of extra
                      width that `aspect-square` then turns into extra height.
                      Pinning it puts the columns where upstream puts them. What
                      it is really saying is that this recipe still lays the grid
                      out itself. --%>
                <th :for={day <- weekday_dates(@week_starts_on)} data-lb-calendar-weekday={Date.to_iso8601(day)} style="width: 19px" class=#{inspect(classes["weekday"])} scope="col">{weekday_name(day)}</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={week <- @weeks} class=#{inspect(classes["week"])}>
                <td :for={day <- week} style="width: 19px" class=#{inspect(classes["day"])}>
                  <button
                    type="button"
                    data-day={Date.to_iso8601(day)}
                    data-selected={to_string(day == @selected)}
                    class={[#{inspect(classes["day_button"])}, if(day.month != @month.month, do: "text-muted-foreground opacity-50 rdp-outside") ]}
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

  defp moduledoc(spec) do
    """
      @moduledoc \"\"\"
      #{Heex.headline(spec)}

      Generated by `mix ui.gen` from `#{Heex.spec_ref(spec)}`.
      \"\"\"\\
    """
  end
end
