import assert from "node:assert/strict";
import test from "node:test";

import {
  actionControlSelector,
  calendarActionStates,
  dataTableActionDefinitions,
  dataTableActionStates,
  dataTableVisualModel,
  dataTableVisualStates,
  datePickerActionStates,
  enterVisualState,
  messageScrollerActionDefinitions,
  messageScrollerActionStates,
  messageScrollerAnimationPreset,
  messageScrollerCommandMenuPopup,
  messageScrollerSelectedControlMatches,
  waitForComboboxEmptyLiveRegion,
  waitForMessageScrollerCommandControls,
  nativeVisualControlSelector,
  settleMessageScrollerActionVisualState,
  visualStateIdentity,
} from "./visual-states.mjs";
import { isOfficialInteractiveShadcnComponent } from "./official-interactive-components.mjs";

async function captureVisibleComboboxEmpty({ textContent, onSettle } = {}) {
  const originalDocument = globalThis.document;
  const originalSetTimeout = globalThis.setTimeout;
  const waits = [];
  const results = [];
  const empty = {
    checkVisibility: () => true,
    isConnected: true,
    textContent,
  };
  const list = {
    parentElement: {
      querySelector: (selector) =>
        selector === "[data-slot='combobox-empty']" ? empty : null,
    },
  };
  const preview = {
    querySelector: (selector) =>
      selector === "[role='combobox'][aria-controls]"
        ? { getAttribute: () => "frameworks-list" }
        : null,
    querySelectorAll: () => [],
  };
  const calls = [];
  const page = {
    waitForFunction: async (...args) => {
      calls.push(args);
      results.push(await args[0](args[1]));
    },
  };

  globalThis.document = {
    getElementById: (id) => (id === "frameworks-list" ? list : null),
    querySelector: () => preview,
  };
  globalThis.setTimeout = (callback, delay) => {
    waits.push(delay);
    onSettle?.(empty);
    callback();
    return 0;
  };

  try {
    await waitForComboboxEmptyLiveRegion(page, "[data-preview='combobox']", {
      kind: "editable",
    });
  } finally {
    globalThis.document = originalDocument;
    globalThis.setTimeout = originalSetTimeout;
  }

  return { calls, results, waits };
}

test("editable capture waits through the Combobox Empty marker lifecycle", async () => {
  const capture = await captureVisibleComboboxEmpty({
    textContent: "No items found.\u2060",
    onSettle: (empty) => {
      empty.textContent = "No items found.";
    },
  });

  assert.deepEqual(capture.waits, [200]);
  assert.deepEqual(capture.results, [true]);
  assert.equal(capture.calls[0][1].selector, "[data-preview='combobox']");
  assert.equal(capture.calls[0][1].marker, "\u2060");
  assert.equal(capture.calls[0][1].resetMs, 200);
});

test("editable capture waits through an already-plain Combobox Empty lifecycle", async () => {
  const capture = await captureVisibleComboboxEmpty({ textContent: "No items found." });

  assert.deepEqual(capture.waits, [200]);
  assert.deepEqual(capture.results, [true]);
  assert.equal(capture.calls[0][2].timeout, 1100);
});

test("Message Scroller action states cover the official primary actions", () => {
  assert.deepEqual(
    Object.fromEntries(
      [
        "default",
        "anchoring",
        "group-chat",
        "previous-context",
        "streaming",
        "animation",
        "load-history",
        "opening-position",
        "commands",
        "visibility",
        "scrollable",
      ].map((example) => [
        example,
        messageScrollerActionStates(example).map(({ action }) => action),
      ]),
    ),
    {
      default: ["send-busy", "send-reply", "scroll-to-end", "reset"],
      anchoring: ["append", "reset"],
      "group-chat": ["append-marker", "append-reply", "reset"],
      "previous-context": ["peek-128", "send-busy", "send-reply", "reset"],
      streaming: ["send-busy", "send-reply", "reset"],
      animation: [
        "preset-fade",
        "preset-slide-up",
        "preset-slide-side",
        "preset-pop",
        "preset-spring-bounce",
        "preset-blur-fade",
        "preset-scale-fade",
        "send-busy",
        "send-reply",
        "reset",
      ],
      "load-history": ["load-history", "reset"],
      "opening-position": [
        "opening-start",
        "opening-end",
        "opening-last-anchor",
      ],
      commands: [
        "command-activation",
        "command-compare",
        "command-experiment",
        "command-risk",
      ],
      visibility: [
        "outline-vis-brief",
        "outline-vis-impact",
        "outline-vis-actions",
        "outline-vis-checklist",
      ],
      scrollable: ["scroll-top", "scroll-middle", "scroll-bottom"],
    },
  );
});

test("Calendar uses one representative selectable-day state", () => {
  assert.deepEqual(calendarActionStates(), [
    { name: "action:select-day", kind: "calendar-action", action: "select-day" },
  ]);
});

test("generic action discovery excludes ARIA-disabled controls", () => {
  assert.match(actionControlSelector(), /:not\(\[aria-disabled='true'\]\)/);
});

test("Message Scroller action identity includes the action descriptor", () => {
  assert.notDeepEqual(
    visualStateIdentity(messageScrollerActionStates("default")[0]),
    visualStateIdentity(messageScrollerActionStates("default")[1]),
  );
});

test("Message Scroller animation selects the pinned combobox name", () => {
  const calls = [];
  const scope = {
    getByRole: (...args) => {
      calls.push(args);
      return "preset";
    },
  };

  assert.equal(messageScrollerAnimationPreset(scope), "preset");
  assert.deepEqual(calls, [["combobox", { name: "Animation preset", exact: true }]]);
});

test("Message Scroller commands resolve one visible menu from the Jump trigger controls", async () => {
  const menu = { count: async () => 1 };
  const calls = [];
  const trigger = {
    evaluate: (callback) =>
      callback({
        getAttribute: (name) =>
          name === "aria-expanded" ? "true" : name === "aria-controls" ? "commands-popup" : null,
      }),
  };
  const scope = {
    getByRole: (...args) => {
      calls.push(["role", ...args]);
      return trigger;
    },
  };
  const page = {
    locator: (selector) => {
      calls.push(["locator", selector]);
      return menu;
    },
  };

  assert.equal(await messageScrollerCommandMenuPopup(page, scope), menu);
  assert.deepEqual(calls, [
    ["role", "button", { name: "Jump to...", exact: true }],
    ["locator", '[id="commands-popup"][role="menu"]:visible'],
  ]);

  await assert.rejects(
    messageScrollerCommandMenuPopup(
      { locator: () => ({ count: async () => 2 }) },
      { getByRole: () => trigger },
    ),
    /did not open exactly once/,
  );
});

test("Message Scroller commands wait for expanded state and delayed controls", async () => {
  const previousRaf = globalThis.requestAnimationFrame;
  let frame = 0;
  const element = {
    getAttribute: (name) => {
      if (name === "aria-expanded") return frame > 0 ? "true" : "false";
      if (name === "aria-controls") return frame > 1 ? "commands-popup" : null;
      return null;
    },
  };
  const trigger = { evaluate: (callback) => callback(element) };
  globalThis.requestAnimationFrame = (callback) => {
    queueMicrotask(() => {
      frame += 1;
      callback();
    });
    return frame;
  };

  try {
    assert.equal(await waitForMessageScrollerCommandControls(trigger), "commands-popup");
  } finally {
    globalThis.requestAnimationFrame = previousRaf;
  }
});

test("Message Scroller selected-state checks use the action's semantic control role", () => {
  const control = {
    textContent: "Fade▼",
    querySelector: (selector) =>
      selector === "[data-slot='select-value']" ? { textContent: "Fade" } : null,
  };
  const root = {
    querySelector: (selector) =>
      selector === 'button[role="combobox"][aria-label="Animation preset"]'
        ? control
        : null,
  };

  const selected = { role: "combobox", name: "Animation preset", value: "Fade" };
  const serialized = Function(`return (${messageScrollerSelectedControlMatches.toString()})`)();

  assert.equal(serialized(root, selected), true);
});

test("Opening Position reaches last-anchor through a real tab change", () => {
  const action = messageScrollerActionDefinitions("opening-position").find(
    ({ name }) => name === "opening-last-anchor",
  );

  assert.notDeepEqual(action.steps, [
    { type: "click", role: "tab", name: "last-anchor" },
  ]);

  assert.deepEqual(action, {
    name: "opening-last-anchor",
    steps: [
      { type: "click", role: "tab", name: "end" },
      { type: "wait", expect: { tab: "end", position: "end" } },
      { type: "click", role: "tab", name: "last-anchor" },
    ],
    expect: {
      tab: "last-anchor",
      position: "message:open-3",
      scrollMargin: 64,
    },
  });
});

test("Message Scroller action visual state waits for an active entry marker", async () => {
  const previousDocument = globalThis.document;
  const previousWindow = globalThis.window;
  const previousRaf = globalThis.requestAnimationFrame;
  const item = {
    active: true,
    hasAttribute(name) {
      return name === "data-lb-message-entry-active" && this.active;
    },
  };
  const calls = [];
  globalThis.window = {};
  globalThis.document = {
    querySelector() {
      return {
        querySelectorAll() {
          return [item];
        },
      };
    },
  };
  globalThis.requestAnimationFrame = (callback) => {
    queueMicrotask(callback);
    return 0;
  };
  const page = {
    async evaluate(callback) {
      calls.push("settle");
      await callback();
    },
    async waitForFunction(predicate, options) {
      calls.push(predicate(options));
      item.active = false;
      calls.push(predicate(options));
      calls.push(predicate(options));
    },
  };

  try {
    await settleMessageScrollerActionVisualState(page, "[data-preview]");
  } finally {
    globalThis.document = previousDocument;
    globalThis.window = previousWindow;
    globalThis.requestAnimationFrame = previousRaf;
  }

  assert.deepEqual(calls, ["settle", false, false, true]);
});

test("hover visual states wait for finite tooltip animations", async () => {
  const originalRaf = globalThis.requestAnimationFrame;
  const originalDocument = globalThis.document;
  let animationFinished = false;
  const calls = [];

  globalThis.requestAnimationFrame = (callback) => {
    queueMicrotask(() => callback());
    return 0;
  };
  globalThis.document = {
    documentElement: { hasAttribute: () => false },
    getAnimations: () => [
      {
        effect: { getComputedTiming: () => ({ endTime: 150 }) },
        finished: Promise.resolve().then(() => {
          animationFinished = true;
        }),
      },
    ],
  };

  const trigger = {
    getAttribute: async () => "tooltip-trigger",
    hover: async () => calls.push("hover"),
  };
  const page = {
    mouse: { move: async () => calls.push("move") },
    waitForFunction: async (callback) => assert.equal(callback(), true),
    locator: (selector) => {
      if (selector.includes("tooltip-trigger")) return { nth: () => trigger };

      assert.equal(selector, "[data-slot='tooltip-content']:visible");
      return { waitFor: async () => calls.push("wait:visible") };
    },
    evaluate: async (callback) => callback(),
  };

  try {
    await enterVisualState(page, "[data-preview='message-scroller']", {
      kind: "hover",
      index: 0,
    });
  } finally {
    globalThis.requestAnimationFrame = originalRaf;
    globalThis.document = originalDocument;
  }

  assert.deepEqual(calls, ["move", "hover", "wait:visible"]);
  assert.equal(animationFinished, true);
});

test("an unknown Message Scroller example cannot silently omit action states", () => {
  assert.throws(
    () => messageScrollerActionStates("missing"),
    /unknown Message Scroller example/,
  );
});

test("Data Table action states cover the pinned controls and menus", () => {
  assert.deepEqual(
    Object.fromEntries(
      ["default", "rtl"].map((example) => [
        example,
        dataTableActionStates(example).map(({ action }) => action),
      ]),
    ),
    {
      default: [
        "filter-carmella",
        "sort-email",
        "select-first-row",
        "select-all",
        "columns-menu",
        "actions-menu",
      ],
      rtl: [
        "filter-carmella",
        "sort-email",
        "select-first-row",
        "select-all",
        "columns-menu",
        "actions-menu",
      ],
    },
  );
});

test("Data Table has only default and declared action states", () => {
  for (const example of ["default", "rtl"]) {
    assert.deepEqual(dataTableVisualModel(example).claimedControlKinds, [
      "checked",
    ]);
    assert.equal(dataTableVisualModel(example).claimsExpandedStates, true);

    const states = dataTableVisualStates(example);

    assert.deepEqual(states, [
      { name: "default", kind: "default" },
      ...dataTableActionStates(example),
    ]);
    assert.equal(
      states.some(({ name }) => name.startsWith("checked:")),
      false,
    );
    assert.equal(
      states.some(({ name }) => name.startsWith("expanded:")),
      false,
    );
  }
});

test("an unknown Data Table example cannot silently omit action states", () => {
  assert.throws(
    () => dataTableActionStates("missing"),
    /unknown Data Table example/,
  );
});

test("Data Table filters use the official locale-specific placeholders", () => {
  const filter = (example) =>
    dataTableActionDefinitions(example)
      .find(({ name }) => name === "filter-carmella")
      .steps.find(({ type }) => type === "filter");

  assert.equal(filter("default").placeholder, "Filter emails...");
  assert.equal(filter("rtl").placeholder, "تصفية البريد الإلكتروني...");
});

test("Date Picker action states cover every pinned source and its interactive state", () => {
  assert.deepEqual(
    Object.fromEntries(
      [
        "default",
        "basic",
        "range",
        "dob",
        "input",
        "time",
        "natural-language",
        "rtl",
      ].map((example) => [
        example,
        datePickerActionStates(example).map(({ action }) => action),
      ]),
    ),
    {
      default: ["open", "select"],
      basic: ["open", "select"],
      range: ["open", "select-range"],
      dob: ["open", "select"],
      input: ["invalid-open", "select"],
      time: ["open", "select-with-time"],
      "natural-language": ["typed-open", "select"],
      rtl: ["open", "select"],
    },
  );
});

test("an unknown Date Picker example cannot silently omit action states", () => {
  assert.throws(
    () => datePickerActionStates("missing"),
    /unknown Date Picker example/,
  );
});

test("visual state identity keeps native field actions distinct", () => {
  const selector = "input[type='text']:visible";

  assert.notDeepEqual(
    visualStateIdentity({ kind: "editable", index: 0, selector }),
    visualStateIdentity({ kind: "editable", index: 1, selector }),
  );
  assert.notDeepEqual(
    visualStateIdentity({
      kind: "native-select",
      index: 0,
      selector: "select:visible",
      value: "a",
    }),
    visualStateIdentity({
      kind: "native-select",
      index: 0,
      selector: "select:visible",
      value: "b",
    }),
  );
});

test("native visual states exclude accessibility-hidden proxies and retain real fields", () => {
  const selectors = nativeVisualControlSelector().split(", ");

  assert.equal(
    selectors.every((selector) =>
      selector.includes(":not([aria-hidden='true']):visible"),
    ),
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

test("visual state identity keeps nested actions on different control paths distinct", () => {
  assert.notDeepEqual(
    visualStateIdentity({
      kind: "nested-control",
      controlKind: "checked",
      index: 0,
      path: [{ index: 0 }],
    }),
    visualStateIdentity({
      kind: "nested-control",
      controlKind: "checked",
      index: 0,
      path: [{ index: 1 }],
    }),
  );
  assert.notDeepEqual(
    visualStateIdentity({
      kind: "nested-control",
      controlKind: "checked",
      index: 0,
      path: [{ index: 0 }],
    }),
    visualStateIdentity({
      kind: "nested-control",
      controlKind: "pressed",
      index: 0,
      path: [{ index: 0 }],
    }),
  );
});

test("named official component suites opt into visual action discovery", () => {
  assert.equal(isOfficialInteractiveShadcnComponent("dropdown-menu"), true);
  assert.equal(isOfficialInteractiveShadcnComponent("questionnaire"), true);
  assert.equal(isOfficialInteractiveShadcnComponent("native-select"), true);
  assert.equal(isOfficialInteractiveShadcnComponent("not-a-component"), false);
});
