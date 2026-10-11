import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("a node toolbar delivers its action to the caller", async ({ page }) => {
  await visit(page, "/preview/toolbar/contract", "#ai-media-contract");
  await expect(page.getByLabel("Node status")).toHaveText("Ready");
  await page.getByRole("toolbar", { name: "Node actions" }).getByRole("button", { name: "Run node" }).click();
  await expect(page.getByLabel("Node status")).toHaveText("Running");
});
