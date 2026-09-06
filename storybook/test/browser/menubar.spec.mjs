import { expect, test } from "@playwright/test";

import { connected } from "./live.mjs";

const sides = [
  { name: "official React", live: false },
  { name: "Phoenix port", live: true },
];

async function visitSide(page, testInfo, side, example = "default") {
  const path = `/preview/menubar/${example}`;
  await page.goto(side.live ? path : `${testInfo.project.use.parityURL}${path}`);
  if (side.live) await connected(page);

  await expect(page.locator("[data-preview='menubar']")).toBeAttached();
}

function trigger(page, name) {
  return page
    .locator("[data-slot='menubar-trigger']")
    .filter({ hasText: name })
    .first();
}

function visibleContent(page, slot = "menubar-content") {
  return page.locator(`[data-slot='${slot}']:visible`).first();
}

for (const side of sides) {
  test.describe(`${side.name} menubar`, () => {
    test.beforeEach(async ({ page }, testInfo) => {
      await visitSide(page, testInfo, side);
    });

    test("opens, closes from Escape, and returns focus", async ({ page }) => {
      const file = trigger(page, "File");

      await expect(file).toHaveAttribute("aria-expanded", "false");
      await file.click();
      await expect(file).toHaveAttribute("aria-expanded", "true");
      await expect(visibleContent(page)).toBeVisible();

      await page.keyboard.press("Escape");
      await expect(file).toHaveAttribute("aria-expanded", "false");
      await expect(file).toBeFocused();
    });

    test("moves between top-level triggers with arrow keys", async ({ page }) => {
      const file = trigger(page, "File");
      const edit = trigger(page, "Edit");

      await file.focus();
      await page.keyboard.press("ArrowRight");
      await expect(edit).toBeFocused();

      await page.keyboard.press("ArrowLeft");
      await expect(file).toBeFocused();
    });

    test("moves an open menu to the hovered trigger", async ({ page }) => {
      const file = trigger(page, "File");
      const edit = trigger(page, "Edit");

      await file.click();
      await expect(file).toHaveAttribute("aria-expanded", "true");

      await edit.hover();
      await expect(edit).toHaveAttribute("aria-expanded", "true");
      await expect(file).toHaveAttribute("aria-expanded", "false");
    });

    test("opens and closes a submenu with arrow keys", async ({ page }) => {
      await trigger(page, "File").click();

      const share = visibleContent(page)
        .locator("[data-slot='menubar-sub-trigger']")
        .filter({ hasText: "Share" });

      await share.focus();
      await page.keyboard.press("ArrowRight");
      await expect(visibleContent(page, "menubar-sub-content")).toBeVisible();

      await page.keyboard.press("ArrowLeft");
      await expect(page.locator(`#${await share.getAttribute("aria-controls")}`)).toBeHidden();
      await expect(share).toBeFocused();
    });

    test("does not choose a disabled item", async ({ page }) => {
      const file = trigger(page, "File");
      await file.click();

      const popup = visibleContent(page);
      const incognito = popup
        .locator("[data-slot='menubar-item']")
        .filter({ hasText: "New Incognito Window" });

      await expect(incognito).toHaveAttribute("data-disabled", "");
      await incognito.click({ force: true });
      await expect(file).toHaveAttribute("aria-expanded", "true");
      await expect(popup).toBeVisible();
    });
  });

  test(`${side.name} checkbox items toggle and keep the menu open`, async ({ page }, testInfo) => {
    await visitSide(page, testInfo, side, "checkbox");
    await trigger(page, "View").click();

    const popup = visibleContent(page);
    const bookmarks = popup
      .locator("[data-slot='menubar-checkbox-item']")
      .filter({ hasText: "Always Show Bookmarks Bar" });

    await expect(bookmarks).toHaveAttribute("aria-checked", "false");
    await bookmarks.click();
    await expect(bookmarks).toHaveAttribute("aria-checked", "true");
    await expect(popup).toBeVisible();
  });

  test(`${side.name} radio items select one value and keep the menu open`, async ({
    page,
  }, testInfo) => {
    await visitSide(page, testInfo, side, "radio");
    await trigger(page, "Profiles").click();

    const popup = visibleContent(page);
    const andy = popup
      .locator("[data-slot='menubar-radio-item']")
      .filter({ hasText: "Andy" });
    const benoit = popup
      .locator("[data-slot='menubar-radio-item']")
      .filter({ hasText: "Benoit" });

    await expect(andy).toHaveAttribute("aria-checked", "false");
    await expect(benoit).toHaveAttribute("aria-checked", "true");
    await andy.click();
    await expect(andy).toHaveAttribute("aria-checked", "true");
    await expect(benoit).toHaveAttribute("aria-checked", "false");
    await expect(popup).toBeVisible();
  });

  test(`${side.name} radio example changes its Theme value and keeps that menu open`, async ({ page }, testInfo) => {
    await visitSide(page, testInfo, side, "radio");
    await trigger(page, "Theme").click();

    const popup = visibleContent(page);
    const light = popup
      .locator("[data-slot='menubar-radio-item']")
      .filter({ hasText: "Light" });
    const system = popup
      .locator("[data-slot='menubar-radio-item']")
      .filter({ hasText: "System" });

    await expect(system).toHaveAttribute("aria-checked", "true");
    await expect(light).toHaveAttribute("aria-checked", "false");
    await light.click();
    await expect(light).toHaveAttribute("aria-checked", "true");
    await expect(system).toHaveAttribute("aria-checked", "false");
    await expect(popup).toBeVisible();
  });

  test(`${side.name} uses the upstream arrow direction in RTL`, async ({ page }, testInfo) => {
    await visitSide(page, testInfo, side, "rtl");

    const file = trigger(page, "ملف");
    const edit = trigger(page, "تعديل");

    await file.focus();
    await page.keyboard.press("ArrowRight");
    await expect(edit).toBeFocused();
  });

  test(`${side.name} RTL menu changes checkbox and profile radio values`, async ({ page }, testInfo) => {
    await visitSide(page, testInfo, side, "rtl");
    await trigger(page, "عرض").click();

    let popup = visibleContent(page);
    const bookmarks = popup
      .locator("[data-slot='menubar-checkbox-item']")
      .filter({ hasText: "شريط الإشارات المرجعية" });

    await expect(popup).toHaveAttribute("dir", "rtl");
    await expect(bookmarks).toHaveAttribute("aria-checked", "false");
    await bookmarks.click();
    await expect(bookmarks).toHaveAttribute("aria-checked", "true");
    await expect(popup).toBeVisible();

    await trigger(page, "الملفات الشخصية").click();
    popup = visibleContent(page);
    const andy = popup
      .locator("[data-slot='menubar-radio-item']")
      .filter({ hasText: "Andy" });
    const benoit = popup
      .locator("[data-slot='menubar-radio-item']")
      .filter({ hasText: "Benoit" });

    await expect(benoit).toHaveAttribute("aria-checked", "true");
    await andy.click();
    await expect(andy).toHaveAttribute("aria-checked", "true");
    await expect(benoit).toHaveAttribute("aria-checked", "false");
    await expect(popup).toBeVisible();
  });
}
