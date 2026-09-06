import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test.beforeEach(async ({ page }) => {
  await visit(page, "/preview/hover-card/default", "#nextjs-trigger");
});

test("hover opens the card and leaving both parts closes it", async ({ page }) => {
  const trigger = page.locator("#nextjs-trigger");
  const popup = page.locator("#nextjs-popup");

  await trigger.hover();
  await expect(popup).toBeVisible();

  await popup.hover();
  await page.waitForTimeout(150);
  await expect(popup).toBeVisible();

  await page.mouse.move(0, 0);
  await expect(popup).toBeHidden();
});

test("keyboard focus opens the card without a pointer delay", async ({ page }) => {
  const trigger = page.locator("#nextjs-trigger");
  const popup = page.locator("#nextjs-popup");

  await trigger.focus();
  await expect(popup).toBeVisible();
});
