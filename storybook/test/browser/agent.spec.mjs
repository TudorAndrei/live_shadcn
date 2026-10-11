import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("an agent exposes its tool details and output schema", async ({ page }) => {
  await visit(page, "/preview/agent/contract", "#review-tools");
  await expect(page.getByText("Code reviewer", { exact: true })).toBeVisible();
  await expect(page.getByText("Report defects with a file and line number.")).toBeVisible();
  await expect(page.locator("code").filter({ hasText: "{ findings: string[] }" })).toBeVisible();

  const tool = page.getByRole("button", { name: "read_file", exact: true });
  const description = page.getByText("Read a file from the selected repository.");
  await expect(description).toBeHidden();
  await tool.press("Enter");
  await expect(description).toBeVisible();
  await expect(page.locator("code").filter({ hasText: "{ path: string }" })).toBeVisible();
  await tool.press(" ");
  await expect(description).toBeHidden();
});
