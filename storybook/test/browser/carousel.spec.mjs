import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const viewport = (page) => page.locator("[data-lb-carousel-viewport]");
const previous = (page) => page.locator("[data-lb-carousel-previous]");
const next = (page) => page.locator("[data-lb-carousel-next]");

test.describe("a carousel", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/carousel/default");
    await expect(viewport(page)).toBeVisible();
  });

  test("moves a slide and measures its controls", async ({ page }) => {
    await expect(previous(page)).toBeDisabled();
    await expect(next(page)).toBeEnabled();

    await next(page).click();

    await expect
      .poll(() => viewport(page).evaluate((element) => element.scrollLeft))
      .toBeGreaterThan(0);
    await expect(previous(page)).toBeEnabled();
  });

  test("moves back with an arrow key", async ({ page }) => {
    await next(page).click();
    await expect
      .poll(() => viewport(page).evaluate((element) => element.scrollLeft))
      .toBeGreaterThan(0);

    await next(page).press("ArrowLeft");

    await expect.poll(() => viewport(page).evaluate((element) => element.scrollLeft)).toBe(0);
  });
});
