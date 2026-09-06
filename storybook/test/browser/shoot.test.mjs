import assert from "node:assert/strict";
import test from "node:test";
import { PNG } from "pngjs";

import { compare, paintedBoxInDocument } from "./shoot.mjs";

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
  const slot = element({ left: 110, top: 210, right: 190, bottom: 290 });
  const child = element({ left: 120, top: 220, right: 180, bottom: 280 });
  const nested = element({ left: 130, top: 230, right: 170, bottom: 270 });
  const ancestor = element({ left: 0, top: 0, right: 1280, bottom: 2048 });
  const fixed = element({ left: 320, top: 220, right: 420, bottom: 320 }, "fixed");

  root.querySelectorAll = () => [slot];
  root.children = [child];
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
    assert.equal(child.layoutReads, 1);
    assert.equal(fixed.layoutReads, 1);
    assert.deepEqual(box, { left: 10, top: 10, right: 320, bottom: 120 });
  });
});

function element(box, position = "static") {
  return {
    children: [],
    contains: () => false,
    getBoundingClientRect() {
      this.layoutReads = (this.layoutReads || 0) + 1;
      return { ...box, width: box.right - box.left, height: box.bottom - box.top };
    },
    layoutReads: 0,
    parentElement: null,
    position,
    querySelectorAll: () => [],
  };
}

function withDocument(document, callback) {
  const previousDocument = globalThis.document;
  const previousGetComputedStyle = globalThis.getComputedStyle;

  globalThis.document = document;
  globalThis.getComputedStyle = (element) => ({ position: element.position });

  try {
    callback();
  } finally {
    globalThis.document = previousDocument;
    globalThis.getComputedStyle = previousGetComputedStyle;
  }
}
