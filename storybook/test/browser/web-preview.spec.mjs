import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("the address bar loads the entered URL", async ({ page }) => {
  await visit(page, "/preview/web-preview/default", "input[placeholder='Enter URL...']");

  const address = page.locator("input[placeholder='Enter URL...']");
  const frame = page.locator("iframe[title='Preview']");
  const preview = page.frameLocator("iframe[title='Preview']");
  await expect(preview.getByRole("heading", { name: "Release notes", level: 1 })).toBeVisible();

  await address.fill("/previews/release.html?version=next");
  await address.press("Enter");

  await expect(frame).toHaveAttribute("src", "/previews/release.html?version=next");
  await expect(preview.getByRole("heading", { name: "Release notes", level: 1 })).toBeVisible();
});
