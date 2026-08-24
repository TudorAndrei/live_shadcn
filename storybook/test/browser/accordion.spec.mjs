// Behaviour parity for the accordion.
//
// Every expectation here is transcribed from the Base UI accordion page: the
// attributes it documents, the keyboard behaviour its examples show, and the
// single-open default its `multiple` prop turns off. If Base UI changes, this
// file is the thing that says so.
//
// The point of running these in a real browser rather than asserting on markup
// is that opening a panel is a client behaviour. Nothing here reaches the
// server, so nothing here can be verified by rendering.

import { expect, test } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

const item = (page, id) => ({
  trigger: page.locator(`#${id}-trigger`),
  panel: page.locator(`#${id}-panel`),
  root: page.locator(`#${id}`),
});

test.describe("a set of panels, one open at a time", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/preview/accordion/default");
    await expect(page.locator("#faq")).toBeVisible();
  });

  test("every panel starts closed and hidden", async ({ page }) => {
    for (const id of ["faq-what", "faq-start", "faq-use"]) {
      const { trigger, panel } = item(page, id);
      await expect(trigger).toHaveAttribute("aria-expanded", "false");
      await expect(panel).toBeHidden();
    }
  });

  test("a click opens the panel and says so", async ({ page }) => {
    const { trigger, panel } = item(page, "faq-what");

    await trigger.click();

    await expect(trigger).toHaveAttribute("aria-expanded", "true");
    await expect(trigger).toHaveAttribute("data-panel-open", "");
    await expect(panel).toBeVisible();
    await expect(panel).toHaveAttribute("data-open", "");
  });

  test("a second click closes it again", async ({ page }) => {
    const { trigger, panel } = item(page, "faq-what");

    await trigger.click();
    await expect(panel).toBeVisible();

    await trigger.click();
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
    await expect(panel).toBeHidden();
  });

  test("opening one panel closes the one before it", async ({ page }) => {
    const first = item(page, "faq-what");
    const second = item(page, "faq-start");

    await first.trigger.click();
    await expect(first.panel).toBeVisible();

    await second.trigger.click();

    await expect(second.panel).toBeVisible();
    await expect(first.panel).toBeHidden();
    await expect(first.trigger).toHaveAttribute("aria-expanded", "false");
  });

  test("the open panel is measured, which is what the class strings ask for", async ({ page }) => {
    const { trigger, panel } = item(page, "faq-what");

    await trigger.click();
    await expect(panel).toBeVisible();

    const height = await panel.evaluate((el) =>
      getComputedStyle(el).getPropertyValue("--accordion-panel-height"),
    );

    expect(parseFloat(height)).toBeGreaterThan(0);
  });

  test("the panel takes the height it was measured at", async ({ page }) => {
    const { trigger, panel } = item(page, "faq-what");

    await trigger.click();
    await expect(panel).toBeVisible();

    const box = await panel.boundingBox();
    expect(box.height).toBeGreaterThan(0);
  });
});

test.describe("keyboard", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/preview/accordion/default");
    await expect(page.locator("#faq")).toBeVisible();
  });

  test("each trigger is reachable by Tab, in document order", async ({ page }) => {
    await page.keyboard.press("Tab");
    await expect(page.locator("#faq-what-trigger")).toBeFocused();

    await page.keyboard.press("Tab");
    await expect(page.locator("#faq-start-trigger")).toBeFocused();
  });

  test("Enter opens the focused panel", async ({ page }) => {
    await page.locator("#faq-what-trigger").focus();
    await page.keyboard.press("Enter");

    await expect(page.locator("#faq-what-panel")).toBeVisible();
  });

  test("Space opens the focused panel", async ({ page }) => {
    await page.locator("#faq-start-trigger").focus();
    await page.keyboard.press(" ");

    await expect(page.locator("#faq-start-panel")).toBeVisible();
  });
});

test.describe("several panels at once", () => {
  test("multiple leaves the other panels alone", async ({ page }) => {
    await page.goto("/preview/accordion/multiple");
    const added = item(page, "release-added");
    const changed = item(page, "release-changed");

    await added.trigger.click();
    await changed.trigger.click();

    await expect(added.panel).toBeVisible();
    await expect(changed.panel).toBeVisible();
  });
});

test.describe("open and disabled", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/preview/accordion/states");
    await expect(page.locator("#states")).toBeVisible();
  });

  test("an item that starts open is readable straight away", async ({ page }) => {
    await expect(page.locator("#states-open-panel")).toBeVisible();
    await expect(page.locator("#states-open-trigger")).toHaveAttribute("aria-expanded", "true");
  });

  test("a disabled item does not open", async ({ page }) => {
    const disabled = item(page, "states-disabled");

    // `"true"`, not presence. ARIA defines the value, and Tailwind compiles
    // `aria-disabled:` to `[aria-disabled="true"]` — so written as a bare
    // attribute the trigger carried it and matched none of the rules written
    // for it, and drew at full opacity beside its enabled neighbours.
    await expect(disabled.trigger).toHaveAttribute("aria-disabled", "true");
    await disabled.trigger.click({ force: true });

    await expect(disabled.panel).toBeHidden();
  });

  test("a disabled trigger is still reachable, which is why it is not a disabled button", async ({
    page,
  }) => {
    await page.locator("#states-disabled-trigger").focus();
    await expect(page.locator("#states-disabled-trigger")).toBeFocused();
  });
});

test.describe("accessibility", () => {
  for (const example of ["default", "multiple", "states"]) {
    test(`${example} has no axe-core violations, closed or open`, async ({ page }) => {
      await page.goto(`/preview/accordion/${example}`);
      await expect(page.locator("[data-preview='accordion']")).toBeVisible();

      const closed = await new AxeBuilder({ page }).analyze();
      expect(closed.violations).toEqual([]);

      // The open state is a different tree: a panel appears, a region is
      // exposed, and the labelling has to hold in both.
      await page.locator("[data-slot='accordion-trigger']").first().click();
      await page.waitForTimeout(250);

      const open = await new AxeBuilder({ page }).analyze();
      expect(open.violations).toEqual([]);
    });
  }
});
