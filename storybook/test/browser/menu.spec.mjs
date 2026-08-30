// Behaviour parity for the menu.
//
// A menu is a popover with a list in it, and the list is what needs a browser.
// The APG asks that the arrow keys move a *highlight* while the focus stays on
// the menu — so a screen reader says "menu, item 2 of 5" rather than reading
// out a button — and that choosing anything closes it.

import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const menu = (page) => ({
  trigger: page.locator("#complex-actions-trigger"),
  popup: page.locator("#complex-actions-popup"),
  item: (value) => page.locator(`#complex-actions-item-${value}`),
});

test.describe("a dropdown menu", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/dropdown-menu/complex", "#complex-actions-trigger");
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

  test("draws the complex menu fixture", async ({ page }) => {
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

    await expect(page.locator("#complex-actions-invite-users-trigger")).toContainText(
      "Invite users",
    );
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
    const subtrigger = page.locator("#complex-actions-invite-users-trigger");
    const subpopup = page.locator("#complex-actions-invite-users-popup");

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
    const subtrigger = page.locator("#complex-actions-invite-users-trigger");
    const subpopup = page.locator("#complex-actions-invite-users-popup");

    await trigger.click();
    await subtrigger.hover();
    await expect(subpopup).toBeVisible();
    await expect(popup).toBeFocused();

    await item("team").hover();
    await expect(subpopup).toBeHidden();
  });

  test("closing the parent also resets its submenu", async ({ page }) => {
    const { trigger, popup } = menu(page);
    const subtrigger = page.locator("#complex-actions-invite-users-trigger");
    const subpopup = page.locator("#complex-actions-invite-users-popup");

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

  test("Enter chooses the focused item", async ({ page }) => {
    const { trigger, popup, item } = menu(page);

    await trigger.click();
    await item("billing").focus();
    await page.keyboard.press("Enter");

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

    const positioner = page.locator("#complex-actions-positioner");
    await expect(positioner).toHaveAttribute("data-side", /top|right|bottom|left/);

    const anchor = await trigger.boundingBox();
    const box = await positioner.boundingBox();
    expect(Math.abs(box.x - anchor.x)).toBeLessThan(40);
  });
});

test.describe("dropdown menu checkbox items", () => {
  test("toggle state and keep the menu open", async ({ page }) => {
    await visit(page, "/preview/dropdown-menu/checkboxes", "#appearance-trigger");

    const trigger = page.locator("#appearance-trigger");
    const popup = page.locator("#appearance-popup");
    const status = page.locator("#appearance-item-status-bar");
    const activity = page.locator("#appearance-item-activity-bar");
    const panel = page.locator("#appearance-item-panel");

    await trigger.click();

    await expect(status).toHaveRole("menuitemcheckbox");
    await expect(status).toHaveAttribute("aria-checked", "true");
    await expect(activity).toHaveAttribute("aria-disabled", "true");
    await expect(panel).toHaveAttribute("aria-checked", "false");

    await panel.click();

    await expect(popup).toBeVisible();
    await expect(panel).toHaveAttribute("aria-checked", "true");
    await expect(
      panel.locator("[data-slot='dropdown-menu-checkbox-item-indicator']"),
    ).toBeVisible();
  });

  test("support arrow keys and Space", async ({ page }) => {
    await visit(page, "/preview/dropdown-menu/checkboxes", "#appearance-trigger");

    const trigger = page.locator("#appearance-trigger");
    const popup = page.locator("#appearance-popup");
    const status = page.locator("#appearance-item-status-bar");
    const panel = page.locator("#appearance-item-panel");

    await trigger.click();
    await expect(popup).toBeFocused();

    await page.keyboard.press("ArrowDown");
    await expect(status).toBeFocused();

    await page.keyboard.press("ArrowDown");
    await expect(panel).toBeFocused();

    await page.keyboard.press("Space");
    await expect(panel).toHaveAttribute("aria-checked", "true");
    await expect(popup).toBeVisible();
  });
});

test.describe("dropdown menu radio items", () => {
  test("select one value and keep the menu open", async ({ page }) => {
    await visit(page, "/preview/dropdown-menu/radio-group", "#panel-position-trigger");

    const trigger = page.locator("#panel-position-trigger");
    const popup = page.locator("#panel-position-popup");
    const top = page.locator("#panel-position-item-top");
    const bottom = page.locator("#panel-position-item-bottom");

    await trigger.click();

    await expect(top).toHaveRole("menuitemradio");
    await expect(top).toHaveAttribute("aria-checked", "false");
    await expect(bottom).toHaveAttribute("aria-checked", "true");

    await top.click();

    await expect(popup).toBeVisible();
    await expect(top).toHaveAttribute("aria-checked", "true");
    await expect(bottom).toHaveAttribute("aria-checked", "false");
    await expect(
      top.locator("[data-slot='dropdown-menu-radio-item-indicator']"),
    ).toBeVisible();
    await expect(
      bottom.locator("[data-slot='dropdown-menu-radio-item-indicator']"),
    ).toBeHidden();
  });

  test("support arrow keys and Enter", async ({ page }) => {
    await visit(page, "/preview/dropdown-menu/radio-group", "#panel-position-trigger");

    const trigger = page.locator("#panel-position-trigger");
    const popup = page.locator("#panel-position-popup");
    const top = page.locator("#panel-position-item-top");

    await trigger.click();
    await page.keyboard.press("ArrowDown");
    await expect(top).toBeFocused();

    await page.keyboard.press("Enter");
    await expect(top).toHaveAttribute("aria-checked", "true");
    await expect(popup).toBeVisible();
  });
});
