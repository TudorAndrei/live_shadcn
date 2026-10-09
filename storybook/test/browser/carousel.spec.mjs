import { expect, test } from "@playwright/test";

import { connected } from "./live.mjs";

const sides = [
  { name: "official React", live: false },
  { name: "Phoenix port", live: true },
];

const root = (page) => page.locator("[data-slot='carousel']");
const track = (page) => page.locator("[data-slot='carousel-content'] > div");
const items = (page) => page.locator("[data-slot='carousel-item']");
const previous = (page) => page.locator("[data-slot='carousel-previous']");
const next = (page) => page.locator("[data-slot='carousel-next']");

async function visitSide(page, testInfo, side, example) {
  const path = `/preview/carousel/${example}`;
  await page.goto(side.live ? path : `${testInfo.project.use.parityURL}${path}`);
  if (side.live) await connected(page);

  await expect(root(page)).toBeVisible();
  await expect(items(page)).toHaveCount(5);
  await expect(track(page)).toHaveCSS("transform", /matrix/);
}

async function transformPosition(locator) {
  return locator.evaluate((element) => {
    const matrix = new DOMMatrixReadOnly(getComputedStyle(element).transform);
    return { x: matrix.m41, y: matrix.m42 };
  });
}

for (const side of sides) {
  test.describe(`${side.name} carousel`, () => {
    test("moves one slide and updates its controls", async ({ page }, testInfo) => {
      await visitSide(page, testInfo, side, "default");
      await expect(previous(page)).toBeDisabled();
      await expect(next(page)).toBeEnabled();

      const before = await transformPosition(track(page));
      await next(page).click();

      await expect.poll(async () => (await transformPosition(track(page))).x).not.toBe(before.x);
      await expect(previous(page)).toBeEnabled();

      await next(page).press("ArrowLeft");
      await expect.poll(async () => (await transformPosition(track(page))).x).toBeCloseTo(before.x, 0);
    });

    test("moves one partial-width item in the size example", async ({ page }, testInfo) => {
      await visitSide(page, testInfo, side, "size");

      const before = await transformPosition(track(page));
      const viewportWidth = await page
        .locator("[data-slot='carousel-content']")
        .evaluate((element) => element.clientWidth);
      const itemWidth = await items(page).first().evaluate((element) => element.getBoundingClientRect().width);

      await next(page).click();
      await expect.poll(async () => Math.abs((await transformPosition(track(page))).x - before.x)).toBeGreaterThan(itemWidth * 0.75);

      const distance = Math.abs((await transformPosition(track(page))).x - before.x);
      expect(distance).toBeLessThan(viewportWidth * 0.75);
    });

    test("moves one spaced item and returns to its first position", async ({ page }, testInfo) => {
      await visitSide(page, testInfo, side, "spacing");

      const before = await transformPosition(track(page));
      const first = await items(page).nth(0).boundingBox();
      const second = await items(page).nth(1).boundingBox();
      expect(first).not.toBeNull();
      expect(second).not.toBeNull();
      const advance = second.x - first.x;

      await next(page).click();
      await expect
        .poll(async () => Math.abs((await transformPosition(track(page))).x - before.x))
        .toBeCloseTo(advance, 0);

      await previous(page).click();
      await expect.poll(async () => (await transformPosition(track(page))).x).toBeCloseTo(before.x, 0);
    });

    test("moves on the vertical axis", async ({ page }, testInfo) => {
      await visitSide(page, testInfo, side, "orientation");
      await expect(track(page)).toHaveClass(/flex-col/);

      const before = await transformPosition(track(page));
      await next(page).click();

      await expect.poll(async () => (await transformPosition(track(page))).y).not.toBe(before.y);
      expect((await transformPosition(track(page))).x).toBeCloseTo(before.x, 0);
    });

    test("reports the selected slide in the API example", async ({ page }, testInfo) => {
      await visitSide(page, testInfo, side, "api");
      await expect(page.getByText("Slide 1 of 5", { exact: true })).toBeVisible();

      await next(page).click();

      await expect(page.getByText("Slide 2 of 5", { exact: true })).toBeVisible();

      await next(page).click();
      await expect(page.getByText("Slide 3 of 5", { exact: true })).toBeVisible();
      await previous(page).click();
      await expect(page.getByText("Slide 2 of 5", { exact: true })).toBeVisible();
      await previous(page).click();
      await expect(page.getByText("Slide 1 of 5", { exact: true })).toBeVisible();
    });

    test("uses the right-to-left direction", async ({ page }, testInfo) => {
      await visitSide(page, testInfo, side, "rtl");
      await expect(root(page)).toHaveAttribute("dir", "rtl");
      await expect(previous(page)).toBeDisabled();

      const before = await transformPosition(track(page));
      await next(page).click();

      await expect.poll(async () => (await transformPosition(track(page))).x).not.toBe(before.x);
      await expect(previous(page)).toBeEnabled();
    });

    test("starts and pauses the autoplay plugin", async ({ page }, testInfo) => {
      test.setTimeout(15_000);
      await visitSide(page, testInfo, side, "plugin");

      await page.mouse.move(0, 0);
      const initial = await transformPosition(track(page));
      await expect
        .poll(async () => (await transformPosition(track(page))).x, { timeout: 3000 })
        .not.toBe(initial.x);

      await page.waitForTimeout(500);
      await root(page).hover();
      const paused = await transformPosition(track(page));
      await page.waitForTimeout(2200);
      const afterPause = await transformPosition(track(page));
      expect(afterPause.x).toBeCloseTo(paused.x, 1);
      expect(afterPause.y).toBeCloseTo(paused.y, 1);
    });
  });
}
