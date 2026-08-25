// Behaviour parity for the scroll area.
//
// Every attribute and every variable this component's class strings read is a
// measurement, and `LiveBase.Scroller` is the only module in that package that
// makes all of them. So this suite asks the one question the snapshot cannot:
// after the page is live, does the browser agree there is something to scroll.

import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const root = (page) => page.locator("#stages");
const viewport = (page) => page.locator("[data-lb-scroller]");
const thumb = (page) => page.locator("[data-lb-thumb]");

// The hook measures when the LiveView connects, which is after the
// server-rendered HTML is on the page.
const measured = async (page) =>
  page.waitForFunction(() => {
    const value = getComputedStyle(document.querySelector("#stages")).getPropertyValue(
      "--scroll-area-thumb-height",
    );

    return value !== "" && value !== "0px";
  });

test.describe("a scroll area", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/scroll-area/default");
    await expect(root(page)).toBeVisible();
  });

  test("says there is more than fits, once it has looked", async ({ page }) => {
    await measured(page);

    await expect(root(page)).toHaveAttribute("data-has-overflow-y", "");
    await expect(root(page)).not.toHaveAttribute("data-overflow-y-start", "");
    await expect(root(page)).toHaveAttribute("data-overflow-y-end", "");
  });

  test("the thumb is as much of the track as the viewport is of the content", async ({ page }) => {
    await measured(page);

    const { thumb: height, track } = await page.evaluate(() => {
      const el = document.querySelector("#stages");

      return {
        thumb: parseFloat(getComputedStyle(el).getPropertyValue("--scroll-area-thumb-height")),
        track: el.clientHeight,
      };
    });

    expect(height).toBeGreaterThan(0);
    expect(height).toBeLessThan(track);
  });

  test("scrolling to the bottom moves which edge has more behind it", async ({ page }) => {
    await measured(page);

    await viewport(page).evaluate((el) => el.scrollTo(0, el.scrollHeight));
    await expect(root(page)).toHaveAttribute("data-overflow-y-start", "");
    await expect(root(page)).not.toHaveAttribute("data-overflow-y-end", "");
  });

  test("scrolling moves the thumb, and the thumb is never moved directly", async ({ page }) => {
    await measured(page);

    const before = await thumb(page).evaluate((el) => el.style.transform);
    await viewport(page).evaluate((el) => el.scrollTo(0, el.scrollHeight));

    await expect
      .poll(() => thumb(page).evaluate((el) => el.style.transform))
      .not.toBe(before);
  });

  test("scrolling costs no round trip", async ({ page }) => {
    await measured(page);

    const events = [];
    page.on("websocket", (socket) =>
      socket.on("framesent", ({ payload }) => events.push(String(payload))),
    );

    await viewport(page).evaluate((el) => el.scrollTo(0, el.scrollHeight));
    await expect(root(page)).toHaveAttribute("data-overflow-y-start", "");

    expect(events.filter((frame) => frame.includes("event"))).toEqual([]);
  });
});
