import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("test results calculate progress and disclose a failed test", async ({ page }) => {
  await visit(page, "/preview/test-results/contract", "#test-progress");
  const progress = page.getByRole("progressbar", { name: "Tests passed" });
  await expect(progress).toHaveAttribute("aria-valuenow", "50.0");
  await expect(progress).toHaveAttribute("aria-valuetext", "2/4 tests passed");
  await expect(page.getByText("1 skipped", { exact: true })).toBeVisible();
  await expect(page.getByText("1.25s", { exact: true })).toBeVisible();

  await page.getByRole("button", { name: "Parser results", exact: true }).click();
  await expect(page.getByText("Expected a validation error.")).toBeVisible();
  await expect(page.getByText("parser_test.exs:42", { exact: true })).toBeVisible();
  await expect(page.getByText("7ms", { exact: true })).toBeVisible();
  await expect(page.getByRole("img", { name: "failed", exact: true })).toBeVisible();

  await page.getByRole("button", { name: "Finish test run" }).click();
  await expect(page.locator("#run-duration")).toHaveText("130ms");
  await expect(progress).toHaveAttribute("aria-valuenow", "100.0");

  await page.getByRole("button", { name: "Clear test results" }).click();
  await expect(progress).toHaveAttribute("aria-valuenow", "0");
  await expect(progress).toHaveAttribute("aria-valuetext", "0/0 tests passed");
  await expect(page.locator("#test-progress")).toContainText("0%");
  await expect(page.locator("#run-duration")).toBeHidden();
});
