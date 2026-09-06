import assert from "node:assert/strict";
import test from "node:test";

import {
  editableInteractionSelector,
  editableInteractionProbeSelector,
  isInteractionControlDisabled,
  probeIdentity,
  scopedInteractionPages,
  waitForDisclosureClosed,
} from "./interaction-parity.mjs";
import { scopeFromEnvironment } from "./preview-scope.mjs";

test("a probe identity excludes locator order but keeps the observable action", () => {
  assert.deepEqual(
    probeIdentity({
      kind: "native-select",
      role: "",
      name: "Status",
      index: 4,
      value: "done",
    }),
    {
      kind: "native-select",
      role: "",
      name: "Status",
      value: "done",
      popupSlot: null,
    },
  );
});

test("an editable text probe keeps the value it enters", () => {
  assert.deepEqual(
    probeIdentity({
      kind: "editable-text",
      role: "",
      name: "Message",
      index: 1,
      value: "Parity text",
    }),
    {
      kind: "editable-text",
      role: "",
      name: "Message",
      value: "Parity text",
      popupSlot: null,
    },
  );
});

test("editable interaction probes exclude accessibility-hidden proxies and retain text fields", () => {
  const selectors = editableInteractionSelector().split(", ");
  const probeSelectors = editableInteractionProbeSelector().split(", ");

  assert.equal(
    selectors.every((selector) =>
      selector.includes(":not([aria-hidden='true'])"),
    ),
    true,
  );
  assert.equal(
    probeSelectors.every((selector) => selector.endsWith(":visible")),
    true,
  );
  assert.equal(
    selectors.some((selector) => selector.includes("input[type='text']")),
    true,
  );
  assert.equal(
    selectors.some((selector) => selector.includes("textarea")),
    true,
  );
});

test("interaction probes treat only true disabled states as disabled", () => {
  const control = ({ nativeDisabled = false, ariaDisabled = null, ancestor }) => ({
    matches: (selector) => selector === ":disabled" && nativeDisabled,
    getAttribute: (name) => (name === "aria-disabled" ? ariaDisabled : null),
    closest: (selector) =>
      selector === "[data-disabled]" && ancestor !== undefined
        ? { getAttribute: () => ancestor }
        : null,
  });

  assert.equal(
    isInteractionControlDisabled(control({ ancestor: "false" })),
    false,
  );
  assert.equal(
    isInteractionControlDisabled(control({ ancestor: "true" })),
    true,
  );
  assert.equal(
    isInteractionControlDisabled(control({ ancestor: "" })),
    true,
  );
  assert.equal(
    isInteractionControlDisabled(control({ ariaDisabled: "true" })),
    true,
  );
  assert.equal(
    isInteractionControlDisabled(control({ nativeDisabled: true })),
    true,
  );
  assert.equal(
    isInteractionControlDisabled(control({ ancestor: "true" })),
    true,
  );
});

test("the shared preview scope selects official examples for named and generic suites", () => {
  const previews = {
    switch: ["default", "disabled", "form"],
    table: ["default", "responsive"],
    select: ["default"],
  };
  const scope = scopeFromEnvironment({ PREVIEW_EXAMPLES: "default,form" });

  const pages = scopedInteractionPages(
    previews,
    scope,
    (_source, name) => name !== "table.default",
  );

  assert.deepEqual(pages, [
    { component: "switch", example: "default" },
    { component: "switch", example: "form" },
    { component: "select", example: "default" },
  ]);
});

test("a disclosure close waits for its opened popup exit before it samples closed state", async () => {
  const calls = [];
  const target = {
    evaluate: async (callback, args) =>
      callback(
        {
          getAttribute: (name) => (name === "aria-expanded" ? "false" : null),
        },
        args,
      ),
  };
  const popup = {
    waitFor: async (options) => calls.push(options),
  };

  await waitForDisclosureClosed(target, popup);

  assert.deepEqual(calls, [{ state: "hidden", timeout: 1_000 }]);
});
