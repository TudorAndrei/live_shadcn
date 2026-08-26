// What the documentation's own sidebar owes a reader.
//
// A live navigation replaces the LiveView's DOM, and the sidebar is in it. So
// everything the browser owned about the sidebar — how far down the list it is
// scrolled, whether it is collapsed — was drawn again from the server's default
// on every click: back to the top, and open. A reader working through the
// `Workflow` section was returned to `Accordion` each time.
//
// Nothing here reaches the server, which is why it is a browser check rather
// than a rendering one.

import { expect, test } from "@playwright/test";

import { connected } from "./live.mjs";

const NAV = "#docs-nav";
const CONTENT = "#docs-nav-content";
const TRIGGER = "[data-lb-sidebar='docs-nav']";

// A link the reader can see after that scroll, so the click is the click a
// person makes rather than one Playwright scrolled the list to reach.
const inView = (content) =>
  content.evaluate((el) => {
    const box = el.getBoundingClientRect();

    const link = [...el.querySelectorAll('a[href^="/docs/"]')].find((a) => {
      const line = a.getBoundingClientRect();
      return line.top >= box.top && line.bottom <= box.bottom;
    });

    return link?.getAttribute("href");
  });

test.describe("the documentation sidebar", () => {
  test("keeps its place when a component is opened from it", async ({ page }) => {
    await page.goto("/docs/badge");
    await connected(page);

    const content = page.locator(CONTENT);
    await content.evaluate((el) => (el.scrollTop = 1200));

    const href = await inView(content);
    expect(href).toBeTruthy();

    await content.locator(`a[href="${href}"]`).click();
    await page.waitForURL(`**${href}`);
    await connected(page);

    await expect
      .poll(() => page.locator(CONTENT).evaluate((el) => el.scrollTop))
      .toBe(1200);
  });

  test("stays collapsed, and its trigger says so", async ({ page }) => {
    await page.goto("/");
    await connected(page);

    await page.locator(TRIGGER).first().click();
    await expect(page.locator(NAV)).toHaveAttribute("data-state", "collapsed");

    // From the front page's own list, because a collapsed sidebar is off the
    // canvas and the link it has for the same page is out of reach.
    await page.locator(`a[href="/docs/button"]:not(${NAV} a)`).click();
    await page.waitForURL("**/docs/button");
    await connected(page);

    await expect(page.locator(NAV)).toHaveAttribute("data-state", "collapsed");
    await expect(page.locator(NAV)).toHaveAttribute("data-collapsible", "offcanvas");
    await expect(page.locator(TRIGGER).first()).toHaveAttribute("aria-expanded", "false");
  });

  test("expands again, and stays expanded", async ({ page }) => {
    await page.goto("/docs/badge");
    await connected(page);

    const trigger = page.locator(TRIGGER).first();
    await trigger.click();
    await expect(page.locator(NAV)).toHaveAttribute("data-state", "collapsed");

    await trigger.click();
    await expect(page.locator(NAV)).toHaveAttribute("data-state", "expanded");

    const content = page.locator(CONTENT);
    const href = await inView(content);
    await content.locator(`a[href="${href}"]`).click();
    await page.waitForURL(`**${href}`);
    await connected(page);

    await expect(page.locator(NAV)).toHaveAttribute("data-state", "expanded");
    await expect(page.locator(TRIGGER).first()).toHaveAttribute("aria-expanded", "true");
  });
});
