import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const viewport = (page) => page.locator("#log [data-lb-scroller]");

test.describe("a conversation", () => {
  test("starts at the newest message", async ({ page }) => {
    await visit(page, "/preview/conversation/default", "#log");

    const rootHeight = await page.locator("#log").evaluate((element) => element.clientHeight);
    await expect.poll(() => viewport(page).evaluate((element) => element.clientHeight)).toBe(rootHeight);
    await expect
      .poll(() => viewport(page).evaluate((element) => element.scrollHeight - element.clientHeight))
      .toBeGreaterThan(0);
    await expect
      .poll(() =>
        viewport(page).evaluate((element) =>
          Math.round(element.scrollHeight - element.clientHeight - element.scrollTop),
        ),
      )
      .toBeLessThanOrEqual(1);
  });

  test("uses the same final scroll geometry as React", async ({ page }, testInfo) => {
    const measure = (selector) =>
      page.locator(selector).evaluate((element) => {
        const first = element.querySelector("p").getBoundingClientRect();
        const box = element.getBoundingClientRect();
        return {
          clientHeight: element.clientHeight,
          firstTop: first.top - box.top,
          scrollHeight: element.scrollHeight,
          scrollTop: element.scrollTop,
        };
      });

    await page.goto(`${testInfo.project.use.parityURL}/preview/conversation/default`);
    await page.waitForTimeout(1200);
    const react = await measure("[data-preview=conversation] [role=log] > div");

    await visit(page, "/preview/conversation/default", "#log");
    const phoenix = await measure("#log [data-lb-scroller]");

    expect(phoenix).toEqual(react);
  });

  test("does not pull the reader back after they scroll away", async ({ page }) => {
    await visit(page, "/preview/conversation/default", "#log");

    await viewport(page).evaluate((element) => {
      element.scrollTop = 0;
    });
    await expect.poll(() => viewport(page).evaluate((element) => element.scrollTop)).toBe(0);

    await page.setViewportSize({ width: 1279, height: 720 });
    await expect.poll(() => viewport(page).evaluate((element) => element.scrollTop)).toBe(0);
  });
});
