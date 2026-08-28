import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("Open in Chat uses the provider query contracts", async ({ page }) => {
  await visit(page, "/preview/open-in-chat/default", "#open-in-chat-trigger");
  await page.locator("#open-in-chat-trigger").click();

  const chatgpt = page.getByRole("menuitem", { name: "Open in ChatGPT" });
  const claude = page.getByRole("menuitem", { name: "Open in Claude" });

  await expect(chatgpt).toBeVisible();
  await expect(claude).toBeVisible();
  await expect(chatgpt).toHaveAttribute(
    "href",
    "https://chatgpt.com/?hints=search&prompt=How+does+the+fold+work%3F",
  );
  await expect(claude).toHaveAttribute(
    "href",
    "https://claude.ai/new?q=How+does+the+fold+work%3F",
  );
  await expect(chatgpt).toHaveAttribute("target", "_blank");
  await expect(chatgpt).toHaveAttribute("rel", "noopener");
});
