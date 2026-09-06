import { expect, test } from "@playwright/test";

import { connected } from "./live.mjs";

const sides = [
  { name: "official React", live: false },
  { name: "Phoenix port", live: true },
];

async function visitSide(page, testInfo, side, example = "default") {
  const path = `/preview/command/${example}`;
  await page.goto(side.live ? path : `${testInfo.project.use.parityURL}${path}`);
  if (side.live) await connected(page);

  await expect(page.locator("[data-preview='command']")).toBeAttached();
}

function item(page, name) {
  return page
    .locator("[data-slot='command-item']")
    .filter({ hasText: name })
    .first();
}

for (const side of sides) {
  test.describe(`${side.name} command`, () => {
    test.beforeEach(async ({ page }, testInfo) => {
      await visitSide(page, testInfo, side);
    });

    test("filters items and shows the empty state", async ({ page }) => {
      const input = page.getByRole("combobox");

      await input.fill("bill");
      await expect(page.locator("[data-slot='command-item']:visible")).toHaveCount(1);
      await expect(item(page, "Billing")).toBeVisible();
      await expect(item(page, "Billing")).toHaveAttribute("aria-selected", "true");
      await expect(page.locator("[data-slot='command-empty']")).toBeHidden();
      await expect(page.locator("[data-slot='command-separator']:visible")).toHaveCount(0);

      await input.fill("nothing matches this");
      await expect(page.locator("[data-slot='command-item']:visible")).toHaveCount(0);
      await expect(page.locator("[data-slot='command-empty']")).toBeVisible();
    });

    test("moves selection with arrow keys and skips disabled items", async ({ page }) => {
      const input = page.getByRole("combobox");
      const calendar = item(page, "Calendar");
      const emoji = item(page, "Search Emoji");
      const profile = item(page, "Profile");

      await expect(calendar).toHaveAttribute("aria-selected", "true");
      await input.focus();
      await page.keyboard.press("ArrowDown");
      await expect(emoji).toHaveAttribute("aria-selected", "true");
      await expect(input).toBeFocused();

      await page.keyboard.press("ArrowDown");
      await expect(profile).toHaveAttribute("aria-selected", "true");
      await expect(input).toBeFocused();
    });

    test("does not select a disabled item", async ({ page }) => {
      const calendar = item(page, "Calendar");
      const calculator = item(page, "Calculator");

      await expect(calculator).toHaveAttribute("aria-disabled", "true");
      await calculator.hover({ force: true });
      await calculator.click({ force: true });
      await expect(calculator).toHaveAttribute("aria-selected", "false");
      await expect(calendar).toHaveAttribute("aria-selected", "true");
    });

    test("selects the item under the pointer", async ({ page }) => {
      const billing = item(page, "Billing");

      await billing.hover();
      await expect(billing).toHaveAttribute("aria-selected", "true");
    });
  });

  test(`${side.name} dialog moves focus in and returns it on Escape`, async ({
    page,
  }, testInfo) => {
    await visitSide(page, testInfo, side, "basic");

    const trigger = page.getByRole("button", { name: "Open Menu" });
    await trigger.click();

    await expect(page.getByRole("dialog")).toBeVisible();
    await expect(page.getByRole("combobox")).toBeFocused();

    await page.keyboard.press("Escape");
    await expect(page.getByRole("dialog")).toBeHidden();
    await expect(trigger).toBeFocused();
  });

  test(`${side.name} shortcut dialog opens its pinned settings commands`, async ({ page }, testInfo) => {
    await visitSide(page, testInfo, side, "shortcuts");

    const trigger = page.getByRole("button", { name: "Open Menu" });
    await trigger.click();

    const dialog = page.getByRole("dialog");
    await expect(dialog).toBeVisible();
    await expect(dialog.getByRole("combobox")).toBeFocused();
    await expect(dialog.getByText("Settings", { exact: true })).toBeVisible();
    await expect(dialog.locator("[data-slot='command-shortcut']")).toHaveText(["⌘P", "⌘B", "⌘S"]);

    await page.keyboard.press("Escape");
    await expect(dialog).toBeHidden();
    await expect(trigger).toBeFocused();
  });

  test(`${side.name} grouped dialog keeps its pinned group boundary`, async ({ page }, testInfo) => {
    await visitSide(page, testInfo, side, "groups");

    await page.getByRole("button", { name: "Open Menu" }).click();

    const dialog = page.getByRole("dialog");
    await expect(dialog).toBeVisible();
    await expect(dialog.getByText("Suggestions", { exact: true })).toBeVisible();
    await expect(dialog.getByText("Settings", { exact: true })).toBeVisible();
    await expect(dialog.locator("[data-slot='command-separator']")).toHaveCount(1);
    await expect(dialog.locator("[data-slot='command-item']")).toHaveCount(6);
  });

  test(`${side.name} scrollable dialog scrolls through its pinned command list`, async ({ page }, testInfo) => {
    await visitSide(page, testInfo, side, "scrollable");

    await page.getByRole("button", { name: "Open Menu" }).click();

    const dialog = page.getByRole("dialog");
    const list = dialog.locator("[data-slot='command-list']");
    await expect(dialog).toBeVisible();
    await expect(list).toBeVisible();

    const geometry = await list.evaluate((element) => ({
      clientHeight: element.clientHeight,
      scrollHeight: element.scrollHeight,
    }));
    expect(geometry.scrollHeight).toBeGreaterThan(geometry.clientHeight);

    await list.evaluate((element) => element.scrollTo({ top: element.scrollHeight, behavior: "auto" }));
    await expect.poll(() => list.evaluate((element) => element.scrollTop)).toBeGreaterThan(0);
    await expect(dialog.getByText("Code Editor", { exact: true })).toBeVisible();
  });
}
