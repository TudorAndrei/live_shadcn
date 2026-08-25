// Behaviour parity for the dialog.
//
// Transcribed from the Base UI dialog page and the ARIA modal dialog pattern.
// Half of what a dialog owes a reader is invisible — where the focus is, what
// happens to Tab, whether the page behind still scrolls — and none of it can be
// checked by looking at markup.

import { expect, test } from "@playwright/test";

const dialog = (page, id) => ({
  trigger: page.locator(`#${id}-trigger`),
  backdrop: page.locator(`#${id}-backdrop`),
  popup: page.locator(`#${id}-popup`),
  title: page.locator(`#${id}-title`),
});

test.describe("a dialog", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/preview/dialog/default");
    await expect(page.locator("#confirm-trigger")).toBeVisible();
  });

  test("starts closed, and says so", async ({ page }) => {
    const { trigger, popup, backdrop } = dialog(page, "confirm");

    await expect(popup).toBeHidden();
    await expect(backdrop).toBeHidden();
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
  });

  test("opens, and marks both layers as Base UI documents", async ({ page }) => {
    const { trigger, popup, backdrop } = dialog(page, "confirm");

    await trigger.click();

    await expect(popup).toBeVisible();
    await expect(backdrop).toBeVisible();
    await expect(popup).toHaveAttribute("data-open", "");
    await expect(backdrop).toHaveAttribute("data-open", "");
    await expect(trigger).toHaveAttribute("data-popup-open", "");
  });

  test("is a modal dialog named by its own title", async ({ page }) => {
    const { trigger, popup } = dialog(page, "confirm");

    await trigger.click();

    await expect(popup).toHaveRole("dialog");
    await expect(popup).toHaveAttribute("aria-modal", "true");
    await expect(popup).toHaveAttribute("aria-labelledby", "confirm-title");
    await expect(page.locator("#confirm-title")).toHaveText("Are you sure?");
  });

  test("the focus moves into it, so a keyboard reader is where the dialog is", async ({ page }) => {
    const { trigger, popup } = dialog(page, "confirm");

    await trigger.click();
    await expect(popup).toBeVisible();

    const inside = await popup.evaluate((el) => el.contains(document.activeElement));
    expect(inside).toBe(true);
  });

  test("the focus comes back to the trigger when it closes", async ({ page }) => {
    const { trigger, popup } = dialog(page, "confirm");

    await trigger.click();
    await expect(popup).toBeVisible();

    await page.keyboard.press("Escape");
    await expect(popup).toBeHidden();
    await expect(trigger).toBeFocused();
  });

  test("Escape closes it", async ({ page }) => {
    const { trigger, popup } = dialog(page, "confirm");

    await trigger.click();
    // Open before Escape, or the key arrives at a page with nothing to close.
    // `click()` resolves when the click is dispatched, not when the dialog has
    // opened, and under a full run that gap is wide enough to lose the key —
    // which read as "Escape does not close the dialog" and passed on its own.
    await expect(popup).toBeVisible();

    await page.keyboard.press("Escape");

    await expect(popup).toBeHidden();
    await expect(popup).toHaveAttribute("data-closed", "");
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
  });

  test("clicking the layer behind closes it", async ({ page }) => {
    const { trigger, popup, backdrop } = dialog(page, "confirm");

    await trigger.click();
    await backdrop.click({ position: { x: 5, y: 5 } });

    await expect(popup).toBeHidden();
  });

  test("the close button closes it", async ({ page }) => {
    const { trigger, popup } = dialog(page, "confirm");

    await trigger.click();
    await page.locator("[data-slot='dialog-close']").click();

    await expect(popup).toBeHidden();
  });

  test("Tab stays inside while it is open", async ({ page }) => {
    const { trigger, popup } = dialog(page, "confirm");

    await trigger.click();
    await expect(popup).toBeVisible();

    // Round the whole dialog and back again. Every stop has to be inside it.
    for (let press = 0; press < 8; press++) {
      await page.keyboard.press("Tab");
      const inside = await popup.evaluate((el) => el.contains(document.activeElement));
      expect(inside).toBe(true);
    }
  });

  test("Shift+Tab stays inside too", async ({ page }) => {
    const { trigger, popup } = dialog(page, "confirm");

    await trigger.click();
    await expect(popup).toBeVisible();

    for (let press = 0; press < 8; press++) {
      await page.keyboard.press("Shift+Tab");
      const inside = await popup.evaluate((el) => el.contains(document.activeElement));
      expect(inside).toBe(true);
    }
  });

  test("the page behind does not scroll while it is open", async ({ page }) => {
    const { trigger, popup } = dialog(page, "confirm");

    await trigger.click();
    await expect(popup).toBeVisible();

    expect(await page.evaluate(() => getComputedStyle(document.body).overflow)).toBe("hidden");

    await page.keyboard.press("Escape");
    await expect(popup).toBeHidden();

    expect(await page.evaluate(() => getComputedStyle(document.body).overflow)).not.toBe("hidden");
  });
});
