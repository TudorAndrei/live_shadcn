import { expect, test } from "@playwright/test";

import { connected, referenceReady, visit } from "./live.mjs";

test.beforeEach(async ({ context }) => {
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
});

test("the default example addon focuses its input", async ({ page }) => {
  await visit(page, "/preview/input-group/default", "input[placeholder='Search...']");

  await page.locator("[data-lb-input-group-addon]").first().click();
  await expect(page.getByPlaceholder("Search...")).toBeFocused();
});

test("the button example keeps a nested button in control of its click", async ({ page }) => {
  await visit(page, "/preview/input-group/button", "#input-group-copy");

  await page.locator("#input-group-copy").click();
  await expect(page.getByPlaceholder("https://x.com/shadcn")).not.toBeFocused();
});

test("the button example copies and marks a favorite", async ({
  page,
}) => {
  await visit(page, "/preview/input-group/button", "#input-group-copy");

  const copy = page.locator("#input-group-copy");
  await expect(copy).toHaveAttribute("data-lb-ready", "");
  await copy.click();
  await expect(copy.locator("[data-lb-state='copied']")).not.toHaveAttribute("hidden", "");
  expect(await page.evaluate(() => navigator.clipboard.readText())).toBe("https://x.com/shadcn");

  const favorite = page.locator("#input-group-favorite");
  const star = page.locator("#input-group-favorite-icon");
  await expect(star).toHaveAttribute("data-favorite", "false");
  await favorite.click();
  await expect(star).toHaveAttribute("data-favorite", "true");
});

for (const side of ["React", "Phoenix"]) {
  test(`the security popover keeps its composed trigger focus on ${side}`, async ({ page }, testInfo) => {
    const path = "/preview/input-group/button";
    await page.goto(side === "React" ? `${testInfo.project.use.parityURL}${path}` : path);
    await (side === "React" ? referenceReady(page) : connected(page));
    const trigger = page.locator("[data-preview='input-group'] [data-slot='popover-trigger']");
    const security = trigger.getByRole("button");
    const popup = page.getByRole("dialog");
    const input = page.locator("#input-secure-19");

    await expect(trigger).toHaveAttribute("aria-haspopup", "dialog");
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
    await expect(trigger).toHaveClass(/cn-input-group-addon/);
    await expect(security).toHaveAttribute("data-slot", "button");
    await expect(security).toHaveAttribute("data-size", "icon-xs");
    await expect(security).toHaveClass(/cn-input-group-button/);
    await input.fill("example.com");
    await security.click();
    await expect(popup).toBeVisible();
    await expect(trigger).toHaveAttribute("aria-expanded", "true");
    if (side === "Phoenix") {
      await expect(page.locator("#input-group-security-positioner")).toHaveAttribute(
        "data-lb-anchor", "input-group-security-trigger",
      );
    }
    await expect(popup).toBeFocused();
    await page.keyboard.press("Escape");
    await expect(popup).toBeHidden();
    await expect(trigger).toBeFocused();

    for (const key of ["Enter", " "]) {
      await trigger.press(key);
      await expect(popup).toBeHidden();
      await expect(trigger).toBeFocused();
      await page.keyboard.press("Tab");
      await expect(security).toBeFocused();
      await security.press(key);
      await expect(popup).toBeVisible();
      await expect(popup).toBeFocused();
      await page.keyboard.press("Escape");
      await expect(popup).toBeHidden();
      await expect(trigger).toBeFocused();
    }

    await security.click();
    await expect(popup).toBeVisible();
    await input.click();
    await expect(popup).toBeHidden();
    await expect(input).toBeFocused();
    await expect(input).toHaveValue("example.com");
  });
}

test("the dropdown example uses input group buttons as menu triggers", async ({ page }) => {
  await visit(page, "/preview/input-group/dropdown", "#input-group-more-trigger");

  const more = page.locator("#input-group-more-trigger");
  const morePopup = page.locator("#input-group-more-popup");
  await expect(more).toHaveAttribute("aria-haspopup", "menu");
  await expect(more).toHaveAttribute("data-size", "icon-xs");
  await expect(more).toHaveClass(/cn-input-group-button/);
  await expect(more.locator("button")).toHaveCount(0);
  await more.click();
  await expect(morePopup).toBeVisible();
  await expect(page.locator("#input-group-more-positioner")).toHaveAttribute(
    "data-lb-anchor",
    "input-group-more-trigger",
  );
  await expect(page.locator("#input-group-more-positioner")).toHaveAttribute("data-align", "end");
  await expect(morePopup).toBeFocused();
  await page.keyboard.press("ArrowDown");
  await expect(page.locator("#input-group-more-item-settings")).toBeFocused();
  await page.keyboard.press("Enter");
  await expect(morePopup).toBeHidden();

  const searchIn = page.locator("#input-group-search-in-trigger");
  const searchInPopup = page.locator("#input-group-search-in-popup");
  await searchIn.click();
  await expect(searchInPopup).toBeVisible();
  await expect(page.locator("#input-group-search-in-positioner")).toHaveAttribute(
    "data-lb-anchor",
    "input-group-search-in-trigger",
  );
  await expect(page.locator("#input-group-search-in-positioner")).toHaveAttribute("data-align", "end");
  await page.keyboard.press("Escape");
  await expect(searchInPopup).toBeHidden();

  await more.click();
  await expect(morePopup).toBeVisible();
  await page.locator("body").click({ position: { x: 5, y: 5 } });
  await expect(morePopup).toBeHidden();
});

test("the custom example grows its textarea", async ({ page }) => {
  await visit(page, "/preview/input-group/custom", "[data-lb-autosize]");

  const textarea = page.locator("[data-lb-autosize]");
  await textarea.fill("First line");
  await expect
    .poll(() => textarea.evaluate((element) => Number.parseFloat(element.style.height)))
    .toBeGreaterThan(0);
  const before = await textarea.evaluate((element) => Number.parseFloat(element.style.height));
  await textarea.fill("First line\nSecond line\nThird line\nFourth line");
  await expect
    .poll(() => textarea.evaluate((element) => Number.parseFloat(element.style.height)))
    .toBeGreaterThan(before);
});
