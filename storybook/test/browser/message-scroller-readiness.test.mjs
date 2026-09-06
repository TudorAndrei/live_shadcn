import assert from "node:assert/strict";
import test from "node:test";

import {
  MESSAGE_SCROLLER_STABLE_FRAME_WINDOW,
  MESSAGE_SCROLLER_TRAILING_FRAMES,
  advanceMessageScrollerEntryReadiness,
  advanceMessageScrollerReadiness,
  waitForMessageScrollerEntryAnimations,
} from "./message-scroller-readiness.mjs";

const sample = (signature, pending = false) => ({
  hasMessageScroller: true,
  pending,
  signature,
});

test("Message Scroller readiness waits for the stable frame window and two trailing frames", () => {
  let state;
  const required = MESSAGE_SCROLLER_STABLE_FRAME_WINDOW + MESSAGE_SCROLLER_TRAILING_FRAMES;

  for (let frame = 1; frame <= required; frame += 1) {
    state = advanceMessageScrollerReadiness(state, sample("final-layout"));
    assert.equal(state.ready, frame === required);
  }
});

test("a pending Message Scroller restarts the final-layout frame window", () => {
  let state = advanceMessageScrollerReadiness(undefined, sample("first-layout"));
  state = advanceMessageScrollerReadiness(state, sample("first-layout"));
  state = advanceMessageScrollerReadiness(state, sample("first-layout", true));

  assert.deepEqual(state, {
    hasMessageScroller: true,
    signature: null,
    stableFrames: 0,
    ready: false,
  });

  state = advanceMessageScrollerReadiness(state, sample("first-layout"));
  assert.equal(state.stableFrames, 1);
  assert.equal(state.ready, false);
});

test("an exact Message Scroller geometry change restarts the frame window", () => {
  let state = advanceMessageScrollerReadiness(undefined, sample("top:88|height:552|row:312:64"));
  state = advanceMessageScrollerReadiness(state, sample("top:88|height:552|row:312:64"));
  state = advanceMessageScrollerReadiness(state, sample("top:88|height:552|row:312.01:64"));

  assert.equal(state.stableFrames, 1);
  assert.equal(state.ready, false);
});

test("Message Scroller anchor readiness rejects lazy intrinsic geometry until the anchor is visible and stable", () => {
  const required = MESSAGE_SCROLLER_STABLE_FRAME_WINDOW + MESSAGE_SCROLLER_TRAILING_FRAMES;
  let state;

  for (let frame = 1; frame <= required; frame += 1) {
    state = advanceMessageScrollerReadiness(state, {
      ...sample("top:320|max:356|anchor:320:384"),
      anchorVisible: false,
    });
    assert.equal(state.ready, false);
  }

  for (let frame = 1; frame <= required; frame += 1) {
    state = advanceMessageScrollerReadiness(state, {
      ...sample("top:356|max:356|anchor:64:128"),
      anchorVisible: true,
    });
    assert.equal(state.ready, frame === required);
  }
});

test("a page without a Message Scroller is ready without a frame wait", () => {
  const state = advanceMessageScrollerReadiness(undefined, {
    hasMessageScroller: false,
    pending: false,
    signature: "[]",
  });

  assert.deepEqual(state, {
    hasMessageScroller: false,
    signature: null,
    stableFrames: 0,
    ready: true,
  });
});

test("Message Scroller action readiness waits for the entry marker after a patch", () => {
  let state = advanceMessageScrollerEntryReadiness(undefined, {
    hasMessageScroller: true,
    entryMarkerActive: true,
  });
  assert.equal(state.ready, false);

  state = advanceMessageScrollerEntryReadiness(state, {
    hasMessageScroller: true,
    entryMarkerActive: false,
  });
  assert.equal(state.ready, false);

  state = advanceMessageScrollerEntryReadiness(state, {
    hasMessageScroller: true,
    entryMarkerActive: false,
  });
  assert.equal(state.ready, true);
});

test("Message Scroller entry readiness waits two quiet rAF frames after the finish callback", async () => {
  const previousDocument = globalThis.document;
  const previousWindow = globalThis.window;
  const item = {
    active: true,
    hasAttribute(name) {
      return name === "data-lb-message-entry-active" && this.active;
    },
    getAnimations() {
      return [];
    },
  };
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
  let finishCallbackComplete = false;
  const frames = [];
  const page = {
    async waitForFunction(predicate, options, polling) {
      assert.deepEqual(polling, { polling: "raf" });
      frames.push({ ready: predicate(options), finishCallbackComplete });
      item.active = false;
      finishCallbackComplete = true;
      frames.push({ ready: predicate(options), finishCallbackComplete });
      frames.push({ ready: predicate(options), finishCallbackComplete });
    },
  };

  try {
    await waitForMessageScrollerEntryAnimations(page, "[data-preview]");
  } finally {
    globalThis.document = previousDocument;
    globalThis.window = previousWindow;
  }

  assert.deepEqual(frames, [
    { ready: false, finishCallbackComplete: false },
    { ready: false, finishCallbackComplete: true },
    { ready: true, finishCallbackComplete: true },
  ]);
  assert.equal(frames.at(-1).ready, true);
  assert.equal(frames.at(-1).finishCallbackComplete, true);
});

test("composed Message Scroller readiness restarts on the 402 to 400 finish layout", () => {
  let entry;
  entry = advanceMessageScrollerEntryReadiness(entry, {
    hasMessageScroller: true,
    entryMarkerActive: true,
  });
  assert.equal(entry.ready, false);
  entry = advanceMessageScrollerEntryReadiness(entry, {
    hasMessageScroller: true,
    entryMarkerActive: false,
  });
  assert.equal(entry.ready, false);
  entry = advanceMessageScrollerEntryReadiness(entry, {
    hasMessageScroller: true,
    entryMarkerActive: false,
  });
  assert.equal(entry.ready, true);

  let layout;
  layout = advanceMessageScrollerReadiness(layout, sample("top:402|max:402|row:257:64"));
  assert.equal(layout.ready, false);
  layout = advanceMessageScrollerReadiness(layout, sample("top:402|max:402|row:257:64"));
  assert.equal(layout.ready, false);

  const required = MESSAGE_SCROLLER_STABLE_FRAME_WINDOW + MESSAGE_SCROLLER_TRAILING_FRAMES;
  for (let frame = 1; frame <= required; frame += 1) {
    layout = advanceMessageScrollerReadiness(layout, sample("top:400|max:400|row:257:64"));
    assert.equal(layout.ready, frame === required);
  }
});
