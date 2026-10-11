import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("graph controls deliver pointer and keyboard actions to the caller", async ({ page }) => {
  await visit(page, "/preview/controls/contract", "#ai-media-contract");
  const controls = page.getByRole("group", { name: "Graph controls" });
  const zoom = page.getByLabel("Zoom", { exact: true });
  await expect(zoom).toHaveText("100%");
  await controls.getByRole("button", { name: "Zoom in" }).click();
  await expect(zoom).toHaveText("125%");
  await controls.getByRole("button", { name: "Zoom out" }).focus();
  await page.keyboard.press("Enter");
  await expect(zoom).toHaveText("100%");
});
