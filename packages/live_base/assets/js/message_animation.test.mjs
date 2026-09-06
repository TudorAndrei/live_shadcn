import assert from "node:assert/strict";
import test from "node:test";

function entryElement() {
  const attributes = new Map();

  return {
    attributes,
    style: {},
    setAttribute(name, value) {
      attributes.set(name, value);
    },
    removeAttribute(name) {
      attributes.delete(name);
    },
    hasAttribute(name) {
      return attributes.has(name);
    },
  };
}

let motionModuleCount = 0;

async function withMotionGlobals(callback) {
  const previous = {
    Element: globalThis.Element,
    HTMLElement: globalThis.HTMLElement,
    NodeList: globalThis.NodeList,
    SVGElement: globalThis.SVGElement,
    matchMedia: globalThis.matchMedia,
    requestAnimationFrame: globalThis.requestAnimationFrame,
  };

  globalThis.Element = class {};
  globalThis.HTMLElement = class {};
  globalThis.NodeList = class {};
  globalThis.SVGElement = class {};
  globalThis.requestAnimationFrame = (callback) => setTimeout(() => callback(performance.now()), 0);

  try {
    const animation = await import(`./message_animation.js?test=${motionModuleCount++}`);
    await callback(animation);
  } finally {
    Object.assign(globalThis, previous);
  }
}

test("Message Scroller keeps all pinned Motion entry presets", async () => {
  await withMotionGlobals(async ({ MESSAGE_ANIMATION_PRESETS }) => {
    assert.deepEqual(MESSAGE_ANIMATION_PRESETS, {
    fade: {
      initial: { opacity: 0 },
      animate: { opacity: 1 },
      transition: { duration: 0.22, ease: "easeOut" },
    },
    "slide-up": {
      initial: { opacity: 0, y: 10 },
      animate: { opacity: 1, y: 0 },
      transition: { duration: 0.26, ease: [0.16, 1, 0.3, 1] },
    },
    "slide-side": {
      initial: { opacity: 0, x: 18 },
      animate: { opacity: 1, x: 0 },
      transition: { duration: 0.28, ease: [0.16, 1, 0.3, 1] },
    },
    pop: {
      initial: { opacity: 0, scale: 0.94, y: 6, originX: 1, originY: 1 },
      animate: { opacity: 1, y: 0, scale: 1 },
      transition: { type: "spring", stiffness: 500, damping: 34, mass: 0.7 },
    },
    "spring-bounce": {
      initial: { opacity: 0, y: 12, scale: 0.96 },
      animate: { opacity: 1, y: 0, scale: 1 },
      transition: { type: "spring", stiffness: 520, damping: 30, mass: 0.7 },
    },
    "blur-fade": {
      initial: { opacity: 0, filter: "blur(4px)", y: 6 },
      animate: { opacity: 1, y: 0, filter: "blur(0px)" },
      transition: { duration: 0.28, ease: "easeOut" },
    },
    "scale-fade": {
      initial: { opacity: 0, scale: 0.98 },
      animate: { opacity: 1, scale: 1 },
      transition: { duration: 0.24, ease: "easeOut" },
    },
    });
  });
});

test("Message Scroller marks an entry active until Motion finishes", async () => {
  await withMotionGlobals(async ({ animateMessageEntry }) => {
    const item = entryElement();
    const controls = animateMessageEntry(item, "fade");

    assert.equal(item.hasAttribute("data-lb-message-entry-active"), true);
    await controls.finished;
    assert.equal(item.hasAttribute("data-lb-message-entry-active"), false);
  });
});

test("Message Scroller clears an active entry marker when Motion stops", async () => {
  await withMotionGlobals(async ({ stopMessageEntry }) => {
    const item = entryElement();
    item.setAttribute("data-lb-message-entry-active", "true");

    stopMessageEntry(item);
    assert.equal(item.hasAttribute("data-lb-message-entry-active"), false);
  });
});

test("Message Scroller clears a stale entry marker with reduced motion", async () => {
  await withMotionGlobals(async ({ animateMessageEntry }) => {
    globalThis.matchMedia = () => ({ matches: true });
    const item = entryElement();
    item.setAttribute("data-lb-message-entry-active", "");

    assert.equal(animateMessageEntry(item, "slide-up"), null);
    assert.equal(item.hasAttribute("data-lb-message-entry-active"), false);
  });
});
