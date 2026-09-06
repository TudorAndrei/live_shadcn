import { expect, test } from "@playwright/test";

import { connected } from "./live.mjs";

test("the default example advances after its delay", async ({ page }) => {
  await page.goto("/preview/progress/default");
  await connected(page);

  const progress = page.locator("[data-slot='progress']");
  await expect(progress).toHaveAttribute("aria-valuenow", "13");
  await expect(progress).toHaveAttribute("aria-valuenow", "66");
});

test("the controlled example keeps the progress value with the slider", async ({ page }) => {
  await page.goto("/preview/progress/controlled");
  await connected(page);

  const slider = page.locator("#progress-slider input[type='range']").first();
  const progress = page.locator("[data-slot='progress']");

  await slider.fill("72");

  await expect(slider).toHaveValue("72");
  await expect(progress).toHaveAttribute("aria-valuenow", "72");
});
