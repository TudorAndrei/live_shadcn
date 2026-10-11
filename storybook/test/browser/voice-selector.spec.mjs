import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("voice metadata and preview controls reflect caller state", async ({ page }) => {
  await visit(page, "/preview/voice-selector/contract", "#ai-media-contract");
  await expect(page.getByText("Vega", { exact: true })).toBeVisible();
  await expect(page.getByText("Clear spoken instructions.")).toBeVisible();
  await expect(page.getByLabel("female", { exact: true })).toBeVisible();
  await expect(page.getByLabel("british", { exact: true })).toBeVisible();
  await expect(page.getByRole("button", { name: "Loading preview" })).toBeDisabled();
  await page.getByRole("button", { name: "Play preview", exact: true }).click();
  await expect(page.getByLabel("Preview state")).toHaveText("Playing");
  const pause = page.getByRole("button", { name: "Pause preview", exact: true });
  await expect(pause).toBeVisible();
  await expect(pause.locator("svg")).toHaveClass(/lucide-pause/);
  await pause.press("Enter");
  await expect(page.getByLabel("Preview state")).toHaveText("Paused");
  await expect(page.getByRole("button", { name: "Play preview", exact: true })).toBeVisible();
});
