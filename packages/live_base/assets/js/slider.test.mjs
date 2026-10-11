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
  const events = [];
  const hook = {
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
        if (selector === "[data-lb-slider-input]") return [input];
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

  return { events, hook, input, listeners };
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
