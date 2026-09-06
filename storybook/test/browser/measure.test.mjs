import assert from "node:assert/strict";
import test from "node:test";
import vm from "node:vm";

import { collect, compare } from "./measure.mjs";

const semantic = (overrides = {}) => ({
  tag: "div",
  role: "",
  text: "",
  className: "cn-message-scroller-item [content-visibility:auto]",
  rendering: {
    contentVisibility: "auto",
    containIntrinsicSize: "auto 160px",
  },
  states: {},
  ...overrides,
});

const slot = (name, box, options = {}) => {
  const { semantic: semanticOverrides, ...rest } = options;

  return {
    slot: name,
    box,
    style: {},
    ...rest,
    semantic: semantic(semanticOverrides),
  };
};

function element({ parent = null, slot = null, box, contentVisibility, checkVisibility } = {}) {
  return {
    hidden: false,
    tagName: "DIV",
    children: [],
    parentElement: parent,
    closest: () => null,
    contains: () => false,
    classList: { contains: () => false },
    getAttribute: (name) => (name === "data-slot" ? slot : null),
    getBoundingClientRect: () => ({
      ...box,
      top: box.y,
      left: box.x,
      right: box.x + box.width,
      bottom: box.y + box.height,
    }),
    ...(contentVisibility ? { contentVisibility } : {}),
    ...(checkVisibility ? { checkVisibility } : {}),
  };
}

function collectMeasure(root, stylesFor, portals = []) {
  const getComputedStyle = (node) => ({
    overflowY: "visible",
    contentVisibility: "visible",
    containIntrinsicSize: "none",
    direction: "ltr",
    getPropertyValue: () => "",
    ...stylesFor(node),
  });
  const previous = {
    document: globalThis.document,
    getComputedStyle: globalThis.getComputedStyle,
    nodeFilter: globalThis.NodeFilter,
  };

  globalThis.document = {
    querySelector: () => root,
    querySelectorAll: () => portals,
    createTreeWalker: () => ({ nextNode: () => false }),
  };
  globalThis.getComputedStyle = getComputedStyle;
  globalThis.NodeFilter = { SHOW_TEXT: 4 };

  try {
    return collect({ selector: "[data-preview]", properties: [], attributes: [] });
  } finally {
    globalThis.document = previous.document;
    globalThis.getComputedStyle = previous.getComputedStyle;
    globalThis.NodeFilter = previous.nodeFilter;
  }
}

test("the collector skips a portal slot under a hidden positioner", () => {
  const root = element({ box: { x: 0, y: 0, width: 336, height: 306 } });
  const positioner = element({ box: { x: 0, y: 0, width: 0, height: 0 } });
  const popup = element({
    parent: positioner,
    slot: "select-content",
    box: { x: 0, y: 0, width: 0, height: 0 },
  });
  positioner.hidden = true;

  const measured = collectMeasure(root, () => ({}), [popup]);

  assert.deepEqual(measured.slots, []);
});

test("the collector retains a visible portal slot", () => {
  const root = element({ box: { x: 0, y: 0, width: 336, height: 306 } });
  const positioner = element({ box: { x: 24, y: 24, width: 144, height: 164 } });
  const popup = element({
    parent: positioner,
    slot: "select-content",
    box: { x: 24, y: 24, width: 144, height: 164 },
  });

  const measured = collectMeasure(root, () => ({}), [popup]);

  assert.deepEqual(measured.slots.map(({ slot }) => slot), ["select-content"]);
});

test("the serialized collector has no module-helper dependency", () => {
  const root = {
    children: [],
    getBoundingClientRect: () => ({ x: 0, y: 0, width: 336, height: 306 }),
  };
  const child = {
    hidden: false,
    tagName: "DIV",
    children: [],
    parentElement: root,
    classList: { contains: () => false },
    getAttribute: (name) => ({ "data-slot": "message-scroller-item", class: "item beta alpha" })[name] || null,
    getBoundingClientRect: () => ({ x: 24, y: 24, width: 288, height: 64 }),
  };
  root.children = [child];

  const getComputedStyle = () => ({
    overflowY: "visible",
    contentVisibility: "visible",
    containIntrinsicSize: "none",
    direction: "ltr",
    getPropertyValue: () => "",
  });
  const serializedCollect = vm.runInNewContext(`(${collect.toString()})`, {
    document: {
      querySelector: () => root,
      querySelectorAll: () => [],
      createTreeWalker: () => ({ nextNode: () => false }),
    },
    getComputedStyle,
    NodeFilter: { SHOW_TEXT: 4 },
  });

  const measured = serializedCollect({
    selector: "[data-preview='message-scroller']",
    properties: [],
    attributes: [],
  });

  assert.deepEqual(measured.slots[0].semantic.className, "alpha beta item");
});

test("the collector omits geometry for an off-screen auto row even when checkVisibility is true", () => {
  const root = element({ box: { x: 0, y: 0, width: 336, height: 306 } });
  const viewport = element({
    parent: root,
    slot: "message-scroller-viewport",
    box: { x: 0, y: 0, width: 336, height: 306 },
  });
  const content = element({
    parent: viewport,
    slot: "message-scroller-content",
    box: { x: 0, y: -160, width: 336, height: 466 },
  });
  const item = element({
    parent: content,
    slot: "message-scroller-item",
    box: { x: 24, y: -160, width: 288, height: 160 },
    contentVisibility: "auto",
    checkVisibility: () => true,
  });

  root.children = [viewport];
  viewport.children = [content];
  content.children = [item];

  const measured = collectMeasure(root, (node) => {
    if (node.getAttribute("data-slot") === "message-scroller-viewport") return { overflowY: "auto" };
    if (node.getAttribute("data-slot") === "message-scroller-item") {
      return { contentVisibility: "auto", containIntrinsicSize: "auto 160px" };
    }

    return {};
  });
  const slots = new Map(measured.slots.map((entry) => [entry.slot, entry]));

  assert.equal(slots.get("message-scroller-viewport > message-scroller-content").lazyOffscreenDescendant, true);
  assert.equal(slots.get("message-scroller-viewport > message-scroller-content > message-scroller-item").geometryOmitted, true);
  assert.equal(slots.get("message-scroller-viewport > message-scroller-content > message-scroller-item").box, null);
});

test("the collector keeps geometry for a visible auto row", () => {
  const root = element({ box: { x: 0, y: 0, width: 336, height: 306 } });
  const viewport = element({
    parent: root,
    slot: "message-scroller-viewport",
    box: { x: 0, y: 0, width: 336, height: 306 },
  });
  const content = element({
    parent: viewport,
    slot: "message-scroller-content",
    box: { x: 0, y: 0, width: 336, height: 466 },
  });
  const item = element({
    parent: content,
    slot: "message-scroller-item",
    box: { x: 24, y: 24, width: 288, height: 160 },
    contentVisibility: "auto",
    checkVisibility: () => true,
  });

  root.children = [viewport];
  viewport.children = [content];
  content.children = [item];

  const measured = collectMeasure(root, (node) => {
    if (node.getAttribute("data-slot") === "message-scroller-viewport") return { overflowY: "auto" };
    if (node.getAttribute("data-slot") === "message-scroller-item") {
      return { contentVisibility: "auto", containIntrinsicSize: "auto 160px" };
    }

    return {};
  });
  const itemSlot = measured.slots.at(-1);

  assert.equal(itemSlot.geometryOmitted, false);
  assert.deepEqual({ ...itemSlot.box }, { x: 24, y: 24, width: 288, height: 160 });
});

test("semantic geometry ignores only off-screen lazy Message Scroller boxes", () => {
  const react = {
    whole: { width: 336, height: 306 },
    slots: [
      slot("message-scroller-viewport", { x: 0, y: 0, width: 336, height: 306 }),
      slot(
        "message-scroller-viewport > message-scroller-content",
        { x: 0, y: -1175, width: 336, height: 1602.75 },
        { lazyOffscreenDescendant: true },
      ),
      slot(
        "message-scroller-viewport > message-scroller-content > message-scroller-item",
        { x: 24, y: -1151, width: 288, height: 160 },
        { geometryOmitted: true },
      ),
    ],
  };
  const phoenix = {
    whole: { width: 336, height: 306 },
    slots: [
      slot("message-scroller-viewport", { x: 0, y: 0, width: 336, height: 306 }),
      slot(
        "message-scroller-viewport > message-scroller-content",
        { x: 0, y: -1079, width: 336, height: 1506.25 },
        { lazyOffscreenDescendant: true },
      ),
      slot(
        "message-scroller-viewport > message-scroller-content > message-scroller-item",
        { x: 24, y: -1055, width: 288, height: 63.5 },
        { geometryOmitted: true },
      ),
    ],
  };

  assert.deepEqual(compare(react, phoenix), []);
});

test("semantic geometry keeps a visible Message Scroller mismatch strict", () => {
  const react = {
    whole: { width: 336, height: 306 },
    slots: [
      slot("message-scroller-viewport", { x: 0, y: 0, width: 336, height: 306 }),
      slot(
        "message-scroller-viewport > message-scroller-content",
        { x: 0, y: -167, width: 336, height: 473 },
      ),
    ],
  };
  const phoenix = {
    whole: { width: 336, height: 306 },
    slots: [
      slot("message-scroller-viewport", { x: 0, y: 0, width: 336, height: 306 }),
      slot(
        "message-scroller-viewport > message-scroller-content",
        { x: 0, y: -111, width: 336, height: 417 },
      ),
    ],
  };

  assert.deepEqual(compare(react, phoenix), [
    {
      slot: "message-scroller-viewport > message-scroller-content",
      property: "y",
      react: -167,
      phoenix: -111,
    },
    {
      slot: "message-scroller-viewport > message-scroller-content",
      property: "height",
      react: 473,
      phoenix: 417,
    },
  ]);
});

test("semantic geometry keeps unrelated overflow nodes strict", () => {
  const react = {
    whole: { width: 336, height: 306 },
    slots: [
      slot("scroll-viewport", { x: 0, y: 0, width: 336, height: 306 }),
      slot("scroll-viewport > scroll-content", { x: 0, y: -160, width: 336, height: 466 }),
    ],
  };
  const phoenix = {
    whole: { width: 336, height: 306 },
    slots: [
      slot("scroll-viewport", { x: 0, y: 0, width: 336, height: 306 }),
      slot("scroll-viewport > scroll-content", { x: 0, y: -96, width: 336, height: 402 }),
    ],
  };

  assert.deepEqual(compare(react, phoenix), [
    { slot: "scroll-viewport > scroll-content", property: "y", react: -160, phoenix: -96 },
    { slot: "scroll-viewport > scroll-content", property: "height", react: 466, phoenix: 402 },
  ]);
});

test("semantic geometry keeps lazy item semantics and rendering facts strict", () => {
  const react = {
    whole: { width: 336, height: 306 },
    slots: [
      slot("message-scroller-viewport", { x: 0, y: 0, width: 336, height: 306 }),
      slot(
        "message-scroller-viewport > message-scroller-content > message-scroller-item",
        { x: 24, y: -1151, width: 288, height: 160 },
        { geometryOmitted: true },
      ),
    ],
  };
  const phoenix = {
    whole: { width: 336, height: 306 },
    slots: [
      slot("message-scroller-viewport", { x: 0, y: 0, width: 336, height: 306 }),
      slot(
        "message-scroller-viewport > message-scroller-content > message-scroller-item",
        { x: 24, y: -1055, width: 288, height: 63.5 },
        {
          geometryOmitted: true,
          semantic: {
            className: "cn-message-scroller-item",
            rendering: {
              contentVisibility: "visible",
              containIntrinsicSize: "none",
            },
          },
        },
      ),
    ],
  };

  assert.deepEqual(compare(react, phoenix), [
    {
      slot: "message-scroller-viewport > message-scroller-content > message-scroller-item",
      property: "class",
      react: "cn-message-scroller-item [content-visibility:auto]",
      phoenix: "cn-message-scroller-item",
    },
    {
      slot: "message-scroller-viewport > message-scroller-content > message-scroller-item",
      property: "content-visibility",
      react: "auto",
      phoenix: "visible",
    },
    {
      slot: "message-scroller-viewport > message-scroller-content > message-scroller-item",
      property: "contain-intrinsic-size",
      react: "auto 160px",
      phoenix: "none",
    },
  ]);
});

test("semantic geometry compares non-box facts when both lazy boxes are omitted", () => {
  const react = {
    whole: { width: 336, height: 306 },
    slots: [
      slot(
        "message-scroller-viewport > message-scroller-content > message-scroller-item",
        null,
        { geometryOmitted: true },
      ),
    ],
  };
  const phoenix = {
    whole: { width: 336, height: 306 },
    slots: [
      slot(
        "message-scroller-viewport > message-scroller-content > message-scroller-item",
        null,
        { geometryOmitted: true },
      ),
    ],
  };

  assert.deepEqual(compare(react, phoenix), []);
});

test("semantic geometry allows one omitted lazy box", () => {
  const react = {
    whole: { width: 336, height: 306 },
    slots: [
      slot(
        "message-scroller-viewport > message-scroller-content > message-scroller-item",
        { x: 24, y: -160, width: 288, height: 160 },
        { geometryOmitted: true },
      ),
    ],
  };
  const phoenix = {
    whole: { width: 336, height: 306 },
    slots: [
      slot(
        "message-scroller-viewport > message-scroller-content > message-scroller-item",
        null,
        { geometryOmitted: true },
      ),
    ],
  };

  assert.deepEqual(compare(react, phoenix), []);
});

test("semantic geometry reports a missing visible box", () => {
  const react = {
    whole: { width: 336, height: 306 },
    slots: [
      slot("message-scroller-viewport > message-scroller-content", { x: 0, y: -167, width: 336, height: 473 }),
    ],
  };
  const phoenix = {
    whole: { width: 336, height: 306 },
    slots: [slot("message-scroller-viewport > message-scroller-content", null)],
  };

  assert.deepEqual(compare(react, phoenix), [
    {
      slot: "message-scroller-viewport > message-scroller-content",
      property: "box",
      react: { x: 0, y: -167, width: 336, height: 473 },
      phoenix: null,
    },
  ]);
});
