// Behaviour parity for the popover family.
//
// Everything here needs a browser twice over. Opening is a client command, and
// *where* it opens is a measurement — `data-side` reports the side the popup
// actually landed on, which is not knowable until it is on the page and the
// browser has said how much room was left.

import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const popover = (page, id) => ({
  trigger: page.locator(`#${id}-trigger`),
  positioner: page.locator(`#${id}-positioner`),
  popup: page.locator(`#${id}-popup`),
});

async function placeWithOffset(page, { side, align, offset, dir = "ltr" }) {
  return page.locator("#popover-alignment-start-positioner").evaluate(
    async (positioner, options) => {
      const hook = window.liveSocket.owner(positioner)?.getHook(positioner);

      if (!hook) throw new Error("LiveBase.Popover.Floating hook was not found");

      positioner.setAttribute("data-lb-side", options.side);
      positioner.setAttribute("data-lb-align", options.align);
      positioner.setAttribute("data-lb-align-offset", String(options.offset));
      hook.requestedSide = options.side;
      hook.requestedAlign = options.align;
      hook.popup.dir = options.dir;
      await hook.place();

      return {
        ...positioner.getBoundingClientRect().toJSON(),
        positionerDirection: getComputedStyle(positioner).direction,
        popupDirection: getComputedStyle(hook.popup).direction,
      };
    },
    { side, align, offset, dir },
  );
}

const axis = (side) => (side === "top" || side === "bottom" ? "x" : "y");
const expectedOffset = (align, amount) => (align === "start" ? amount : -amount);

test.describe("a popover", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/popover/default", "#popover-default-trigger");
  });

  test("starts closed, and says so", async ({ page }) => {
    const { trigger, popup } = popover(page, "popover-default");

    await expect(popup).toBeHidden();
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
  });

  test("a click opens it and a second click closes it", async ({ page }) => {
    const { trigger, popup } = popover(page, "popover-default");

    await trigger.click();
    await expect(popup).toBeVisible();
    await expect(trigger).toHaveAttribute("data-popup-open", "");

    await trigger.click();
    await expect(popup).toBeHidden();
  });

  test("it is placed beside its trigger, not at the origin", async ({ page }) => {
    const { trigger, positioner } = popover(page, "popover-default");

    await trigger.click();
    await expect(page.locator("#popover-default-popup")).toBeVisible();

    const anchor = await trigger.boundingBox();
    const box = await positioner.boundingBox();

    // Below the trigger, and overlapping it horizontally. Where exactly is the
    // browser's business; that it is anchored at all is the hook's.
    expect(box.y).toBeGreaterThan(anchor.y);
    expect(box.x).toBeLessThan(anchor.x + anchor.width + 40);
  });

  test("it reports the side it actually landed on", async ({ page }) => {
    const { trigger, positioner } = popover(page, "popover-default");

    await trigger.click();
    await expect(page.locator("#popover-default-popup")).toBeVisible();

    await expect(positioner).toHaveAttribute("data-side", /top|right|bottom|left/);
    await expect(positioner).toHaveAttribute("data-align", /start|center|end/);
  });

  test("it measures the room it was given, which no class string can", async ({ page }) => {
    const { trigger, positioner } = popover(page, "popover-default");

    await trigger.click();
    await expect(page.locator("#popover-default-popup")).toBeVisible();

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
    const { trigger, popup } = popover(page, "popover-default");

    await trigger.click();
    await expect(popup).toBeVisible();

    await page.keyboard.press("Escape");
    await expect(popup).toBeHidden();
  });

  test("a click outside closes it", async ({ page }) => {
    const { trigger, popup } = popover(page, "popover-default");

    await trigger.click();
    await expect(popup).toBeVisible();

    await page.locator("body").click({ position: { x: 5, y: 5 } });
    await expect(popup).toBeHidden();
  });

  test("the focus moves to its first control", async ({ page }) => {
    const { trigger, popup } = popover(page, "popover-default");

    await trigger.click();
    await expect(popup).toBeVisible();
    await expect(page.locator("#width")).toBeFocused();
  });
});

test.describe("Floating align offsets", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/popover/alignments", "#popover-alignment-start-trigger");
    await page.locator("#popover-alignment-start-trigger").click();
    await expect(page.locator("#popover-alignment-start-popup")).toBeVisible();
  });

  for (const side of ["top", "bottom", "left", "right"]) {
    for (const align of ["start", "end"]) {
      test(`${side} ${align} uses the raw offset on its alignment axis`, async ({ page }) => {
        const base = await placeWithOffset(page, { side, align, offset: 0 });
        const shifted = await placeWithOffset(page, { side, align, offset: 12 });

        expect(shifted[axis(side)] - base[axis(side)]).toBeCloseTo(expectedOffset(align, 12));
      });
    }
  }

  for (const align of ["start", "end"]) {
    test(`RTL bottom ${align} keeps the logical horizontal offset`, async ({ page }) => {
      const base = await placeWithOffset(page, { side: "bottom", align, offset: 0, dir: "rtl" });
      const shifted = await placeWithOffset(page, { side: "bottom", align, offset: 12, dir: "rtl" });

      // Public Popover dir is on the popup. The body portal stays LTR.
      expect(base.positionerDirection).toBe("ltr");
      expect(shifted.positionerDirection).toBe("ltr");
      expect(base.popupDirection).toBe("rtl");
      expect(shifted.popupDirection).toBe("rtl");
      expect(shifted.x - base.x).toBeCloseTo(expectedOffset(align, 12));
    });
  }
});
