import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const examples = [
  ["default", "actions"],
  ["basic", "dropdown-basic"],
  ["submenu", "dropdown-submenu"],
  ["shortcuts", "dropdown-shortcuts"],
  ["icons", "dropdown-icons"],
  ["checkboxes", "appearance"],
  ["checkboxes-icons", "notification-preferences"],
  ["radio-group", "panel-position"],
  ["radio-icons", "payment-method"],
  ["destructive", "dropdown-destructive"],
  ["avatar", "dropdown-avatar"],
  ["complex", "complex-actions"],
  ["rtl", "dropdown-rtl"],
];

for (const [example, id] of examples) {
  test(`${example} opens and closes when the user clicks outside`, async ({ page }) => {
    await visit(page, `/preview/dropdown-menu/${example}`, `#${id}-trigger`);

    const trigger = page.locator(`#${id}-trigger`);
    const popup = page.locator(`#${id}-popup`);

    await expect(trigger).toHaveAttribute("aria-haspopup", "menu");
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
    await trigger.click();
    await expect(popup).toBeVisible();
    await expect(popup).toHaveRole("menu");

    await page.locator("body").click({ position: { x: 5, y: 5 } });
    await expect(popup).toBeHidden();
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
  });
}

test("the keyboard moves through items and skips a disabled item", async ({ page }) => {
  await visit(page, "/preview/dropdown-menu/default", "#actions-trigger");

  const popup = page.locator("#actions-popup");
  await page.locator("#actions-trigger").click();
  await expect(popup).toBeFocused();

  await page.keyboard.press("ArrowDown");
  await expect(page.locator("#actions-item-profile")).toBeFocused();

  await page.locator("#actions-item-support").focus();
  await page.keyboard.press("ArrowDown");
  await expect(page.locator("#actions-item-log-out")).toBeFocused();

  await page.keyboard.press("Enter");
  await expect(popup).toBeHidden();
});

test("the nested submenu example opens both submenu levels", async ({ page }) => {
  await visit(page, "/preview/dropdown-menu/submenu", "#dropdown-submenu-trigger");
  await page.locator("#dropdown-submenu-trigger").click();

  const invite = page.locator("#dropdown-submenu-invite-users-trigger");
  await invite.click();
  await expect(page.locator("#dropdown-submenu-invite-users-popup")).toBeVisible();

  const more = page.locator("#dropdown-submenu-invite-users-more-options-trigger");
  await more.click();
  await expect(page.locator("#dropdown-submenu-invite-users-more-options-popup")).toBeVisible();
  await expect(page.locator("#dropdown-submenu-popup")).toBeVisible();
  await expect(page.locator("#dropdown-submenu-trigger")).toHaveAttribute("aria-expanded", "true");
  await expect(page.locator("#dropdown-submenu-invite-users-popup")).toBeVisible();
  await expect(invite).toHaveAttribute("aria-expanded", "true");
  await expect(page.getByRole("menuitem", { name: "Webhook" })).toBeVisible();
});

test("checkbox items change state and keep the menu open", async ({ page }) => {
  await visit(page, "/preview/dropdown-menu/checkboxes-icons", "#notification-preferences-trigger");
  await page.locator("#notification-preferences-trigger").click();

  const popup = page.locator("#notification-preferences-popup");
  const email = page.locator("#notification-preferences-item-email");
  const sms = page.locator("#notification-preferences-item-sms");

  await expect(email).toHaveAttribute("aria-checked", "true");
  await expect(sms).toHaveAttribute("aria-checked", "false");
  await sms.click();
  await expect(sms).toHaveAttribute("aria-checked", "true");
  await expect(popup).toBeVisible();
});

test("radio items select one value and keep the menu open", async ({ page }) => {
  await visit(page, "/preview/dropdown-menu/radio-icons", "#payment-method-trigger");
  await page.locator("#payment-method-trigger").click();

  const popup = page.locator("#payment-method-popup");
  const card = page.locator("#payment-method-item-card");
  const bank = page.locator("#payment-method-item-bank");

  await expect(card).toHaveAttribute("aria-checked", "true");
  await bank.click();
  await expect(bank).toHaveAttribute("aria-checked", "true");
  await expect(card).toHaveAttribute("aria-checked", "false");
  await expect(popup).toBeVisible();
});

test("the complex menu opens a third menu level", async ({ page }) => {
  await visit(page, "/preview/dropdown-menu/complex", "#complex-actions-trigger");
  await page.locator("#complex-actions-trigger").click();
  await page.locator("#complex-actions-open-recent-trigger").click();
  await page.locator("#complex-actions-open-recent-more-projects-trigger").click();

  await expect(page.locator("#complex-actions-open-recent-more-projects-popup")).toBeVisible();
  await expect(page.locator("#complex-actions-popup")).toBeVisible();
  await expect(page.locator("#complex-actions-open-recent-popup")).toBeVisible();
  await expect(page.getByRole("menuitem", { name: "Project Gamma" })).toBeVisible();
  await expect(page.getByRole("menuitem", { name: "Project Delta" })).toBeVisible();
});

test("the Arabic menu keeps its direction in each open level", async ({ page }) => {
  await visit(page, "/preview/dropdown-menu/rtl", "#dropdown-rtl-trigger");
  await page.locator("#dropdown-rtl-trigger").click();

  const root = page.locator("#dropdown-rtl-popup");
  await expect(root).toHaveAttribute("dir", "rtl");
  await expect(root).toHaveAttribute("data-lang", "ar");

  await page.locator("#dropdown-rtl-invite-users-trigger").click();
  const invite = page.locator("#dropdown-rtl-invite-users-popup");
  await expect(invite).toHaveAttribute("dir", "rtl");
  await expect(invite).toHaveAttribute("data-lang", "ar");

  await page.locator("#dropdown-rtl-invite-users-more-trigger").click();
  const more = page.locator("#dropdown-rtl-invite-users-more-popup");
  await expect(more).toHaveAttribute("dir", "rtl");
  await expect(more).toHaveAttribute("data-lang", "ar");
});
