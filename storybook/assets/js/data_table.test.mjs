import assert from "node:assert/strict";
import test from "node:test";

import { DataTableFilter } from "./data_table.js";

function filterHook() {
  const listeners = new Map();
  const events = [];
  const el = {
    dataset: { tableFilterEvent: "data_table" },
    value: "",
    addEventListener(name, listener) {
      listeners.set(name, listener);
    },
    removeEventListener(name, listener) {
      if (listeners.get(name) === listener) listeners.delete(name);
    },
  };

  return { el, events, listeners, pushEvent: (event, payload) => events.push({ event, payload }) };
}

test("Data Table filter sends the controlled React filter state without a form", () => {
  const hook = filterHook();
  DataTableFilter.mounted.call(hook);

  hook.el.value = "carmella";
  hook.listeners.get("input")();

  assert.deepEqual(hook.events, [
    { event: "data_table", payload: { action: "filter", filter: "carmella" } },
  ]);
});

test("Data Table filter removes its input listener on destroy", () => {
  const hook = filterHook();
  DataTableFilter.mounted.call(hook);
  DataTableFilter.destroyed.call(hook);

  assert.equal(hook.listeners.has("input"), false);
});
