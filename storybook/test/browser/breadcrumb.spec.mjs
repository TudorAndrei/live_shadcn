// Browser behavior for the interactive shadcn Breadcrumb examples.

import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const menu = (page, id) => ({
  trigger: page.locator(`#${id}-trigger`),
  popup: page.locator(`#${id}-popup`),
  items: page.locator(`#${id}-popup [role="menuitem"]`),
});

test.describe("the default breadcrumb menu", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/breadcrumb/default", "#breadcrumb-default-menu-trigger");
  });

  test("opens with the official items", async ({ page }) => {
    const { trigger, popup, items } = menu(page, "breadcrumb-default-menu");

    await trigger.click();

    await expect(trigger).toHaveAttribute("aria-expanded", "true");
    await expect(popup).toBeVisible();
    await expect(items).toHaveText(["Documentation", "Themes", "GitHub"]);
    await expect(items.first()).not.toHaveAttribute("data-highlighted", "");
  });

  test("closes when an item is selected", async ({ page }) => {
    const { trigger, popup, items } = menu(page, "breadcrumb-default-menu");

    await trigger.click();
    await items.filter({ hasText: "Themes" }).click();

    await expect(popup).toBeHidden();
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
  });

  test("closes when the user clicks outside", async ({ page }) => {
    const { trigger, popup } = menu(page, "breadcrumb-default-menu");

    await trigger.click();
    await expect(popup).toBeVisible();
    await page.locator("body").click({ position: { x: 5, y: 5 } });

    await expect(popup).toBeHidden();
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
  });

  test("opens from the keyboard and moves focus into the menu", async ({ page }) => {
    const { trigger, popup, items } = menu(page, "breadcrumb-default-menu");

    await trigger.focus();
    await page.keyboard.press("Enter");

    await expect(popup).toBeVisible();
    await expect(items.first()).toBeFocused();
    await expect(items.first()).toHaveAttribute("data-highlighted", "");
  });
});

test("the RTL menu keeps the official Arabic direction and items", async ({ page }) => {
  await visit(page, "/preview/breadcrumb/rtl", "#breadcrumb-rtl-menu-trigger");
  const { trigger, popup, items } = menu(page, "breadcrumb-rtl-menu");

  await trigger.click();

  await expect(popup).toHaveAttribute("dir", "rtl");
  await expect(popup).toHaveAttribute("data-lang", "ar");
  await expect(items).toHaveText(["التوثيق", "السمات", "جيت هاب"]);
});
