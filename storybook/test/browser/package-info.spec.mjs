import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("package information shows version changes and dependency requirements", async ({ page }) => {
  await visit(page, "/preview/package-info/contract", "#package-change");
  const change = page.locator("#package-change");
  await expect(change).toContainText("live_ai_elements");
  await expect(change).toContainText("0.1.0");
  await expect(change).toContainText("0.1.1");
  await expect(change.getByText("patch", { exact: true })).toBeVisible();
  const requirement = page.getByText("phoenix_live_view", { exact: true }).locator("..");
  await expect(requirement).toContainText("~> 1.2");

  await page.getByRole("button", { name: "Use minor update" }).click();
  await expect(change).toContainText("0.2.0");
  await expect(change.getByText("minor", { exact: true })).toBeVisible();
  await expect(change).toContainText("0.1.0");
});
