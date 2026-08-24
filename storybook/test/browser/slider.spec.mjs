// Behaviour parity for the slider.
//
// The control is a native `<input type="range">` per thumb, so most of what a
// slider does is the platform's and needs no test here. What does need one is
// the half this project wrote: whether the thumb a reader sees ends up where
// the input a reader operates says it is.

import { expect, test } from "@playwright/test";

const thumbs = (page) => page.locator("[data-lb-slider-thumb]");
const inputs = (page) => page.locator("[data-lb-slider-input]");
const range = (page) => page.locator("[data-lb-slider-range]");

// The hook places on mount, which is when the LiveView connects.
const placed = async (page) =>
  page.waitForFunction(
    () => document.querySelector("[data-lb-slider-thumb]")?.style.insetInlineStart !== "",
  );

test.describe("a slider", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/preview/slider/default");
    await expect(page.locator("#passes")).toBeVisible();
    await placed(page);
  });

  test("the thumb sits where its input says", async ({ page }) => {
    // 3 of 1..5 is halfway.
    await expect(thumbs(page).first()).toHaveCSS("inset-inline-start", /.+/);

    const along = await thumbs(page).first().evaluate((el) => el.style.insetInlineStart);
    expect(along).toBe("50%");
  });

  test("moving the input moves the thumb", async ({ page }) => {
    await inputs(page).first().fill("5");

    await expect
      .poll(() => thumbs(page).first().evaluate((el) => el.style.insetInlineStart))
      .toBe("100%");
  });

  test("the filled part of the track reaches the thumb", async ({ page }) => {
    await inputs(page).first().fill("1");
    await expect.poll(() => range(page).evaluate((el) => el.style.width)).toBe("0%");

    await inputs(page).first().fill("5");
    await expect.poll(() => range(page).evaluate((el) => el.style.width)).toBe("100%");
  });

  test("a keypress moves it, because the input is a real one", async ({ page }) => {
    await inputs(page).first().focus();
    await page.keyboard.press("ArrowRight");

    await expect(inputs(page).first()).toHaveValue("4");
    await expect
      .poll(() => thumbs(page).first().evaluate((el) => el.style.insetInlineStart))
      .toBe("75%");
  });

  test("moving it costs no round trip", async ({ page }) => {
    const events = [];
    page.on("websocket", (socket) =>
      socket.on("framesent", ({ payload }) => events.push(String(payload))),
    );

    await inputs(page).first().fill("5");
    await expect
      .poll(() => thumbs(page).first().evaluate((el) => el.style.insetInlineStart))
      .toBe("100%");

    expect(events.filter((frame) => frame.includes("event"))).toEqual([]);
  });
});

test.describe("a slider with two values", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/preview/slider/range");
    await expect(page.locator("#tiers")).toBeVisible();
    await placed(page);
  });

  test("draws one thumb per value, and one input under each", async ({ page }) => {
    await expect(thumbs(page)).toHaveCount(2);
    await expect(inputs(page)).toHaveCount(2);
  });

  test("both inputs carry the same name, so the form reports a list", async ({ page }) => {
    await expect(inputs(page).first()).toHaveAttribute("name", "tiers");
    await expect(inputs(page).nth(1)).toHaveAttribute("name", "tiers");
  });

  test("the filled part of the track runs between them", async ({ page }) => {
    const { start, width } = await range(page).evaluate((el) => ({
      start: el.style.insetInlineStart,
      width: el.style.width,
    }));

    expect(start).toBe("20%");
    expect(width).toBe("60%");
  });
});
