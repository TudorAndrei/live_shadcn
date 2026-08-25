// Behaviour for a collapsible that is also a card.
//
// `plan` is the second AI Elements component the disclosure recipe generates,
// and the first where the fold produced *one* element out of two upstream
// components: `<Collapsible asChild><Card>` is one `<div>`, and
// `<CollapsibleTrigger asChild><Button>` is one `<button>`. Read as two, this
// component rendered a button inside a button — which axe reports, and which is
// the only thing here a snapshot could not have told apart from correct markup.
//
// So the expectations are the collapsible's contract, asked of the folded copy,
// plus the one about nesting.

import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const trigger = (page) => page.locator("#rollout-trigger");
const panel = (page) => page.locator("#rollout-panel");

test.describe("a plan", () => {
  test("starts closed, and says so where a class string reads it", async ({ page }) => {
    await visit(page, "/preview/plan/default", "#rollout");

    await expect(trigger(page)).toHaveAttribute("aria-expanded", "false");
    await expect(page.locator("#rollout")).toHaveAttribute("data-closed", "");
    await expect(panel(page)).toBeHidden();
  });

  test("a click opens the panel", async ({ page }) => {
    await visit(page, "/preview/plan/default", "#rollout");
    await trigger(page).click();

    await expect(trigger(page)).toHaveAttribute("aria-expanded", "true");
    await expect(panel(page)).toBeVisible();
    await expect(panel(page)).toHaveAttribute("data-open", "");
  });

  test("opening costs no round trip", async ({ page }) => {
    const frames = [];
    page.on("websocket", (socket) =>
      socket.on("framesent", ({ payload }) => frames.push(String(payload)))
    );

    await visit(page, "/preview/plan/default", "#rollout");
    await trigger(page).click();
    await expect(panel(page)).toBeVisible();

    expect(frames.filter((frame) => frame.includes("event"))).toHaveLength(0);
  });

  test("the trigger is one button", async ({ page }) => {
    await visit(page, "/preview/plan/default", "#rollout");

    // `asChild` says the collapsible's trigger and the button inside it are one
    // element. Two of them is what the reader used to produce, and a button
    // inside a button is not markup a browser can be asked to make sense of.
    await expect(trigger(page).locator("button")).toHaveCount(0);
    await expect(page.locator("#rollout button")).toHaveCount(1);
  });

  test("the trigger names the panel it controls", async ({ page }) => {
    await visit(page, "/preview/plan/default", "#rollout");

    await expect(trigger(page)).toHaveAttribute("aria-controls", "rollout-panel");
    await expect(panel(page)).toHaveAttribute("aria-labelledby", "rollout-trigger");
    await expect(panel(page)).toHaveAttribute("role", "region");
  });

  test("is clean under axe, open and closed", async ({ page }) => {
    await visit(page, "/preview/plan/default", "#rollout");

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
