// Behaviour parity for tabs.
//
// Transcribed from the Base UI tabs page and the ARIA tabs pattern. The part
// that needs a browser is the keyboard: the arrow keys walk the row, Home and
// End go to its ends, and exactly one tab is in the page's tab order at a time
// so Tab moves past the whole set rather than through it.

import { expect, test } from "@playwright/test";

const tab = (page, value) => page.locator(`#stages-tab-${value}`);
const panel = (page, value) => page.locator(`#stages-panel-${value}`);

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
    await page.goto("/preview/tabs/default");
    await expect(page.locator("#stages")).toBeVisible();
  });

  test("shows the tab the caller named, and only that one", async ({ page }) => {
    await expect(panel(page, "spec")).toBeVisible();
    await expect(panel(page, "fetch")).toBeHidden();
    await expect(panel(page, "gen")).toBeHidden();

    await expect(tab(page, "spec")).toHaveAttribute("aria-selected", "true");
    await expect(tab(page, "fetch")).toHaveAttribute("aria-selected", "false");
  });

  test("is a tab list of tabs, named for a screen reader", async ({ page }) => {
    await expect(page.locator("#stages-list")).toHaveRole("tablist");
    await expect(tab(page, "spec")).toHaveRole("tab");
    await expect(panel(page, "spec")).toHaveRole("tabpanel");
    await expect(panel(page, "spec")).toHaveAttribute("aria-labelledby", "stages-tab-spec");
  });

  test("choosing one unchooses the rest", async ({ page }) => {
    await tab(page, "gen").click();

    await expect(panel(page, "gen")).toBeVisible();
    await expect(panel(page, "spec")).toBeHidden();
    await expect(tab(page, "gen")).toHaveAttribute("data-active", "");
    await expect(tab(page, "spec")).not.toHaveAttribute("data-active", "");
  });

  test("only the chosen tab is in the page's tab order", async ({ page }) => {
    await expect(tab(page, "spec")).toHaveAttribute("tabindex", "0");
    await expect(tab(page, "fetch")).toHaveAttribute("tabindex", "-1");

    await tab(page, "fetch").click();

    await expect(tab(page, "fetch")).toHaveAttribute("tabindex", "0");
    await expect(tab(page, "spec")).toHaveAttribute("tabindex", "-1");
  });

  test("the right arrow walks along the row", async ({ page }) => {
    await chose(page, "fetch");
    await page.keyboard.press("ArrowRight");

    await expect(tab(page, "spec")).toBeFocused();
    await expect(panel(page, "spec")).toBeVisible();
  });

  test("the left arrow walks back", async ({ page }) => {
    await chose(page, "gen");
    await page.keyboard.press("ArrowLeft");

    await expect(tab(page, "spec")).toBeFocused();
    await expect(panel(page, "spec")).toBeVisible();
  });

  test("the row wraps at its ends", async ({ page }) => {
    await chose(page, "gen");
    await page.keyboard.press("ArrowRight");

    await expect(tab(page, "fetch")).toBeFocused();
    await expect(panel(page, "fetch")).toBeVisible();
  });

  test("Home and End go to the ends", async ({ page }) => {
    await chose(page, "spec");

    await page.keyboard.press("End");
    await expect(tab(page, "gen")).toBeFocused();

    await page.keyboard.press("Home");
    await expect(tab(page, "fetch")).toBeFocused();
    await expect(panel(page, "fetch")).toBeVisible();
  });
});
