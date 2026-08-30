import { expect, test } from "@playwright/test";

import { enterVisualState, visualStates } from "./visual-states.mjs";

test("popover / default exposes its closed and expanded render states", async ({ page }) => {
  const selector = "[data-preview='popover']";

  await page.goto("/preview/popover/default");

  const states = await visualStates(page, selector);

  expect(states.map(({ name }) => name)).toEqual(["default", "expanded:What is a recipe?"]);

  await enterVisualState(page, selector, states[1]);

  await expect(page.getByRole("dialog")).toBeVisible();
});

test("disabled disclosures do not become render states", async ({ page }) => {
  await page.goto("/preview/accordion/states");

  const states = await visualStates(page, "[data-preview='accordion']");

  expect(states.map(({ name }) => name)).toEqual(["default"]);
});

test("tooltip exposes its hover state", async ({ page }) => {
  const selector = "[data-preview='tooltip']";
  await page.goto("/preview/tooltip/default");

  const states = await visualStates(page, selector);
  expect(states.map(({ name }) => name)).toEqual(["default", "hover:ac60ef5"]);

  await enterVisualState(page, selector, states[1]);
  await expect(page.locator("[data-slot='tooltip-content']")).toBeVisible();
});

test("context menu exposes its right-click state", async ({ page }) => {
  const selector = "[data-preview='context-menu']";
  await page.goto("/preview/context-menu/default");

  const states = await visualStates(page, selector);
  expect(states.map(({ name }) => name)).toEqual(["default", "context:accordion.json"]);

  await enterVisualState(page, selector, states[1]);
  await expect(page.locator("[data-slot='context-menu-content']")).toBeVisible();
});
