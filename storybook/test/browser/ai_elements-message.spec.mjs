import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("message branches show one answer, return the current page, and wrap in either direction", async ({ page }) => {
  await visit(page, "/preview/ai_elements-message/contract", "#chatbot-contract");
  const first = page.getByText("First answer", { exact: true });
  const second = page.getByText("Second answer", { exact: true });

  await expect(first).toBeVisible();
  await expect(second).toBeHidden();
  await expect(page.getByText("1 of 2", { exact: true })).toBeVisible();
  await expect(page.locator("strong")).toHaveText("selected answer");

  await page.getByRole("button", { name: "Next branch" }).click();
  await expect(first).toBeHidden();
  await expect(second).toBeVisible();
  await expect(page.getByText("2 of 2", { exact: true })).toBeVisible();

  await page.getByRole("button", { name: "Next branch" }).click();
  await expect(first).toBeVisible();
  await expect(second).toBeHidden();
  await page.getByRole("button", { name: "Previous branch" }).click();
  await expect(second).toBeVisible();
  await expect(page.getByText("2 of 2", { exact: true })).toBeVisible();
});

test("message actions expose their tooltip and preserve the caller action", async ({ page }) => {
  await visit(page, "/preview/ai_elements-message/contract", "#chatbot-contract");
  const action = page.getByRole("button", { name: "Save answer", exact: true });
  const tooltip = page.locator("#save-answer-popup");
  await expect(tooltip).toBeHidden();
  await action.hover();
  await expect(tooltip).toBeVisible();
  await expect(tooltip).toHaveText("Save this answer");
  await action.click();
  await expect(page.getByRole("status")).toHaveText("Answer saved");
});
