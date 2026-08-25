// Behaviour parity for the menu.
//
// A menu is a popover with a list in it, and the list is what needs a browser.
// The APG asks that the arrow keys move a *highlight* while the focus stays on
// the menu — so a screen reader says "menu, item 2 of 5" rather than reading
// out a button — and that choosing anything closes it.

import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const menu = (page) => ({
  trigger: page.locator("#actions-trigger"),
  popup: page.locator("#actions-popup"),
  item: (value) => page.locator(`#actions-item-${value}`),
});

test.describe("a dropdown menu", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/dropdown-menu/default", "#actions-trigger");
  });

  test("says it opens a menu, and starts closed", async ({ page }) => {
    const { trigger, popup } = menu(page);

    await expect(trigger).toHaveAttribute("aria-haspopup", "menu");
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
    await expect(popup).toBeHidden();
  });

  test("opens as a menu of menu items", async ({ page }) => {
    const { trigger, popup, item } = menu(page);

    await trigger.click();

    await expect(popup).toBeVisible();
    await expect(popup).toHaveRole("menu");
    await expect(item("fetch")).toHaveRole("menuitem");
  });

  test("the focus goes to the menu itself, not to an item", async ({ page }) => {
    const { trigger, popup } = menu(page);

    await trigger.click();
    await expect(popup).toBeVisible();

    await expect(popup).toBeFocused();
  });

  test("the arrow keys move through the items", async ({ page }) => {
    const { trigger, popup } = menu(page);

    await trigger.click();
    await expect(popup).toBeVisible();

    await page.keyboard.press("ArrowDown");
    await expect(menu(page).item("fetch")).toBeFocused();

    await page.keyboard.press("ArrowDown");
    await expect(menu(page).item("generate")).toBeFocused();
  });

  test("a disabled item is skipped, not merely unclickable", async ({ page }) => {
    const { trigger, popup, item } = menu(page);

    await trigger.click();
    await expect(popup).toBeVisible();
    await expect(item("publish")).toHaveAttribute("data-disabled", "");

    await page.keyboard.press("End");

    // `publish` is last and disabled, so End lands on the one before it.
    await expect(item("verify")).toBeFocused();
  });

  test("choosing an item closes the menu", async ({ page }) => {
    const { trigger, popup, item } = menu(page);

    await trigger.click();
    await expect(popup).toBeVisible();

    await item("generate").click();
    await expect(popup).toBeHidden();
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
  });

  test("Escape closes it without choosing anything", async ({ page }) => {
    const { trigger, popup } = menu(page);

    await trigger.click();
    await expect(popup).toBeVisible();

    await page.keyboard.press("Escape");
    await expect(popup).toBeHidden();
  });

  test("it is positioned against its trigger", async ({ page }) => {
    const { trigger, popup } = menu(page);

    await trigger.click();
    await expect(popup).toBeVisible();

    const positioner = page.locator("#actions-positioner");
    await expect(positioner).toHaveAttribute("data-side", /top|right|bottom|left/);

    const anchor = await trigger.boundingBox();
    const box = await positioner.boundingBox();
    expect(Math.abs(box.x - anchor.x)).toBeLessThan(40);
  });
});
