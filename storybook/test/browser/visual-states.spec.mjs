import { expect, test } from "@playwright/test";

import { enterVisualState, visualStates } from "./visual-states.mjs";

test("state names use a control's native label", async ({ page }) => {
  await page.setContent(`
    <main data-preview="labelled-control">
      <label for="billing-month">الشهر</label>
      <button id="billing-month" role="switch" aria-checked="false">MM</button>
    </main>
  `);

  const states = await visualStates(page, "[data-preview='labelled-control']");

  expect(states.map(({ name }) => name)).toEqual(["default", "checked:الشهر"]);
});

test("popover / default exposes its closed and expanded render states", async ({ page }) => {
  const selector = "[data-preview='popover']";

  await page.goto("/preview/popover/default");

  const states = await visualStates(page, selector);

  expect(states.map(({ name }) => name)).toEqual(["default", "expanded:Open popover"]);

  await page.goto("/preview/popover/default");
  await enterVisualState(page, selector, states[1]);

  await expect(page.getByRole("dialog")).toBeVisible();
});

test("editable comboboxes use a user click to enter the expanded state", async ({ page }, testInfo) => {
  const selector = "[data-preview='combobox']";
  const paths = [
    "/preview/combobox/default",
    `${testInfo.project.use.parityURL}/preview/combobox/default`,
  ];

  for (const path of paths) {
    await page.goto(path);
    const states = await visualStates(page, selector);

    expect(states.map(({ kind, path }) => ({ kind, path }))).toEqual([
      { kind: "default", path: undefined },
      { kind: "expanded", path: [{ index: 0 }] },
      { kind: "expanded", path: [{ index: 1 }] },
    ]);

    await page.goto(path);
    await enterVisualState(page, selector, states[1]);
    await expect(page.getByRole("combobox", { name: "Select a framework" })).toHaveAttribute(
      "aria-expanded",
      "true",
    );
    await expect(page.getByRole("listbox")).toBeVisible();
  }
});

test("disabled disclosures do not become render states", async ({ page }) => {
  await page.goto("/preview/accordion/disabled");

  const states = await visualStates(page, "[data-preview='accordion']");

  expect(states.map(({ name }) => name)).toEqual([
    "default",
    "expanded:Can I access my account history?",
    "expanded:How do I update my email address?",
  ]);
});

test("tooltip exposes its hover state", async ({ page }) => {
  const selector = "[data-preview='tooltip']";
  await page.goto("/preview/tooltip/default");

  const states = await visualStates(page, selector);
  expect(states).toEqual([
    { name: "default", kind: "default" },
    { name: "hover:Hover", kind: "hover", index: 0 },
  ]);

  await enterVisualState(page, selector, states[1]);
  await expect(page.locator("[data-slot='tooltip-content']")).toBeVisible();
});

test("chart tooltip examples expose their hover state", async ({ page }, testInfo) => {
  const selector = "[data-preview='chart']";
  const paths = [
    "/preview/chart/example-tooltip",
    `${testInfo.project.use.parityURL}/preview/chart/example-tooltip`,
  ];

  for (const path of paths) {
    await page.goto(path);
    const states = await visualStates(page, selector);

    expect(states).toEqual([
      { name: "default", kind: "default" },
      { name: "chart-hover:first-series", kind: "chart-hover", index: 0 },
    ]);

    await page.goto(path);
    await enterVisualState(page, selector, states[1]);
    await expect(page.locator(".recharts-tooltip-wrapper")).toBeVisible();
  }
});

test("context menu exposes its right-click state", async ({ page }) => {
  const selector = "[data-preview='context-menu']";
  await page.goto("/preview/context-menu/default");

  const states = await visualStates(page, selector);
  expect(states.map(({ name }) => name)).toEqual(["default", "context:accordion.json"]);

  await enterVisualState(page, selector, states[1]);
  await expect(page.locator("[data-slot='context-menu-content']")).toBeVisible();
});

test("dropdown menu exposes its nested menu state", async ({ page }, testInfo) => {
  const selector = "[data-preview='dropdown-menu']";
  const paths = [
    "/preview/dropdown-menu/default",
    `${testInfo.project.use.parityURL}/preview/dropdown-menu/default`,
  ];

  for (const path of paths) {
    await page.goto(path);
    const states = await visualStates(page, selector);

    expect(states.map(({ name }) => name)).toEqual([
      "default",
      "expanded:Open",
      "expanded:Open > Invite users",
    ]);

    await page.goto(path);
    await enterVisualState(page, selector, states[2]);
    await expect(page.locator("[data-slot='dropdown-menu-sub-content']")).toBeVisible();
  }
});

test("table actions expose each menu as a separate render state", async ({ page }, testInfo) => {
  const selector = "[data-preview='table']";
  const paths = [
    "/preview/table/actions",
    `${testInfo.project.use.parityURL}/preview/table/actions`,
  ];

  for (const path of paths) {
    await page.goto(path);
    const states = await visualStates(page, selector);

    expect(states.map(({ name }) => name)).toEqual([
      "default",
      "expanded:Open menu",
      "expanded:Open menu",
      "expanded:Open menu",
    ]);
  }
});

test("navigation menu exposes each content state", async ({ page }, testInfo) => {
  const selector = "[data-preview='navigation-menu']";
  const paths = [
    "/preview/navigation-menu/default",
    `${testInfo.project.use.parityURL}/preview/navigation-menu/default`,
  ];

  for (const path of paths) {
    await page.goto(path);
    const states = await visualStates(page, selector);

    expect(states.map(({ name }) => name)).toEqual([
      "default",
      "expanded:Getting started",
      "expanded:Components",
      "expanded:With Icon",
    ]);
  }
});

test("toast exposes each action result and the completed Promise", async ({ page }, testInfo) => {
  const selector = "[data-preview='toast']";
  const paths = [
    "/preview/toast/promise",
    `${testInfo.project.use.parityURL}/preview/toast/promise`,
  ];

  for (const path of paths) {
    await page.goto(path);
    const states = await visualStates(page, selector);

    expect(states.map(({ name }) => name)).toEqual([
      "default",
      "action:Create Event",
      "action-settled:Create Event",
    ]);

    await page.goto(path);
    await enterVisualState(page, selector, states[1]);
    await expect(page.locator("[data-slot='toast-description']")).toHaveText("Creating event…");

    await page.goto(path);
    await enterVisualState(page, selector, states[2]);
    await expect(page.locator("[data-slot='toast-description']")).toHaveText("Event created.");
  }
});
