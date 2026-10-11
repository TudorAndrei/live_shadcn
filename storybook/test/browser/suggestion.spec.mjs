import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("suggestions send their values with default and custom labels", async ({ page }) => {
  await visit(page, "/preview/suggestion/contract", "#chatbot-contract");
  await page.getByRole("button", { name: "Explain the result" }).click();
  await expect(page.getByLabel("Prompt")).toHaveValue("Explain the result");
  await page.getByRole("button", { name: "Sources", exact: true }).press("Enter");
  await expect(page.getByLabel("Prompt")).toHaveValue("Show the sources");
  await expect(page.locator("#chatbot-contract")).toHaveAttribute("data-actions", "2");
  await expect(page.getByRole("button", { name: "Unavailable" })).toBeDisabled();
});

test("a suggestion fills the prompt and submits the selected question", async ({ page }) => {
  await visit(page, "/preview/suggestion/input", "#variant-message");
  await page.getByRole("button", { name: "Explain quantum computing", exact: true }).click();
  await expect(page.getByRole("textbox", { name: "Message" })).toHaveValue("Explain quantum computing");
  await page.getByRole("button", { name: "Submit", exact: true }).click();
  await expect(page.getByRole("status")).toHaveText("Submitted: Explain quantum computing");
  await expect(page.getByRole("textbox", { name: "Message" })).toHaveValue("");
});
