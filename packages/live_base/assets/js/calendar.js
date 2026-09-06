// The Calendar hook owns the same client state that react-day-picker owns for
// an uncontrolled Calendar. The server renders the first grid, so a LiveView
// page remains useful before JavaScript loads. After mount this hook updates
// native buttons and grid cells in place, and sends ISO dates to a host when
// the component is controlled.

const DAY = 86_400_000;
const PERSIAN_MONTHS = ["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"];
const PERSIAN_DIGITS = ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"];
const RANGE_CELL_CLASSES = {
  start: "relative isolate z-0 rounded-l-(--cell-radius) bg-muted after:absolute after:inset-y-0 after:right-0 after:w-4 after:bg-muted",
  middle: "rounded-none",
  end: "relative isolate z-0 rounded-r-(--cell-radius) bg-muted after:absolute after:inset-y-0 after:left-0 after:w-4 after:bg-muted",
};

export const Calendar = {
  mounted() {
    this.onClick = (event) => this.click(event);
    this.onChange = (event) => this.change(event);
    this.onKeydown = (event) => this.keydown(event);
    this.el.addEventListener("click", this.onClick);
    this.el.addEventListener("change", this.onChange);
    this.el.addEventListener("keydown", this.onKeydown);
    this.dayGroupAfterSelectActive = false;
    this.read();
    this.captureTemplates();
    this.sync();
  },

  updated() {
    const selectedByClient = this.pendingFocus;
    this.pendingFocus = null;
    this.read();
    this.captureTemplates();
    this.sync();
    if (selectedByClient) {
      const returnFocus = this.el.dataset?.lbCalendarReturnFocus;

      if (returnFocus) {
        document.getElementById(returnFocus)?.focus({ preventScroll: true });
      } else if (this.visible()) {
        this.focusDate(fromISO(selectedByClient));
      }
    }
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick);
    this.el.removeEventListener("change", this.onChange);
    this.el.removeEventListener("keydown", this.onKeydown);
  },

  read() {
    this.mode = this.el.dataset.lbCalendarMode || "single";
    this.system = this.el.dataset.lbCalendarSystem || "gregorian";
    this.locale = this.el.dataset.lbCalendarLocale === "browser" ? navigator.language : this.el.dataset.lbCalendarLocale || "en";
    this.count = Number(this.el.dataset.lbCalendarNumberOfMonths || 1);
    this.startsOn = Number(this.el.dataset.lbCalendarWeekStartsOn || 7);
    this.fixedWeeks = this.el.hasAttribute("data-lb-calendar-fixed-weeks");
    this.outsideDays = this.el.hasAttribute("data-lb-calendar-show-outside-days");
    this.weekNumbers = this.el.hasAttribute("data-lb-calendar-show-week-number");
    this.captionLayout = this.el.dataset.lbCalendarCaptionLayout || "label";
    this.extra = this.el.dataset.lbCalendarDayExtra;
    this.dayGroupAfterSelect = this.el.dataset.lbCalendarDayGroupAfterSelect === "true";
    this.current = fromISO(this.el.dataset.lbCalendarMonth) || monthStart(new Date());
    this.selected = readSelection(this.el.dataset.lbCalendarSelected, this.mode);
    this.disabled = readDisabled(this.el.dataset.lbCalendarDisabled);
  },

  captureTemplates() {
    const month = this.months()[0];
    if (!month) return;
    this.monthTemplate = month.cloneNode(true);
    this.rowTemplate = month.querySelector("tbody tr")?.cloneNode(true);
    this.dayTemplate = month.querySelector("td[role='gridcell']")?.cloneNode(true);
    this.weekTemplate = month.querySelector("td.rdp-week_number")?.cloneNode(true);
  },

  months() { return [...this.el.querySelectorAll(".rdp-month[data-lb-calendar-month]")]; },
  days() { return [...this.el.querySelectorAll("button[data-lb-calendar-day]")]; },

  click(event) {
    const nav = event.target.closest("[data-lb-calendar-nav]");
    if (nav && this.el.contains(nav)) {
      event.preventDefault();
      if (nav.disabled) return;
      this.navigate(nav.dataset.lbCalendarNav === "next" ? 1 : -1, nav);
      return;
    }

    const day = event.target.closest("button[data-lb-calendar-day]");
    if (day && this.el.contains(day) && !day.disabled) {
      event.preventDefault();
      this.select(day.dataset.day, day);
    }
  },

  change(event) {
    const caption = event.target.closest("select[data-lb-calendar-caption]");
    if (!caption || !this.el.contains(caption)) return;
    const month = this.calendarParts(this.current);
    if (caption.dataset.lbCalendarCaption === "month") month.month = Number(caption.value) + 1;
    if (caption.dataset.lbCalendarCaption === "year") month.year = Number(caption.value);
    this.current = this.system === "persian" ? jalaliToGregorian(month.year, month.month, 1) : utcDate(month.year, month.month, 1);
    this.el.dataset.lbCalendarMonth = toISO(this.current);
    this.render();
    this.emitMonthChange();
  },

  keydown(event) {
    const target = event.target.closest("button[data-lb-calendar-day]");
    if (!target || !this.el.contains(target)) return;
    const date = fromISO(target.dataset.day);
    if (!date) return;

    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      this.select(target.dataset.day, target);
      return;
    }

    const rtl = this.el.dir === "rtl";
    const movement = {
      ArrowLeft: [event.shiftKey ? "month" : "day", rtl ? "after" : "before"],
      ArrowRight: [event.shiftKey ? "month" : "day", rtl ? "before" : "after"],
      ArrowUp: [event.shiftKey ? "year" : "week", "before"],
      ArrowDown: [event.shiftKey ? "year" : "week", "after"],
      PageUp: [event.shiftKey ? "year" : "month", "before"],
      PageDown: [event.shiftKey ? "year" : "month", "after"],
      Home: ["startOfWeek", "before"],
      End: ["endOfWeek", "after"],
    }[event.key];

    if (movement) {
      event.preventDefault();
      event.stopPropagation();
      this.moveFocus(movement[0], movement[1], date);
    }
  },

  select(iso, target) {
    const date = fromISO(iso);
    if (!date || this.isDisabled(date)) return;

    if (this.mode === "multiple") {
      const dates = this.selected instanceof Set ? this.selected : new Set();
      dates.has(iso) ? dates.delete(iso) : dates.add(iso);
      this.selected = dates;
    } else if (this.mode === "range") {
      const range = this.selected?.from ? this.selected : {};
      if (!range.from) {
        this.selected = { from: iso, to: null };
      } else if (iso < range.from) {
        this.selected = { from: iso, to: range.to || range.from };
      } else if (range.to && iso === range.from) {
        this.selected = { from: range.from, to: iso };
      } else if (range.to && iso === range.to) {
        this.selected = { from: iso, to: iso };
      } else {
        this.selected = { from: range.from, to: iso };
      }
    } else {
      this.selected = this.selected === iso ? null : iso;
    }

    if (this.dayGroupAfterSelect) this.dayGroupAfterSelectActive = true;
    this.writeSelection();
    this.sync();
    this.focus(target);
    this.pendingFocus = iso;
    this.emitSelect();
  },

  navigate(offset, trigger, focusDate = null) {
    if (!this.canNavigate(offset)) return;
    this.current = addCalendarMonths(this.current, offset, this.system);
    this.el.dataset.lbCalendarMonth = toISO(this.current);
    this.render();
    this.emitMonthChange();
    const focus = focusDate ? addCalendarMonths(focusDate, offset, this.system) : this.firstFocusable();
    if (focus) this.focusDate(focus);
    else if (trigger) trigger.focus();
  },

  render() {
    if (!this.monthTemplate || !this.rowTemplate || !this.dayTemplate) return;
    const holder = this.monthTemplate.parentElement;
    if (!holder) return;
    this.months().forEach((month) => month.remove());
    for (let offset = 0; offset < this.count; offset += 1) {
      const date = addCalendarMonths(this.current, offset, this.system);
      const month = this.monthTemplate.cloneNode(true);
      this.renderMonth(month, date);
      holder.append(month);
    }
    this.captureTemplates();
    this.sync();
  },

  renderMonth(month, date) {
    month.dataset.lbCalendarMonth = toISO(date);
    const parts = this.calendarParts(date);
    const label = calendarLabel(parts, this.locale, this.system);
    const monthSelect = month.querySelector("select[data-lb-calendar-caption='month']");
    const yearSelect = month.querySelector("select[data-lb-calendar-caption='year']");
    const caption = month.querySelector(".rdp-caption_label");
    const captionStatus = month.querySelector("[data-lb-calendar-caption-status]");
    if (caption && !monthSelect) setLeadingText(caption, label);
    if (captionStatus) captionStatus.textContent = label;
    if (monthSelect) setLeadingText(monthSelect.parentElement?.querySelector(".rdp-caption_label"), shortMonth(parts, this.locale, this.system));
    if (yearSelect) setLeadingText(yearSelect.parentElement?.querySelector(".rdp-caption_label"), displayYear(parts, this.system));
    if (monthSelect) monthSelect.value = String(parts.month - 1);
    if (yearSelect) yearSelect.value = String(parts.year);

    const table = month.querySelector("table[role='grid']");
    if (table) table.setAttribute("aria-label", label);
    const body = month.querySelector("tbody");
    if (!body) return;
    body.replaceChildren();

    for (const week of calendarWeeks(date, this.startsOn, this.fixedWeeks, this.system)) {
      const row = this.rowTemplate.cloneNode(false);
      if (this.weekNumbers && this.weekTemplate) {
        const number = this.weekTemplate.cloneNode(true);
        number.querySelector("div").textContent = String(localeWeek(week[0])).padStart(2, "0");
        row.append(number);
      }
      for (const day of week) row.append(this.renderDay(day, date));
      body.append(row);
    }
  },

  renderDay(date, month) {
    const cell = this.dayTemplate.cloneNode(true);
    const button = cell.querySelector("button[data-lb-calendar-day]");
    const iso = toISO(date);
    const outside = !sameCalendarMonth(date, month, this.system);
    const disabled = this.isDisabled(date);
    const hidden = this.isHidden(date, outside);
    cell.dataset.day = iso;
    toggle(cell, "data-outside", outside);
    toggle(cell, "data-disabled", disabled);
    toggle(cell, "data-hidden", hidden);
    toggle(cell, "data-today", iso === toISO(today()));
    cell.classList.toggle("rdp-outside", outside);
    cell.classList.toggle("text-muted-foreground", outside || disabled);
    cell.classList.toggle("rdp-disabled", disabled);
    cell.classList.toggle("opacity-50", disabled);
    cell.classList.toggle("invisible", hidden);
    cell.classList.toggle("rdp-hidden", hidden);
    if (hidden) {
      button.remove();
      return cell;
    }
    button.dataset.day = iso;
    button.setAttribute("aria-label", dayLabel(date, this.locale, this.system));
    button.disabled = disabled;
    button.replaceChildren(document.createTextNode(displayDay(date, this.system)));
    if (this.extra === "price" && !outside) {
      const price = document.createElement("span");
      price.textContent = [0, 6].includes(date.getUTCDay()) ? "$120" : "$100";
      button.append(price);
    }
    return cell;
  },

  sync() {
    this.syncNavigation();
    this.syncDayGroupsAfterSelect();
    this.days().forEach((button) => {
      const date = fromISO(button.dataset.day);
      if (!date) return;
      const cell = button.closest("[role='gridcell']");
      const state = this.rangeState(button.dataset.day);
      const selected = state !== null;
      toggle(cell, "data-selected", selected);
      toggle(button, "data-selected-single", selected && state === "single");
      toggle(button, "data-range-start", state === "start");
      toggle(button, "data-range-middle", state === "middle");
      toggle(button, "data-range-end", state === "end");
      if (selected) cell.setAttribute("aria-selected", "true"); else cell.removeAttribute("aria-selected");
      button.removeAttribute("aria-pressed");
      button.tabIndex = selected || toISO(date) === toISO(today()) ? 0 : -1;
      syncCalendarDayClass(cell, selected, state);
    });
  },

  syncDayGroupsAfterSelect() {
    if (!this.dayGroupAfterSelect || !this.dayGroupAfterSelectActive) return;

    this.days().forEach((button) => {
      const cell = button.closest("[role='gridcell']");
      if (!cell || cell.classList.contains("group/day")) return;
      delete cell.dataset.lbCalendarDayBaseClass;
      cell.setAttribute("class", `group/day ${cell.getAttribute("class") || ""}`.trim());
    });
  },

  syncNavigation() {
    const previous = this.el.querySelector("button[data-lb-calendar-nav='previous']");
    const next = this.el.querySelector("button[data-lb-calendar-nav='next']");
    if (previous) previous.disabled = !this.canNavigate(-1);
    if (next) next.disabled = !this.canNavigate(1);
  },

  canNavigate(offset) {
    if (this.captionLayout !== "dropdown") return true;
    const target = this.calendarParts(addCalendarMonths(this.current, offset, this.system));
    const currentYear = this.calendarParts(today()).year;
    return target.year >= currentYear - 100 && target.year <= currentYear;
  },

  rangeState(iso) {
    if (this.mode === "multiple") return this.selected?.has(iso) ? "single" : null;
    if (this.mode === "single") return this.selected === iso ? "single" : null;
    const range = this.selected;
    if (!range?.from) return null;
    if (range.from === iso) return "start";
    if (range.to === iso) return "end";
    if (range.to && iso > range.from && iso < range.to) return "middle";
    return null;
  },

  isDisabled(date) {
    const iso = toISO(date);
    return this.disabled.some(({ from, to }) => iso >= from && iso <= to);
  },

  isHidden(date, outside) {
    if (!this.outsideDays && outside) return true;
    if (this.el.dataset.lbCalendarCaptionLayout !== "dropdown") return false;
    const year = date.getUTCFullYear();
    const currentYear = today().getUTCFullYear();
    return year < currentYear - 100 || year > currentYear;
  },

  writeSelection() {
    const value = selectionValue(this.selected, this.mode);
    if (value) this.el.dataset.lbCalendarSelected = value;
    else delete this.el.dataset.lbCalendarSelected;
  },

  emitSelect() {
    const value = selectionValue(this.selected, this.mode);
    const detail = { mode: this.mode, selected: value };
    this.el.dispatchEvent(new CustomEvent("calendar:select", { bubbles: true, detail }));
    if (this.el.dataset.lbCalendarSelectEvent && this.pushEvent) this.pushEvent(this.el.dataset.lbCalendarSelectEvent, detail);
  },

  emitMonthChange() {
    const detail = { month: toISO(this.current) };
    this.el.dispatchEvent(new CustomEvent("calendar:month-change", { bubbles: true, detail }));
    if (this.el.dataset.lbCalendarMonthChangeEvent && this.pushEvent) this.pushEvent(this.el.dataset.lbCalendarMonthChangeEvent, detail);
  },

  firstFocusable() { return fromISO(this.days().find((button) => !button.disabled)?.dataset.day); },

  moveFocus(moveBy, moveDir, date) {
    let candidate = date;

    for (let attempt = 0; attempt <= 365; attempt += 1) {
      candidate = nextFocusableDate(moveBy, moveDir, candidate, this.startsOn, this.system);

      if (!this.isDisabled(candidate) && !this.isHidden?.(candidate, false)) {
        this.focusDate(candidate);
        return;
      }
    }
  },

  focusDate(date) {
    const iso = toISO(date);
    let button = this.days().find((item) => item.dataset.day === iso && !item.disabled);
    if (!button) {
      this.current = monthStart(date);
      this.el.dataset.lbCalendarMonth = toISO(this.current);
      this.render();
      button = this.days().find((item) => item.dataset.day === iso && !item.disabled);
    }
    if (button) this.focus(button);
  },

  focus(button) {
    this.el.querySelectorAll("[role='gridcell'][data-focused]").forEach((cell) => cell.removeAttribute("data-focused"));
    button.closest("[role='gridcell']")?.setAttribute("data-focused", "true");
    button.tabIndex = 0;
    button.focus({ preventScroll: true });
    this.sync();
  },

  visible() {
    return this.el.getClientRects().length > 0;
  },

  calendarParts(date) { return this.system === "persian" ? gregorianToJalali(date) : { year: date.getUTCFullYear(), month: date.getUTCMonth() + 1, day: date.getUTCDate() }; },
};

function today() { const now = new Date(); return utcDate(now.getFullYear(), now.getMonth() + 1, now.getDate()); }
function utcDate(year, month, day) { return new Date(Date.UTC(year, month - 1, day)); }
function fromISO(value) { return value && /^\d{4}-\d{2}-\d{2}$/.test(value) ? new Date(`${value}T00:00:00Z`) : null; }
function toISO(date) { return date.toISOString().slice(0, 10); }
function addDays(date, days) { return new Date(date.getTime() + days * DAY); }
function monthStart(date) { return utcDate(date.getUTCFullYear(), date.getUTCMonth() + 1, 1); }
function weekdayOffset(date, startsOn) { return (date.getUTCDay() - (startsOn % 7) + 7) % 7; }
function nextFocusableDate(moveBy, moveDir, date, startsOn, system) {
  const direction = moveDir === "after" ? 1 : -1;

  switch (moveBy) {
    case "day": return addDays(date, direction);
    case "week": return addDays(date, direction * 7);
    case "month": return addFocusMonths(date, direction, system);
    case "year": return addFocusYears(date, direction, system);
    case "startOfWeek": return addDays(date, -weekdayOffset(date, startsOn));
    case "endOfWeek": return addDays(date, 6 - weekdayOffset(date, startsOn));
    default: return date;
  }
}

function addFocusMonths(date, offset, system) {
  if (system === "persian") {
    const parts = gregorianToJalali(date);
    const index = parts.year * 12 + parts.month - 1 + offset;
    const year = Math.floor(index / 12);
    const month = (index % 12) + 1;
    return jalaliToGregorian(year, month, Math.min(parts.day, jalaliDaysInMonth(year, month)));
  }

  const index = date.getUTCFullYear() * 12 + date.getUTCMonth() + offset;
  const year = Math.floor(index / 12);
  const month = (index % 12) + 1;
  return utcDate(year, month, Math.min(date.getUTCDate(), gregorianDaysInMonth(year, month)));
}

function addFocusYears(date, offset, system) {
  if (system === "persian") {
    const parts = gregorianToJalali(date);
    const year = parts.year + offset;
    return jalaliToGregorian(year, parts.month, Math.min(parts.day, jalaliDaysInMonth(year, parts.month)));
  }

  const year = date.getUTCFullYear() + offset;
  const month = date.getUTCMonth() + 1;
  return utcDate(year, month, Math.min(date.getUTCDate(), gregorianDaysInMonth(year, month)));
}

function gregorianDaysInMonth(year, month) { return new Date(Date.UTC(year, month, 0)).getUTCDate(); }
function toggle(element, name, value) {
  if (!element) return;
  if (value) element.setAttribute(name, "true");
  else element.removeAttribute(name);
}
function setLeadingText(element, text) { const textNode = [...element.childNodes].find((node) => node.nodeType === Node.TEXT_NODE); if (textNode) textNode.textContent = text; else element.prepend(document.createTextNode(text)); }

function syncCalendarDayClass(cell, selected, state) {
  const base = calendarDayBaseClass(cell);
  const classes = [base];

  if (cell.hasAttribute("data-focused")) classes.push("rdp-focused");
  if (selected) classes.push("rdp-selected");
  if (state === "start") classes.push(RANGE_CELL_CLASSES.start, "rdp-range_start");
  if (state === "middle") classes.push(RANGE_CELL_CLASSES.middle, "rdp-range_middle");
  if (state === "end") classes.push(RANGE_CELL_CLASSES.end, "rdp-range_end");

  cell.setAttribute("class", classes.filter(Boolean).join(" "));
}

function calendarDayBaseClass(cell) {
  const remembered = cell.dataset.lbCalendarDayBaseClass;
  if (remembered !== undefined) return remembered;

  const tokens = (cell.getAttribute("class") || "").trim().split(/\s+/).filter(Boolean);
  for (const rangeClass of Object.values(RANGE_CELL_CLASSES)) removeClassSequence(tokens, rangeClass);

  const base = tokens
    .filter((token) => !["rdp-focused", "rdp-selected", "rdp-range_start", "rdp-range_middle", "rdp-range_end"].includes(token))
    .join(" ");

  cell.dataset.lbCalendarDayBaseClass = base;
  return base;
}

function removeClassSequence(tokens, classes) {
  const sequence = classes.split(" ");
  const start = tokens.join(" ").indexOf(classes);
  if (start < 0) return;

  let offset = 0;
  for (let index = 0; index < tokens.length; index += 1) {
    if (tokens.slice(index, index + sequence.length).join(" ") === classes) {
      offset = index;
      break;
    }
  }

  tokens.splice(offset, sequence.length);
}

function readSelection(value, mode) {
  if (!value) return mode === "multiple" ? new Set() : null;
  if (mode === "multiple") return new Set(value.split(",").filter(Boolean));
  if (mode === "range") { const [from, to] = value.split("/"); return from ? { from, to: to || null } : null; }
  return value;
}

function selectionValue(value, mode) {
  if (mode === "multiple") return [...(value || [])].sort().join(",");
  if (mode === "range") return value?.from ? `${value.from}/${value.to || ""}` : "";
  return value || "";
}

function readDisabled(value) {
  if (!value) return [];
  return value.split(",").filter(Boolean).map((entry) => {
    const [from, to] = entry.split("/");
    return { from, to: to || from };
  });
}

function addCalendarMonths(date, offset, system) {
  if (system !== "persian") return utcDate(date.getUTCFullYear(), date.getUTCMonth() + 1 + offset, 1);
  const parts = gregorianToJalali(date);
  const index = parts.year * 12 + parts.month - 1 + offset;
  return jalaliToGregorian(Math.floor(index / 12), (index % 12) + 1, 1);
}

function sameCalendarMonth(a, b, system) {
  const left = system === "persian" ? gregorianToJalali(a) : { year: a.getUTCFullYear(), month: a.getUTCMonth() + 1 };
  const right = system === "persian" ? gregorianToJalali(b) : { year: b.getUTCFullYear(), month: b.getUTCMonth() + 1 };
  return left.year === right.year && left.month === right.month;
}

function calendarWeeks(month, startsOn, fixed, system) {
  const parts = system === "persian" ? gregorianToJalali(month) : { year: month.getUTCFullYear(), month: month.getUTCMonth() + 1 };
  const first = system === "persian" ? jalaliToGregorian(parts.year, parts.month, 1) : utcDate(parts.year, parts.month, 1);
  const start = addDays(first, -weekdayOffset(first, startsOn));
  const days = system === "persian" ? jalaliDaysInMonth(parts.year, parts.month) : new Date(Date.UTC(parts.year, parts.month, 0)).getUTCDate();
  const length = fixed ? 6 : Math.ceil((weekdayOffset(first, startsOn) + days) / 7);
  return Array.from({ length }, (_, week) => Array.from({ length: 7 }, (_, day) => addDays(start, week * 7 + day)));
}

function calendarLabel(parts, locale, system) {
  if (system === "persian") return `${PERSIAN_MONTHS[parts.month - 1]} ${persianDigits(parts.year)}`;
  if (locale.startsWith("ar")) return new Intl.DateTimeFormat("ar-SA", { month: "long", year: "numeric", timeZone: "UTC" }).format(utcDate(parts.year, parts.month, 1));
  return new Intl.DateTimeFormat(locale, { month: "long", year: "numeric", timeZone: "UTC" }).format(utcDate(parts.year, parts.month, 1));
}

function shortMonth(parts, locale, system) {
  if (system === "persian") return PERSIAN_MONTHS[parts.month - 1];
  if (locale.startsWith("ar")) return new Intl.DateTimeFormat("ar-SA", { month: "short", timeZone: "UTC" }).format(utcDate(parts.year, parts.month, 1));
  return new Intl.DateTimeFormat(locale, { month: "short", timeZone: "UTC" }).format(utcDate(parts.year, parts.month, 1));
}

function displayYear(parts, system) { return system === "persian" ? persianDigits(parts.year) : String(parts.year); }

function dayLabel(date, locale, system) { const parts = system === "persian" ? gregorianToJalali(date) : { year: date.getUTCFullYear(), month: date.getUTCMonth() + 1, day: date.getUTCDate() }; return `${displayDay(date, system)} ${calendarLabel(parts, locale, system)}`; }
function displayDay(date, system) { return system === "persian" ? persianDigits(gregorianToJalali(date).day) : String(date.getUTCDate()); }
function localeWeek(date) {
  const nextStart = firstWeekStart(date.getUTCFullYear() + 1);
  const start = date >= nextStart ? nextStart : firstWeekStart(date.getUTCFullYear());
  return Math.floor((date - start) / DAY / 7) + 1;
}
function firstWeekStart(year) { const first = utcDate(year, 1, 1); return addDays(first, -first.getUTCDay()); }
function persianDigits(value) { return String(value).replace(/\d/g, (digit) => PERSIAN_DIGITS[Number(digit)]); }

// Civil Jalali conversion. Dates remain ISO Gregorian at the component edge.
function gregorianToJalali(date) {
  const gy = date.getUTCFullYear(); const gm = date.getUTCMonth() + 1; const gd = date.getUTCDate();
  const g = 365 * (gy - 1600) + Math.floor((gy - 1597) / 4) - Math.floor((gy - 1501) / 100) + Math.floor((gy - 1201) / 400) + gregorianBeforeMonth(gm, leapGregorian(gy)) + gd - 1;
  let days = g - 79; let jy = 979 + 33 * Math.floor(days / 12053); days %= 12053;
  if (days >= 366) { jy += 4 * Math.floor((days - 1) / 1461); days = (days - 1) % 1461; }
  if (days >= 365) { jy += Math.floor(days / 365); days %= 365; }
  return { year: jy, month: days < 186 ? Math.floor(days / 31) + 1 : Math.floor((days - 186) / 30) + 7, day: days < 186 ? days % 31 + 1 : (days - 186) % 30 + 1 };
}

function jalaliToGregorian(jy, jm, jd) {
  let days = 365 * (jy - 979) + Math.floor((jy - 979) / 33) * 8 + Math.floor(((jy - 979) % 33 + 3) / 4) + jalaliBeforeMonth(jm) + jd - 1 + 79;
  let gy = 1600 + 400 * Math.floor(days / 146097); days %= 146097;
  if (days >= 36525) { gy += 100 * Math.floor((days - 1) / 36524); days = (days - 1) % 36524; }
  if (days >= 1461) { gy += 4 * Math.floor(days / 1461); days %= 1461; }
  if (days >= 365) { gy += Math.floor(days / 365); days %= 365; }
  let gm = 1; while (gm < 12 && days >= gregorianBeforeMonth(gm + 1, leapGregorian(gy))) gm += 1;
  return utcDate(gy, gm, days - gregorianBeforeMonth(gm, leapGregorian(gy)) + 1);
}

function gregorianBeforeMonth(month, leap) { return [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334][month - 1] + (leap && month > 2 ? 1 : 0); }
function jalaliBeforeMonth(month) { return month <= 6 ? (month - 1) * 31 : 186 + (month - 7) * 30; }
function jalaliDaysInMonth(year, month) { if (month <= 6) return 31; if (month <= 11) return 30; return [1, 5, 9, 13, 17, 22, 26, 30].includes((year + 12) % 33) ? 30 : 29; }
function leapGregorian(year) { return year % 4 === 0 && (year % 100 !== 0 || year % 400 === 0); }
