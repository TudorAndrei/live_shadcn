// Behaviour parity for the scroll area.
//
// Every attribute and every variable this component's class strings read is a
// measurement, and `LiveBase.Scroller` is the only module in that package that
// makes all of them. So this suite asks the one question the snapshot cannot:
// after the page is live, does the browser agree there is something to scroll.

import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const root = (page) => page.locator("#tags");
const viewport = (page) => page.locator("[data-lb-scroller]");
const thumb = (page) => page.locator("[data-lb-thumb]");
const area = (page, id) => page.locator(`#${id}`);
const areaViewport = (page, id) => area(page, id).locator("[data-lb-scroller]");
const areaThumb = (page, id, orientation) =>
  area(page, id).locator(`[data-lb-thumb][data-orientation='${orientation}']`);

// The hook measures when the LiveView connects, which is after the
// server-rendered HTML is on the page.
const measured = async (page) =>
  page.waitForFunction(() => {
    const value = getComputedStyle(document.querySelector("#tags")).getPropertyValue(
      "--scroll-area-thumb-height",
    );

    return value !== "" && value !== "0px";
  });

const measuredAxis = async (page, id, axis) =>
  page.waitForFunction(
    ({ id, axis }) => {
      const value = getComputedStyle(document.getElementById(id)).getPropertyValue(
        `--scroll-area-thumb-${axis === "x" ? "width" : "height"}`,
      );
      return value !== "" && value !== "0px";
    },
    { id, axis },
  );

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
      const el = document.querySelector("#tags");

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

test("the horizontal artwork example scrolls on the x axis and moves its thumb", async ({ page }) => {
  await visit(page, "/preview/scroll-area/horizontal-demo", "#artwork");
  await measuredAxis(page, "artwork", "x");

  const horizontal = area(page, "artwork");
  const scroller = areaViewport(page, "artwork");
  const horizontalThumb = areaThumb(page, "artwork", "horizontal");
  const before = await horizontalThumb.evaluate((element) => element.style.transform);

  await expect(horizontal).toHaveAttribute("data-has-overflow-x", "");
  await expect(horizontal).toHaveAttribute("data-overflow-x-end", "");
  await scroller.evaluate((element) => element.scrollTo({ left: element.scrollWidth, behavior: "auto" }));

  await expect.poll(() => scroller.evaluate((element) => element.scrollLeft)).toBeGreaterThan(0);
  await expect(horizontal).toHaveAttribute("data-overflow-x-start", "");
  await expect(horizontal).not.toHaveAttribute("data-overflow-x-end", "");
  await expect
    .poll(() => horizontalThumb.evaluate((element) => element.style.transform))
    .not.toBe(before);
});

test("the RTL tag example keeps direction while the user scrolls to the end", async ({ page }) => {
  await visit(page, "/preview/scroll-area/rtl", "#tags-rtl");
  await measuredAxis(page, "tags-rtl", "y");

  const rtl = area(page, "tags-rtl");
  const scroller = areaViewport(page, "tags-rtl");
  await expect(rtl).toHaveAttribute("dir", "rtl");
  await expect(rtl).toHaveAttribute("data-has-overflow-y", "");

  await scroller.evaluate((element) => element.scrollTo({ top: element.scrollHeight, behavior: "auto" }));
  await expect.poll(() => scroller.evaluate((element) => element.scrollTop)).toBeGreaterThan(0);
  await expect(rtl).toHaveAttribute("data-overflow-y-start", "");
  await expect(rtl).not.toHaveAttribute("data-overflow-y-end", "");
});
