// Behaviour parity for the popover family.
//
// Everything here needs a browser twice over. Opening is a client command, and
// *where* it opens is a measurement — `data-side` reports the side the popup
// actually landed on, which is not knowable until it is on the page and the
// browser has said how much room was left.

import { expect, test } from "@playwright/test";

const popover = (page, id) => ({
  trigger: page.locator(`#${id}-trigger`),
  positioner: page.locator(`#${id}-positioner`),
  popup: page.locator(`#${id}-popup`),
});

test.describe("a popover", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/preview/popover/default");
    await expect(page.locator("#details-trigger")).toBeVisible();
  });

  test("starts closed, and says so", async ({ page }) => {
    const { trigger, popup } = popover(page, "details");

    await expect(popup).toBeHidden();
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
  });

  test("a click opens it and a second click closes it", async ({ page }) => {
    const { trigger, popup } = popover(page, "details");

    await trigger.click();
    await expect(popup).toBeVisible();
    await expect(trigger).toHaveAttribute("data-popup-open", "");

    await trigger.click();
    await expect(popup).toBeHidden();
  });

  test("it is placed beside its trigger, not at the origin", async ({ page }) => {
    const { trigger, positioner } = popover(page, "details");

    await trigger.click();
    await expect(page.locator("#details-popup")).toBeVisible();

    const anchor = await trigger.boundingBox();
    const box = await positioner.boundingBox();

    // Below the trigger, and overlapping it horizontally. Where exactly is the
    // browser's business; that it is anchored at all is the hook's.
    expect(box.y).toBeGreaterThan(anchor.y);
    expect(box.x).toBeLessThan(anchor.x + anchor.width + 40);
  });

  test("it reports the side it actually landed on", async ({ page }) => {
    const { trigger, positioner } = popover(page, "details");

    await trigger.click();
    await expect(page.locator("#details-popup")).toBeVisible();

    await expect(positioner).toHaveAttribute("data-side", /top|right|bottom|left/);
    await expect(positioner).toHaveAttribute("data-align", /start|center|end/);
  });

  test("it measures the room it was given, which no class string can", async ({ page }) => {
    const { trigger, positioner } = popover(page, "details");

    await trigger.click();
    await expect(page.locator("#details-popup")).toBeVisible();

    const measured = await positioner.evaluate((el) => ({
      anchor: getComputedStyle(el).getPropertyValue("--anchor-width"),
      available: getComputedStyle(el).getPropertyValue("--available-height"),
      origin: getComputedStyle(el).getPropertyValue("--transform-origin"),
    }));

    expect(parseFloat(measured.anchor)).toBeGreaterThan(0);
    expect(parseFloat(measured.available)).toBeGreaterThan(0);
    expect(measured.origin.trim()).toMatch(/top|right|bottom|left/);
  });

  test("Escape closes it", async ({ page }) => {
    const { trigger, popup } = popover(page, "details");

    await trigger.click();
    await expect(popup).toBeVisible();

    await page.keyboard.press("Escape");
    await expect(popup).toBeHidden();
  });

  test("a click outside closes it", async ({ page }) => {
    const { trigger, popup } = popover(page, "details");

    await trigger.click();
    await expect(popup).toBeVisible();

    await page.locator("h1").click({ force: true });
    await expect(popup).toBeHidden();
  });

  test("the focus moves into it, because a popover is a dialog", async ({ page }) => {
    const { trigger, popup } = popover(page, "details");

    await trigger.click();
    await expect(popup).toBeVisible();

    const inside = await popup.evaluate((el) => el.contains(document.activeElement));
    expect(inside).toBe(true);
  });
});

test.describe("a tooltip", () => {
  test("uses the same positioning and reports the same side", async ({ page }) => {
    await page.goto("/preview/tooltip/default");
    const { trigger, positioner, popup } = popover(page, "digest");

    await trigger.click();
    await expect(popup).toBeVisible();

    await expect(positioner).toHaveAttribute("data-side", /top|right|bottom|left/);
  });
});
