import assert from "node:assert/strict";
import test from "node:test";

import { InteractionTrigger } from "./interaction_trigger.js";

test("InteractionTrigger releases the blocked click when LiveView enables a caller click", () => {
  let callerOwnsClick = false;
  const listeners = new Set();
  const el = {
    hasAttribute(name) {
      return name === "data-lb-caller-click" && callerOwnsClick;
    },
    addEventListener(name, callback, capture) {
      assert.equal(name, "click");
      assert.equal(capture, true);
      listeners.add(callback);
    },
    removeEventListener(name, callback, capture) {
      assert.equal(name, "click");
      assert.equal(capture, true);
      listeners.delete(callback);
    },
  };
  const hook = {
    el,
    blockTrustedClick: null,
    syncTrustedClickBlocker: InteractionTrigger.syncTrustedClickBlocker,
  };

  InteractionTrigger.syncTrustedClickBlocker.call(hook);
  assert.equal(listeners.size, 1);
  assert.equal(typeof hook.blockTrustedClick, "function");

  callerOwnsClick = true;
  InteractionTrigger.updated.call(hook);

  assert.equal(listeners.size, 0);
  assert.equal(hook.blockTrustedClick, null);
});

test("InteractionTrigger defers a zero-delay hover open until after a native click", () => {
  const originalSetTimeout = globalThis.setTimeout;
  let scheduled;
  let opens = 0;

  globalThis.setTimeout = (callback, delay) => {
    scheduled = { callback, delay };
    return 1;
  };

  try {
    const hook = {
      openTimer: null,
      closeTimer: null,
      delay: () => 0,
      openHover: () => {
        opens += 1;
      },
    };

    InteractionTrigger.scheduleOpen.call(hook);

    assert.equal(opens, 0);
    assert.equal(scheduled.delay, 0);

    scheduled.callback();
    assert.equal(opens, 1);
  } finally {
    globalThis.setTimeout = originalSetTimeout;
  }
});

test("InteractionTrigger does not open a tooltip from pointer-induced focus", () => {
  let opens = 0;
  let closes = 0;
  const hook = {
    el: {
      hasAttribute: () => false,
      getAttribute: () => null,
    },
    pointerPressed: false,
    openTimer: 1,
    scheduleOpen: () => {
      opens += 1;
    },
    scheduleClose: () => {
      closes += 1;
    },
  };

  InteractionTrigger.markPointerPressed.call(hook);
  InteractionTrigger.scheduleFocusOpen.call(hook);

  assert.equal(hook.pointerPressed, true);
  assert.equal(opens, 0);

  InteractionTrigger.leavePointer.call(hook);
  InteractionTrigger.scheduleFocusOpen.call(hook);

  assert.equal(hook.pointerPressed, false);
  assert.equal(closes, 1);
  assert.equal(opens, 1);
});
