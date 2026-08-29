import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const read = (page) =>
  page.locator("[data-preview=shimmer] p").first().evaluate((element) => {
    const animation = element.getAnimations()[0];
    return {
      backgroundPosition: getComputedStyle(element).backgroundPosition,
      duration: animation?.effect.getTiming().duration,
      frames: animation?.effect
        .getKeyframes()
        .map(({ backgroundPosition }) => backgroundPosition),
      spread: getComputedStyle(element).getPropertyValue("--spread"),
    };
  });

test("Shimmer uses the same gradient motion as React", async ({ page }, testInfo) => {
  await page.goto(`${testInfo.project.use.parityURL}/preview/shimmer/default`);
  const react = await read(page);

  await visit(page, "/preview/shimmer/default", "#thinking");
  const phoenix = await read(page);

  expect(phoenix.spread).toBe(react.spread);
  expect(phoenix.duration).toBe(2000);
  expect(phoenix.frames).toEqual(["100% center", "0% center"]);
});
