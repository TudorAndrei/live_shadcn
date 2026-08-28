import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("the citation carousel moves and updates its index", async ({ page }) => {
  await visit(page, "/preview/inline-citation/carousel", "#citation-carousel");

  const viewport = page.locator("#citation-carousel [data-lb-carousel-viewport]");
  const previous = page.getByRole("button", { name: "Previous" });
  const next = page.getByRole("button", { name: "Next" });
  const index = page.locator("[data-lb-carousel-index]");

  await expect(index).toHaveText("1/2");
  await expect(previous).toBeDisabled();
  await expect(next).toBeEnabled();

  await next.click();
  await expect.poll(() => viewport.evaluate((element) => element.scrollLeft)).toBeGreaterThan(0);
  await expect(index).toHaveText("2/2");
  await expect(previous).toBeEnabled();
  await expect(next).toBeDisabled();

  await previous.click();
  await expect.poll(() => viewport.evaluate((element) => element.scrollLeft)).toBe(0);
  await expect(index).toHaveText("1/2");
});
