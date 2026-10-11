import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("shimmer moves its gradient across the text in a two second cycle", async ({ page }) => {
  await visit(page, "/preview/shimmer/default", "#thinking");
  const shimmer = page.locator("#thinking");
  await expect(shimmer).toHaveText("This text has a shimmer effect");
  const motion = await shimmer.evaluate((element) => {
    const animation = element.getAnimations()[0];
    animation.pause();
    animation.currentTime = 0;
    const start = getComputedStyle(element).backgroundPosition;
    animation.currentTime = 1000;
    const halfway = getComputedStyle(element).backgroundPosition;
    return {
      start,
      halfway,
      duration: animation.effect.getTiming().duration,
      spread: getComputedStyle(element).getPropertyValue("--spread"),
    };
  });
  expect(motion.duration).toBe(2000);
  expect(motion.spread).toBe("60px");
  expect(motion.start).not.toEqual(motion.halfway);
});

test("shimmer keeps readable text without animation when reduced motion is requested", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await visit(page, "/preview/shimmer/default", "#thinking");
  await expect(page.locator("#thinking")).toHaveText("This text has a shimmer effect");
  expect(await page.locator("#thinking").evaluate((element) => element.getAnimations().length)).toBe(0);
});

test("shimmer duration variants use their configured cycle lengths", async ({ page }) => {
  await visit(page, "/preview/shimmer/duration", "#shimmer-fast");
  for (const [id, duration] of [["fast", 1000], ["default", 2000], ["slow", 4000], ["very-slow", 6000]]) {
    const actual = await page.locator(`#shimmer-${id}`).evaluate((element) => element.getAnimations()[0].effect.getTiming().duration);
    expect(actual).toBe(duration);
  }
});

test("shimmer supports semantic headings and inline text", async ({ page }) => {
  await visit(page, "/preview/shimmer/elements", "#shimmer-heading");
  await expect(page.getByRole("heading", { name: "Large Heading with Shimmer", level: 2 })).toBeVisible();
  await expect(page.locator("span#shimmer-inline")).toHaveText("with AI magic");
  await expect(page.locator("p#shimmer-paragraph")).toHaveText("This is rendered as a paragraph");
  await expect(page.locator("div#shimmer-div")).toHaveText("Custom styled shimmer text");
});
