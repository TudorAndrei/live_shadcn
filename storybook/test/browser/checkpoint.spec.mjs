import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("checkpoint tooltip explains its action and restore reaches the caller once", async ({ page }) => {
  await visit(page, "/preview/checkpoint/contract", "#chatbot-contract");
  const restore = page.getByRole("button", { name: "Restore checkpoint" });
  const tooltip = page.locator("#restore-checkpoint-popup");

  await expect(tooltip).toBeHidden();
  await restore.hover();
  await expect(tooltip).toHaveText("Restore this saved conversation");
  await expect(tooltip).toBeVisible();
  await restore.click();

  await expect(page.getByRole("status")).toHaveText("Conversation restored");
  await expect(restore).toBeDisabled();
  await expect(page.locator("#chatbot-contract")).toHaveAttribute("data-actions", "1");
});
