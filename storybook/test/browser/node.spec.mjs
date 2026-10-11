import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("a node renders optional handles and retains its action after a caller update", async ({ page }) => {
  await visit(page, "/preview/node/contract", "#plain-node");
  await expect(page.locator("#plain-node")).toHaveText("No connections");
  const node = page.locator("#connected-node");
  await expect(node.locator("[data-node-handle='target']")).toBeVisible();
  await expect(node.locator("[data-node-handle='source']")).toBeVisible();
  await expect(node.locator("[data-slot='card-title']")).toHaveText("Reader");
  await expect(node.locator("[data-slot='card-title']")).toHaveClass(/text-blue-600/);
  await expect(node.locator("[data-slot='card-content']")).toHaveText("input.txt");
  await expect(node.locator("[data-slot='card-footer']")).toHaveText("Ready");
  await node.getByRole("button", { name: "Run node" }).click();
  await expect(node.locator("[data-slot='card-footer']")).toHaveText("Running");
});
