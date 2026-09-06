import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("the avatar dropdown follows the menu interaction contract", async ({ page }) => {
  await visit(page, "/preview/avatar/dropdown", "#avatar-dropdown-trigger");

  const trigger = page.locator("#avatar-dropdown-trigger");
  const popup = page.locator("#avatar-dropdown-popup");

  await expect(trigger).toHaveAttribute("aria-haspopup", "menu");
  await expect(trigger).toHaveAttribute("aria-expanded", "false");

  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(popup).toHaveRole("menu");
  await expect(trigger).toHaveAttribute("aria-expanded", "true");

  await page.keyboard.press("ArrowDown");
  await expect(page.locator("#avatar-dropdown-item-profile")).toBeFocused();

  await page.locator("body").click({ position: { x: 5, y: 5 } });
  await expect(popup).toBeHidden();
  await expect(trigger).toHaveAttribute("aria-expanded", "false");
});
