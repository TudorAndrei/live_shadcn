import assert from "node:assert/strict";
import test from "node:test";

import { Scroller } from "./scroller.js";

test("Message Scroller refreshes button state after intrinsic rows settle on resize", () => {
  const attributes = new Map([["data-active", "true"]]);
  const button = {
    tabIndex: 0,
    getAttribute(name) {
      return name === "data-direction" ? "end" : attributes.get(name) || null;
    },
    setAttribute(name, value) {
      attributes.set(name, value);
    },
    toggleAttribute(name, enabled) {
      if (enabled) attributes.set(name, "");
      else attributes.delete(name);
    },
  };
  const viewport = {
    scrollTop: 0,
    scrollHeight: 160,
    clientHeight: 100,
    setAttribute() {},
    removeAttribute() {},
    toggleAttribute() {},
    dispatchEvent() {},
  };
  const hook = {
    messageScroller: true,
    viewport,
    messageRoot: {
      querySelectorAll(selector) {
        return selector === "[data-slot='message-scroller-button']" ? [button] : [];
      },
      setAttribute() {},
      removeAttribute() {},
      toggleAttribute() {},
    },
    messageThreshold: 8,
    messageVisibilityEnabled: false,
    messageOpeningFrozenTop: null,
    messageOpeningHold: false,
    sticky: false,
    measure() {},
    reanchorMessageItem() {},
    finishPendingScroll() {},
    syncMessageScrollStateBindings() {},
    atMessageStart: Scroller.atMessageStart,
    atMessageEnd: Scroller.atMessageEnd,
    syncMessageState: Scroller.syncMessageState,
  };

  assert.equal(button.getAttribute("data-active"), "true");

  viewport.scrollHeight = 103;
  Scroller.resized.call(hook);

  assert.equal(button.getAttribute("data-active"), "false");
  assert.equal(button.tabIndex, -1);
});

test("Message Scroller commits its unheld opening before observers and measurement", () => {
  const calls = [];
  const frames = [];
  const previousResizeObserver = globalThis.ResizeObserver;
  const previousRequestAnimationFrame = globalThis.requestAnimationFrame;
  globalThis.ResizeObserver = class {
    observe() {
      calls.push("observe");
    }
  };
  globalThis.requestAnimationFrame = (callback) => {
    calls.push("frame");
    frames.push(callback);
    return frames.length;
  };

  const root = {
    hasAttribute() {
      return false;
    },
    getAttribute(name) {
      return name === "data-lb-message-opening-hold" ? "false" : null;
    },
    querySelector(selector) {
      return selector === "[data-lb-scroller]" ? viewport : null;
    },
    querySelectorAll() {
      return [];
    },
  };
  const viewport = {
    children: [],
    clientHeight: 100,
    scrollHeight: 300,
    scrollTop: 0,
    hasAttribute(name) {
      return name === "data-lb-message-scroller-viewport";
    },
    closest() {
      return root;
    },
    addEventListener() {},
    scrollTo({ top }) {
      calls.push("scroll");
      this.scrollTop = top;
    },
  };
  const hook = {
    el: root,
    installMessageScroller() {
      this.messageOpened = false;
      this.messageOpeningHold = false;
    },
    animateMessageScrollerItems() {},
    applyInitialUnheldMessageOpeningPosition: Scroller.applyInitialUnheldMessageOpeningPosition,
    clearMessageSpacer() {
      calls.push("clear");
    },
    markMessageAutoscrolling() {
      calls.push("autoscroll");
    },
    commitMessageScrollState() {
      calls.push("commit");
    },
    scheduleMessageScrollStateCommit: Scroller.scheduleMessageScrollStateCommit,
    measure() {
      calls.push("measure");
    },
    syncMessageState() {
      calls.push("state");
    },
  };

  try {
    Scroller.mounted.call(hook);

    assert.deepEqual(calls, ["clear", "autoscroll", "commit", "scroll", "frame", "commit", "observe", "measure", "state"]);
    assert.equal(hook.messageOpened, true);

    frames.shift()();
    assert.deepEqual(calls, ["clear", "autoscroll", "commit", "scroll", "frame", "commit", "observe", "measure", "state", "commit"]);
  } finally {
    globalThis.ResizeObserver = previousResizeObserver;
    globalThis.requestAnimationFrame = previousRequestAnimationFrame;
  }
});

test("Message Scroller state commit reads every row rectangle exactly once", () => {
  const reads = [];
  const first = {
    getBoundingClientRect() {
      reads.push("first");
      return { bottom: 140 };
    },
  };
  const second = {
    getBoundingClientRect() {
      reads.push("second");
      return { bottom: 300 };
    },
  };
  const viewport = {
    scrollTop: 50,
    getBoundingClientRect() {
      return { top: 100 };
    },
  };
  let committed = null;
  const hook = {
    viewport,
    messageContentPadding() {
      return { start: 8, end: 12 };
    },
    messageItems() {
      return [first, second];
    },
    messageMeasuredContentBottom: Scroller.messageMeasuredContentBottom,
    syncMessageState(contentBottom) {
      committed = contentBottom;
    },
    commitMessageScrollState: Scroller.commitMessageScrollState,
  };

  Scroller.commitMessageScrollState.call(hook);

  assert.deepEqual(reads, ["first", "second"]);
  assert.equal(committed, 262);
});

test("Message Scroller preserves the first visible row when a prepend occurs at the end", () => {
  const oldFirst = { id: "m1" };
  const visible = { id: "m3" };
  const prepended = { id: "old-1" };
  const content = {
    firstElementChild: prepended,
    querySelector(selector) {
      return selector.includes("m3") ? visible : null;
    },
  };
  const viewport = {
    scrollTop: 320,
    getAttribute(name) {
      return name === "data-lb-message-preserve-prepend" ? "true" : null;
    },
    querySelector() {
      return content;
    },
  };

  let synchronized = false;
  const hook = {
    viewport,
    messageContent: null,
    messageSpacer: null,
    messageBeforeUpdate: {
      first: "m1",
      firstVisible: { id: "m3", viewportTop: 24 },
      count: 4,
      height: 640,
      top: 320,
      atEnd: true,
    },
    messageItems() {
      return [prepended, oldFirst, visible];
    },
    messageElementViewportTop(item) {
      return item === visible ? 72 : 0;
    },
    syncMessageState() {
      synchronized = true;
    },
  };

  for (const item of hook.messageItems()) {
    item.getAttribute = (name) => (name === "data-message-id" ? item.id : null);
  }

  Scroller.reconcileMessagePatch.call(hook);

  assert.equal(viewport.scrollTop, 368);
  assert.equal(synchronized, true);
  assert.equal(hook.messageBeforeUpdate, null);
});

test("Message Scroller preserves a retained row without realizing prepended lazy rows", () => {
  let prependedGeometryReads = 0;
  let retainedGeometryReads = 0;
  let allRowReads = 0;
  const prepended = {
    style: { containIntrinsicSize: "auto 160px" },
    getAttribute(name) {
      return name === "data-message-id" ? "old-1" : null;
    },
    getBoundingClientRect() {
      prependedGeometryReads += 1;
      return { height: 63.5, top: -136 };
    },
  };
  const retained = {
    getAttribute(name) {
      return name === "data-message-id" ? "m3" : null;
    },
    getBoundingClientRect() {
      retainedGeometryReads += 1;
      return { top: 72 };
    },
  };
  const content = {
    firstElementChild: prepended,
    querySelector(selector) {
      return selector.includes("m3") ? retained : null;
    },
  };
  const viewport = {
    scrollTop: 320,
    getAttribute(name) {
      return name === "data-lb-message-preserve-prepend" ? "true" : null;
    },
    querySelector() {
      return content;
    },
  };
  const hook = {
    viewport,
    messageContent: null,
    messageSpacer: null,
    messageBeforeUpdate: {
      first: "m1",
      firstVisible: { id: "m3", viewportTop: 24 },
      count: 4,
      height: 640,
      top: 320,
      atEnd: true,
    },
    messageItems() {
      allRowReads += 1;
      return [prepended, retained];
    },
    messageElementViewportTop(item) {
      return item.getBoundingClientRect().top;
    },
    syncMessageState() {},
  };

  Scroller.reconcileMessagePatch.call(hook);

  assert.equal(viewport.scrollTop, 368);
  assert.equal(retainedGeometryReads, 1);
  assert.equal(prependedGeometryReads, 0);
  assert.equal(allRowReads, 0);
});

test("Message Scroller restores a prepended anchor before it measures the new layout", () => {
  const calls = [];
  const hook = {
    messageScroller: true,
    messageOpeningHold: false,
    refreshMessageScrollerConfig() {},
    animateMessageScrollerItems() {},
    applyUpdatedMessageOpeningPosition() {
      return false;
    },
    applyMessageOpeningPosition() {
      return false;
    },
    reconcileMessagePatch() {
      calls.push("restore");
    },
    measure() {
      calls.push("measure");
    },
    syncMessageState() {
      calls.push("state");
    },
  };

  Scroller.updated.call(hook);

  assert.deepEqual(calls, ["restore", "measure", "state"]);
});

test("Message Scroller reconciles an appended anchor while its mount opening settles", () => {
  const calls = [];
  const existing = {
    dataset: { scrollAnchor: "false" },
    getAttribute(name) {
      return name === "data-message-id" ? "existing" : null;
    },
  };
  const appended = {
    dataset: { scrollAnchor: "true" },
    getAttribute(name) {
      return name === "data-message-id" ? "appended-anchor" : null;
    },
  };
  const hook = {
    messageScroller: true,
    messageOpeningHold: true,
    messageBeforeUpdate: { first: "existing", firstVisible: null, count: 1 },
    messageContent: { firstElementChild: existing },
    messageHandledAnchors: new WeakSet(),
    sticky: false,
    viewport: {
      getAttribute() {
        return null;
      },
      querySelector() {
        return null;
      },
    },
    refreshMessageScrollerConfig() {},
    animateMessageScrollerItems() {},
    applyUpdatedMessageOpeningPosition() {
      return false;
    },
    settleMessageOpeningPosition() {
      calls.push("settle");
      return true;
    },
    messageItems() {
      return [existing, appended];
    },
    scrollMessageToElement(item, options) {
      calls.push(`${item.getAttribute("data-message-id")}:${options.keepPreviousPeek}`);
      return true;
    },
    measure() {
      calls.push("measure");
    },
    syncMessageState() {
      calls.push("state");
    },
    reconcileMessagePatch: Scroller.reconcileMessagePatch,
  };

  Scroller.updated.call(hook);

  assert.deepEqual(calls, ["settle", "appended-anchor:true", "measure", "state"]);
  assert.equal(hook.messageHandledAnchors.has(appended), true);
});

test("Message Scroller resets after LiveView commits the replacement transcript", () => {
  const writes = [];
  const attributes = new Map([
    ["data-lb-message-default-position", "end"],
    ["data-lb-message-opening-generation", "1"],
  ]);
  const viewport = {
    clientHeight: 267,
    scrollHeight: 267,
    scrollTop: 95,
    scrollTo({ top }) {
      writes.push(top);
      this.scrollTop = top;
    },
    setAttribute() {},
    removeAttribute() {},
  };
  const root = {
    getAttribute(name) {
      if (name === "data-lb-message-opening-hold") return "false";
      return attributes.get(name) || null;
    },
    setAttribute() {},
    removeAttribute() {},
  };
  const hook = {
    messageScroller: true,
    viewport,
    messageRoot: root,
    messageDefaultPosition: "end",
    messageOpeningGeneration: "0",
    messageOpened: true,
    messageOpeningFrozenTop: null,
    messageOpeningHold: false,
    messageOpeningSawLayout: false,
    messageOpeningStableFrames: 0,
    messageOpeningTarget: null,
    messageAnchoredItem: { id: "old-anchor" },
    messageSpacerHeight: 0,
    pendingTargets: [],
    refreshMessageScrollerConfig() {},
    animateMessageScrollerItems() {},
    messageItems() {
      return [{ id: "msg-1" }, { id: "msg-2" }];
    },
    clearMessageSpacer() {},
    markMessageAutoscrolling() {},
    atMessageEnd: Scroller.atMessageEnd,
    syncMessageState() {},
    finishPendingScroll() {},
    measure() {},
    applyMessageOpeningPosition: Scroller.applyMessageOpeningPosition,
    applyUpdatedMessageOpeningPosition: Scroller.applyUpdatedMessageOpeningPosition,
    restartMessageOpeningPosition: Scroller.restartMessageOpeningPosition,
    scrollMessageToEnd: Scroller.scrollMessageToEnd,
  };

  Scroller.updated.call(hook);

  assert.deepEqual(writes, [0]);
  assert.equal(viewport.scrollTop, 0);
  assert.equal(hook.messageOpeningGeneration, "1");
  assert.equal(hook.messageAnchoredItem, null);
});

test("Message Scroller resets a generation at its intrinsic end before lazy rows paint", () => {
  const writes = [];
  const attributes = new Map([
    ["data-lb-message-default-position", "end"],
    ["data-lb-message-opening-generation", "0"],
  ]);
  const content = { kind: "content" };
  const items = ["first", "second"].map((kind) => ({
    kind,
    getAttribute(name) {
      return name === "data-lb-message-intrinsic-size" ? "same" : null;
    },
  }));
  const previous = globalThis.getComputedStyle;

  globalThis.getComputedStyle = (element) => {
    if (element === content) {
      return {
        paddingTop: "16px",
        paddingBottom: "24px",
        rowGap: "12px",
        gap: "12px",
      };
    }

    return { containIntrinsicSize: "auto 174px" };
  };

  try {
    const viewport = {
      clientHeight: 267,
      scrollTop: 228,
      get scrollHeight() {
        throw new Error("a generation reset must not use the painted native end");
      },
      scrollTo({ top }) {
        writes.push(top);
        this.scrollTop = top;
      },
      setAttribute() {},
      removeAttribute() {},
    };
    const root = {
      getAttribute(name) {
        if (name === "data-lb-message-opening-hold") return "false";
        return attributes.get(name) || null;
      },
      setAttribute() {},
      removeAttribute() {},
    };
    const hook = {
      viewport,
      messageRoot: root,
      messageContent: content,
      messageDefaultPosition: "end",
      messageOpeningGeneration: "0",
      messageOpened: true,
      messageOpeningFrozenTop: null,
      messageOpeningHold: false,
      messageOpeningSawLayout: false,
      messageOpeningStableFrames: 0,
      messageOpeningTarget: null,
      messageOpeningUsesIntrinsicLayout: false,
      messageAnchoredItem: { id: "old-anchor" },
      pendingTargets: [],
      messageItems() {
        return items;
      },
      clearMessageSpacer() {},
      markMessageAutoscrolling() {},
      atMessageEnd() {
        return false;
      },
      syncMessageState() {},
      finishPendingScroll() {},
      messageVirtualContentEnd: Scroller.messageVirtualContentEnd,
      applyMessageOpeningPosition: Scroller.applyMessageOpeningPosition,
      applyUpdatedMessageOpeningPosition: Scroller.applyUpdatedMessageOpeningPosition,
      restartMessageOpeningPosition: Scroller.restartMessageOpeningPosition,
      scrollMessageToEnd: Scroller.scrollMessageToEnd,
    };

    attributes.set("data-lb-message-opening-generation", "1");
    assert.equal(Scroller.applyUpdatedMessageOpeningPosition.call(hook), true);
    assert.deepEqual(writes, [133]);
    assert.equal(viewport.scrollTop, 133);
    assert.equal(hook.messageOpeningUsesIntrinsicLayout, true);
  } finally {
    globalThis.getComputedStyle = previous;
  }
});

test("Message Scroller opens a reset from its replacement transcript subtree", () => {
  const writes = [];
  const oldSpacer = { hidden: false, style: { height: "95px", marginTop: "" } };
  const newSpacer = { hidden: true, style: { height: "", marginTop: "" } };
  const oldContent = { querySelector() { return oldSpacer; } };
  const newContent = { querySelector() { return newSpacer; } };
  const attributes = new Map([
    ["data-lb-message-default-position", "end"],
    ["data-lb-message-opening-generation", "1"],
  ]);
  const viewport = {
    clientHeight: 267,
    scrollTop: 228,
    querySelector() {
      return newContent;
    },
    get scrollHeight() {
      return hook.messageSpacer === newSpacer ? 400 : 495;
    },
    scrollTo({ top }) {
      writes.push(top);
      this.scrollTop = top;
    },
    setAttribute() {},
    removeAttribute() {},
  };
  const root = {
    getAttribute(name) {
      if (name === "data-lb-message-opening-hold") return "false";
      return attributes.get(name) || null;
    },
    setAttribute() {},
    removeAttribute() {},
  };
  const hook = {
    messageScroller: true,
    viewport,
    messageRoot: root,
    messageContent: oldContent,
    messageSpacer: oldSpacer,
    messageSpacerHeight: 95,
    messageDefaultPosition: "end",
    messageOpeningGeneration: "0",
    messageOpened: true,
    messageOpeningFrozenTop: null,
    messageOpeningHold: false,
    messageOpeningSawLayout: false,
    messageOpeningStableFrames: 0,
    messageOpeningTarget: null,
    messageAnchoredItem: { id: "old-anchor" },
    pendingTargets: [],
    refreshMessageScrollerConfig() {},
    animateMessageScrollerItems() {},
    messageItems() {
      return this.messageContent === newContent ? [{ id: "msg-1" }, { id: "msg-2" }] : [];
    },
    clearMessageSpacer: Scroller.clearMessageSpacer,
    markMessageAutoscrolling() {},
    atMessageEnd: Scroller.atMessageEnd,
    syncMessageState() {},
    finishPendingScroll() {},
    measure() {},
    refreshMessageScrollerElements: Scroller.refreshMessageScrollerElements,
    applyMessageOpeningPosition: Scroller.applyMessageOpeningPosition,
    applyUpdatedMessageOpeningPosition: Scroller.applyUpdatedMessageOpeningPosition,
    restartMessageOpeningPosition: Scroller.restartMessageOpeningPosition,
    scrollMessageToEnd: Scroller.scrollMessageToEnd,
  };

  Scroller.updated.call(hook);

  assert.equal(hook.messageContent, newContent);
  assert.equal(hook.messageSpacer, newSpacer);
  assert.equal(hook.messageSpacerHeight, 0);
  assert.deepEqual(writes, [133]);
  assert.equal(viewport.scrollTop, 133);
});

test("Message Scroller does not treat an existing anchor as newly appended", () => {
  const item = {
    dataset: { scrollAnchor: "true" },
    getAttribute(name) {
      return name === "data-message-id" ? "m1" : null;
    },
  };
  let anchorScrolls = 0;
  const hook = {
    viewport: {
      getAttribute() {
        return "true";
      },
      querySelector() {
        return null;
      },
    },
    sticky: false,
    messageHandledAnchors: new WeakSet(),
    messageBeforeUpdate: {
      first: "m1",
      firstVisible: null,
      count: 1,
      height: 200,
      top: 0,
      atEnd: false,
    },
    messageItems() {
      return [item];
    },
    scrollMessageToElement() {
      anchorScrolls += 1;
    },
    syncMessageState() {},
  };

  Scroller.reconcileMessagePatch.call(hook);

  assert.equal(anchorScrolls, 0);
});

test("Message Scroller reapplies the exact end opening when its generation changes", () => {
  const attributes = new Map([
    ["data-lb-message-default-position", "end"],
    ["data-lb-message-opening-generation", "0"],
  ]);
  const pending = new Set();
  const frames = [];
  const previousRequestAnimationFrame = globalThis.requestAnimationFrame;
  const previousCancelAnimationFrame = globalThis.cancelAnimationFrame;

  globalThis.requestAnimationFrame = (callback) => {
    frames.push(callback);
    return frames.length;
  };
  globalThis.cancelAnimationFrame = () => {};

  try {
    const viewport = {
      clientHeight: 200,
      scrollHeight: 506,
      scrollTop: 0,
      scrollTo({ top }) {
        this.scrollTop = Math.min(this.scrollHeight - this.clientHeight, Math.max(0, top));
      },
      setAttribute(name) {
        pending.add(name);
      },
      removeAttribute(name) {
        pending.delete(name);
      },
    };
    const root = {
      getAttribute(name) {
        return attributes.get(name) || null;
      },
      setAttribute(name) {
        pending.add(name);
      },
      removeAttribute(name) {
        pending.delete(name);
      },
    };
    const hook = {
      messageScroller: true,
      viewport,
      messageRoot: root,
      messageDefaultPosition: "end",
      messageOpeningGeneration: "0",
      messageOpened: true,
      messageOpeningHold: false,
      messageOpeningSawLayout: false,
      messageOpeningStableFrames: 0,
      messageOpeningTarget: null,
      messageAnchoredItem: null,
      messageSpacerHeight: 0,
      pendingTargets: [],
      messageItems() {
        return [{}];
      },
      clearMessageSpacer() {},
      syncMessageState() {},
      markMessageAutoscrolling() {},
      atMessageEnd() {
        return this.viewport.scrollHeight - this.viewport.scrollTop - this.viewport.clientHeight <= 8;
      },
      applyMessageOpeningPosition: Scroller.applyMessageOpeningPosition,
      scrollMessageToEnd: Scroller.scrollMessageToEnd,
      restartMessageOpeningPosition: Scroller.restartMessageOpeningPosition,
      settleMessageOpeningPosition: Scroller.settleMessageOpeningPosition,
      finishPendingScroll: Scroller.finishPendingScroll,
    };

    assert.equal(Scroller.applyUpdatedMessageOpeningPosition.call(hook), false);

    attributes.set("data-lb-message-opening-generation", "1");
    assert.equal(Scroller.applyUpdatedMessageOpeningPosition.call(hook), true);
    assert.equal(viewport.scrollTop, 306);
    assert.equal(pending.has("data-pending-scroll"), true);

    // Browser scroll anchoring can move the new viewport after the first
    // opening write. The hold must restore the exact end before it clears.
    viewport.scrollTop = 200;
    hook.messageOpeningSawLayout = true;
    frames.shift()();
    assert.equal(viewport.scrollTop, 306);
    assert.equal(pending.has("data-pending-scroll"), true);

    frames.shift()();
    assert.equal(pending.has("data-pending-scroll"), true);
    frames.shift()();
    assert.equal(pending.has("data-pending-scroll"), false);
  } finally {
    globalThis.requestAnimationFrame = previousRequestAnimationFrame;
    globalThis.cancelAnimationFrame = previousCancelAnimationFrame;
  }
});

test("Message Scroller materializes a held last-anchor opening through its anchor, then restores lazy rows", () => {
  const frames = [];
  const previousRequestAnimationFrame = globalThis.requestAnimationFrame;
  const previousCancelAnimationFrame = globalThis.cancelAnimationFrame;
  globalThis.requestAnimationFrame = (callback) => {
    frames.push(callback);
    return frames.length;
  };
  globalThis.cancelAnimationFrame = () => {};

  const first = { style: { contentVisibility: "", containIntrinsicSize: "auto 10rem" }, dataset: {} };
  const second = { style: { contentVisibility: "auto", containIntrinsicSize: "auto 10rem" }, dataset: {} };
  const anchor = {
    style: { contentVisibility: "", containIntrinsicSize: "auto 10rem" },
    dataset: { scrollAnchor: "true" },
  };
  const later = { style: { contentVisibility: "", containIntrinsicSize: "auto 10rem" }, dataset: {} };
  const items = [first, second, anchor, later];
  const viewport = {
    clientHeight: 330,
    scrollTop: 0,
    scrollTo({ top }) {
      this.scrollTop = Math.min(356, Math.max(0, top));
    },
  };
  const hook = {
    viewport,
    messageRoot: {
      getAttribute(name) {
        return name === "data-lb-message-default-position" ? "last-anchor" : null;
      },
    },
    messageOpeningHold: true,
    messageOpeningSawLayout: true,
    messageOpeningStableFrames: 1,
    messageOpeningTarget: 111,
    messageOpened: false,
    messageMargin: 0,
    messagePreviousPeek: 64,
    messageAnchoredItem: null,
    pendingTargets: [],
    messageItems() {
      return items;
    },
    messageContentBottom() {
      return 900;
    },
    messageElementTop(item) {
      return item.style.contentVisibility === "visible" ? 199 : 408;
    },
    messageElementHeight() {
      return 64;
    },
    messageContentPadding() {
      return { start: 24, end: 24 };
    },
    updateMessageSpacer() {},
    atMessageEnd() {
      return false;
    },
    syncMessageState() {},
    materializeMessageOpeningAnchor: Scroller.materializeMessageOpeningAnchor,
    clearMessageOpeningMaterialization: Scroller.clearMessageOpeningMaterialization,
    scrollMessageToElement: Scroller.scrollMessageToElement,
    applyMessageOpeningPosition: Scroller.applyMessageOpeningPosition,
    settleMessageOpeningPosition: Scroller.settleMessageOpeningPosition,
    finishPendingScroll: Scroller.finishPendingScroll,
  };

  try {
    assert.equal(Scroller.applyMessageOpeningPosition.call(hook), true);
    assert.equal(viewport.scrollTop, 111);
    assert.deepEqual(
      items.map((item) => item.style.contentVisibility),
      ["visible", "visible", "visible", ""],
    );

    assert.equal(Scroller.settleMessageOpeningPosition.call(hook), true);
    assert.equal(hook.messageOpeningHold, false);
    assert.deepEqual(
      items.map((item) => item.style.contentVisibility),
      ["", "auto", "", ""],
    );
    assert.deepEqual(
      items.map((item) => item.style.containIntrinsicSize),
      ["auto 10rem", "auto 10rem", "auto 10rem", "auto 10rem"],
    );
  } finally {
    globalThis.requestAnimationFrame = previousRequestAnimationFrame;
    globalThis.cancelAnimationFrame = previousCancelAnimationFrame;
  }
});

test("Message Scroller leaves non-last-anchor openings lazy", () => {
  const item = { style: { contentVisibility: "auto" }, dataset: {} };
  const hook = {
    viewport: { scrollTop: 320 },
    messageRoot: {
      getAttribute(name) {
        return name === "data-lb-message-default-position" ? "end" : null;
      },
    },
    messageOpeningHold: true,
    messageOpened: false,
    messageItems() {
      return [item];
    },
    scrollMessageToEnd() {
      this.viewport.scrollTop = 356;
    },
    atMessageEnd() {
      return true;
    },
    syncMessageState() {},
  };

  Scroller.applyMessageOpeningPosition.call(hook);

  assert.equal(item.style.contentVisibility, "auto");
  assert.equal(hook.viewport.scrollTop, 356);
});

test("Message Scroller reopens a selected last anchor with the held materialization path", () => {
  const attributes = new Map([
    ["data-lb-message-default-position", "end"],
    ["data-lb-message-opening-generation", "0"],
  ]);
  const items = [
    { style: { contentVisibility: "" }, dataset: {} },
    { style: { contentVisibility: "" }, dataset: {} },
    { style: { contentVisibility: "" }, dataset: { scrollAnchor: "true" } },
    { style: { contentVisibility: "" }, dataset: {} },
  ];
  const frames = [];
  const previousRequestAnimationFrame = globalThis.requestAnimationFrame;
  const previousCancelAnimationFrame = globalThis.cancelAnimationFrame;
  globalThis.requestAnimationFrame = (callback) => {
    frames.push(callback);
    return frames.length;
  };
  globalThis.cancelAnimationFrame = () => {};
  const hook = {
    viewport: {
      clientHeight: 330,
      scrollTop: 356,
      scrollTo({ top }) {
        this.scrollTop = Math.min(356, Math.max(0, top));
      },
      setAttribute() {},
      removeAttribute() {},
    },
    messageRoot: {
      getAttribute(name) {
        return attributes.get(name) || null;
      },
      setAttribute() {},
      removeAttribute() {},
    },
    messageDefaultPosition: "end",
    messageOpeningGeneration: "0",
    messageOpened: true,
    messageOpeningHold: false,
    messageOpeningSawLayout: false,
    messageOpeningStableFrames: 0,
    messageOpeningTarget: null,
    messageMargin: 0,
    messagePreviousPeek: 64,
    messageAnchoredItem: null,
    messageItems() {
      return items;
    },
    messageContentBottom() {
      return 900;
    },
    messageElementTop(item) {
      return item.style.contentVisibility === "visible" ? 199 : 408;
    },
    messageElementHeight() {
      return 64;
    },
    messageContentPadding() {
      return { start: 24, end: 24 };
    },
    updateMessageSpacer() {},
    atMessageEnd() {
      return false;
    },
    syncMessageState() {},
    materializeMessageOpeningAnchor: Scroller.materializeMessageOpeningAnchor,
    clearMessageOpeningMaterialization: Scroller.clearMessageOpeningMaterialization,
    scrollMessageToElement: Scroller.scrollMessageToElement,
    applyMessageOpeningPosition: Scroller.applyMessageOpeningPosition,
    settleMessageOpeningPosition: Scroller.settleMessageOpeningPosition,
    restartMessageOpeningPosition: Scroller.restartMessageOpeningPosition,
    finishPendingScroll: Scroller.finishPendingScroll,
  };

  try {
    attributes.set("data-lb-message-default-position", "last-anchor");
    assert.equal(Scroller.applyUpdatedMessageOpeningPosition.call(hook), true);

    assert.equal(hook.messageOpeningHold, true);
    assert.equal(hook.viewport.scrollTop, 111);
  } finally {
    globalThis.requestAnimationFrame = previousRequestAnimationFrame;
    globalThis.cancelAnimationFrame = previousCancelAnimationFrame;
  }
});

test("Message Scroller leaves an unheld opening for the hook to apply", () => {
  const writes = [];
  const previousMutationObserver = globalThis.MutationObserver;
  globalThis.MutationObserver = class {
    observe() {}
  };

  try {
    let top = 0;
    const content = { querySelector() { return null; } };
    const viewport = {
      querySelector() {
        return content;
      },
      addEventListener() {},
      get scrollTop() {
        return top;
      },
      set scrollTop(value) {
        writes.push(value);
        top = value;
      },
    };
    const root = {
      id: "message-scroller-previous-context-0",
      getAttribute(name) {
        if (name === "data-lb-message-default-position") return "end";
        if (name === "data-lb-message-opening-hold") return "false";
        if (name === "data-lb-message-opening-generation") return "0";
        return null;
      },
      addEventListener() {},
    };
    const hook = {
      viewport,
      messageRoot: root,
      pendingTargets: [],
      refreshMessageScrollerConfig() {},
      hasMessageVisibilityConsumer() {
        return false;
      },
      installMessageVisibilityObserver() {},
      atMessageEnd() {
        return false;
      },
      syncMessageState() {},
      restoreMessageFrozenOpeningPosition: Scroller.restoreMessageFrozenOpeningPosition,
    };

    Scroller.installMessageScroller.call(hook);
    assert.equal(hook.messageOpened, false);
    assert.equal(hook.messageOpeningFrozenTop, null);
    assert.deepEqual(writes, []);
  } finally {
    globalThis.MutationObserver = previousMutationObserver;
  }
});

test("Message Scroller releases an unheld opening freeze for a valid public message request", () => {
  const writes = [];
  let top = 133;
  const item = {
    getAttribute(name) {
      return name === "data-message-id" ? "open-3" : null;
    },
  };
  const hook = {
    messageOpeningFrozenTop: 133,
    viewport: {
      get scrollTop() {
        return top;
      },
      set scrollTop(value) {
        writes.push(value);
        top = value;
      },
    },
    messageItems() {
      return [item];
    },
    scrollMessageToId: Scroller.scrollMessageToId,
    scrollMessageToElement(target, options) {
      assert.equal(target, item);
      assert.deepEqual(options, {
        align: "start",
        behavior: "auto",
        scrollMargin: 64,
      });
      this.viewport.scrollTop = 111;
      return true;
    },
    releaseMessageFrozenOpeningPosition: Scroller.releaseMessageFrozenOpeningPosition,
    restoreMessageFrozenOpeningPosition: Scroller.restoreMessageFrozenOpeningPosition,
  };

  assert.equal(
    Scroller.scrollMessageToRequest.call(hook, {
      id: "open-3",
      align: "start",
      behavior: "auto",
      scrollMargin: 64,
    }),
    true,
  );
  assert.equal(hook.messageOpeningFrozenTop, null);
  assert.deepEqual(writes, [111]);

  top = 228;
  assert.equal(Scroller.restoreMessageFrozenOpeningPosition.call(hook), false);
  assert.equal(top, 228);
  assert.deepEqual(writes, [111]);
});

test("Message Scroller keeps an opening freeze for invalid or empty public requests", () => {
  const hook = {
    messageOpeningFrozenTop: 133,
    releaseMessageFrozenOpeningPosition() {
      this.messageOpeningFrozenTop = null;
    },
  };

  assert.equal(Scroller.scrollMessageToRequest.call(hook, {}), false);
  assert.equal(Scroller.scrollMessageToRequest.call(hook, { direction: "middle" }), false);
  assert.equal(hook.messageOpeningFrozenTop, 133);
});

test("Message Scroller uses the native end for an unheld opening", () => {
  let nativeEndCalls = 0;
  const viewport = { scrollTop: 0 };
  const attributes = new Map([
    ["data-lb-message-default-position", "end"],
    ["data-lb-message-opening-hold", "false"],
  ]);
  const hook = {
    viewport,
    messageOpened: false,
    messageRoot: {
      getAttribute(name) {
        return attributes.get(name) || null;
      },
    },
    messageItems() {
      return [{}];
    },
    scrollMessageToEnd() {
      nativeEndCalls += 1;
      viewport.scrollTop = 167;
      return true;
    },
    atMessageEnd() {
      return true;
    },
    syncMessageState() {},
  };

  assert.equal(Scroller.applyMessageOpeningPosition.call(hook), true);
  assert.equal(nativeEndCalls, 1);
  assert.equal(viewport.scrollTop, 167);
});

test("Message Scroller reset uses the native end target", () => {
  const writes = [];
  let top = 228;
  const viewport = {
    clientHeight: 267,
    scrollHeight: 495,
    get scrollTop() {
      return top;
    },
    set scrollTop(value) {
      writes.push(value);
      top = value;
    },
    setAttribute() {},
  };
  const hook = {
    viewport,
    messageRoot: {
      getAttribute(name) {
        if (name === "data-lb-message-default-position") return "end";
        if (name === "data-lb-message-opening-hold") return "false";
        return null;
      },
      setAttribute() {},
    },
    messageOpened: true,
    messageOpeningFrozenTop: 95,
    messageOpeningHold: false,
    pendingTargets: [],
    messageItems() { return [{}]; },
    scrollMessageToEnd() {
      viewport.scrollTop = 228;
    },
    atMessageEnd() {
      return false;
    },
    syncMessageState() {},
    finishPendingScroll() {},
    applyMessageOpeningPosition: Scroller.applyMessageOpeningPosition,
  };

  Scroller.restartMessageOpeningPosition.call(hook);

  assert.deepEqual(writes, [228]);
  assert.equal(top, 228);
  assert.equal(hook.messageOpeningFrozenTop, null);
});

test("Message Scroller scrolls to the native maximum at the end", () => {
  const calls = [];
  const hook = {
    viewport: {
      scrollHeight: 495,
      clientHeight: 267,
      scrollTo(options) {
        calls.push(options);
      },
    },
    clearMessageSpacer() {},
    markMessageAutoscrolling() {},
    syncMessageState() {},
  };

  Scroller.scrollMessageToEnd.call(hook);

  assert.deepEqual(calls, [{ top: 228, behavior: "auto" }]);
});

test("Message Scroller keeps an early opening target until user intent", () => {
  const hook = {
    viewport: { scrollTop: 228 },
    messageOpeningFrozenTop: 133,
    atMessageEnd() {
      return false;
    },
    syncMessageState() {},
  };

  assert.equal(Scroller.restoreMessageFrozenOpeningPosition.call(hook), true);
  assert.equal(hook.viewport.scrollTop, 133);
  assert.equal(hook.messageOpeningFrozenTop, 133);

  Scroller.releaseMessageFrozenOpeningPosition.call(hook);
  assert.equal(hook.messageOpeningFrozenTop, null);
});

test("Message Scroller runs public direction and message requests", () => {
  const calls = [];
  const hook = {
    messageOpeningFrozenTop: null,
    releaseMessageFrozenOpeningPosition: Scroller.releaseMessageFrozenOpeningPosition,
    scrollMessageToStart(options) {
      calls.push(["start", options]);
      return true;
    },
    scrollMessageToEnd(options) {
      calls.push(["end", options]);
      return true;
    },
    scrollMessageToId(id, options) {
      calls.push([id, options]);
      return true;
    },
  };

  assert.equal(
    Scroller.scrollMessageToRequest.call(hook, { direction: "start", behavior: "auto" }),
    true,
  );
  assert.equal(
    Scroller.scrollMessageToRequest.call(hook, { direction: "end", behavior: "smooth" }),
    true,
  );
  assert.equal(
    Scroller.scrollMessageToRequest.call(hook, {
      id: "open-3",
      align: "start",
      behavior: "auto",
      scrollMargin: 64,
    }),
    true,
  );

  assert.deepEqual(calls, [
    ["start", { behavior: "auto" }],
    ["end", { behavior: "smooth" }],
    ["open-3", { align: "start", behavior: "auto", scrollMargin: 64 }],
  ]);
});

test("Message Scroller completes an existing-DOM held restart without a resize callback", () => {
  const frames = [];
  const pending = new Set();
  const previousRequestAnimationFrame = globalThis.requestAnimationFrame;
  const previousCancelAnimationFrame = globalThis.cancelAnimationFrame;
  globalThis.requestAnimationFrame = (callback) => {
    frames.push(callback);
    return frames.length;
  };
  globalThis.cancelAnimationFrame = () => {};

  const first = { style: { contentVisibility: "" }, dataset: {} };
  const second = { style: { contentVisibility: "auto" }, dataset: {} };
  const anchor = { style: { contentVisibility: "" }, dataset: { scrollAnchor: "true" } };
  const later = { style: { contentVisibility: "" }, dataset: {} };
  const items = [first, second, anchor, later];
  const pendingTarget = {
    setAttribute(name) {
      pending.add(name);
    },
    removeAttribute(name) {
      pending.delete(name);
    },
  };
  const hook = {
    viewport: {
      ...pendingTarget,
      clientHeight: 330,
      scrollTop: 356,
      scrollTo({ top }) {
        this.scrollTop = Math.min(356, Math.max(0, top));
      },
    },
    messageRoot: {
      ...pendingTarget,
      getAttribute(name) {
        return name === "data-lb-message-default-position" ? "last-anchor" : null;
      },
    },
    messageOpened: true,
    messageOpeningHold: false,
    messageOpeningSawLayout: false,
    messageOpeningStableFrames: 0,
    messageOpeningTarget: null,
    messageOpeningFrozenTop: null,
    messageMargin: 0,
    messagePreviousPeek: 64,
    messageAnchoredItem: null,
    pendingTargets: [],
    messageItems() {
      return items;
    },
    messageContentBottom() {
      return 900;
    },
    messageElementTop(item) {
      return item.style.contentVisibility === "visible" ? 199 : 408;
    },
    messageElementHeight() {
      return 64;
    },
    messageContentPadding() {
      return { start: 24, end: 24 };
    },
    updateMessageSpacer() {},
    atMessageEnd() {
      return false;
    },
    syncMessageState() {},
    materializeMessageOpeningAnchor: Scroller.materializeMessageOpeningAnchor,
    clearMessageOpeningMaterialization: Scroller.clearMessageOpeningMaterialization,
    scrollMessageToElement: Scroller.scrollMessageToElement,
    applyMessageOpeningPosition: Scroller.applyMessageOpeningPosition,
    settleMessageOpeningPosition: Scroller.settleMessageOpeningPosition,
    restartMessageOpeningPosition: Scroller.restartMessageOpeningPosition,
    finishPendingScroll: Scroller.finishPendingScroll,
  };

  try {
    Scroller.restartMessageOpeningPosition.call(hook);

    assert.equal(hook.viewport.scrollTop, 111);
    assert.equal(pending.has("data-pending-scroll"), true);
    assert.equal(hook.messageOpeningSawLayout, true);

    frames.shift()();
    assert.equal(pending.has("data-pending-scroll"), true);

    frames.shift()();
    assert.equal(pending.has("data-pending-scroll"), false);
    assert.deepEqual(
      items.map((item) => item.style.contentVisibility),
      ["", "auto", "", ""],
    );
  } finally {
    globalThis.requestAnimationFrame = previousRequestAnimationFrame;
    globalThis.cancelAnimationFrame = previousCancelAnimationFrame;
  }
});

function anchoredScrollHook({
  contentTail = 0,
  itemOffset = 425,
  scrollMargin = 0,
  previousPeek = 64,
  visualOffset: initialVisualOffset = 0,
} = {}) {
  let spacerHeight = 0;
  let visualOffset = initialVisualOffset;
  const offsetParent = {};

  const viewport = {
    clientHeight: 200,
    scrollTop: 0,
    get scrollHeight() {
      return itemOffset + 78 + spacerHeight + contentTail;
    },
    getBoundingClientRect() {
      return { top: 0 };
    },
    scrollTo({ top }) {
      const maximum = this.scrollHeight - this.clientHeight;
      this.scrollTop = Math.min(maximum, Math.max(0, top));
    },
  };

  const item = {
    isConnected: true,
    offsetHeight: 78,
    offsetParent,
    offsetTop: itemOffset,
    getBoundingClientRect() {
      const top = itemOffset - viewport.scrollTop + visualOffset;
      return { top, bottom: top + 78, height: 78 };
    },
  };

  const style = {};
  Object.defineProperty(style, "height", {
    get: () => `${spacerHeight}px`,
    set: (value) => {
      spacerHeight = Number.parseFloat(value) || 0;
    },
  });

  const hook = {
    viewport,
    messageRoot: {
      getAttribute(name) {
        if (name === "data-lb-message-scroll-margin") return String(scrollMargin);
        if (name === "data-lb-message-previous-peek") return String(previousPeek);
        if (name === "data-lb-message-scroll-edge-threshold") return "8";
        return null;
      },
    },
    messageContent: {
      offsetParent,
      offsetTop: 0,
      getBoundingClientRect() {
        return { top: -viewport.scrollTop };
      },
      contains(candidate) {
        return candidate === item;
      },
    },
    messageSpacer: { hidden: true, style },
    messageSpacerHeight: null,
    messageAnchoredItem: null,
    messageMargin: scrollMargin,
    messagePreviousPeek: previousPeek,
    messageContentPadding: Scroller.messageContentPadding,
    messageElementTop: Scroller.messageElementTop,
    messageElementHeight: Scroller.messageElementHeight,
    messageContentBottom: Scroller.messageContentBottom,
    messageVirtualContentEnd: Scroller.messageVirtualContentEnd,
    messageSpacerContentEnd: Scroller.messageSpacerContentEnd,
    messageItems() {
      return [item];
    },
    updateMessageSpacer: Scroller.updateMessageSpacer,
    syncMessageState() {},
    atMessageEnd() {
      return this.viewport.scrollHeight - this.viewport.scrollTop - this.viewport.clientHeight <= 8;
    },
  };

  hook.scrollMessageToElement = Scroller.scrollMessageToElement;
  hook.reanchorMessageItem = Scroller.reanchorMessageItem;
  hook.refreshMessageScrollerConfig = Scroller.refreshMessageScrollerConfig;

  return {
    hook,
    item,
    spacer: hook.messageSpacer,
    setVisualOffset(offset) {
      visualOffset = offset;
    },
  };
}

test("Message Scroller adds the exact anchor spacer before it scrolls", () => {
  const previous = globalThis.getComputedStyle;
  globalThis.getComputedStyle = () => ({
    paddingBlockStart: "16px",
    paddingBlockEnd: "0px",
    rowGap: "normal",
    gap: "0px",
  });

  try {
    const { hook, item, spacer } = anchoredScrollHook();
    Scroller.scrollMessageToElement.call(hook, item, { align: "start", keepPreviousPeek: true });

    // 425px item offset - 16px content padding - 64px peek = 345px.
    // The unextended transcript ends at 503px, so it needs 42px of spacer
    // for a 200px viewport to make the requested 345px position reachable.
    assert.equal(spacer.hidden, false);
    assert.equal(spacer.style.height, "42px");
    assert.equal(hook.viewport.scrollTop, 345);
  } finally {
    globalThis.getComputedStyle = previous;
  }
});

test("Message Scroller derives an intrinsic content end without layout reads", () => {
  const content = { kind: "content" };
  const itemStyleReads = [];
  const items = ["first", "second"].map((kind) => ({
    kind,
    getAttribute(name) {
      return name === "data-lb-message-intrinsic-size" ? "auto 10rem" : null;
    },
  }));
  const previous = globalThis.getComputedStyle;

  globalThis.getComputedStyle = (element) => {
    if (element === content) {
      return {
        paddingTop: "16px",
        paddingBottom: "24px",
        rowGap: "12px",
        gap: "12px",
      };
    }

    itemStyleReads.push(element.kind);
    return { containIntrinsicSize: "auto 160px" };
  };

  try {
    const hook = {
      messageContent: content,
      messageItems() {
        return items;
      },
    };

    assert.equal(Scroller.messageVirtualContentEnd.call(hook), 372);
    assert.deepEqual(itemStyleReads, ["first"]);
  } finally {
    globalThis.getComputedStyle = previous;
  }
});

test("Message Scroller falls back when an intrinsic content end is incomplete", () => {
  const content = { kind: "content" };
  const items = [
    {
      kind: "first",
      getAttribute(name) {
        return name === "data-lb-message-intrinsic-size" ? "auto 10rem" : null;
      },
    },
    {
      kind: "second",
      getAttribute() {
        return null;
      },
    },
  ];
  const previous = globalThis.getComputedStyle;
  let measuredCalls = 0;

  globalThis.getComputedStyle = (element) => {
    if (element === content) {
      return {
        paddingTop: "16px",
        paddingBottom: "24px",
        rowGap: "12px",
        gap: "12px",
      };
    }

    return { containIntrinsicSize: "auto 160px" };
  };

  try {
    const hook = {
      messageOpeningUsesIntrinsicLayout: true,
      messageContent: content,
      messageItems() {
        return items;
      },
      messageVirtualContentEnd: Scroller.messageVirtualContentEnd,
      messageContentBottom() {
        measuredCalls += 1;
        return 503;
      },
    };

    assert.equal(Scroller.messageSpacerContentEnd.call(hook), 503);
    assert.equal(measuredCalls, 1);
  } finally {
    globalThis.getComputedStyle = previous;
  }
});

test("Message Scroller extends an intrinsic opening without reading other rows", () => {
  const previous = globalThis.getComputedStyle;
  let spacerHeight = 0;
  let targetReads = 0;
  let skippedReads = 0;
  let scrollHeightReads = 0;
  const viewport = {
    clientHeight: 200,
    scrollTop: 0,
    get scrollHeight() {
      return 503 + spacerHeight;
    },
    getBoundingClientRect() {
      return { top: 0 };
    },
    scrollTo({ top }) {
      this.scrollTop = Math.min(this.scrollHeight - this.clientHeight, Math.max(0, top));
    },
  };
  const content = {
    get scrollHeight() {
      scrollHeightReads += 1;
      throw new Error("intrinsic opening must not read content scrollHeight");
    },
    getBoundingClientRect() {
      return { top: -viewport.scrollTop };
    },
  };
  const target = {
    getAttribute(name) {
      return name === "data-lb-message-intrinsic-size" ? "same" : null;
    },
    getBoundingClientRect() {
      targetReads += 1;
      const top = 425 - viewport.scrollTop;
      return { top, height: 78 };
    },
  };
  const skipped = {
    getAttribute(name) {
      return name === "data-lb-message-intrinsic-size" ? "same" : null;
    },
    getBoundingClientRect() {
      skippedReads += 1;
      throw new Error("intrinsic opening must not measure an off-screen row");
    },
  };
  const spacerStyle = {};
  Object.defineProperty(spacerStyle, "height", {
    get: () => `${spacerHeight}px`,
    set: (value) => {
      spacerHeight = Number.parseFloat(value) || 0;
    },
  });
  const hook = {
    viewport,
    messageContent: content,
    messageSpacer: { hidden: true, style: spacerStyle },
    messageSpacerHeight: null,
    messageOpeningUsesIntrinsicLayout: true,
    messageAnchoredItem: null,
    messageMargin: 0,
    messagePreviousPeek: 64,
    messageContentPadding: Scroller.messageContentPadding,
    messageElementTop: Scroller.messageElementTop,
    messageElementHeight: Scroller.messageElementHeight,
    messageContentBottom: Scroller.messageContentBottom,
    messageVirtualContentEnd: Scroller.messageVirtualContentEnd,
    messageSpacerContentEnd: Scroller.messageSpacerContentEnd,
    messageItems() {
      return [skipped, target];
    },
    updateMessageSpacer: Scroller.updateMessageSpacer,
    syncMessageState() {},
    atMessageEnd() {
      return false;
    },
  };

  globalThis.getComputedStyle = (element) => {
    if (element === content) {
      return {
        paddingBlockStart: "16px",
        paddingBlockEnd: "0px",
        paddingTop: "16px",
        paddingBottom: "0px",
        rowGap: "0px",
        gap: "0px",
      };
    }

    if (element === skipped) return { containIntrinsicSize: "auto 243.5px" };
    throw new Error("intrinsic opening must not read a later row style");
  };

  try {
    Scroller.scrollMessageToElement.call(hook, target, {
      align: "start",
      keepPreviousPeek: true,
    });

    assert.equal(targetReads > 0, true);
    assert.equal(skippedReads, 0);
    assert.equal(scrollHeightReads, 0);
    assert.equal(spacerStyle.height, "42px");
    assert.equal(viewport.scrollTop, 345);

    Scroller.scrollMessageToElement.call(hook, target, {
      align: "start",
      keepPreviousPeek: true,
    });
    assert.equal(spacerStyle.height, "42px");

    Scroller.updateMessageSpacer.call(hook, 0);
    assert.equal(hook.messageSpacer.hidden, true);
    assert.equal(spacerStyle.height, "0px");
  } finally {
    globalThis.getComputedStyle = previous;
  }
});

test("Message Scroller reapplies an anchored position after a resize", () => {
  const previous = globalThis.getComputedStyle;
  globalThis.getComputedStyle = () => ({
    paddingBlockStart: "16px",
    paddingBlockEnd: "0px",
    rowGap: "normal",
    gap: "0px",
  });

  try {
    const { hook, item } = anchoredScrollHook();
    hook.viewport.scrollTop = 303;
    hook.messageAnchoredItem = item;

    assert.equal(Scroller.reanchorMessageItem.call(hook), true);
    assert.equal(hook.viewport.scrollTop, 345);
  } finally {
    globalThis.getComputedStyle = previous;
  }
});

test("Message Scroller reads the current Previous Context peek before it positions an added anchor", () => {
  const previous = globalThis.getComputedStyle;
  globalThis.getComputedStyle = () => ({
    paddingBlockStart: "16px",
    paddingBlockEnd: "0px",
    rowGap: "normal",
    gap: "0px",
  });

  try {
    const { hook, item } = anchoredScrollHook({
      itemOffset: 502,
      scrollMargin: 24,
      previousPeek: 64,
    });

    hook.messageRoot.getAttribute = (name) => {
      if (name === "data-lb-message-scroll-margin") return "24";
      if (name === "data-lb-message-previous-peek") return "128";
      if (name === "data-lb-message-scroll-edge-threshold") return "8";
      return null;
    };

    Scroller.refreshMessageScrollerConfig.call(hook);
    Scroller.scrollMessageToElement.call(hook, item, {
      align: "start",
      keepPreviousPeek: true,
    });

    // 502px item offset - 16px content padding - 24px margin - 128px peek.
    assert.equal(hook.viewport.scrollTop, 334);
  } finally {
    globalThis.getComputedStyle = previous;
  }
});

test("Message Scroller includes the active Slide Up rectangle in its first anchor write", () => {
  const previous = globalThis.getComputedStyle;
  globalThis.getComputedStyle = (element) => ({
    paddingBlockStart: "16px",
    paddingBlockEnd: "0px",
    rowGap: "normal",
    gap: "0px",
    transform: element === item ? "matrix(1, 0, 0, 1, 0, 10)" : "none",
  });

  let item;
  try {
    const setup = anchoredScrollHook({
      itemOffset: 502,
      scrollMargin: 24,
      previousPeek: 128,
      visualOffset: 10,
    });
    const hook = setup.hook;
    item = setup.item;

    Scroller.scrollMessageToElement.call(hook, item, {
      align: "start",
      keepPreviousPeek: true,
    });

    // The pinned React package reads the visual rectangle during the entry.
    assert.equal(hook.viewport.scrollTop, 344);
  } finally {
    globalThis.getComputedStyle = previous;
  }
});

test("Message Scroller reanchors when the Slide Up visual offset finishes", async () => {
  const previous = globalThis.getComputedStyle;
  globalThis.getComputedStyle = () => ({
    paddingBlockStart: "16px",
    paddingBlockEnd: "0px",
    rowGap: "normal",
    gap: "0px",
  });

  try {
    const { hook, item, setVisualOffset } = anchoredScrollHook({
      contentTail: 100,
      itemOffset: 480,
      visualOffset: 2,
    });
    let finish;
    const controls = { finished: new Promise((resolve) => (finish = resolve)) };

    Scroller.scrollMessageToElement.call(hook, item, {
      align: "start",
      keepPreviousPeek: true,
    });
    assert.equal(hook.viewport.scrollTop, 402);

    Scroller.reanchorMessageEntryAfterFinish.call(hook, item, controls);
    setVisualOffset(0);
    finish();
    await Promise.resolve();

    assert.equal(hook.viewport.scrollTop, 400);
  } finally {
    globalThis.getComputedStyle = previous;
  }
});

test("Message Scroller keeps subpixel anchor geometry without an entry transform", () => {
  const previous = globalThis.getComputedStyle;
  globalThis.getComputedStyle = () => ({
    paddingBlockStart: "16px",
    paddingBlockEnd: "0px",
    rowGap: "normal",
    gap: "0px",
    transform: "none",
  });

  try {
    const { hook, item } = anchoredScrollHook({
      itemOffset: 502.5,
      scrollMargin: 24,
      previousPeek: 128,
    });

    Scroller.scrollMessageToElement.call(hook, item, {
      align: "start",
      keepPreviousPeek: true,
    });

    assert.equal(hook.viewport.scrollTop, 334.5);
  } finally {
    globalThis.getComputedStyle = previous;
  }
});

test("Message Scroller reanchors with the current Previous Context peek after a resize", () => {
  const previous = globalThis.getComputedStyle;
  globalThis.getComputedStyle = () => ({
    paddingBlockStart: "16px",
    paddingBlockEnd: "0px",
    rowGap: "normal",
    gap: "0px",
  });

  try {
    const { hook, item } = anchoredScrollHook({
      itemOffset: 502,
      scrollMargin: 24,
      previousPeek: 64,
    });

    hook.viewport.scrollTop = 398;
    hook.messageAnchoredItem = item;
    hook.messageRoot.getAttribute = (name) => {
      if (name === "data-lb-message-scroll-margin") return "24";
      if (name === "data-lb-message-previous-peek") return "128";
      if (name === "data-lb-message-scroll-edge-threshold") return "8";
      return null;
    };

    Scroller.refreshMessageScrollerConfig.call(hook);

    assert.equal(Scroller.reanchorMessageItem.call(hook), true);
    assert.equal(hook.viewport.scrollTop, 334);
  } finally {
    globalThis.getComputedStyle = previous;
  }
});

test("Message Scroller keeps normal off-screen rows at their intrinsic size", () => {
  let rowRectReads = 0;
  const attributes = new Map();
  const eventDetails = [];
  const row = {
    dataset: { scrollAnchor: "false" },
    getAttribute(name) {
      return name === "data-message-id" ? "history-1" : null;
    },
    getBoundingClientRect() {
      rowRectReads += 1;
      return { top: 0, bottom: 10 };
    },
  };
  const viewport = {
    scrollTop: 24,
    scrollHeight: 600,
    clientHeight: 200,
    setAttribute(name, value) {
      attributes.set(name, value);
    },
    removeAttribute(name) {
      attributes.delete(name);
    },
    toggleAttribute(name, active) {
      if (active) attributes.set(name, "");
      else attributes.delete(name);
    },
    dispatchEvent(event) {
      eventDetails.push(event.detail);
    },
  };
  const hook = {
    messageScroller: true,
    viewport,
    messageRoot: {
      querySelectorAll() {
        return [];
      },
      setAttribute() {},
      removeAttribute() {},
      toggleAttribute() {},
    },
    messageVisibilityEnabled: false,
    messageVisibleIds: new Set(),
    atMessageStart() {
      return false;
    },
    atMessageEnd() {
      return false;
    },
    syncMessageScrollStateBindings() {},
    messageItems() {
      return [row];
    },
  };

  Scroller.syncMessageState.call(hook);

  assert.equal(rowRectReads, 0);
  assert.deepEqual(eventDetails, [{ start: true, end: true, currentAnchorId: null, visibleMessageIds: [] }]);
});

test("Message Scroller uses observer visibility without measuring normal rows", () => {
  let rowRectReads = 0;
  const details = [];
  const row = {
    dataset: { scrollAnchor: "false" },
    getAttribute(name) {
      return name === "data-message-id" ? "history-6" : null;
    },
    getBoundingClientRect() {
      rowRectReads += 1;
      return { top: 0, bottom: 10 };
    },
  };
  const hook = {
    messageScroller: true,
    viewport: {
      scrollTop: 0,
      scrollHeight: 600,
      clientHeight: 200,
      getBoundingClientRect() {
        return { top: 0, bottom: 200 };
      },
      setAttribute() {},
      removeAttribute() {},
      toggleAttribute() {},
      dispatchEvent(event) {
        details.push(event.detail);
      },
    },
    messageRoot: {
      querySelectorAll() {
        return [];
      },
      setAttribute() {},
      removeAttribute() {},
      toggleAttribute() {},
    },
    messageVisibilityEnabled: true,
    messageVisibilityReady: true,
    messageVisibilityObserver: {},
    messageVisibleIds: new Set(["history-6"]),
    messageMargin: 0,
    messagePreviousPeek: 0,
    atMessageStart() {
      return true;
    },
    atMessageEnd() {
      return false;
    },
    syncMessageScrollStateBindings() {},
    syncMessageOutline() {},
    observeMessageVisibilityItems() {},
    messageItems() {
      return [row];
    },
  };

  Scroller.syncMessageState.call(hook);

  assert.equal(rowRectReads, 0);
  assert.deepEqual(details, [{ start: false, end: true, currentAnchorId: null, visibleMessageIds: ["history-6"] }]);
});

test("Message Scroller defers a visibility consumer until its opening finishes", () => {
  const previousCancelAnimationFrame = globalThis.cancelAnimationFrame;
  globalThis.cancelAnimationFrame = () => {};
  let anchorBoxReads = 0;
  let observerInstalls = 0;
  let pendingRemovals = 0;
  const anchor = {
    dataset: { scrollAnchor: "true" },
    getAttribute(name) {
      return name === "data-message-id" ? "vis-checklist" : null;
    },
    getBoundingClientRect() {
      anchorBoxReads += 1;
      return { top: 24, bottom: 88 };
    },
  };
  const hook = {
    messageScroller: true,
    messageOpened: true,
    messageOpeningHold: false,
    messageOpeningFrame: null,
    pendingFrame: null,
    pendingTargets: [{ removeAttribute() { pendingRemovals += 1; } }],
    viewport: {
      scrollTop: 0,
      scrollHeight: 600,
      clientHeight: 200,
      getBoundingClientRect() {
        return { top: 0, bottom: 200 };
      },
      setAttribute() {},
      removeAttribute() {},
      toggleAttribute() {},
      dispatchEvent() {},
    },
    messageRoot: {
      querySelectorAll() {
        return [];
      },
      setAttribute() {},
      removeAttribute() {},
      toggleAttribute() {},
    },
    messageVisibilityEnabled: true,
    messageVisibilityReady: false,
    messageVisibilityObserver: null,
    messageVisibleIds: new Set(),
    messageMargin: 12,
    messagePreviousPeek: 64,
    messageThreshold: 8,
    atMessageStart() {
      return true;
    },
    atMessageEnd() {
      return false;
    },
    syncMessageScrollStateBindings() {},
    syncMessageOutline() {},
    observeMessageVisibilityItems() {},
    installMessageVisibilityObserver() {
      observerInstalls += 1;
      this.messageVisibilityObserver = {};
    },
    clearMessageOpeningMaterialization() {},
    messageItems() {
      return [anchor];
    },
    syncMessageState: Scroller.syncMessageState,
    activateMessageVisibility: Scroller.activateMessageVisibility,
  };

  try {
    Scroller.syncMessageState.call(hook);
    assert.equal(anchorBoxReads, 0);
    assert.equal(observerInstalls, 0);

    Scroller.finishPendingScroll.call(hook);
    assert.equal(pendingRemovals, 1);
    assert.equal(observerInstalls, 1);
    assert.equal(anchorBoxReads, 1);

    Scroller.finishPendingScroll.call(hook);
    assert.equal(observerInstalls, 1);
  } finally {
    globalThis.cancelAnimationFrame = previousCancelAnimationFrame;
  }
});

test("Message Scroller leaves normal opening roots without visibility setup", () => {
  const previousCancelAnimationFrame = globalThis.cancelAnimationFrame;
  globalThis.cancelAnimationFrame = () => {};
  let observerInstalls = 0;
  const hook = {
    messageScroller: true,
    messageOpened: true,
    messageOpeningHold: false,
    messageOpeningFrame: null,
    pendingFrame: null,
    pendingTargets: [],
    messageVisibilityEnabled: false,
    messageVisibilityReady: false,
    installMessageVisibilityObserver() {
      observerInstalls += 1;
    },
    syncMessageState() {
      throw new Error("normal roots must not add a visibility sync");
    },
    clearMessageOpeningMaterialization() {},
  };

  try {
    Scroller.finishPendingScroll.call(hook);

    assert.equal(observerInstalls, 0);
  } finally {
    globalThis.cancelAnimationFrame = previousCancelAnimationFrame;
  }
});

test("Message Scroller clears an unheld bootstrap pending state after its initial opening", () => {
  const previousCancelAnimationFrame = globalThis.cancelAnimationFrame;
  globalThis.cancelAnimationFrame = () => {};
  const removed = [];
  const root = {
    removeAttribute(name) {
      removed.push(`root:${name}`);
    },
  };
  const viewport = {
    removeAttribute(name) {
      removed.push(`viewport:${name}`);
    },
  };
  const hook = {
    messageScroller: true,
    messageOpened: true,
    messageOpeningHold: false,
    messageOpeningUsesIntrinsicLayout: true,
    messageOpeningFrame: null,
    pendingFrame: null,
    pendingTargets: [root, viewport],
    clearMessageOpeningMaterialization() {},
    messageItems() {
      return [{}];
    },
  };

  try {
    Scroller.finishPendingScroll.call(hook);
    assert.deepEqual(removed, ["root:data-pending-scroll", "viewport:data-pending-scroll"]);
    assert.equal(hook.messageOpeningUsesIntrinsicLayout, false);
  } finally {
    globalThis.cancelAnimationFrame = previousCancelAnimationFrame;
  }
});
