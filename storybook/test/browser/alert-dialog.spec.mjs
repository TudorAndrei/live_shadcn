import { expect, test } from "@playwright/test";

import { connected } from "./live.mjs";

const sides = [
  { name: "official React", live: false },
  { name: "Phoenix port", live: true },
];

async function visitSide(page, testInfo, side, example = "basic") {
  const path = `/preview/alert-dialog/${example}`;
  const url = side.live ? path : `${testInfo.project.use.parityURL}${path}`;

  await page.goto(url);
  if (side.live) await connected(page);

  await expect(page.locator("[data-preview='alert-dialog']")).toBeAttached();
}

function alertDialog(page) {
  return {
    trigger: page.locator("[data-slot='alert-dialog-trigger']").first(),
    popup: page.locator("[data-slot='alert-dialog-content']").first(),
    backdrop: page.locator("[data-slot='alert-dialog-overlay']").first(),
    cancel: page.locator("[data-slot='alert-dialog-cancel']").first(),
    action: page.locator("[data-slot='alert-dialog-action']").first(),
  };
}

for (const side of sides) {
  test.describe(`${side.name} alert dialog`, () => {
    test.beforeEach(async ({ page }, testInfo) => {
      await visitSide(page, testInfo, side);
    });

    test("starts closed and opens as an alert dialog", async ({ page }) => {
      const { trigger, popup } = alertDialog(page);

      await expect(trigger).toHaveAttribute("aria-expanded", "false");
      await expect(popup).toBeHidden();

      await trigger.click();

      await expect(trigger).toHaveAttribute("aria-expanded", "true");
      await expect(popup).toBeVisible();
      await expect(popup).toHaveRole("alertdialog");
      await expect(popup).toHaveAccessibleName("Are you absolutely sure?");
    });

    test("moves focus inside and returns it after Cancel", async ({ page }) => {
      const { trigger, popup, cancel } = alertDialog(page);

      await trigger.click();
      await expect(popup).toBeVisible();
      expect(await popup.evaluate((element) => element.contains(document.activeElement))).toBe(true);

      await cancel.click();

      await expect(popup).toBeHidden();
      await expect(trigger).toBeFocused();
    });

    test("ignores backdrop clicks and closes with Escape", async ({ page }) => {
      const { trigger, popup, backdrop } = alertDialog(page);

      await trigger.click();
      await expect(popup).toBeVisible();

      await backdrop.click({ position: { x: 5, y: 5 } });
      await expect(trigger).toHaveAttribute("aria-expanded", "true");
      await expect(popup).toBeVisible();

      await page.keyboard.press("Escape");
      await expect(trigger).toHaveAttribute("aria-expanded", "false");
      await expect(popup).toBeHidden();
      await expect(trigger).toBeFocused();
    });

    test("keeps the dialog open when its action has no application handler", async ({ page }) => {
      const { trigger, popup, action } = alertDialog(page);

      await trigger.click();
      await expect(popup).toBeVisible();

      await action.click();

      await expect(popup).toBeVisible();
    });
  });

  test(`${side.name} exposes both RTL dialog states`, async ({ page }, testInfo) => {
    await visitSide(page, testInfo, side, "rtl");

    const triggers = page.locator("[data-slot='alert-dialog-trigger']");
    await expect(triggers).toHaveCount(2);

    for (let index = 0; index < 2; index += 1) {
      const trigger = triggers.nth(index);
      await trigger.click();
      await expect(trigger).toHaveAttribute("aria-expanded", "true");

      const popup = page.locator("[data-slot='alert-dialog-content']:visible");
      await expect(popup).toHaveAttribute("dir", "rtl");
      await expect(popup).toHaveAttribute("data-lang", "ar");
      await popup.locator("[data-slot='alert-dialog-cancel']").click();
      await expect(trigger).toHaveAttribute("aria-expanded", "false");
    }
  });
}
