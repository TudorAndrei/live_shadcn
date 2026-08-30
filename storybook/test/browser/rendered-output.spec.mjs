import { expect, test } from "@playwright/test";

import { collect, compare, PROPERTIES, SEMANTIC_ATTRIBUTES } from "./measure.mjs";

test("the rendered-output check rejects semantic HTML differences", () => {
  const slot = {
    slot: "dropdown-menu-item",
    box: { x: 0, y: 0, width: 80, height: 24 },
    style: { display: "flex" },
  };

  const react = {
    whole: { width: 80, height: 24 },
    slots: [
      {
        ...slot,
        semantic: {
          tag: "div",
          role: "menuitem",
          text: "Publish",
          states: { "aria-disabled": "false" },
        },
      },
    ],
  };
  const phoenix = {
    whole: { width: 80, height: 24 },
    slots: [
      {
        ...slot,
        semantic: {
          tag: "div",
          role: "button",
          text: "Publish",
          states: { "aria-disabled": "false" },
        },
      },
    ],
  };

  expect(compare(react, phoenix)).toEqual([
    {
      slot: "dropdown-menu-item",
      property: "role",
      react: "menuitem",
      phoenix: "button",
    },
  ]);
});

test("the rendered-output check rejects HTML element differences", () => {
  const common = {
    slot: "trigger",
    box: { x: 0, y: 0, width: 80, height: 24 },
    style: { display: "flex" },
  };
  const semantic = { role: "button", text: "Open", states: {} };
  const react = {
    whole: { width: 80, height: 24 },
    slots: [{ ...common, semantic: { ...semantic, tag: "button" } }],
  };
  const phoenix = {
    whole: { width: 80, height: 24 },
    slots: [{ ...common, semantic: { ...semantic, tag: "div" } }],
  };

  expect(compare(react, phoenix)).toEqual([
    { slot: "trigger", property: "tag", react: "button", phoenix: "div" },
  ]);
});

test("the rendered-output check rejects painted CSS differences", () => {
  const semantic = { tag: "div", role: "menu", text: "", states: {} };
  const common = {
    slot: "dropdown-menu-content",
    box: { x: 0, y: 0, width: 160, height: 120 },
    semantic,
  };
  const react = {
    whole: { width: 160, height: 120 },
    slots: [{ ...common, style: { padding: "4px", "box-shadow": "none" } }],
  };
  const phoenix = {
    whole: { width: 160, height: 120 },
    slots: [{ ...common, style: { padding: "8px", "box-shadow": "none" } }],
  };

  expect(compare(react, phoenix)).toEqual([
    {
      slot: "dropdown-menu-content",
      property: "padding",
      react: "4px",
      phoenix: "8px",
    },
  ]);
});

test("the rendered-output check ignores dormant outline defaults", () => {
  const semantic = { tag: "button", role: "", text: "Open", states: {} };
  const common = {
    slot: "trigger",
    box: { x: 0, y: 0, width: 80, height: 36 },
    semantic,
  };
  const react = {
    whole: { width: 80, height: 36 },
    slots: [
      {
        ...common,
        style: {
          "outline-style": "none",
          "outline-width": "3px",
          "outline-color": "black",
        },
      },
    ],
  };
  const phoenix = {
    whole: { width: 80, height: 36 },
    slots: [
      {
        ...common,
        style: {
          "outline-style": "none",
          "outline-width": "1px",
          "outline-color": "transparent",
        },
      },
    ],
  };

  expect(compare(react, phoenix)).toEqual([]);
});

test("the rendered-output check ignores dormant zero-size shadows", () => {
  const semantic = { tag: "div", role: "menu", text: "", states: {} };
  const common = {
    slot: "menu",
    box: { x: 0, y: 0, width: 160, height: 120 },
    semantic,
  };
  const active = "rgba(0, 0, 0, 0.1) 0px 4px 6px -1px";
  const react = {
    whole: { width: 160, height: 120 },
    slots: [{ ...common, style: { "box-shadow": active } }],
  };
  const phoenix = {
    whole: { width: 160, height: 120 },
    slots: [
      {
        ...common,
        style: {
          "box-shadow": `oklab(0 0 0 / 0.1) 0px 0px 0px 0px, ${active}`,
        },
      },
    ],
  };

  expect(compare(react, phoenix)).toEqual([]);
});

test("the rendered-output check ignores a React portal transport wrapper", async ({ page }) => {
  await page.setContent(`
    <main data-preview="dialog"></main>
    <div data-slot="dialog-portal">
      <div data-slot="dialog-overlay"></div>
      <section data-slot="dialog-content"></section>
    </div>
  `);

  const measured = await page.evaluate(collect, {
    selector: "[data-preview='dialog']",
    properties: PROPERTIES,
    attributes: SEMANTIC_ATTRIBUTES,
  });

  expect(measured.slots.map(({ slot }) => slot)).toEqual([
    "dialog-overlay",
    "dialog-content",
  ]);
});
