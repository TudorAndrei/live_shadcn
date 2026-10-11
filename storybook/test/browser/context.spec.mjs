import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("context reveals usage, compact token counts, and caller prices", async ({ page }) => {
  await visit(page, "/preview/context/contract", "#chatbot-contract");
  const panel = page.locator("#context-usage-popup");

  await expect(panel).toBeHidden();
  await page.getByRole("button", { name: "Context usage" }).hover();
  await expect(panel).toBeVisible();
  await expect(panel).toContainText("32K / 128K");
  await expect(panel.getByRole("progressbar")).toHaveAttribute("aria-valuenow", "25");
  await expect(page.locator("#context-input")).toContainText("31K• $0.03");
  await expect(page.locator("#context-output")).toContainText("1K• $0.01");
  await expect(page.locator("#context-reasoning")).toContainText("250");
  await expect(page.locator("#context-cache")).toContainText("1B");
  await expect(panel).toContainText("Total cost$0.04");
  await page.keyboard.press("Escape");
  await expect(panel).toBeHidden();
});
