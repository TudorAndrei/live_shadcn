import { expect, test } from "@playwright/test";

import { connected, referenceReady, visit } from "./live.mjs";

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

for (const side of ["React", "Phoenix"]) {
  test(`choice-card labels keep focus on the visible radio on ${side}`, async ({ page }, testInfo) => {
    const path = "/preview/field/choice-card";
    await page.goto(side === "React" ? `${testInfo.project.use.parityURL}${path}` : path);
    await (side === "React" ? referenceReady(page) : connected(page));
    const scope = page.locator("[data-preview='field']");
    const label = scope.locator("label").filter({ hasText: "Virtual Machine" });
    const radio = label.getByRole("radio");
    await label.click();
    await expect(radio).toHaveAttribute("aria-checked", "true");
    await expect(radio).toBeFocused();
    await expect(scope.locator("input[type='radio']:checked")).toHaveValue("vm");
    await page.mouse.click(0, 0);
    await label.click();
    await expect(radio).toHaveAttribute("aria-checked", "true");
    await expect(radio).toBeFocused();
    await expect(scope.locator("input[type='radio']:checked")).toHaveValue("vm");
  });
}
