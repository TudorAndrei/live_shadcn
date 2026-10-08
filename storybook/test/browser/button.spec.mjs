import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("the official size example keeps names on each icon button", async ({ page }) => {
  await visit(page, "/preview/button/size", "[data-preview='button']");

  const iconButtons = page.getByRole("button", { name: "Submit" });
  await expect(iconButtons).toHaveCount(4);

  for (let index = 0; index < 4; index += 1) {
    await expect(iconButtons.nth(index)).toHaveAccessibleName("Submit");
  }
});

test("the rendered Button classes make a real link", async ({ page }) => {
  await visit(page, "/preview/button/render", "[data-preview='button'] a");

  const link = page.getByRole("link", { name: "Login" });
  await expect(link).toHaveAttribute("href", "#");
  await expect(link).toHaveClass(/cn-button-variant-secondary/);
  await expect(link).toHaveClass(/cn-button-size-sm/);
});

test("the Button group menu and its radio submenu work", async ({ page }) => {
  await visit(page, "/preview/button/group-demo", "#button-more-options-trigger");

  const trigger = page.locator("#button-more-options-trigger");
  const popup = page.locator("#button-more-options-popup");
  await expect(trigger).toHaveAccessibleName("More Options");

  await trigger.click();
  await expect(popup).toBeVisible();

  const labelTrigger = page.locator("#button-more-options-label-trigger");
  await labelTrigger.click();

  const labelPopup = page.locator("#button-more-options-label-popup");
  const personal = page.locator("#button-more-options-label-item-personal");
  const work = page.locator("#button-more-options-label-item-work");
  await expect(labelPopup).toBeVisible();
  await expect(personal).toHaveAttribute("aria-checked", "true");

  await labelTrigger.focus();
  await page.keyboard.press("Escape");
  await expect(labelPopup).toBeHidden();
  await expect(popup).toBeVisible();
  await expect(labelTrigger).toBeFocused();
  await labelTrigger.evaluate(async (submenuTrigger) => {
    const scheduleFrame = window.requestAnimationFrame;
    const pendingFrames = [];
    window.requestAnimationFrame = (callback) => {
      pendingFrames.push(callback);
      return 0;
    };
    try {
      submenuTrigger.dispatchEvent(
        new KeyboardEvent("keydown", { key: "ArrowRight", bubbles: true, cancelable: true }),
      );
      await Promise.resolve();
      const parent = document.getElementById("button-more-options-popup");
      parent.focus();
      parent.dispatchEvent(
        new KeyboardEvent("keydown", { key: "Escape", bubbles: true, cancelable: true }),
      );
      await Promise.resolve();
    } finally {
      window.requestAnimationFrame = scheduleFrame;
    }
    // Deliver the pending frame before the close timer. This order can occur
    // with rapid key input and must preserve the Escape focus destination.
    for (const callback of pendingFrames) callback(performance.now());
  });
  await expect(labelPopup).toBeHidden();
  await expect(popup).toBeVisible();
  await expect(labelTrigger).toBeFocused();
  await labelTrigger.press("ArrowRight");
  await expect(labelPopup).toBeVisible();

  await popup.focus();
  await page.keyboard.press("Escape");
  await expect(labelPopup).toBeHidden();
  await expect(popup).toBeVisible();
  await expect(labelTrigger).toBeFocused();
  await labelTrigger.press("ArrowRight");
  await expect(labelPopup).toBeVisible();

  await work.click();
  await expect(work).toHaveAttribute("aria-checked", "true");
  await expect(personal).toHaveAttribute("aria-checked", "false");
  await expect(popup).toBeVisible();
  await expect(labelPopup).toBeVisible();

  await page.keyboard.press("Escape");
  await expect(labelPopup).toBeHidden();
  await expect(popup).toBeVisible();
  await expect(labelTrigger).toBeFocused();
  await labelTrigger.press("ArrowRight");
  await expect(labelPopup).toBeVisible();
  await expect(work).toHaveAttribute("aria-checked", "true");

  await page.locator("body").click({ position: { x: 5, y: 5 } });
  await expect(popup).toBeHidden();
  await expect(labelPopup).toBeHidden();
});

test("the Arabic example keeps direction and disabled state", async ({ page }) => {
  await visit(page, "/preview/button/rtl", "[data-preview='button'] [dir='rtl']");

  const preview = page.locator("[data-preview='button'] [dir='rtl']");
  await expect(preview).toHaveAttribute("dir", "rtl");
  await expect(page.getByRole("button", { name: /جاري التحميل/ })).toBeDisabled();
});
