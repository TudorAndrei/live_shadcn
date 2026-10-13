import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("queue actions update completion and remove only the selected item", async ({ page }) => {
  await visit(page, "/preview/queue/contract", "#chatbot-contract");
  const review = page.getByText("Review the response", { exact: true });
  const description = page.getByText("Check the cited sources.", { exact: true });
  await expect(page.getByRole("listitem")).toHaveCount(2);
  await expect(review).toHaveCSS("text-decoration-line", "none");
  await page.locator("#queue-review").hover();
  await page.getByRole("button", { name: "Toggle completion" }).click();
  await expect(review).toHaveCSS("text-decoration-line", "line-through");
  await expect(description).toHaveCSS("text-decoration-line", "line-through");
  await page.getByRole("button", { name: "Toggle completion" }).click();
  await expect(review).toHaveCSS("text-decoration-line", "none");

  await expect(page.getByText("notes.txt", { exact: true })).toBeVisible();
  await page.locator("#queue-draft").hover();
  await page.getByRole("button", { name: "Remove draft" }).click();
  await expect(page.getByRole("listitem")).toHaveCount(1);
  await expect(page.getByText("1 tasks", { exact: true })).toBeVisible();
  await expect(review).toBeVisible();
});

test("the queued prompt removes a task and stops its simulated response", async ({ page }) => {
  await visit(page, "/preview/queue/prompt-input", 'textarea[aria-label="Message"]');
  await expect(page.getByRole("listitem")).toHaveCount(5);
  await page.locator("#todo-2").hover();
  await page.getByRole("button", { name: "Remove Implement authentication", exact: true }).click();
  await expect(page.getByRole("listitem")).toHaveCount(4);
  await page.getByRole("textbox", { name: "Message" }).fill("Review the remaining tasks");
  await page.getByRole("button", { name: "Submit", exact: true }).click();
  await expect(page.getByRole("button", { name: "Stop", exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Stop", exact: true }).click();
  await expect(page.getByRole("button", { name: "Submit", exact: true })).toBeVisible();
  await expect(page.getByRole("status")).toHaveText("Submitted: Review the remaining tasks");

  const message = page.getByRole("textbox", { name: "Message" });
  await message.fill("Check the task order");
  await message.press("Enter");
  await expect(page.getByRole("button", { name: "Stop", exact: true })).toBeVisible();
  await message.fill("Keep this draft");
  await message.press("Enter");
  await expect(page.getByRole("button", { name: "Submit", exact: true })).toBeVisible();
  await expect(page.getByRole("status")).toHaveText("Submitted: Check the task order");
  await expect(message).toHaveValue("Keep this draft");
});
