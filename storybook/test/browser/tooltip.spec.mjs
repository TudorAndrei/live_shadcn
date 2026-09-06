import { expect, test } from "@playwright/test";

import { connected } from "./live.mjs";

test.beforeEach(async ({ page }) => {
  await page.goto("/preview/tooltip/default");
  await connected(page);
});

test("uses the same positioning and reports the same side", async ({ page }) => {
  const trigger = page.locator("#tooltip-default-trigger");
  const positioner = page.locator("#tooltip-default-positioner");
  const popup = page.locator("#tooltip-default-popup");

  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(positioner).toHaveAttribute("data-side", /top|right|bottom|left/);
});
