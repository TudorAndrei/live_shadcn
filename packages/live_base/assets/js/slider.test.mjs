import assert from "node:assert/strict";
import test from "node:test";

import { Slider } from "./slider.js";

function sliderHook({ scalar = true } = {}) {
  const listeners = new Map();
  const input = {
    value: "64",
    min: "64",
    max: "128",
    dataset: {},
    addEventListener(name, handler) {
      listeners.set(name, handler);
    },
    removeEventListener(name) {
      listeners.delete(name);
    },
  };
  const controls = [input];
  const events = [];
  const hook = {
    refreshControls: Slider.refreshControls,
    clampValue: Slider.clampValue,
    reportValue: Slider.reportValue,
    el: {
      clientWidth: 0,
      getAttribute(name) {
        return name === "data-lb-change-event" ? "message_scroller_peek" : null;
      },
      hasAttribute(name) {
        return name === "data-lb-slider-scalar" && scalar;
      },
      querySelectorAll(selector) {
        if (selector === "[data-lb-slider-input]") return controls;
        if (selector === "[data-lb-slider-thumb]") return [];
        return [];
      },
      querySelector() {
        return null;
      },
    },
    place() {},
    dragging() {},
    focused() {},
    pushEvent(name, payload) {
      events.push({ name, payload });
    },
  };

  return { controls, events, hook, input, listeners };
}

test("Slider sends the final keyboard value when the browser emits change", () => {
  const { events, hook, input, listeners } = sliderHook();
  Slider.mounted.call(hook);

  input.value = "128";
  listeners.get("change")({ target: input });

  assert.deepEqual(events, [
    {
      name: "message_scroller_peek",
      payload: { value: "128", values: ["128"] },
    },
  ]);
});

test("Slider sends one event for the browser input and change pair", () => {
  const { events, hook, input, listeners } = sliderHook();
  Slider.mounted.call(hook);

  input.value = "96";
  listeners.get("input")({ target: input });
  listeners.get("change")({ target: input });

  assert.deepEqual(events, [
    {
      name: "message_scroller_peek",
      payload: { value: "96", values: ["96"] },
    },
  ]);
});

test("range input changes stop at the adjacent thumb before reporting values", () => {
  for (const [index, attempted, expected] of [[0, "100", "70"], [1, "0", "20"]]) {
    const { events, hook, input, listeners } = sliderHook({ scalar: false });
    Slider.mounted.call(hook);
    const neighbor = { value: index === 0 ? "70" : "20" };
    input.min = "0";
    input.max = "100";
    hook.inputs = index === 0 ? [input, neighbor] : [neighbor, input];
    input.value = attempted;
    listeners.get("input")({ target: input });
    listeners.get("change")({ target: input });

    assert.equal(input.value, expected);
    assert.deepEqual(events.map(event => event.payload), [{
      value: expected,
      values: index === 0 ? ["70", "70"] : ["20", "20"],
    }]);
  }
});


test("duplicate scalar inputs report one logical value without losing alternate-thumb changes", () => {
  const { events, hook, input, listeners } = sliderHook();
  Slider.mounted.call(hook);
  const second = { ...input, dataset: {} };
  hook.inputs.push(second);

  for (const [target, value] of [[input, "96"], [second, "128"], [input, "96"]]) {
    target.value = value;
    listeners.get("input")({ target });
    listeners.get("change")({ target });
    assert.deepEqual(hook.inputs.map(control => control.value), [value, value]);
  }

  assert.deepEqual(events.map(event => event.payload), [
    { value: "96", values: ["96"] },
    { value: "128", values: ["128"] },
    { value: "96", values: ["96"] },
  ]);

  Slider.destroyed.call(hook);
  assert.equal(listeners.has("input"), false);
  assert.equal(listeners.has("change"), false);
});

for (const count of [1, 2]) {
  test(`scalar reports resume after a server reset with ${count} native controls`, () => {
    const { controls, events, hook, input, listeners } = sliderHook();
    input.min = "0";
    input.max = "100";
    if (count === 2) controls.push({ ...input, dataset: {} });
    Slider.mounted.call(hook);

    for (const target of hook.inputs) {
      target.value = "100";
      listeners.get("input")({ target });
      // LiveView can acknowledge input before the browser commits change.
      Slider.updated.call(hook);
      listeners.get("change")({ target });
      assert.deepEqual(hook.inputs.map(control => control.value), Array(count).fill("100"));

      // A later server patch resets the controlled value without user input.
      for (const control of hook.inputs) control.value = "50";
      Slider.updated.call(hook);
    }

    input.value = "100";
    listeners.get("input")({ target: input });
    Slider.updated.call(hook);
    listeners.get("change")({ target: input });
    assert.deepEqual(events.map(event => event.payload), Array(count + 1).fill({
      value: "100", values: ["100"],
    }));
  });
}

for (const scalar of [true, false]) {
  test(`server control changes keep ${scalar ? "scalar" : "range"} inputs operable and release removed inputs`, () => {
    const { events, hook } = sliderHook({ scalar });
    const makeInput = value => Object.assign(new EventTarget(), {
      value, min: "0", max: "100", dataset: {},
    });
    const marks = [];
    hook.dragging = value => marks.push(["dragging", value]);
    hook.focused = value => marks.push(["focused", value]);
    const first = makeInput("20");
    const second = makeInput("70");
    let controls = [first];
    hook.el.querySelectorAll = selector => selector === "[data-lb-slider-input]" ? controls : [];
    Slider.mounted.call(hook);

    let callerEvents = 0;
    second.addEventListener("input", () => { callerEvents += 1; });
    controls = [first, second];
    Slider.updated.call(hook);
    second.dispatchEvent(new Event("pointerdown"));
    second.dispatchEvent(new Event("focus"));
    assert.deepEqual(marks, [["dragging", true], ["focused", true]]);
    second.value = "80";
    second.dispatchEvent(new Event("input"));
    second.dispatchEvent(new Event("change"));
    assert.deepEqual(events.map(event => event.payload), [{
      value: "80", values: scalar ? ["80"] : ["20", "80"],
    }]);
    if (scalar) assert.equal(first.value, "80");

    controls = [first];
    Slider.updated.call(hook);
    second.value = "90";
    second.dispatchEvent(new Event("input"));
    assert.equal(events.length, 1);
    assert.equal(callerEvents, 2);
    second.dispatchEvent(new Event("pointerup"));
    second.dispatchEvent(new Event("blur"));
    assert.equal(marks.length, 2);

    controls = [first, second];
    Slider.updated.call(hook);
    second.value = "100";
    second.dispatchEvent(new Event("input"));
    second.dispatchEvent(new Event("change"));
    assert.deepEqual(events.at(-1).payload, {
      value: "100", values: scalar ? ["100"] : ["20", "100"],
    });
    assert.equal(events.length, 2);

    Slider.destroyed.call(hook);
    second.value = "95";
    second.dispatchEvent(new Event("input"));
    assert.equal(events.length, 2);
    assert.equal(callerEvents, 4);
    second.dispatchEvent(new Event("pointerdown"));
    second.dispatchEvent(new Event("focus"));
    assert.equal(marks.length, 2);
  });
}
