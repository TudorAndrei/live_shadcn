// Behaviour parity for the dialog.
//
// Transcribed from the Base UI dialog page and the ARIA modal dialog pattern.
// Half of what a dialog owes a reader is invisible — where the focus is, what
// happens to Tab, whether the page behind still scrolls — and none of it can be
// checked by looking at markup.

import { expect, test } from "@playwright/test";

import { discoverInteractionProbes, enterInteractionProbe } from "./interaction-parity.mjs";
import { connected, referenceReady, visit } from "./live.mjs";

const dialog = (page, id) => ({
  trigger: page.locator(`#${id}-trigger`),
  backdrop: page.locator(`#${id}-backdrop`),
  popup: page.locator(`#${id}-popup`),
  title: page.locator(`#${id}-title`),
});

test.describe("a dialog", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/dialog/default", "#dialog-default-trigger");
  });

  test("starts closed, and says so", async ({ page }) => {
    const { trigger, popup, backdrop } = dialog(page, "dialog-default");

    await expect(popup).toBeHidden();
    await expect(backdrop).toBeHidden();
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
  });

  test("opens, and marks both layers as Base UI documents", async ({ page }) => {
    const { trigger, popup, backdrop } = dialog(page, "dialog-default");

    await trigger.click();

    await expect(popup).toBeVisible();
    await expect(backdrop).toBeVisible();
    await expect(popup).toHaveAttribute("data-open", "");
    await expect(backdrop).toHaveAttribute("data-open", "");
    await expect(trigger).toHaveAttribute("data-popup-open", "");
  });

  test("is a dialog named by its own title", async ({ page }) => {
    const { trigger, popup } = dialog(page, "dialog-default");

    await trigger.click();

    await expect(popup).toHaveRole("dialog");
    await expect(popup).not.toHaveAttribute("aria-modal", /.*/);
    await expect(popup).toHaveAttribute("aria-labelledby", "dialog-default-title");
    await expect(page.locator("#dialog-default-title")).toHaveText("Edit profile");
  });

  test("the focus moves into it, so a keyboard reader is where the dialog is", async ({ page }) => {
    const { trigger, popup } = dialog(page, "dialog-default");

    await trigger.click();
    await expect(popup).toBeVisible();

    const inside = await popup.evaluate((el) => el.contains(document.activeElement));
    expect(inside).toBe(true);
  });

  test("the focus comes back to the trigger when it closes", async ({ page }) => {
    const { trigger, popup } = dialog(page, "dialog-default");

    await trigger.click();
    await expect(popup).toBeVisible();

    await page.keyboard.press("Escape");
    await expect(popup).toBeHidden();
    await expect(trigger).toBeFocused();
  });

  test("Escape closes it", async ({ page }) => {
    const { trigger, popup } = dialog(page, "dialog-default");

    await trigger.click();
    // Open before Escape, or the key arrives at a page with nothing to close.
    // `click()` resolves when the click is dispatched, not when the dialog has
    // opened, and under a full run that gap is wide enough to lose the key —
    // which read as "Escape does not close the dialog" and passed on its own.
    await expect(popup).toBeVisible();

    await page.keyboard.press("Escape");

    await expect(popup).toBeHidden();
    await expect(popup).toHaveAttribute("data-closed", "");
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
  });

  test("clicking the layer behind closes it", async ({ page }) => {
    const { trigger, popup, backdrop } = dialog(page, "dialog-default");

    await trigger.click();
    // Open before clicking the layer behind it. `click()` auto-waits for its
    // own target to be actionable, and the backdrop is actionable before the
    // dialog has finished opening — so the click can land while the handler
    // that closes on it is not yet listening.
    await expect(popup).toBeVisible();

    await backdrop.click({ position: { x: 5, y: 5 } });

    await expect(popup).toBeHidden();
  });

  test("the close button closes it", async ({ page }) => {
    const { trigger, popup } = dialog(page, "dialog-default");

    await trigger.click();
    await expect(popup).toBeVisible();

    await popup.locator(".cn-dialog-close").click();

    await expect(popup).toBeHidden();
  });

  test("Tab stays inside while it is open", async ({ page }) => {
    const { trigger, popup } = dialog(page, "dialog-default");

    await trigger.click();
    await expect(popup).toBeVisible();

    // Round the whole dialog and back again. Every stop has to be inside it.
    for (let press = 0; press < 8; press++) {
      await page.keyboard.press("Tab");
      const inside = await popup.evaluate((el) => el.contains(document.activeElement));
      expect(inside).toBe(true);
    }
  });

  test("Shift+Tab stays inside too", async ({ page }) => {
    const { trigger, popup } = dialog(page, "dialog-default");

    await trigger.click();
    await expect(popup).toBeVisible();

    for (let press = 0; press < 8; press++) {
      await page.keyboard.press("Shift+Tab");
      const inside = await popup.evaluate((el) => el.contains(document.activeElement));
      expect(inside).toBe(true);
    }
  });

  test("the page behind does not scroll while it is open", async ({ page }) => {
    const { trigger, popup } = dialog(page, "dialog-default");

    await trigger.click();
    await expect(popup).toBeVisible();

    expect(await page.evaluate(() => getComputedStyle(document.body).overflow)).toBe("hidden");

    await page.keyboard.press("Escape");
    await expect(popup).toBeHidden();

    expect(await page.evaluate(() => getComputedStyle(document.body).overflow)).not.toBe("hidden");
  });
});

test("the footer close button closes the share dialog", async ({ page }) => {
  await visit(page, "/preview/dialog/close-button", "#dialog-close-button-trigger");
  const { trigger, popup } = dialog(page, "dialog-close-button");

  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(page.locator("#link")).toHaveValue("https://ui.shadcn.com/docs/installation");
  await expect(page.locator("#link")).toHaveAttribute("readonly", "");

  await popup.locator("[data-slot='dialog-footer'] [data-slot='dialog-close']").click();
  await expect(popup).toBeHidden();
});

test("the no-close-button example omits the top close control", async ({ page }) => {
  await visit(page, "/preview/dialog/no-close-button", "#dialog-no-close-button-trigger");
  const { trigger, popup } = dialog(page, "dialog-no-close-button");

  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(popup.locator("[data-slot='dialog-close']")).toHaveCount(0);
});

test("the sticky footer stays fixed while its content scrolls", async ({ page }) => {
  await visit(page, "/preview/dialog/sticky-footer", "#dialog-sticky-footer-trigger");
  const { trigger, popup } = dialog(page, "dialog-sticky-footer");

  await trigger.click();
  await expect(popup).toBeVisible();

  const scroller = popup.locator(".overflow-y-auto");
  const footer = popup.locator("[data-slot='dialog-footer']");
  await popup.evaluate(async (element) => {
    await Promise.all(element.getAnimations({ subtree: true }).map((animation) => animation.finished));
  });
  const before = await footer.boundingBox();
  await scroller.evaluate((element) => (element.scrollTop = element.scrollHeight));
  const after = await footer.boundingBox();

  expect(await scroller.evaluate((element) => element.scrollTop)).toBeGreaterThan(0);
  expect(after.y).toBe(before.y);
});

test("the RTL dialog keeps the Arabic content direction", async ({ page }) => {
  await visit(page, "/preview/dialog/rtl", "#dialog-rtl-trigger");
  const { trigger, popup } = dialog(page, "dialog-rtl");

  await trigger.click();

  await expect(popup).toHaveAttribute("dir", "rtl");
  await expect(popup).toHaveAttribute("data-lang", "ar");
  await expect(popup.locator("#dialog-rtl-title")).toHaveText("تعديل الملف الشخصي");
});

for (const side of ["React", "Phoenix"]) {
  test(`interaction observations include visible popup fields on ${side}`, async ({ page }, testInfo) => {
    const path = side === "Phoenix" ? "/preview/dialog/default"
      : `${testInfo.project.use.parityURL}/preview/dialog/default`;
    const selector = "[data-preview='dialog']";
    async function load() {
      await page.goto(path);
      if (side === "Phoenix") await connected(page);
      else await referenceReady(page);
      const probes = await discoverInteractionProbes(page.locator(selector));
      return probes.find(({ kind }) => kind === "disclosure");
    }
    const probe = await load();
    expect(probe).toBeDefined();
    const result = await enterInteractionProbe(page, selector, probe);
    expect(result.opened.controls.map(({ name, values }) => ({ name, values }))).toEqual([
      { name: "Name", values: ["Pedro Duarte"] },
      { name: "Username", values: ["@peduarte"] },
    ]);
    expect(result.closed.controls).toEqual([]);

    await load();
    await enterInteractionProbe(page, selector, probe, { keepOpen: true });
    const popup = page.getByRole("dialog");
    const edits = await discoverInteractionProbes(popup);
    const edit = edits.find(({ kind, name }) => kind === "editable-text" && name === "Username");
    expect(edit).toBeDefined();
    const changed = await enterInteractionProbe(page, popup, edit);
    expect(changed.controls.map(({ name, values }) => ({ name, values }))).toEqual([
      { name: "Name", values: ["Pedro Duarte"] },
      { name: "Username", values: ["Parity text"] },
    ]);
    expect(changed.controls).not.toEqual(result.opened.controls);
  });
}
