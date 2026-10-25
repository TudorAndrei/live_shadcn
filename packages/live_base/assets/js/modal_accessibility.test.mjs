import assert from "node:assert/strict";
import test from "node:test";

class FakeObserver {
  observe() {}
  disconnect() {}
  takeRecords() { return []; }
}

class FakeNode {
  constructor(document, parent = null) {
    this.ownerDocument = document;
    this.parentElement = parent;
    this.children = [];
    this.attributes = new Map();
    this.isConnected = true;
    if (parent) parent.children.push(this);
  }

  matches() { return false; }
  contains(node) {
    for (let current = node; current; current = current.parentElement) {
      if (current === this) return true;
    }
    return false;
  }
  hasAttribute(name) { return this.attributes.has(name); }
  getAttribute(name) { return this.attributes.has(name) ? this.attributes.get(name) : null; }
  setAttribute(name, value) { this.attributes.set(name, String(value)); }
  removeAttribute(name) { this.attributes.delete(name); }
}

function fakeDocument() {
  const document = {
    defaultView: {
      MutationObserver: FakeObserver,
      getComputedStyle: () => ({ display: "block" }),
    },
    querySelectorAll: () => [],
    getElementById: () => null,
  };
  document.body = new FakeNode(document);
  return document;
}

test("independently bundled copies share one modal stack", async () => {
  // Each colocated hook bundle carries its own copy of this module.
  const first = await import("./modal_accessibility.js?copy=first");
  const second = await import("./modal_accessibility.js?copy=second");
  assert.notEqual(first, second);

  const document = fakeDocument();
  const background = new FakeNode(document, document.body);
  const drawer = new FakeNode(document, document.body);
  const dialog = new FakeNode(document, document.body);
  drawer.setAttribute("data-open", "");
  dialog.setAttribute("data-open", "");

  const drawerLease = first.holdAccessibility(drawer, () => new Set([drawer]));
  const dialogLease = second.holdAccessibility(dialog, () => new Set([dialog]));
  assert.equal(drawer.getAttribute("aria-hidden"), "true");

  // The drawer closes while the dialog stays open: the page behind must stay hidden.
  first.releaseAccessibility(drawerLease);
  assert.equal(background.getAttribute("aria-hidden"), "true");
  assert.equal(dialog.getAttribute("aria-hidden"), null);

  second.releaseAccessibility(dialogLease);
  for (const node of [background, drawer, dialog]) {
    assert.equal(node.getAttribute("aria-hidden"), null);
  }
});
