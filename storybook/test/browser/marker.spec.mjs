import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

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

  test("shows the official notice when the revert button is selected", async ({ page }) => {
    await page.getByRole("button", { name: "Revert this change" }).click();

    await expect(page.getByRole("status")).toContainText("You clicked the revert button");
  });
});
