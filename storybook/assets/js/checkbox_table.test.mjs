import assert from "node:assert/strict";
import test from "node:test";

import { CheckboxTable } from "./checkbox_table.js";

test("CheckboxTable makes the header mixed when one row is selected", () => {
  const attributes = new Map([["aria-checked", "false"], ["data-unchecked", ""]]);
  const indicator = { hidden: true };
  const input = { checked: false, toggleAttribute() {} };
  const control = {
    setAttribute(name, value) {
      attributes.set(name, value);
    },
    toggleAttribute(name, value) {
      if (value) attributes.set(name, "");
      else attributes.delete(name);
    },
    querySelector(selector) {
      return selector === "[data-slot='checkbox-indicator']" ? indicator : null;
    },
    nextElementSibling: input,
  };

  CheckboxTable.setControl.call({ input: CheckboxTable.input }, control, false, true);

  assert.equal(attributes.get("aria-checked"), "mixed");
  assert.equal(attributes.has("data-indeterminate"), true);
  assert.equal(indicator.hidden, false);
});
