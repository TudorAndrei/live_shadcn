import assert from "node:assert/strict";
import test from "node:test";
import { PNG } from "pngjs";

import { compare, localise, paintedBoxInDocument as browserPaintedBox } from "./shoot.mjs";

// Playwright serializes the function without its module scope.
const paintedBoxInDocument = new Function(`return (${browserPaintedBox.toString()});`)();

function image(red, green, blue) {
  const png = new PNG({ width: 3, height: 3 });

  for (let offset = 0; offset < png.data.length; offset += 4) {
    png.data.set([red, green, blue, 255], offset);
  }

  return png;
}

test("compare reports exact matching pixels without a diagnostic image", () => {
  const result = compare(image(10, 20, 30), image(10, 20, 30));

  assert.equal(result.differing, 0);
  assert.equal(result.diff, undefined);
});

test("compare creates a diagnostic image for a differing pixel", () => {
  const result = compare(image(10, 20, 30), image(250, 240, 230));

  assert.equal(result.differing, 9);
  assert.deepEqual([...result.diff.data.slice(0, 4)], [255, 0, 0, 255]);
});

test("paintedBox skips root relatives in its outside-content scan", () => {
  const root = element({ left: 100, top: 200, right: 300, bottom: 400 });
  const slot = element({ left: 110, top: 210, right: 190, bottom: 290 }, { slot: "button" });
  const child = element({ left: 120, top: 220, right: 180, bottom: 280 });
  const nested = element({ left: 130, top: 230, right: 170, bottom: 270 }, { hidden: true });
  const ancestor = element({ left: 0, top: 0, right: 1280, bottom: 2048 });
  const fixed = element({ left: 320, top: 220, right: 420, bottom: 320 }, "fixed");

  child.children = [nested];
  nested.parentElement = child;
  root.children = [child];
  child.parentElement = root;

  root.querySelectorAll = (selector) => {
    if (selector === "[data-slot]") return [slot];
    if (selector === "*") return [slot, child, nested];
    return [];
  };

  root.contains = (candidate) =>
    candidate === root || candidate === slot || candidate === child || candidate === nested;
  ancestor.contains = (candidate) =>
    candidate === root || candidate === slot || candidate === child || candidate === nested;

  const body = {
    querySelectorAll: () => [ancestor, root, slot, child, nested, fixed],
  };
  fixed.parentElement = body;

  withDocument({ querySelector: () => root, body }, () => {
    const box = paintedBoxInDocument("[data-preview='button']");

    assert.equal(ancestor.layoutReads, 0);
    assert.equal(nested.layoutReads, 0);
    assert.equal(slot.layoutReads, 1);
    assert.equal(child.layoutReads, 3);
    assert.equal(fixed.layoutReads, 1);
    assert.deepEqual(box, { left: 10, top: 10, right: 320, bottom: 120 });
  });
});

test("paintedBox includes visible unslotted overflow inside the preview root", () => {
  const root = element({ left: 100, top: 200, right: 400, bottom: 500 });
  const slot = element({ left: 110, top: 210, right: 300, bottom: 400 }, { slot: "card" });
  const overflow = element({ left: 280, top: 350, right: 380, bottom: 450 });

  slot.parentElement = root;
  overflow.parentElement = slot;
  slot.children = [overflow];
  root.children = [slot];

  root.querySelectorAll = (selector) => {
    if (selector === "[data-slot]") return [slot];
    if (selector === "*") return [slot, overflow];
    return [];
  };

  root.contains = (candidate) => candidate === root || candidate === slot || candidate === overflow;

  withDocument({ querySelector: () => root, body: { querySelectorAll: () => [root, slot, overflow] } }, () => {
    const box = paintedBoxInDocument("[data-preview='card']");

    assert.deepEqual(box, { left: 10, top: 10, right: 280, bottom: 250 });
  });
});

test("paintedBox excludes overflow clipped by a hidden ancestor", () => {
  const root = element({ left: 100, top: 200, right: 400, bottom: 500 });
  const clipper = element({ left: 110, top: 210, right: 300, bottom: 400 }, { overflow: "hidden" });
  const overflow = element({ left: 280, top: 350, right: 380, bottom: 450 });

  clipper.parentElement = root;
  overflow.parentElement = clipper;
  clipper.children = [overflow];
  root.children = [clipper];

  root.querySelectorAll = (selector) => {
    if (selector === "[data-slot]") return [];
    if (selector === "*") return [clipper, overflow];
    return [];
  };

  root.contains = (candidate) => candidate === root || candidate === clipper || candidate === overflow;

  withDocument({ querySelector: () => root, body: { querySelectorAll: () => [root, clipper, overflow] } }, () => {
    const box = paintedBoxInDocument("[data-preview='card']");

    assert.deepEqual(box, { left: 10, top: 10, right: 200, bottom: 200 });
    assert.equal(overflow.layoutReads, 1);
  });
});

test("paintedBox excludes hidden descendants from unslotted overflow", () => {
  const root = element({ left: 100, top: 200, right: 400, bottom: 500 });
  const host = element({ left: 110, top: 210, right: 300, bottom: 400 });
  const hidden = element({ left: 280, top: 350, right: 380, bottom: 450 }, { hidden: true });

  host.parentElement = root;
  hidden.parentElement = host;
  host.children = [hidden];
  root.children = [host];

  root.querySelectorAll = (selector) => {
    if (selector === "[data-slot]") return [];
    if (selector === "*") return [host, hidden];
    return [];
  };

  root.contains = (candidate) => candidate === root || candidate === host || candidate === hidden;

  withDocument({ querySelector: () => root, body: { querySelectorAll: () => [root, host, hidden] } }, () => {
    const box = paintedBoxInDocument("[data-preview='card']");

    assert.deepEqual(box, { left: 10, top: 10, right: 200, bottom: 200 });
    assert.equal(hidden.layoutReads, 0);
  });
});

test("paintedBox ignores off-screen lazy descendants", () => {
  const root = element({ left: 100, top: 200, right: 400, bottom: 500 });
  const viewport = element(
    { left: 110, top: 210, right: 300, bottom: 400 },
    { overflowY: "auto" },
  );
  const lazy = element({ left: 120, top: 50, right: 280, bottom: 180 }, { contentVisibility: "auto" });

  viewport.parentElement = root;
  lazy.parentElement = viewport;
  viewport.children = [lazy];
  root.children = [viewport];

  root.querySelectorAll = (selector) => {
    if (selector === "[data-slot]") return [];
    if (selector === "*") return [viewport, lazy];
    return [];
  };

  root.contains = (candidate) => candidate === root || candidate === viewport || candidate === lazy;

  withDocument({ querySelector: () => root, body: { querySelectorAll: () => [root, viewport, lazy] } }, () => {
    const box = paintedBoxInDocument("[data-preview='message-scroller']");

    assert.deepEqual(box, { left: 10, top: 10, right: 200, bottom: 200 });
    assert.equal(lazy.layoutReads, 2);
  });
});

test("localise keeps unmatched pixels in the outside-slot bucket when slot boxes are null", () => {
  const diff = new Uint8Array(16);
  diff[0] = 255;
  diff[4] = 255;

  const regions = localise(diff, 2, 2, [{ slot: "card", box: null }], {
    origin: { x: 0, y: 0 },
    clip: { x: 0, y: 0 },
    scale: 1,
  });

  assert.deepEqual(regions, [{ slot: "outside any slot", count: 2 }]);
});

test("overflow outside a slot box produces a pixel difference in the outside-slot bucket", () => {
  const react = image(10, 20, 30);
  const phoenix = image(250, 240, 230);

  const result = compare(react, phoenix);
  const regions = localise(result.diff.data, result.width, result.height, [
    { slot: "card", box: { x: 0, y: 0, width: 1, height: 1 } },
  ]);

  assert.equal(result.differing, 9);
  assert.ok(regions.some(({ slot, count }) => slot === "card" && count > 0));
  assert.ok(regions.some(({ slot, count }) => slot === "outside any slot" && count > 0));
});

test("paintedBox keeps portalled content outside the preview root", () => {
  const root = element({ left: 100, top: 200, right: 200, bottom: 300 });
  const portalled = element({ left: 320, top: 220, right: 420, bottom: 320 });

  root.querySelectorAll = (selector) => (selector === "[data-slot]" || selector === "*" ? [] : []);
  root.children = [];
  root.contains = (candidate) => candidate === root;

  const body = {
    querySelectorAll: () => [root, portalled],
  };
  portalled.parentElement = body;

  withDocument({ querySelector: () => root, body }, () => {
    const box = paintedBoxInDocument("[data-preview='toast']");

    assert.deepEqual(box, { left: 220, top: 20, right: 320, bottom: 120 });
  });
});

function element(box, options = {}) {
  const position = typeof options === "string" ? options : options.position || "static";

  return {
    children: [],
    contains: () => false,
    getAttribute(name) {
      if (name === "data-slot") return options.slot ?? null;
      if (name === "aria-hidden") return options.ariaHidden ?? null;
      return null;
    },
    getBoundingClientRect() {
      this.layoutReads = (this.layoutReads || 0) + 1;
      return { ...box, width: box.right - box.left, height: box.bottom - box.top };
    },
    hasAttribute(name) {
      return name === "data-slot" ? Boolean(options.slot) : name === "hidden" ? Boolean(options.hidden) : false;
    },
    hidden: Boolean(options.hidden),
    layoutReads: 0,
    parentElement: null,
    position,
    querySelectorAll: () => [],
    checkVisibility() {
      return !this.hidden && options.ariaHidden !== "true";
    },
    overflow: options.overflow,
    overflowY: options.overflowY,
    contentVisibility: options.contentVisibility,
  };
}

function withDocument(document, callback) {
  const previousDocument = globalThis.document;
  const previousGetComputedStyle = globalThis.getComputedStyle;

  globalThis.document = document;
  globalThis.getComputedStyle = (element) => ({
    position: element.position,
    overflow: element.overflow ?? "visible",
    overflowX: element.overflowX ?? "visible",
    overflowY: element.overflowY ?? "visible",
    display: element.hidden ? "none" : "block",
    visibility: "visible",
    opacity: "1",
    contentVisibility: element.contentVisibility ?? "visible",
  });

  try {
    callback();
  } finally {
    globalThis.document = previousDocument;
    globalThis.getComputedStyle = previousGetComputedStyle;
  }
}
