import assert from "node:assert/strict";
import test from "node:test";

import { Combobox } from "./combobox.js";

test("Combobox updates direct trigger text after a selection without changing its icon", () => {
  const originalDocument = globalThis.document;
  const originalCss = globalThis.CSS;
  const attributes = new Map();
  const valueText = { nodeType: 3, textContent: "Select country" };
  const icon = { nodeType: 1 };
  const trigger = {
    childNodes: [valueText, icon],
    querySelector: () => null,
  };
  const input = { disabled: false, value: "" };
  const list = { toggleAttribute() {} };
  const item = {
    getAttribute(name) {
      return { "data-combobox-label": "Argentina", "data-value": "ar" }[name] || null;
    },
    setAttribute() {},
    toggleAttribute() {},
  };
  const content = {
    querySelector(selector) {
      return selector === "[data-slot='combobox-list']" ? list : null;
    },
    querySelectorAll() {
      return [item];
    },
  };
  const hook = {
    controllerId: "country",
    el: {
      closest: () => null,
      getAttribute: (name) => (name === "data-combobox-controller" ? "country" : null),
      hasAttribute: () => false,
      matches: () => false,
      querySelector: () => null,
      setAttribute: (name, value) => attributes.set(name, value),
      toggleAttribute: (name, present) => {
        if (present) attributes.set(name, "");
        else attributes.delete(name);
      },
    },
    selected: new Set(["ar"]),
    allItems: Combobox.allItems,
    anchorOrContent: Combobox.anchorOrContent,
    label: Combobox.label,
    multiple: () => false,
    renderChips() {},
    renderFormValues() {},
    syncIndicator() {},
    value: Combobox.value,
  };

  globalThis.CSS = { escape: (value) => value };
  globalThis.document = {
    addEventListener() {},
    getElementById(id) {
      return {
        "country-content": content,
        "country-input": input,
        "country-positioner": null,
        "country-trigger": trigger,
      }[id];
    },
    querySelector: () => null,
    querySelectorAll: () => [],
  };

  try {
    Combobox.bind.call(hook);
    assert.equal(hook.valueNode, valueText);

    Combobox.sync.call(hook, { emit: false });

    assert.equal(valueText.textContent, "Argentina");
    assert.equal(trigger.childNodes[1], icon);
  } finally {
    globalThis.CSS = originalCss;
    globalThis.document = originalDocument;
  }
});

test("Combobox leaves pointer opens unhighlighted and highlights the first item on ArrowDown", () => {
  const input = { disabled: false };
  const pointerCalls = [];
  const pointerHook = {
    disabled: () => false,
    input,
    inputPointerDown: true,
    selected: new Set(),
    open(options) {
      pointerCalls.push(options);
    },
  };

  Combobox.focusin.call(pointerHook, { target: input });

  assert.deepEqual(pointerCalls, [
    {
      autoHighlight: false,
      focus: false,
      highlightSelected: false,
      source: input,
    },
  ]);

  const keyboardCalls = [];
  const inputAttributes = new Map();
  const firstAttributes = new Map();
  const first = {
    hidden: false,
    id: "first",
    removeAttribute(name) {
      firstAttributes.delete(name);
    },
    scrollIntoView() {},
    setAttribute(name, value) {
      firstAttributes.set(name, value);
    },
  };
  const keyboardInput = {
    ...input,
    removeAttribute(name) {
      inputAttributes.delete(name);
    },
    setAttribute(name, value) {
      inputAttributes.set(name, value);
    },
  };
  const keyboardHook = {
    disabled: () => false,
    clearHighlight() {
      first.removeAttribute("data-highlighted");
    },
    highlight: Combobox.highlight,
    highlighted: () => null,
    input: keyboardInput,
    isOpen: () => false,
    move: Combobox.move,
    open(options) {
      keyboardCalls.push(["open", options]);
    },
    visibleItems: () => [first],
  };
  const event = {
    key: "ArrowDown",
    preventDefault() {
      keyboardCalls.push(["preventDefault"]);
    },
    target: keyboardInput,
  };

  Combobox.keydown.call(keyboardHook, event);

  assert.deepEqual(keyboardCalls, [
    ["preventDefault"],
    ["open", { focus: false, source: keyboardInput }],
  ]);
  assert.equal(firstAttributes.get("data-highlighted"), "");
  assert.equal(inputAttributes.get("aria-activedescendant"), "first");
});

test("Combobox keeps an empty Popup input addon exposed when it opens", () => {
  const originalDocument = globalThis.document;
  const attributes = () => new Map();
  const element = (values = attributes()) => ({
    removeAttribute: (name) => values.delete(name),
    setAttribute: (name, value) => values.set(name, value),
    values,
  });
  const emptyAddon = { ...element(), querySelector: () => null };
  const hook = {
    addons: [emptyAddon],
    clear: null,
    content: element(),
    disabled: () => false,
    el: { ...element(), matches: () => false },
    filter() {},
    input: element(),
    isOpen: () => false,
    labels: [],
    positioner: element(),
    selected: new Set(),
    setChipsHidden() {},
    setControls() {},
    trigger: element(),
  };

  globalThis.document = { activeElement: null };

  try {
    Combobox.open.call(hook, { focus: false });

    assert.equal(emptyAddon.values.has("aria-hidden"), false);
  } finally {
    globalThis.document = originalDocument;
  }
});

test("Combobox replaces a server-rendered chip during client synchronization", () => {
  let removed = false;
  const hook = {
    chips: {
      querySelector: () => null,
      querySelectorAll(selector) {
        return selector === "[data-combobox-chip]" ? [{ remove: () => (removed = true) }] : [];
      },
    },
    isOpen: () => false,
    setChipsHidden() {},
  };

  Combobox.renderChips.call(hook, []);

  assert.equal(removed, true);
});

test("Combobox preserves server Clear state and clears the same control", () => {
  const rootAttributes = new Map([["data-combobox-value", "Next.js"]]);
  const clearAttributes = new Map([["data-visible", ""]]);
  const input = { focus() {}, value: "Next.js" };
  const clear = {
    hidden: false,
    remove() {
      this.hidden = true;
    },
    toggleAttribute(name, present) {
      if (present) clearAttributes.set(name, "");
      else clearAttributes.delete(name);
    },
  };
  const itemAttributes = new Map();
  const item = {
    getAttribute(name) {
      return { "data-combobox-label": "Next.js", "data-value": "Next.js" }[name] || null;
    },
    hasAttribute: () => false,
    setAttribute(name, value) {
      itemAttributes.set(name, value);
    },
    toggleAttribute(name, present) {
      if (present) itemAttributes.set(name, "");
      else itemAttributes.delete(name);
    },
  };
  const hook = {
    allItems: Combobox.allItems,
    clear,
    content: {
      querySelector: () => ({ toggleAttribute() {} }),
      querySelectorAll: () => [item],
    },
    el: {
      getAttribute: (name) => rootAttributes.get(name) || null,
      hasAttribute: () => false,
      setAttribute: (name, value) => rootAttributes.set(name, value),
      toggleAttribute(name, present) {
        if (present) rootAttributes.set(name, "");
        else rootAttributes.delete(name);
      },
    },
    filter() {},
    hiddenInput: null,
    input,
    label: Combobox.label,
    multiple: () => false,
    renderChips() {},
    renderFormValues() {},
    selected: new Set(),
    sync: Combobox.sync,
    syncIndicator() {},
    value: Combobox.value,
  };

  Combobox.readInitialValue.call(hook);
  Combobox.sync.call(hook, { emit: false });

  assert.deepEqual([...hook.selected], ["Next.js"]);
  assert.equal(input.value, "Next.js");
  assert.equal(clear.hidden, false);
  assert.equal(clearAttributes.get("data-visible"), "");

  Combobox.clearValue.call(hook);

  assert.equal(input.value, "");
  assert.equal(clear.hidden, true);
  assert.equal(clearAttributes.has("data-visible"), false);
});

test("Combobox Clear closes, restores its trigger, and keeps input focus without reopening", async () => {
  const attributes = (initial = []) => new Map(initial);
  const element = (values = attributes()) => ({
    getAttribute: (name) => values.get(name) || null,
    hasAttribute: (name) => values.has(name),
    removeAttribute: (name) => values.delete(name),
    setAttribute: (name, value) => values.set(name, value),
    toggleAttribute(name, present) {
      if (present) values.set(name, "");
      else values.delete(name);
    },
    values,
  });
  const root = element(attributes([["data-open", ""]]));
  const content = element(attributes([["data-open", ""]]));
  const positioner = element(attributes([["data-open", ""]]));
  const addon = element(attributes([["aria-hidden", "true"]]));
  const trigger = element(attributes([["aria-expanded", "true"]]));
  const clearParent = { append() {} };
  const clear = {
    ...element(attributes([["data-visible", ""], ["tabindex", "-1"]])),
    hidden: false,
    parentElement: clearParent,
    remove() {
      this.parentElement = null;
    },
  };
  let inputFocuses = 0;
  const input = {
    ...element(attributes([["aria-controls", "frameworks-list"], ["aria-expanded", "true"]])),
    disabled: false,
    value: "Next.js",
    focus() {
      inputFocuses += 1;
      Combobox.focusin.call(hook, { target: input });
    },
  };
  const list = { toggleAttribute() {} };
  content.querySelector = (selector) =>
    selector === "[data-slot='combobox-list']" ? list : null;
  content.querySelectorAll = () => [];
  let openCalls = 0;
  const hook = {
    addons: [addon],
    allItems: () => [],
    chips: null,
    clear,
    clearParent,
    clearHighlight() {},
    close: Combobox.close,
    content,
    disabled: () => false,
    el: root,
    filter() {},
    hiddenInput: null,
    input,
    isOpen: Combobox.isOpen,
    label() {},
    labels: [],
    multiple: () => false,
    open() {
      openCalls += 1;
    },
    openedBy: input,
    positioner,
    renderChips() {},
    renderFormValues() {},
    selected: new Set(["Next.js"]),
    setChipsHidden() {},
    setControls: Combobox.setControls,
    sync: Combobox.sync,
    syncIndicator() {},
    trigger,
    value() {},
  };

  Combobox.clearValue.call(hook);

  assert.deepEqual([...hook.selected], []);
  assert.equal(root.values.has("data-open"), false);
  assert.equal(root.values.get("data-closed"), "");
  assert.equal(content.values.has("data-open"), false);
  assert.equal(positioner.values.has("data-open"), false);
  assert.equal(input.values.get("aria-expanded"), "false");
  assert.equal(input.values.has("aria-controls"), false);
  assert.equal(trigger.values.get("aria-expanded"), "false");
  assert.equal(addon.values.has("aria-hidden"), false);
  assert.equal(clear.parentElement, null);
  assert.equal(inputFocuses, 1);
  assert.equal(openCalls, 0);

  await Promise.resolve();
  assert.equal(hook.skipNextInputOpen, false);
});

test("Combobox removes ARIA controls when an input disclosure closes", () => {
  const element = (attributes) => ({
    hasAttribute: (name) => attributes.has(name),
    removeAttribute: (name) => attributes.delete(name),
    setAttribute: (name, value) => attributes.set(name, value),
  });
  const rootAttributes = new Map([["data-open", ""]]);
  const inputAttributes = new Map([
    ["aria-expanded", "true"],
    ["aria-controls", "timezones-list"],
  ]);
  const triggerAttributes = new Map([
    ["aria-expanded", "true"],
    ["aria-controls", "timezones-list"],
  ]);
  const hook = {
    addons: [],
    clearHighlight() {},
    content: element(new Map([["data-open", ""]])),
    el: element(rootAttributes),
    input: element(inputAttributes),
    isOpen: Combobox.isOpen,
    labels: [],
    openedBy: null,
    positioner: element(new Map([["data-open", ""]])),
    setControls: Combobox.setControls,
    setChipsHidden() {},
    trigger: element(triggerAttributes),
  };

  Combobox.close.call(hook);

  assert.equal(inputAttributes.get("aria-expanded"), "false");
  assert.equal(inputAttributes.has("aria-controls"), false);
  assert.equal(triggerAttributes.get("aria-expanded"), "false");
  assert.equal(triggerAttributes.has("aria-controls"), false);
});

test("Combobox gives a popup input the listbox and its button the dialog", () => {
  const attributes = () => new Map();
  const element = (values = attributes()) => ({
    getAttribute: (name) => values.get(name) || null,
    get id() {
      return values.get("id") || "";
    },
    removeAttribute: (name) => values.delete(name),
    setAttribute: (name, value) => values.set(name, value),
    values,
  });
  const list = element(new Map([["id", "_r_1_"]]));
  const content = element(new Map([["id", "base-ui-_r_0_-popup"], ["role", "dialog"]]));
  content.querySelector = (selector) =>
    selector === "[data-slot='combobox-list']" ? list : null;
  const input = element();
  const trigger = element();

  Combobox.setControls.call({ content, input, trigger }, true);

  assert.equal(input.values.get("aria-controls"), "_r_1_");
  assert.equal(trigger.values.get("aria-controls"), "base-ui-_r_0_-popup");
});

test("Combobox leaves focus on its input when Escape closes an input controller", () => {
  const element = (attributes) => ({
    hasAttribute: (name) => attributes.has(name),
    removeAttribute: (name) => attributes.delete(name),
    setAttribute: (name, value) => attributes.set(name, value),
  });
  const rootAttributes = new Map([
    ["aria-expanded", "true"],
    ["data-open", ""],
  ]);
  const input = { ...element(rootAttributes), tagName: "INPUT" };
  let triggerFocuses = 0;
  const trigger = {
    ...element(new Map([["aria-expanded", "true"]])),
    focus() {
      triggerFocuses += 1;
    },
    isConnected: true,
    tagName: "BUTTON",
  };
  const hook = {
    addons: [],
    clearHighlight() {},
    close: Combobox.close,
    content: element(new Map([["data-open", ""]])),
    disabled: () => false,
    el: input,
    input,
    isOpen: Combobox.isOpen,
    labels: [],
    openedBy: input,
    positioner: element(new Map([["data-open", ""]])),
    setChipsHidden() {},
    setControls: Combobox.setControls,
    trigger,
  };
  const event = {
    key: "Escape",
    preventDefault() {},
    target: input,
  };

  Combobox.keydown.call(hook, event);

  assert.equal(rootAttributes.has("data-open"), false);
  assert.equal(triggerFocuses, 0);
});

test("Combobox restores button trigger focus when Escape closes a popup controller", () => {
  const element = (attributes) => ({
    hasAttribute: (name) => attributes.has(name),
    removeAttribute: (name) => attributes.delete(name),
    setAttribute: (name, value) => attributes.set(name, value),
  });
  const rootAttributes = new Map([
    ["aria-expanded", "true"],
    ["data-open", ""],
  ]);
  let triggerFocuses = 0;
  const trigger = {
    ...element(rootAttributes),
    focus() {
      triggerFocuses += 1;
    },
    isConnected: true,
    tagName: "BUTTON",
  };
  const input = { ...element(new Map([["aria-expanded", "true"]])), tagName: "INPUT" };
  const hook = {
    addons: [],
    clearHighlight() {},
    close: Combobox.close,
    content: element(new Map([["data-open", ""]])),
    disabled: () => false,
    el: trigger,
    input,
    isOpen: Combobox.isOpen,
    labels: [],
    openedBy: trigger,
    positioner: element(new Map([["data-open", ""]])),
    setChipsHidden() {},
    setControls: Combobox.setControls,
    trigger,
  };

  Combobox.keydown.call(hook, {
    key: "Escape",
    preventDefault() {},
    target: input,
  });

  assert.equal(rootAttributes.has("data-open"), false);
  assert.equal(triggerFocuses, 1);
});

test("Combobox keeps its input focused while an item is selected", () => {
  const item = {};
  const hook = {
    content: { contains: (candidate) => candidate === item },
    outsidePointerDown() {
      assert.fail("an item pointer event must stay inside the Combobox");
    },
  };
  const pointerEvent = {
    target: { closest: (selector) => (selector === "[data-slot='combobox-item']" ? item : null) },
    preventDefault() {
      this.defaultPrevented = true;
    },
  };
  const mouseEvent = {
    target: { closest: (selector) => (selector === "[data-slot='combobox-item']" ? item : null) },
    preventDefault() {
      this.defaultPrevented = true;
    },
  };

  Combobox.pointerdown.call(hook, pointerEvent);
  Combobox.mousedown.call(hook, mouseEvent);

  assert.equal(pointerEvent.defaultPrevented, true);
  assert.equal(mouseEvent.defaultPrevented, true);
});

test("Combobox returns focus to its input after a chip is removed", () => {
  const calls = [];
  const input = {
    focus() {
      calls.push("focus");
      Combobox.focusin.call(hook, { target: input });
    },
    value: "",
  };
  const hook = {
    disabled: () => false,
    input,
    open() {
      calls.push("open");
    },
    selected: new Set(["Next.js", "Remix"]),
    sync() {
      calls.push("sync");
      assert.deepEqual([...this.selected], ["Remix"]);
      assert.equal(this.input.value, "");
    },
  };
  const chip = { getAttribute: (name) => (name === "data-combobox-chip" ? "Next.js" : null) };

  Combobox.remove.call(hook, chip);

  assert.deepEqual([...hook.selected], ["Remix"]);
  assert.deepEqual(calls, ["sync", "focus"]);
});

test("Combobox chips expose toolbar semantics only while a chip exists", () => {
  const attributes = () => new Map();
  const element = (values = attributes()) => ({
    removeAttribute: (name) => values.delete(name),
    setAttribute: (name, value) => values.set(name, value),
    toggleAttribute(name, present) {
      if (present) values.set(name, "");
      else values.delete(name);
    },
    values,
  });
  const chips = element();
  const hook = {
    allItems: () => [],
    chips,
    content: null,
    el: element(),
    hiddenInput: null,
    input: null,
    multiple: () => true,
    renderChips() {},
    renderFormValues() {},
    selected: new Set(["Next.js"]),
  };

  Combobox.sync.call(hook, { emit: false });
  assert.equal(chips.values.get("role"), "toolbar");

  hook.selected.clear();
  Combobox.sync.call(hook, { emit: false });
  assert.equal(chips.values.has("role"), false);
});

test("Combobox matches the pinned initial and later no-results live-region states", async () => {
  const contentAttributes = new Map();
  const listAttributes = new Map();
  const item = {
    hidden: false,
    getAttribute(name) {
      return { "data-combobox-label": "London", "data-value": "london" }[name] || null;
    },
    hasAttribute() {
      return false;
    },
  };
  const empty = { textContent: "No timezones found." };
  const list = {
    toggleAttribute(name, present) {
      if (present) listAttributes.set(name, "");
      else listAttributes.delete(name);
    },
  };
  const hook = {
    allItems: Combobox.allItems,
    content: {
      querySelector(selector) {
        return {
          "[data-slot='combobox-empty']": empty,
          "[data-slot='combobox-list']": list,
        }[selector] || null;
      },
      querySelectorAll(selector) {
        return selector === "[data-slot='combobox-item']" ? [item] : [];
      },
      toggleAttribute(name, present) {
        if (present) contentAttributes.set(name, "");
        else contentAttributes.delete(name);
      },
    },
    el: { hasAttribute: () => false },
    empty,
    emptyMessage: "No timezones found.",
    highlighted: () => null,
    label: Combobox.label,
    query: "Atlantis",
    visibleItems: Combobox.visibleItems,
  };

  Combobox.filter.call(hook, { initialLiveRegion: true });

  await new Promise((resolve) => setTimeout(resolve));

  assert.equal(item.hidden, true);
  assert.equal(empty.textContent, "No timezones found.\u2060");
  assert.equal(contentAttributes.get("data-empty"), "");
  assert.equal(listAttributes.get("data-empty"), "");

  await new Promise((resolve) => setTimeout(resolve, 220));
  assert.equal(empty.textContent, "No timezones found.");

  hook.query = "London";
  Combobox.filter.call(hook);

  assert.equal(item.hidden, false);
  assert.equal(empty.textContent, "");
  assert.equal(contentAttributes.has("data-empty"), false);
  assert.equal(listAttributes.has("data-empty"), false);

  hook.query = "Atlantis";
  Combobox.filter.call(hook);

  assert.equal(empty.textContent, "No timezones found.");
  assert.equal(contentAttributes.get("data-empty"), "");
  assert.equal(listAttributes.get("data-empty"), "");
});
