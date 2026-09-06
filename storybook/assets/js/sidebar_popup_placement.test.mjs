import assert from "node:assert/strict";
import test from "node:test";

import { popupSide, syncSidebarPopupPlacement } from "./sidebar_popup_placement.js";

test("SidebarPopupPlacement uses the official desktop and mobile sides", () => {
  assert.equal(popupSide(false), "right");
  assert.equal(popupSide(true), "bottom");
});

test("SidebarPopupPlacement updates every marked popup and asks for a new layout", () => {
  const events = [];
  const attributes = [];
  const positioner = {
    setAttribute(name, value) {
      attributes.push([name, value]);
    },
    dispatchEvent(event) {
      events.push(event.type);
    },
  };
  const popup = {
    closest(selector) {
      assert.equal(selector, "[data-lb-anchor]");
      return positioner;
    },
  };

  syncSidebarPopupPlacement([popup], true);

  assert.deepEqual(attributes, [["data-lb-side", "bottom"]]);
  assert.deepEqual(events, ["live-base:reposition"]);
});
