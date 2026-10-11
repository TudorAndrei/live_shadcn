import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import test from "node:test";
import vm from "node:vm";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const rootLayout = readFileSync(join(here, "../../lib/storybook_web/layouts/root.html.heex"), "utf8");
const inlineOpeningScript = rootLayout.match(
  /<script nonce=\{assigns\[:csp_nonce\]\} phx-no-curly-interpolation>\s*([\s\S]*?)\s*<\/script>/,
)?.[1];

class FakeElement {
  constructor(attributes = {}) {
    this.attributes = new Map(Object.entries(attributes));
    this.children = [];
    this.id = attributes.id || "";
  }

  getAttribute(name) {
    return this.attributes.get(name) ?? null;
  }

  hasAttribute(name) {
    return this.attributes.has(name);
  }

  removeAttribute(name) {
    this.attributes.delete(name);
  }
}

function runOpeningScript({ consumer = false, unheld = false } = {}) {
  assert.ok(inlineOpeningScript, "the root layout has an inline opening script");

  const root = new FakeElement({
    id: "visibility-root",
    "data-lb-message-scroller": "",
    "data-lb-message-default-position": "end",
    "data-pending-scroll": "",
    ...(unheld ? { "data-lb-message-opening-hold": "false" } : {}),
  });
  const viewport = new FakeElement({
    "data-lb-message-scroller-viewport": "",
    "data-pending-scroll": "",
  });
  const content = new FakeElement();
  const item = new FakeElement({ "data-lb-message-intrinsic-size": "auto 10rem" });
  const secondItem = new FakeElement({ "data-lb-message-intrinsic-size": "auto 10rem" });
  let writes = 0;
  let target = null;
  const itemStyleReads = [];

  viewport.scrollHeight = 515;
  viewport.clientHeight = unheld ? 100 : 415;
  Object.defineProperty(viewport, "scrollTop", {
    get: () => writes === 0 ? 0 : 100,
    set: (value) => {
      writes += 1;
      target = value;
    },
  });
  viewport.closest = () => root;
  viewport.querySelector = () => content;
  root.querySelectorAll = () => [viewport];
  content.children = [item, secondItem];

  const outline = new FakeElement({
    "data-message-scroller-outline": "",
    "data-message-scroller-controller": "visibility-root",
  });
  const document = {
    querySelectorAll(selector) {
      if (selector.startsWith("[data-lb-message-scroller]")) return [root];
      if (selector === "[data-message-scroller-outline]") return consumer ? [outline] : [];
      return [];
    },
  };

  vm.runInNewContext(inlineOpeningScript, {
    document,
    HTMLElement: FakeElement,
    getComputedStyle: (element) => {
      if (element === content) {
        return { paddingTop: "0px", paddingBottom: "0px", rowGap: "0px", gap: "0px" };
      }

      itemStyleReads.push(element);
      return { containIntrinsicSize: "auto 160px" };
    },
  });

  return { root, viewport, writes, target, item, secondItem, itemStyleReads };
}

test("the root opening script keeps a visibility consumer pending for Scroller", () => {
  const { root, viewport, writes } = runOpeningScript({ consumer: true });

  assert.equal(writes, 0);
  assert.equal(root.hasAttribute("data-pending-scroll"), true);
  assert.equal(viewport.hasAttribute("data-pending-scroll"), true);
});

test("the root opening script keeps pre-live scroll for roots without a visibility consumer", () => {
  const { root, viewport, writes } = runOpeningScript();

  assert.equal(writes, 1);
  assert.equal(root.hasAttribute("data-pending-scroll"), false);
  assert.equal(viewport.hasAttribute("data-pending-scroll"), false);
});

test("the root opening script pre-scrolls an unheld opening for Scroller", () => {
  const { root, viewport, writes, target, itemStyleReads } = runOpeningScript({ unheld: true });

  assert.equal(writes, 1);
  assert.equal(target, 515);
  assert.equal(root.hasAttribute("data-pending-scroll"), true);
  assert.equal(viewport.hasAttribute("data-pending-scroll"), true);
  assert.equal(viewport.__liveBaseMessageOpeningApplied, true);
  assert.equal(viewport.__liveBaseMessageOpeningTop, undefined);
  assert.deepEqual(itemStyleReads, []);
});
