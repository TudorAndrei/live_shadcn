import assert from "node:assert/strict";
import test from "node:test";

import {
  alignedSelectItemLeft,
  Floating,
  floatingScale,
  selectItemAlignmentFinal,
  selectItemAlignmentDirection,
  selectItemAlignmentLayout,
  snapAnchorDimensions,
} from "./floating.js";

function withHTMLElement(callback) {
  const originalHTMLElement = globalThis.HTMLElement;
  const originalGetComputedStyle = globalThis.getComputedStyle;

  class TestHTMLElement {}

  globalThis.HTMLElement = TestHTMLElement;
  globalThis.getComputedStyle = (element) => element.computedStyle;

  try {
    return callback(TestHTMLElement);
  } finally {
    if (originalHTMLElement === undefined) delete globalThis.HTMLElement;
    else globalThis.HTMLElement = originalHTMLElement;

    if (originalGetComputedStyle === undefined) delete globalThis.getComputedStyle;
    else globalThis.getComputedStyle = originalGetComputedStyle;
  }
}

function floatingElement(TestHTMLElement, {
  cssWidth,
  cssHeight,
  offsetWidth,
  offsetHeight,
  rectWidth,
  rectHeight,
}) {
  const element = new TestHTMLElement();
  element.offsetWidth = offsetWidth;
  element.offsetHeight = offsetHeight;
  element.computedStyle = { width: cssWidth, height: cssHeight };
  element.getBoundingClientRect = () => ({ width: rectWidth, height: rectHeight });
  return element;
}

test("Floating scale preserves fractional CSS trigger dimensions", () => {
  withHTMLElement((TestHTMLElement) => {
    const element = floatingElement(TestHTMLElement, {
      cssWidth: "73.265625px",
      cssHeight: "36px",
      offsetWidth: 73,
      offsetHeight: 36,
      rectWidth: 73.265625,
      rectHeight: 36,
    });

    assert.deepEqual(floatingScale(element), { x: 1, y: 1 });
  });
});

test("Floating scale retains real CSS transforms", () => {
  withHTMLElement((TestHTMLElement) => {
    const element = floatingElement(TestHTMLElement, {
      cssWidth: "100px",
      cssHeight: "50px",
      offsetWidth: 100,
      offsetHeight: 50,
      rectWidth: 125,
      rectHeight: 75,
    });

    assert.deepEqual(floatingScale(element), { x: 1.25, y: 1.5 });
  });
});

test("Floating scale uses rounded layout dimensions when CSS and offset dimensions differ", () => {
  withHTMLElement((TestHTMLElement) => {
    const element = floatingElement(TestHTMLElement, {
      cssWidth: "100px",
      cssHeight: "20px",
      offsetWidth: 101,
      offsetHeight: 20,
      rectWidth: 120.5,
      rectHeight: 20,
    });

    assert.deepEqual(floatingScale(element), { x: 121 / 101, y: 1 });
  });
});

test("Floating scale returns one for zero and non-HTML dimensions", () => {
  withHTMLElement((TestHTMLElement) => {
    const zero = floatingElement(TestHTMLElement, {
      cssWidth: "0px",
      cssHeight: "0px",
      offsetWidth: 0,
      offsetHeight: 0,
      rectWidth: 0,
      rectHeight: 0,
    });
    const svg = {
      getBoundingClientRect: () => ({ width: 200, height: 100 }),
      offsetWidth: 100,
      offsetHeight: 50,
    };

    assert.deepEqual(floatingScale(zero), { x: 1, y: 1 });
    assert.deepEqual(floatingScale(svg), { x: 1, y: 1 });
  });
});

test("Floating rereads its placement request after a responsive side change", () => {
  const values = new Map([
    ["data-lb-side", "right"],
    ["data-lb-align", "start"],
  ]);
  const hook = {
    el: { getAttribute: (name) => values.get(name) || null },
  };

  Floating.syncPlacementRequest.call(hook);
  assert.equal(hook.requestedSide, "right");
  assert.equal(hook.requestedSemanticSide, "right");
  assert.equal(hook.requestedAlign, "start");

  values.set("data-lb-side", "bottom");
  Floating.syncPlacementRequest.call(hook);
  assert.equal(hook.requestedSide, "bottom");
});

test("Floating gives Base UI alignOffset to Floating UI's alignment axis", () => {
  const values = new Map([
    ["data-lb-side", "bottom"],
    ["data-lb-offset", "10"],
    ["data-lb-align-offset", "-8"],
  ]);
  const hook = {
    el: { getAttribute: (name) => values.get(name) || null },
    popup: { dir: "ltr" },
    requestedSide: "bottom",
    crossAxisOffset: Floating.crossAxisOffset,
  };

  assert.deepEqual(Floating.offsetOptions.call(hook), {
    mainAxis: 10,
    crossAxis: -8,
    alignmentAxis: -8,
  });
});

test("Floating returns focus to a marked trigger after LiveView replaces the active calendar day", () => {
  let anchorFocused = false;
  let openerFocused = false;
  const originalDocument = globalThis.document;

  const hook = {
    el: { hasAttribute: (name) => name === "data-lb-return-focus-to-trigger" },
    anchor: { focus: () => (anchorFocused = true) },
    returnTo: { focus: () => (openerFocused = true) },
    popup: { contains: () => false },
  };

  globalThis.document = { activeElement: {} };

  try {
    Floating.returnFocus.call(hook);
  } finally {
    if (originalDocument === undefined) {
      delete globalThis.document;
    } else {
      globalThis.document = originalDocument;
    }
  }

  assert.equal(anchorFocused, true);
  assert.equal(openerFocused, false);
  assert.equal(hook.returnTo, null);
});

test("Floating only returns focus to the normal opener from inside its popup", () => {
  let openerFocused = false;
  const originalDocument = globalThis.document;

  const hook = {
    el: { hasAttribute: () => false },
    anchor: { focus: () => assert.fail("should not focus the trigger") },
    returnTo: { focus: () => (openerFocused = true) },
    popup: { contains: () => false },
  };

  globalThis.document = { activeElement: {} };

  try {
    Floating.returnFocus.call(hook);
  } finally {
    if (originalDocument === undefined) {
      delete globalThis.document;
    } else {
      globalThis.document = originalDocument;
    }
  }

  assert.equal(openerFocused, false);
  assert.equal(hook.returnTo, null);
});

test("Floating restores the direct menu trigger after the popup closes", () => {
  let openerFocused = false;
  const originalDocument = globalThis.document;

  const opener = { focus: () => (openerFocused = true) };
  const activeItem = {};
  const hook = {
    el: { hasAttribute: () => false },
    anchor: { focus: () => assert.fail("should use the captured trigger") },
    returnTo: opener,
    popup: { contains: (element) => element === activeItem },
  };

  globalThis.document = { activeElement: activeItem };

  try {
    Floating.returnFocus.call(hook);
  } finally {
    if (originalDocument === undefined) {
      delete globalThis.document;
    } else {
      globalThis.document = originalDocument;
    }
  }

  assert.equal(openerFocused, true);
  assert.equal(hook.returnTo, null);
});

test("Floating can leave focus in a closed popup when the caller requests it", () => {
  const originalDocument = globalThis.document;

  const hook = {
    el: { hasAttribute: (name) => name === "data-lb-no-return-focus" },
    anchor: { focus: () => assert.fail("should not focus the trigger") },
    returnTo: { focus: () => assert.fail("should not restore focus") },
    popup: { contains: () => true },
  };

  globalThis.document = { activeElement: {} };

  try {
    Floating.returnFocus.call(hook);
  } finally {
    if (originalDocument === undefined) {
      delete globalThis.document;
    } else {
      globalThis.document = originalDocument;
    }
  }

  assert.equal(hook.returnTo, null);
});

test("Floating focuses a selected Select option after a pointer open", () => {
  let highlighted = false;
  let optionFocused = false;
  let popupFocused = false;
  const originalDocument = globalThis.document;
  const option = {
    setAttribute: () => (highlighted = true),
    focus: () => (optionFocused = true),
  };
  const hook = {
    el: { hasAttribute: (name) => name === "data-lb-autofocus" },
    popup: {
      hasAttribute: (name) => name === "data-lb-initial-highlight",
      querySelector: (selector) => (selector.startsWith("[role='option']") ? option : null),
      matches: () => false,
      focus: () => (popupFocused = true),
    },
    openedByKeyboard: false,
  };

  globalThis.document = { activeElement: {} };

  try {
    Floating.takeFocus.call(hook);
  } finally {
    if (originalDocument === undefined) {
      delete globalThis.document;
    } else {
      globalThis.document = originalDocument;
    }
  }

  assert.equal(highlighted, true);
  assert.equal(optionFocused, true);
  assert.equal(popupFocused, false);
});

test("Floating focuses a selected Select option after a keyboard open", () => {
  let highlighted = false;
  let optionFocused = false;
  let popupFocused = false;
  const originalDocument = globalThis.document;
  const option = {
    setAttribute: () => (highlighted = true),
    focus: () => (optionFocused = true),
  };
  const hook = {
    el: { hasAttribute: (name) => name === "data-lb-autofocus" },
    popup: {
      hasAttribute: (name) => name === "data-lb-initial-highlight",
      querySelector: (selector) => (selector.startsWith("[role='option']") ? option : null),
      matches: () => false,
      focus: () => (popupFocused = true),
    },
    openedByKeyboard: true,
  };

  globalThis.document = { activeElement: {} };

  try {
    Floating.takeFocus.call(hook);
  } finally {
    if (originalDocument === undefined) {
      delete globalThis.document;
    } else {
      globalThis.document = originalDocument;
    }
  }

  assert.equal(highlighted, true);
  assert.equal(optionFocused, true);
  assert.equal(popupFocused, false);
});

test("Floating derives anchor dimensions from device-pixel snapped edges", () => {
  assert.deepEqual(
    snapAnchorDimensions({ x: 10.25, y: 20.25, width: 20.25, height: 30.25 }, 2),
    { width: 20, height: 30 },
  );
});

test("Floating keeps exact dimensions when both reference edges share the device-pixel grid", () => {
  assert.deepEqual(
    snapAnchorDimensions({ x: 10.5, y: 20.5, width: 20, height: 30 }, 2),
    { width: 20, height: 30 },
  );
});

test("Floating item alignment keeps the positioner fractional left edge", () => {
  const positioner = { left: 470.984375 };
  const popup = { left: 471 };
  const value = { left: 520.984375, right: 620.984375 };
  const text = { left: 525.984375, right: 630.984375 };

  const alignedLeft = alignedSelectItemLeft(positioner, value, text);
  const popupBasedLeft = popup.left + value.left - text.left;

  assert.equal(alignedLeft, 465.984375);
  assert.notEqual(alignedLeft, popupBasedLeft);
});

test("Floating item alignment uses right edges in RTL", () => {
  const positioner = { left: 470.984375 };
  const value = { left: 520.984375, right: 620.984375 };
  const text = { left: 525.984375, right: 630.984375 };

  assert.equal(alignedSelectItemLeft(positioner, value, text, "rtl"), 460.984375);
});

test("Floating Select alignment reads the positioner direction, not the popup direction", () => {
  const originalGetComputedStyle = globalThis.getComputedStyle;
  const positioner = { dir: "" };
  const popup = { dir: "rtl" };

  globalThis.getComputedStyle = (element) => {
    assert.equal(element, positioner);
    return { direction: "ltr" };
  };

  try {
    assert.equal(selectItemAlignmentDirection(positioner, popup), "ltr");
  } finally {
    if (originalGetComputedStyle === undefined) {
      delete globalThis.getComputedStyle;
    } else {
      globalThis.getComputedStyle = originalGetComputedStyle;
    }
  }
});

test("Floating Select preserves the pinned LTR and RTL item-alignment edges", () => {
  const common = {
    triggerRect: { left: 280, right: 408, top: 48, bottom: 84, width: 128, height: 36 },
    positionerRect: { left: 0, right: 144, top: 0, bottom: 337, width: 144, height: 337 },
    viewportWidth: 1280,
    viewportHeight: 720,
    scrollHeight: 337,
    borderBottom: 0,
    marginTop: 10,
    marginBottom: 10,
    minHeight: 100,
  };

  const ltr = selectItemAlignmentLayout({
    ...common,
    direction: "ltr",
    valueRect: { left: 289, right: 369, top: 56, bottom: 76, width: 80, height: 20 },
    textRect: { left: 4, right: 84, top: 8, bottom: 28, width: 80, height: 20 },
  });
  const rtl = selectItemAlignmentLayout({
    ...common,
    direction: "rtl",
    valueRect: { left: 313, right: 399, top: 56, bottom: 76, width: 86, height: 20 },
    textRect: { left: 18, right: 98, top: 8, bottom: 28, width: 80, height: 20 },
  });

  assert.equal(ltr.left, 285);
  assert.equal(rtl.left, 301);
});

test("Floating SelectPopup keeps the first positioner rectangle through final left alignment", () => {
  const layout = selectItemAlignmentLayout({
    triggerRect: { left: 500, right: 600, top: 400, bottom: 440, width: 100, height: 40 },
    positionerRect: {
      left: 470.984375,
      right: 630.984375,
      top: 444,
      bottom: 644,
      width: 160,
      height: 200,
    },
    valueRect: { left: 520.984375, right: 620.984375, top: 410, bottom: 430, width: 100, height: 20 },
    textRect: { left: 525.984375, right: 630.984375, top: 460, bottom: 480, width: 105, height: 20 },
    viewportWidth: 800,
    viewportHeight: 900,
    scrollHeight: 600,
    borderBottom: 1,
    marginTop: 10,
    marginBottom: 10,
    minHeight: 100,
  });

  assert.equal(layout.left, 465.984375);
  assert.equal(layout.height, 497);
  assert.deepEqual(
    selectItemAlignmentFinal(layout, {
      maxScrollTop: 103,
      positionerHeight: 200,
      maxPopupHeight: Infinity,
    }),
    {
      fallback: false,
      height: 497,
      top: "",
      bottom: "0px",
      scrollTop: 0,
      reachedMaxHeight: false,
    },
  );
});

test("Floating SelectPopup clamps the final left edge and sets the top edge", () => {
  const layout = selectItemAlignmentLayout({
    triggerRect: { left: 2, right: 102, top: 200, bottom: 240, width: 100, height: 40 },
    positionerRect: { left: 0, right: 160, top: 244, bottom: 934, width: 160, height: 690 },
    viewportWidth: 800,
    viewportHeight: 900,
    scrollHeight: 600,
    borderBottom: 0,
    marginTop: 10,
    marginBottom: 10,
    minHeight: 100,
  });

  assert.equal(layout.left, 5);
  assert.deepEqual(
    selectItemAlignmentFinal(layout, {
      maxScrollTop: 0,
      positionerHeight: 690,
      maxPopupHeight: Infinity,
    }),
    {
      fallback: false,
      height: 690,
      top: "190px",
      bottom: "",
      scrollTop: 0,
      reachedMaxHeight: false,
    },
  );
});
