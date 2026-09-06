import assert from "node:assert/strict";
import test from "node:test";

import { Slider } from "./slider.js";

function sliderHook() {
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
    reportValue: Slider.reportValue,
    el: {
      clientWidth: 0,
      getAttribute(name) {
        return name === "data-lb-change-event" ? "message_scroller_peek" : null;
      },
      hasAttribute() {
        return true;
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
