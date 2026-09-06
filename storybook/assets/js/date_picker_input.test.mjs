import assert from "node:assert/strict";
import test from "node:test";

import { DatePickerInput } from "./date_picker_input.js";
import { Floating } from "../../../packages/live_base/assets/js/floating.js";

function hook({ selection = "0", value = "June 01, 2025" } = {}) {
  const el = {
    dataset: { datePickerSelection: selection, datePickerValue: value },
    value: "not a date",
  };

  return { el, selection: null };
}

test("DatePickerInput retains dirty text until a calendar selection changes", () => {
  const state = hook();
  DatePickerInput.mounted.call(state);
  DatePickerInput.updated.call(state);

  assert.equal(state.el.value, "not a date");
});

test("DatePickerInput applies the server value after a calendar selection", () => {
  const state = hook();
  DatePickerInput.mounted.call(state);
  state.el.dataset.datePickerSelection = "1";
  state.el.dataset.datePickerValue = "June 02, 2025";

  DatePickerInput.updated.call(state);

  assert.equal(state.el.value, "June 02, 2025");
  assert.equal(state.selection, "1");
});

test("DatePickerInput restores focus after close then a server selection patch", () => {
  const originalDocument = globalThis.document;
  const body = {};
  let activeElement = {};
  const staleTrigger = { focus: () => (activeElement = staleTrigger) };
  const currentTrigger = { focus: () => (activeElement = currentTrigger) };
  const state = hook();

  state.el.dataset.datePickerFocusTarget = "date-required";
  globalThis.document = {
    get activeElement() {
      return activeElement;
    },
    getElementById: (id) => (id === "date-required" ? currentTrigger : null),
  };

  try {
    DatePickerInput.mounted.call(state);

    Floating.returnFocus.call({
      el: { hasAttribute: (name) => name === "data-lb-return-focus-to-trigger" },
      anchor: staleTrigger,
      popup: { contains: () => true },
      returnTo: null,
    });

    assert.equal(activeElement, staleTrigger);

    // LiveView replaces the focused trigger while it applies the server patch.
    activeElement = body;
    state.el.dataset.datePickerSelection = "1";
    state.el.dataset.datePickerValue = "June 02, 2025";
    DatePickerInput.updated.call(state);

    assert.equal(state.el.value, "June 02, 2025");
    assert.equal(activeElement, currentTrigger);
  } finally {
    if (originalDocument === undefined) {
      delete globalThis.document;
    } else {
      globalThis.document = originalDocument;
    }
  }
});
