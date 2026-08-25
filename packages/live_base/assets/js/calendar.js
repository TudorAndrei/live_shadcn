// A server calendar starts in a predictable locale. This opt-in replaces only
// its labels after mount, where the browser can truthfully report its locale.
export const Calendar = {
  mounted() {
    if (this.el.dataset.lbCalendarLocale !== "browser") return;

    const locale = navigator.language;
    const month = this.el.querySelector("[data-lb-calendar-month]");

    if (month) {
      month.textContent = new Intl.DateTimeFormat(locale, { month: "long", year: "numeric" }).format(
        new Date(`${month.dataset.lbCalendarMonth}T00:00:00`)
      );
    }

    this.el.querySelectorAll("[data-lb-calendar-weekday]").forEach((weekday) => {
      weekday.textContent = weekdayName(locale, weekday.dataset.lbCalendarWeekday);
    });
  },
};

// Two letters, and the server renders two letters.
//
// react-day-picker formats a weekday heading with date-fns `cccccc`, the
// two-letter standalone form — `Su Mo Tu`. `Intl` has no such width: `short` is
// `Sun` and `narrow` is `S`. The server already cuts `%a` to two, and this must
// cut the same way or the two disagree with each other: the heading is what
// decides how wide a column settles, so a hook that wrote `Sun` after mount
// made every column 1.2px wider than the one the server had drawn, and the
// whole grid 8.5px wider than React's.
function weekdayName(locale, iso) {
  const short = new Intl.DateTimeFormat(locale, { weekday: "short" }).format(
    new Date(`${iso}T00:00:00`)
  );

  return [...short].slice(0, 2).join("");
}
