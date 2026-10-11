import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("artifact actions reach the caller and preserve content after reopening", async ({ page }) => {
  await visit(page, "/preview/artifact/contract", "#review-artifact");
  await expect(page.getByText("Review content 1", { exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Revise review", exact: true }).press("Enter");
  await expect(page.getByText("Review content 2", { exact: true })).toBeVisible();
  await expect(page.getByText("Review version 2", { exact: true })).toBeVisible();

  await page.getByRole("button", { name: "Close", exact: true }).press(" ");
  await expect(page.locator("#review-artifact")).toBeHidden();
  await page.getByRole("button", { name: "Open review", exact: true }).click();
  await expect(page.getByText("Review content 2", { exact: true })).toBeVisible();
});
