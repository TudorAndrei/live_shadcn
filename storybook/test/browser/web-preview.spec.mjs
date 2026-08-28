import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("the address bar loads the entered URL", async ({ page }) => {
  await visit(page, "/preview/web-preview/default", "input[placeholder='Enter URL...']");

  const address = page.locator("input[placeholder='Enter URL...']");
  const frame = page.locator("iframe[title='Preview']");

  await address.fill("https://example.org/");
  await address.press("Enter");

  await expect(frame).toHaveAttribute("src", "https://example.org/");
});
