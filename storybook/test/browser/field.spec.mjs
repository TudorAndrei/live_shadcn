import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("the price range label follows both slider values", async ({ page }) => {
  await visit(page, "/preview/field/slider", "#field-price-range");

  const values = page.locator("#field-price-range input[type='range']");
  const description = page.locator("[data-slot='field-description']");

  await expect(values).toHaveCount(2);
  await values.first().fill("300");

  await expect(values.first()).toHaveValue("300");
  await expect(values.last()).toHaveValue("800");
  await expect(description).toContainText("Set your budget range ($300 - 800).");
});

test("the select field chooses a department and updates its form value", async ({ page }) => {
  await visit(page, "/preview/field/select", "#department-trigger");

  const trigger = page.locator("#department-trigger");
  const input = page.locator("#department-input");

  await trigger.click();
  await page.locator("#department-option-engineering").click();

  await expect(trigger).toContainText("Engineering");
  await expect(input).toHaveValue("engineering");
});
