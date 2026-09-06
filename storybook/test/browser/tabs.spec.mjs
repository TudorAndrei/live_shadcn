// Behaviour parity for tabs.
//
// Transcribed from the Base UI tabs page and the ARIA tabs pattern. The part
// that needs a browser is the keyboard: the arrow keys walk the row, Home and
// End go to its ends, and exactly one tab is in the page's tab order at a time
// so Tab moves past the whole set rather than through it.

import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const tab = (page, value, root = "tabs-default") => page.locator(`#${root}-tab-${value}`);
const panel = (page, value, root = "tabs-default") => page.locator(`#${root}-panel-${value}`);

test.describe("a set of tabs", () => {
  // Focused before the key, not merely clicked.
  //
  // `click()` resolves when the click is dispatched. A tab row is a roving
  // tabindex: the click is what moves focus and `tabindex="0"` to the tab that
  // was chosen, and an arrow key pressed into that gap walks from wherever
  // focus still was. On its own the gap never opened; under a full run it did,
  // and it read as "the row does not wrap".
  const chose = async (page, value) => {
    await tab(page, value).click();
    await expect(tab(page, value)).toBeFocused();
  };

  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/tabs/default", "#tabs-default");
  });

  test("shows the tab the caller named, and only that one", async ({ page }) => {
    await expect(panel(page, "overview")).toBeVisible();
    await expect(panel(page, "analytics")).toBeHidden();
    await expect(panel(page, "reports")).toBeHidden();
    await expect(panel(page, "settings")).toBeHidden();

    await expect(tab(page, "overview")).toHaveAttribute("aria-selected", "true");
    await expect(tab(page, "analytics")).toHaveAttribute("aria-selected", "false");
  });

  test("is a tab list of tabs, named for a screen reader", async ({ page }) => {
    await expect(page.locator("#tabs-default-list")).toHaveRole("tablist");
    await expect(tab(page, "overview")).toHaveRole("tab");
    await expect(panel(page, "overview")).toHaveRole("tabpanel");
    await expect(panel(page, "overview")).toHaveAttribute(
      "aria-labelledby",
      "tabs-default-tab-overview",
    );
  });

  test("choosing one unchooses the rest", async ({ page }) => {
    await tab(page, "reports").click();

    await expect(panel(page, "reports")).toBeVisible();
    await expect(panel(page, "overview")).toBeHidden();
    await expect(tab(page, "reports")).toHaveAttribute("data-active", "");
    await expect(tab(page, "overview")).not.toHaveAttribute("data-active", "");
  });

  test("only the chosen tab is in the page's tab order", async ({ page }) => {
    await expect(tab(page, "overview")).toHaveAttribute("tabindex", "0");
    await expect(tab(page, "analytics")).toHaveAttribute("tabindex", "-1");

    await tab(page, "analytics").click();

    await expect(tab(page, "analytics")).toHaveAttribute("tabindex", "0");
    await expect(tab(page, "overview")).toHaveAttribute("tabindex", "-1");
  });

  test("the right arrow walks along the row", async ({ page }) => {
    await chose(page, "overview");
    await page.keyboard.press("ArrowRight");

    await expect(tab(page, "analytics")).toBeFocused();
    await expect(panel(page, "analytics")).toBeVisible();
  });

  test("the left arrow walks back", async ({ page }) => {
    await chose(page, "reports");
    await page.keyboard.press("ArrowLeft");

    await expect(tab(page, "analytics")).toBeFocused();
    await expect(panel(page, "analytics")).toBeVisible();
  });

  test("the row wraps at its ends", async ({ page }) => {
    await chose(page, "settings");
    await page.keyboard.press("ArrowRight");

    await expect(tab(page, "overview")).toBeFocused();
    await expect(panel(page, "overview")).toBeVisible();
  });

  test("Home and End go to the ends", async ({ page }) => {
    await chose(page, "analytics");

    await page.keyboard.press("End");
    await expect(tab(page, "settings")).toBeFocused();

    await page.keyboard.press("Home");
    await expect(tab(page, "overview")).toBeFocused();
    await expect(panel(page, "overview")).toBeVisible();
  });
});

test("a disabled official tab does not activate", async ({ page }) => {
  await visit(page, "/preview/tabs/disabled", "#tabs-disabled");
  const disabled = tab(page, "settings", "tabs-disabled");

  await expect(disabled).toHaveAttribute("aria-disabled", "true");
  await disabled.click({ force: true });
  await expect(disabled).toHaveAttribute("aria-selected", "false");
  await expect(tab(page, "home", "tabs-disabled")).toHaveAttribute("aria-selected", "true");
});

test("vertical tabs use the down arrow", async ({ page }) => {
  await visit(page, "/preview/tabs/vertical", "#tabs-vertical");
  const account = tab(page, "account", "tabs-vertical");
  const password = tab(page, "password", "tabs-vertical");

  await account.click();
  await page.keyboard.press("ArrowDown");
  await expect(password).toBeFocused();
  await expect(password).toHaveAttribute("aria-selected", "true");
});
