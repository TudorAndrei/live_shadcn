import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const sheet = (page, id) => ({
  trigger: page.locator(`#${id}-trigger`),
  backdrop: page.locator(`#${id}-backdrop`),
  popup: page.locator(`#${id}-popup`),
});

test.describe("the official profile sheet", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/sheet/default", "#sheet-demo-trigger");
  });

  test("starts closed and opens as a named dialog", async ({ page }) => {
    const { trigger, backdrop, popup } = sheet(page, "sheet-demo");

    await expect(popup).toBeHidden();
    await expect(backdrop).toBeHidden();
    await trigger.click();

    await expect(popup).toBeVisible();
    await expect(backdrop).toBeVisible();
    await expect(popup).toHaveRole("dialog");
    await expect(popup).toHaveAttribute("aria-labelledby", "sheet-demo-title");
    await expect(page.locator("#sheet-demo-title")).toHaveText("Edit profile");
  });

  test("Escape closes it and returns focus", async ({ page }) => {
    const { trigger, popup } = sheet(page, "sheet-demo");

    await trigger.click();
    await expect(popup).toBeVisible();
    await page.keyboard.press("Escape");

    await expect(popup).toBeHidden();
    await expect(trigger).toBeFocused();
  });

  test("the backdrop closes it", async ({ page }) => {
    const { trigger, backdrop, popup } = sheet(page, "sheet-demo");

    await trigger.click();
    await expect(popup).toBeVisible();
    await backdrop.click({ position: { x: 5, y: 5 } });

    await expect(popup).toBeHidden();
  });

  test("the footer close action closes it", async ({ page }) => {
    const { trigger, popup } = sheet(page, "sheet-demo");

    await trigger.click();
    await expect(popup).toBeVisible();
    await popup.locator("[data-slot='sheet-footer'] [data-slot='sheet-close']").click();

    await expect(popup).toBeHidden();
  });
});

for (const side of ["top", "right", "bottom", "left"]) {
  test(`the ${side} trigger opens the ${side} sheet`, async ({ page }) => {
    await visit(page, "/preview/sheet/side", `#sheet-side-${side}-trigger`);
    const { trigger, popup } = sheet(page, `sheet-side-${side}`);

    await trigger.click();
    await expect(popup).toBeVisible();
    await expect(popup).toHaveAttribute("data-side", side);
  });
}

test("the no-close example omits the top close button", async ({ page }) => {
  await visit(page, "/preview/sheet/no-close-button", "#sheet-no-close-trigger");
  const { trigger, popup } = sheet(page, "sheet-no-close");

  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(popup.locator(":scope > [data-slot='sheet-close']")).toHaveCount(0);
});

test("the RTL sheet opens from the left with Arabic direction data", async ({ page }) => {
  await visit(page, "/preview/sheet/rtl", "#sheet-rtl-trigger");
  const { trigger, popup } = sheet(page, "sheet-rtl");

  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(popup).toHaveAttribute("dir", "rtl");
  await expect(popup).toHaveAttribute("data-lang", "ar");
  await expect(popup).toHaveAttribute("data-side", "left");
});
