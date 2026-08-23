// Behaviour parity for the AI Elements task.
//
// The task is the first component generated out of the AI Elements registry,
// and it exists here to check the one thing that registry does differently:
// it renders no Base UI primitive of its own. Upstream writes `<Collapsible>`,
// `<CollapsibleTrigger>` and `<CollapsibleContent>`, and the spec reader folds
// shadcn's markup for those three into this component rather than calling it.
//
// A fold that produced plausible markup and no behaviour would look right in a
// snapshot and do nothing on a page. So the expectations below are the same
// ones the collapsible is held to — the Base UI attribute contract, and a panel
// that opens without a round trip — asked of the folded copy.

import { expect, test } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

const trigger = (page) => page.locator("#search-trigger");
const panel = (page) => page.locator("#search-panel");

test.describe("a task", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/preview/task/default");
    await expect(page.locator("#search")).toBeVisible();
  });

  test("starts closed, and says so where a class string reads it", async ({ page }) => {
    await expect(trigger(page)).toHaveAttribute("aria-expanded", "false");
    await expect(page.locator("#search")).toHaveAttribute("data-closed", "");
    await expect(panel(page)).toBeHidden();
  });

  test("a click opens the panel", async ({ page }) => {
    await trigger(page).click();

    await expect(trigger(page)).toHaveAttribute("aria-expanded", "true");
    await expect(trigger(page)).toHaveAttribute("data-panel-open", "");
    await expect(panel(page)).toBeVisible();
    await expect(panel(page)).toHaveAttribute("data-open", "");
  });

  test("a second click closes it again", async ({ page }) => {
    await trigger(page).click();
    await expect(panel(page)).toBeVisible();

    await trigger(page).click();
    await expect(trigger(page)).toHaveAttribute("aria-expanded", "false");
    await expect(panel(page)).toBeHidden();
  });

  test("opening costs no round trip", async ({ page }) => {
    // The whole point of the disclosure recipe. If the fold had dropped the
    // `JS` command and left a `phx-click` that pushes, this is what would catch
    // it: the socket would carry an event.
    const events = [];
    page.on("websocket", (socket) =>
      socket.on("framesent", ({ payload }) => events.push(String(payload)))
    );

    await trigger(page).click();
    await expect(panel(page)).toBeVisible();

    expect(events.filter((frame) => frame.includes("event"))).toHaveLength(0);
  });

  test("the trigger names the panel it controls", async ({ page }) => {
    await expect(trigger(page)).toHaveAttribute("aria-controls", "search-panel");
    await expect(panel(page)).toHaveAttribute("aria-labelledby", "search-trigger");
    await expect(panel(page)).toHaveAttribute("role", "region");
  });

  test("is clean under axe, open and closed", async ({ page }) => {
    const scan = async () => {
      const { violations } = await new AxeBuilder({ page }).analyze();
      // Contrast is upstream's, and some of shadcn's own colours fall below
      // 4.5:1. Everything else axe reports is markup, which is ours.
      return violations.filter(({ id }) => id !== "color-contrast");
    };

    expect(await scan()).toEqual([]);

    await trigger(page).click();
    await expect(panel(page)).toBeVisible();

    expect(await scan()).toEqual([]);
  });
});
