import { expect, test } from "@playwright/test";
import { disclosureContract } from "./ai-contracts.mjs";

test("reasoning discloses formatted text without a server request", async ({ page }) => {
  await disclosureContract(page, "reasoning", "#thought");
  await page.getByRole("button", { name: "Thought for 4 seconds" }).press("Space");
  await expect(page.locator("#thought-panel strong")).toHaveText("today's");
  await expect(page.locator("#thought-panel")).toContainText("weather, so call the tool.");
});
