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
    await expect(item("profile")).toHaveRole("menuitem");
  });

  test("matches the pinned official demo", async ({ page }) => {
    const { trigger, popup, item } = menu(page);

    await trigger.click();

    await expect(popup.getByText("My Account", { exact: true })).toBeVisible();

    for (const [value, label, shortcut] of [
      ["profile", "Profile", "⇧⌘P"],
      ["billing", "Billing", "⌘B"],
      ["settings", "Settings", "⌘S"],
      ["team", "Team"],
      ["new-team", "New Team", "⌘+T"],
      ["github", "GitHub"],
      ["support", "Support"],
      ["api", "API"],
      ["log-out", "Log out", "⇧⌘Q"],
    ]) {
      await expect(item(value)).toContainText(label);

      if (shortcut) {
        await expect(item(value).locator("[data-slot='dropdown-menu-shortcut']")).toHaveText(
          shortcut,
        );
      }
    }

    await expect(page.locator("#actions-invite-users-trigger")).toContainText("Invite users");
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
    await expect(menu(page).item("profile")).toBeFocused();

    await page.keyboard.press("ArrowDown");
    await expect(menu(page).item("billing")).toBeFocused();
  });

  test("a disabled item is skipped, not merely unclickable", async ({ page }) => {
    const { trigger, popup, item } = menu(page);

    await trigger.click();
    await expect(popup).toBeVisible();
    await expect(item("api")).toHaveAttribute("data-disabled", "");

    await item("support").focus();
    await page.keyboard.press("ArrowDown");

    await expect(item("log-out")).toBeFocused();
  });

  test("opens and closes the submenu with the arrow keys", async ({ page }) => {
    const { trigger } = menu(page);
    const subtrigger = page.locator("#actions-invite-users-trigger");
    const subpopup = page.locator("#actions-invite-users-popup");

    await trigger.click();
    await subtrigger.focus();
    await page.keyboard.press("ArrowRight");

    await expect(subpopup).toBeVisible();
    await expect(subpopup.getByText("Email", { exact: true })).toBeVisible();
    await expect(subpopup.getByText("Message", { exact: true })).toBeVisible();
    await expect(subpopup.getByText("More...", { exact: true })).toBeVisible();

    await page.keyboard.press("ArrowLeft");
    await expect(subpopup).toBeHidden();
    await expect(subtrigger).toBeFocused();
  });

  test("opens the submenu after the pointer rests on it", async ({ page }) => {
    const { trigger, popup, item } = menu(page);
    const subtrigger = page.locator("#actions-invite-users-trigger");
    const subpopup = page.locator("#actions-invite-users-popup");

    await trigger.click();
    await subtrigger.hover();
    await expect(subpopup).toBeVisible();
    await expect(popup).toBeFocused();

    await item("team").hover();
    await expect(subpopup).toBeHidden();
  });

  test("closing the parent also resets its submenu", async ({ page }) => {
    const { trigger, popup } = menu(page);
    const subtrigger = page.locator("#actions-invite-users-trigger");
    const subpopup = page.locator("#actions-invite-users-popup");

    await trigger.click();
    await subtrigger.click();
    await expect(subpopup).toBeVisible();

    await page.keyboard.press("Escape");
    await expect(popup).toBeHidden();
    await expect(subpopup).toBeHidden();
    await expect(subtrigger).toHaveAttribute("aria-expanded", "false");

    await trigger.click();
    await expect(popup).toBeVisible();
    await expect(subpopup).toBeHidden();
    await expect(subtrigger).toHaveAttribute("aria-expanded", "false");
  });

  test("choosing an item closes the menu", async ({ page }) => {
    const { trigger, popup, item } = menu(page);

    await trigger.click();
    await expect(popup).toBeVisible();

    await item("billing").click();
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
