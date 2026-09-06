import assert from "node:assert/strict";
import test from "node:test";

import { Calendar } from "./calendar.js";

for (const [mode, date] of [
  ["single", "2025-06-02"],
  ["range", "2025-06-05"],
]) {
  test(`Calendar restores the ${mode} selection focus after a LiveView update`, () => {
    let focused;
    const hook = {
      pendingFocus: date,
      el: { getClientRects: () => [{}] },
      read() {},
      captureTemplates() {},
      sync() {},
      visible: Calendar.visible,
      focusDate(value) {
        focused = value.toISOString().slice(0, 10);
      },
    };

    Calendar.updated.call(hook);

    assert.equal(focused, date);
    assert.equal(hook.pendingFocus, null);
  });
}

test("Calendar does not restore focus into a closed popup", () => {
  let focused = false;
  const hook = {
    pendingFocus: "2025-06-02",
    el: { getClientRects: () => [] },
    read() {},
    captureTemplates() {},
    sync() {},
    visible: Calendar.visible,
    focusDate() {
      focused = true;
    },
  };

  Calendar.updated.call(hook);

  assert.equal(focused, false);
  assert.equal(hook.pendingFocus, null);
});

test("Calendar restores focus to its declared control after a LiveView selection patch", () => {
  const originalDocument = globalThis.document;
  let focused = false;
  const hook = {
    pendingFocus: "2025-06-02",
    el: {
      dataset: { lbCalendarReturnFocus: "date-required" },
      getClientRects: () => [],
    },
    read() {},
    captureTemplates() {},
    sync() {},
    visible: Calendar.visible,
    focusDate() {
      assert.fail("the declared control must receive focus instead");
    },
  };

  globalThis.document = {
    getElementById: (id) => (id === "date-required" ? { focus: () => (focused = true) } : null),
  };

  try {
    Calendar.updated.call(hook);
  } finally {
    globalThis.document = originalDocument;
  }

  assert.equal(focused, true);
  assert.equal(hook.pendingFocus, null);
});

for (const [dropdownValue, expectedMonth] of [
  ["0", 1],
  ["11", 12],
]) {
  test(`Calendar converts dropdown month value ${dropdownValue} to internal month ${expectedMonth}`, () => {
    let rendered;
    const caption = {
      dataset: { lbCalendarCaption: "month" },
      value: dropdownValue,
      closest: () => caption,
    };
    const hook = {
      current: new Date("2026-12-01T00:00:00Z"),
      system: "gregorian",
      el: {
        contains: (element) => element === caption,
        dataset: {},
      },
      calendarParts: Calendar.calendarParts,
      render() {
        rendered = this.current.toISOString().slice(0, 10);
      },
      emitMonthChange() {},
    };

    Calendar.change.call(hook, { target: caption });

    assert.equal(rendered, `2026-${String(expectedMonth).padStart(2, "0")}-01`);
    assert.equal(hook.el.dataset.lbCalendarMonth, rendered);
  });
}

test("Calendar range selection extends a complete range through the clicked date", () => {
  const makeClassList = (...initial) => {
    const values = new Set(initial);

    return {
      add: (...names) => names.forEach((name) => values.add(name)),
      contains: (name) => values.has(name),
      remove: (...names) => names.forEach((name) => values.delete(name)),
      toggle: (name, present) => {
        if (present) values.add(name);
        else values.delete(name);
      },
      values,
    };
  };

  const makeCell = (...classes) => {
    const attributes = new Map();
    const classList = makeClassList(...classes);
    attributes.set("class", classes.join(" "));

    return {
      attributes,
      classList,
      dataset: {},
      getAttribute: (name) => attributes.get(name) || null,
      hasAttribute: (name) => attributes.has(name),
      removeAttribute: (name) => attributes.delete(name),
      setAttribute: (name, value) => {
        attributes.set(name, value);
        if (name === "class") {
          for (const known of [...classList.values]) classList.remove(known);
          value.split(/\s+/).filter(Boolean).forEach((name) => classList.add(name));
        }
      },
      toggleAttribute: (name, present) => {
        if (present) attributes.set(name, "");
        else attributes.delete(name);
      },
    };
  };

  const makeDay = (iso, ...classes) => {
    const cell = makeCell(...classes);

    return {
      cell,
      button: {
        attributes: new Map(),
        classList: makeClassList(),
        dataset: { day: iso },
        closest: () => cell,
        focus() {},
        removeAttribute(name) { this.attributes.delete(name); },
        setAttribute(name, value) { this.attributes.set(name, value); },
        toggleAttribute(name, present) {
          if (present) this.attributes.set(name, "");
          else this.attributes.delete(name);
        },
      },
    };
  };

  const start = makeDay("2026-11-29", "rdp-outside");
  const middle = makeDay("2026-11-30", "rdp-outside");
  const end = makeDay("2026-12-18");
  const outside = makeDay("2026-12-19");
  const days = [start, middle, end, outside];
  const root = {
    dataset: {
      lbCalendarSelected: "2026-12-08/2026-12-18",
      lbCalendarDayGroupAfterSelect: "true",
    },
    querySelector: () => null,
    querySelectorAll: () => [],
  };
  const hook = {
    el: root,
    mode: "range",
    dayGroupAfterSelect: true,
    dayGroupAfterSelectActive: false,
    selected: { from: "2026-12-08", to: "2026-12-18" },
    days: () => days.map(({ button }) => button),
    emitSelect() {},
    focus: Calendar.focus,
    isDisabled: () => false,
    rangeState: Calendar.rangeState,
    sync: Calendar.sync,
    syncDayGroupsAfterSelect: Calendar.syncDayGroupsAfterSelect,
    syncNavigation() {},
    writeSelection: Calendar.writeSelection,
  };

  assert.equal(days.every(({ cell }) => cell.classList.contains("group/day")), false);

  Calendar.select.call(hook, "2026-11-29", start.button);

  assert.deepEqual(hook.selected, { from: "2026-11-29", to: "2026-12-18" });
  assert.equal(root.dataset.lbCalendarSelected, "2026-11-29/2026-12-18");

  assert.equal(start.cell.attributes.get("data-selected"), "true");
  assert.equal(start.cell.attributes.get("data-focused"), "true");
  assert.equal(start.cell.classList.contains("rdp-focused"), true);
  assert.equal(start.cell.classList.contains("rdp-selected"), true);
  assert.equal(start.cell.classList.contains("rdp-range_start"), true);
  assert.equal(days.every(({ cell }) => cell.classList.contains("group/day")), true);
  assert.equal(middle.cell.classList.contains("rdp-selected"), true);
  assert.equal(middle.cell.classList.contains("rdp-range_middle"), true);
  assert.equal(end.cell.classList.contains("rdp-selected"), true);
  assert.equal(end.cell.classList.contains("rdp-range_end"), true);
  assert.equal(outside.cell.classList.contains("rdp-selected"), false);
});

test("Calendar follows DayPicker Shift navigation and skips disabled dates", () => {
  const moved = [];
  const hook = {
    el: { contains: () => true, dir: "ltr" },
    startsOn: 7,
    system: "gregorian",
    isDisabled: () => false,
    isHidden: () => false,
    moveFocus: Calendar.moveFocus,
    focusDate: (date) => moved.push(date.toISOString().slice(0, 10)),
  };
  const target = {
    dataset: { day: "2026-01-12" },
    closest: () => target,
  };
  const event = (key, shiftKey = false) => ({
    key,
    shiftKey,
    target,
    preventDefault() {},
    stopPropagation() {},
  });

  Calendar.keydown.call(hook, event("ArrowRight", true));
  Calendar.keydown.call(hook, event("ArrowDown", true));

  hook.isDisabled = (date) => date.toISOString().slice(0, 10) === "2026-01-13";
  Calendar.keydown.call(hook, event("ArrowRight"));

  assert.deepEqual(moved, ["2026-02-12", "2027-01-12", "2026-01-14"]);
});
