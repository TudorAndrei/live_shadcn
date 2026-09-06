import assert from "node:assert/strict";
import test from "node:test";

import { OpeningPosition, openingPositionRequest } from "./opening_position.js";

test("Opening Position creates the pinned scroll request for each selected tab", () => {
  assert.deepEqual(openingPositionRequest("start"), { direction: "start", behavior: "auto" });
  assert.deepEqual(openingPositionRequest("end"), { direction: "end", behavior: "auto" });
  assert.deepEqual(openingPositionRequest("last-anchor"), {
    id: "open-3",
    align: "start",
    behavior: "auto",
    scrollMargin: 64,
  });
  assert.equal(openingPositionRequest("middle"), null);
});

test("Opening Position waits for the initial end opening to settle before it dispatches last-anchor", () => {
  const previousDocument = globalThis.document;
  const previousRequestAnimationFrame = globalThis.requestAnimationFrame;
  const previousCancelAnimationFrame = globalThis.cancelAnimationFrame;
  const previousMutationObserver = globalThis.MutationObserver;
  const previousCustomEvent = globalThis.CustomEvent;
  const requests = [];
  const frames = [];
  const observers = [];
  let pending = true;
  const target = {
    hasAttribute(name) { return name === "data-pending-scroll" && pending; },
    dispatchEvent(event) { requests.push(event.detail); },
  };
  const selected = {
    id: "message-scroller-opening-tabs-tab-last-anchor",
    closest() { return this; },
  };
  const element = {
    id: "message-scroller-opening-tabs",
    getAttribute(name) {
      return name === "data-lb-opening-position-target" ? "message-scroller-opening" : null;
    },
    querySelector() { return selected; },
    contains() { return true; },
    addEventListener() {},
    removeEventListener() {},
  };
  const hook = { el: element, pushEvent() {} };

  globalThis.document = { getElementById: () => target };
  globalThis.requestAnimationFrame = (callback) => {
    frames.push(callback);
    return frames.length;
  };
  globalThis.cancelAnimationFrame = () => {};
  globalThis.MutationObserver = class {
    constructor(callback) {
      this.callback = callback;
      observers.push(this);
    }
    observe() {}
    disconnect() {}
  };
  globalThis.CustomEvent = class {
    constructor(type, init) {
      this.type = type;
      this.detail = init?.detail;
    }
  };

  try {
    OpeningPosition.mounted.call(hook);
    frames.shift()();
    assert.deepEqual(requests, []);
    assert.equal(observers.length, 1);

    pending = false;
    observers[0].callback([{ attributeName: "data-pending-scroll" }]);
    assert.deepEqual(requests, [{
      id: "open-3",
      align: "start",
      behavior: "auto",
      scrollMargin: 64,
    }]);
    assert.equal(frames.length, 0);
  } finally {
    globalThis.document = previousDocument;
    globalThis.requestAnimationFrame = previousRequestAnimationFrame;
    globalThis.cancelAnimationFrame = previousCancelAnimationFrame;
    globalThis.MutationObserver = previousMutationObserver;
    globalThis.CustomEvent = previousCustomEvent;
  }
});

test("Opening Position cancels an initial pending command when the hook is destroyed", () => {
  const previousDocument = globalThis.document;
  const previousRequestAnimationFrame = globalThis.requestAnimationFrame;
  const previousCancelAnimationFrame = globalThis.cancelAnimationFrame;
  const previousMutationObserver = globalThis.MutationObserver;
  const previousCustomEvent = globalThis.CustomEvent;
  const requests = [];
  const frames = [];
  const observers = [];
  let pending = true;
  const target = {
    hasAttribute(name) { return name === "data-pending-scroll" && pending; },
    dispatchEvent(event) { requests.push(event.detail); },
  };
  const selected = {
    id: "message-scroller-opening-tabs-tab-last-anchor",
    closest() { return this; },
  };
  const element = {
    id: "message-scroller-opening-tabs",
    getAttribute(name) {
      return name === "data-lb-opening-position-target" ? "message-scroller-opening" : null;
    },
    querySelector() { return selected; },
    contains() { return true; },
    addEventListener() {},
    removeEventListener() {},
  };
  const hook = { el: element, pushEvent() {} };

  globalThis.document = { getElementById: () => target };
  globalThis.requestAnimationFrame = (callback) => {
    frames.push(callback);
    return frames.length;
  };
  globalThis.cancelAnimationFrame = () => {};
  globalThis.MutationObserver = class {
    constructor(callback) {
      this.callback = callback;
      observers.push(this);
    }
    observe() {}
    disconnect() {}
  };
  globalThis.CustomEvent = class {
    constructor(type, init) {
      this.type = type;
      this.detail = init?.detail;
    }
  };

  try {
    OpeningPosition.mounted.call(hook);
    frames.shift()();
    OpeningPosition.destroyed.call(hook);

    pending = false;
    observers[0].callback([{ attributeName: "data-pending-scroll" }]);
    assert.deepEqual(requests, []);
    assert.deepEqual(frames, []);
  } finally {
    globalThis.document = previousDocument;
    globalThis.requestAnimationFrame = previousRequestAnimationFrame;
    globalThis.cancelAnimationFrame = previousCancelAnimationFrame;
    globalThis.MutationObserver = previousMutationObserver;
    globalThis.CustomEvent = previousCustomEvent;
  }
});

test("Opening Position dispatches the selected command in the first rAF after an unheld opening", () => {
  const previousDocument = globalThis.document;
  const previousRequestAnimationFrame = globalThis.requestAnimationFrame;
  const previousCancelAnimationFrame = globalThis.cancelAnimationFrame;
  const previousCustomEvent = globalThis.CustomEvent;
  const requests = [];
  const events = [];
  const target = {
    hasAttribute() {
      return false;
    },
    dispatchEvent(event) {
      requests.push(event.detail);
    },
  };
  const tabs = ["start", "end", "last-anchor"].map((position) => ({
    id: `message-scroller-opening-tabs-tab-${position}`,
    closest() {
      return this;
    },
  }));
  let selected = 2;
  const element = {
    id: "message-scroller-opening-tabs",
    getAttribute(name) {
      return name === "data-lb-opening-position-target" ? "message-scroller-opening" : null;
    },
    querySelector() {
      return tabs[selected];
    },
    contains(tab) {
      return tabs.includes(tab);
    },
    addEventListener() {},
    removeEventListener() {},
  };
  const hook = {
    el: element,
    pushEvent(name, payload) {
      events.push([name, payload]);
    },
  };

  globalThis.document = { getElementById: () => target };
  const frames = [];
  globalThis.requestAnimationFrame = (callback) => {
    frames.push(callback);
    return frames.length;
  };
  globalThis.cancelAnimationFrame = () => {};
  globalThis.CustomEvent = class {
    constructor(type, init) {
      this.type = type;
      this.detail = init?.detail;
    }
  };

  try {
    OpeningPosition.mounted.call(hook);
    frames.shift()();

    hook.onClick({ target: tabs[0] });
    assert.deepEqual(requests, [
      {
        id: "open-3",
        align: "start",
        behavior: "auto",
        scrollMargin: 64,
      },
    ]);

    selected = 0;
    assert.equal(frames.length, 1);
    frames.shift()();

    assert.deepEqual(requests, [
      {
        id: "open-3",
        align: "start",
        behavior: "auto",
        scrollMargin: 64,
      },
      { direction: "start", behavior: "auto" },
    ]);
    assert.deepEqual(events, [
      ["message_scroller_opening_position", { position: "start" }],
    ]);
  } finally {
    globalThis.document = previousDocument;
    globalThis.requestAnimationFrame = previousRequestAnimationFrame;
    globalThis.cancelAnimationFrame = previousCancelAnimationFrame;
    globalThis.CustomEvent = previousCustomEvent;
  }
});

test("Opening Position keeps only the final rapid click command", () => {
  const previousDocument = globalThis.document;
  const previousRequestAnimationFrame = globalThis.requestAnimationFrame;
  const previousCancelAnimationFrame = globalThis.cancelAnimationFrame;
  const previousCustomEvent = globalThis.CustomEvent;
  const requests = [];
  const events = [];
  const frames = new Map();
  let frameId = 0;
  const target = { dispatchEvent(event) { requests.push(event.detail); } };
  const tabs = ["start", "end", "last-anchor"].map((position) => ({
    id: `message-scroller-opening-tabs-tab-${position}`,
    closest() { return this; },
  }));
  const element = {
    id: "message-scroller-opening-tabs",
    getAttribute(name) {
      return name === "data-lb-opening-position-target" ? "message-scroller-opening" : null;
    },
    querySelector() { return tabs[0]; },
    contains(tab) { return tabs.includes(tab); },
    addEventListener() {},
    removeEventListener() {},
  };
  const hook = {
    el: element,
    pushEvent(name, payload) { events.push([name, payload]); },
  };

  globalThis.document = { getElementById: () => target };
  globalThis.requestAnimationFrame = (callback) => {
    frameId += 1;
    frames.set(frameId, callback);
    return frameId;
  };
  globalThis.cancelAnimationFrame = (id) => frames.delete(id);
  globalThis.CustomEvent = class {
    constructor(type, init) {
      this.type = type;
      this.detail = init?.detail;
    }
  };

  try {
    OpeningPosition.mounted.call(hook);
    hook.onClick({ target: tabs[0] });
    hook.onClick({ target: tabs[1] });
    hook.onClick({ target: tabs[2] });

    assert.equal(frames.size, 1);
    [...frames.values()][0]();
    assert.deepEqual(requests, [{
      id: "open-3",
      align: "start",
      behavior: "auto",
      scrollMargin: 64,
    }]);
    assert.deepEqual(events, [
      ["message_scroller_opening_position", { position: "start" }],
      ["message_scroller_opening_position", { position: "end" }],
      ["message_scroller_opening_position", { position: "last-anchor" }],
    ]);
  } finally {
    globalThis.document = previousDocument;
    globalThis.requestAnimationFrame = previousRequestAnimationFrame;
    globalThis.cancelAnimationFrame = previousCancelAnimationFrame;
    globalThis.CustomEvent = previousCustomEvent;
  }
});
