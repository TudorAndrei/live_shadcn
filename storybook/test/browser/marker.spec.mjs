import { expect, test } from "@playwright/test";

import { referenceReady, visit } from "./live.mjs";

test.describe("the official marker link and button example", () => {
  test.beforeEach(async ({ page }) => {
    await visit(
      page,
      "/preview/marker/link-button",
      "[data-slot='marker'][href='#links-and-buttons']",
    );
  });

  test("uses native link and button elements", async ({ page }) => {
    await expect(page.getByRole("link", { name: "View the pull request" })).toHaveAttribute(
      "href",
      "#links-and-buttons",
    );
    await expect(page.getByRole("button", { name: "Revert this change" })).toHaveAttribute(
      "type",
      "button",
    );
  });

  test("shows the official notice when the revert button is selected", async ({ page }, testInfo) => {
    for (const path of [
      `${testInfo.project.use.parityURL}/preview/marker/link-button`,
      "/preview/marker/link-button",
    ]) {
      if (path.startsWith("http")) {
        await page.goto(path);
        await referenceReady(page);
      } else await visit(page, path);

      await page.getByRole("button", { name: "Revert this change" }).click();
      const notice = page.locator("[data-sonner-toaster]").getByRole("listitem");
      await expect(notice).toHaveCount(1);
      await expect(notice.locator("[data-title]")).toHaveText("You clicked the revert button");
      await expect(notice.locator("xpath=ancestor::section")).toHaveAttribute("aria-live", "polite");
    }
  });
});
