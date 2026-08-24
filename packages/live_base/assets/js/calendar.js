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
      weekday.textContent = new Intl.DateTimeFormat(locale, { weekday: "short" }).format(
        new Date(`${weekday.dataset.lbCalendarWeekday}T00:00:00`)
      );
    });
  },
};
