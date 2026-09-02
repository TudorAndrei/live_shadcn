import assert from "node:assert/strict";
import test from "node:test";

import {
  MESSAGE_SCROLLER_STABLE_FRAME_WINDOW,
  MESSAGE_SCROLLER_TRAILING_FRAMES,
  advanceMessageScrollerReadiness,
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
