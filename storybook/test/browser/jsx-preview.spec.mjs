import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("a caller can replace compiled content with an error and recover", async ({ page }) => {
  await visit(page, "/preview/jsx-preview/contract", "article");
  const preview = page.getByRole("article", { name: "Compiled preview" });
  await expect(preview).toContainText("Account card");
  await expect(page.locator("#custom-preview-error")).toHaveText("Custom error details");

  await page.getByRole("button", { name: "Show compilation error" }).click();
  await expect(page.getByText("The closing tag is missing.")).toBeVisible();
  await expect(preview).toBeHidden();
  await page.getByRole("button", { name: "Restore compiled preview" }).click();
  await expect(preview).toBeVisible();
  await expect(page.getByText("The closing tag is missing.")).toBeHidden();
});
