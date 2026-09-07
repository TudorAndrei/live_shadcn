// Behaviour parity for the slider.
//
// The control is a native `<input type="range">` per thumb, so most of what a
// slider does is the platform's and needs no test here. What does need one is
// the half this project wrote: whether the thumb a reader sees ends up where
// the input a reader operates says it is.

import { expect, test } from "@playwright/test";

import { referenceReady, visit } from "./live.mjs";

const thumbs = (page) => page.locator("[data-lb-slider-thumb]");
const inputs = (page) => page.locator("[data-lb-slider-input]");
const range = (page) => page.locator("[data-lb-slider-range]");

test("the reference accepts keyboard input after delayed hydration", async ({ page }, testInfo) => {
  await page.route("**/slider-rtl.tsx", async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    await route.continue();
  });
  await page.goto(`${testInfo.project.use.parityURL}/preview/slider/rtl`);
  await referenceReady(page);
  const input = page.locator("input[type='range']");
  await input.press("End");
  await expect(input).toHaveValue("100");
});

// The hook places on mount, which is when the LiveView connects.
const placed = async (page) =>
  page.waitForFunction(
    () => document.querySelector("[data-lb-slider-thumb]")?.style.insetInlineStart !== "",
  );

test.describe("a slider", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/slider/default", "#slider-demo");
    await placed(page);
  });

  test("the thumb sits where its input says", async ({ page }) => {
    await expect(thumbs(page).first()).toHaveCSS("inset-inline-start", /.+/);

    const along = await thumbs(page).first().evaluate((el) => el.style.insetInlineStart);
    expect(along).toBe("236px");
  });

  test("moving the input moves the thumb", async ({ page }) => {
    await inputs(page).first().fill("100");

    await expect
      .poll(() => thumbs(page).first().evaluate((el) => el.style.insetInlineStart))
      .toBe("312px");
  });

  test("the filled part of the track reaches the thumb", async ({ page }) => {
    await inputs(page).first().fill("0");
    await expect.poll(() => range(page).evaluate((el) => el.style.width)).toBe("8px");

    await inputs(page).first().fill("100");
    await expect.poll(() => range(page).evaluate((el) => el.style.width)).toBe("312px");
  });

  test("a keypress moves it, because the input is a real one", async ({ page }) => {
    await inputs(page).first().focus();
    await page.keyboard.press("ArrowRight");

    await expect(inputs(page).first()).toHaveValue("76");
    await expect
      .poll(() => thumbs(page).first().evaluate((el) => el.style.insetInlineStart))
      .toBe("239.04px");
  });

  test("moving it costs no round trip", async ({ page }) => {
    const events = [];
    page.on("websocket", (socket) =>
      socket.on("framesent", ({ payload }) => events.push(String(payload))),
    );

    await inputs(page).first().fill("100");
    await expect
      .poll(() => thumbs(page).first().evaluate((el) => el.style.insetInlineStart))
      .toBe("312px");

    expect(events.filter((frame) => frame.includes("event"))).toEqual([]);
  });
});

test.describe("a slider with two values", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/slider/range", "#slider-range");
    await placed(page);
  });

  test("draws one thumb per value, and one input under each", async ({ page }) => {
    await expect(thumbs(page)).toHaveCount(2);
    await expect(inputs(page)).toHaveCount(2);
  });

  test("both native inputs carry the official values and step", async ({ page }) => {
    await expect(inputs(page).first()).toHaveValue("25");
    await expect(inputs(page).nth(1)).toHaveValue("50");
    await expect(inputs(page).first()).toHaveAttribute("step", "5");
    await expect(inputs(page).nth(1)).toHaveAttribute("step", "5");
  });

  test("the filled part of the track runs between them", async ({ page }) => {
    const { start, width } = await range(page).evaluate((el) => ({
      start: el.style.insetInlineStart,
      width: el.style.width,
    }));

    expect(start).toBe("84px");
    expect(width).toBe("76px");
  });
});

test("the multiple example draws all three official values", async ({ page }) => {
  await visit(page, "/preview/slider/multiple", "#slider-multiple");
  await placed(page);

  await expect(inputs(page)).toHaveCount(3);
  await expect(inputs(page).nth(0)).toHaveValue("10");
  await expect(inputs(page).nth(1)).toHaveValue("20");
  await expect(inputs(page).nth(2)).toHaveValue("70");
});

test("the vertical example draws two independent vertical sliders", async ({ page }) => {
  await visit(page, "/preview/slider/vertical", "#slider-vertical-first");
  await placed(page);

  const first = page.locator("#slider-vertical-first");
  const second = page.locator("#slider-vertical-second");

  await expect(first).toHaveAttribute("data-orientation", "vertical");
  await expect(second).toHaveAttribute("data-orientation", "vertical");
  await expect(first.locator("[data-lb-slider-thumb]")).toHaveCSS("bottom", /.+/);
  await expect(second.locator("[data-lb-slider-thumb]")).toHaveCSS("bottom", /.+/);
});

test("the controlled example updates its value text and keeps both values", async ({ page }) => {
  await visit(page, "/preview/slider/controlled", "#slider-demo-temperature");
  await placed(page);

  const controlledInputs = page.locator("#slider-demo-temperature [data-lb-slider-input]");
  await controlledInputs.first().fill("0.4");

  await expect(page.getByText("0.4, 0.7", { exact: true })).toBeVisible();
  await expect(controlledInputs.first()).toHaveValue("0.4");
  await expect(controlledInputs.nth(1)).toHaveValue("0.7");
});

test("the disabled example refuses native input", async ({ page }) => {
  await visit(page, "/preview/slider/disabled", "#slider-disabled");
  await placed(page);

  await expect(page.locator("#slider-disabled")).toHaveAttribute("data-disabled", "");
  await expect(inputs(page).first()).toBeDisabled();
});

test("the RTL example uses right-to-left direction", async ({ page }) => {
  await visit(page, "/preview/slider/rtl", "#slider-rtl");
  await placed(page);

  await expect(page.locator("#slider-rtl")).toHaveAttribute("dir", "rtl");
  await expect(inputs(page).first()).toHaveValue("75");
});
