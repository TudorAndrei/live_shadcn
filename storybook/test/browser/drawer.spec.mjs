import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const standardExamples = [
  ["default", "drawer-demo", "Open Drawer"],
  ["sides", "drawer-sides", "Open Left Drawer"],
  ["swipe-handle", "drawer-swipe-handle", "Open Drawer"],
];

for (const [example, id, triggerName] of standardExamples) {
  test(`${example} opens and closes through its public controls`, async ({ page }) => {
    await visit(page, `/preview/drawer/${example}`, `#${id}-trigger`);

    const trigger = page.getByRole("button", { name: triggerName, exact: true });
    const popup = page.locator(`#${id}-popup`);

    await trigger.click();
    await expect(popup).toBeVisible();
    await expect(popup).toHaveRole("dialog");
    await expect(trigger).toHaveAttribute("aria-expanded", "true");

    await popup.getByRole("button", { name: /^(Cancel|Close)$/ }).click();
    await expect(popup).toBeHidden();
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
    await expect(trigger).toBeFocused();
  });
}

test("snap-points opens at its compact point and closes with Escape", async ({ page }) => {
  await visit(page, "/preview/drawer/snap-points", "#drawer-snap-points-trigger");

  const trigger = page.getByRole("button", { name: "Open Snap Drawer", exact: true });
  const popup = page.locator("#drawer-snap-points-popup");

  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(popup).toHaveRole("dialog");

  await page.keyboard.press("Escape");
  await expect(popup).toBeHidden();
  await expect(trigger).toBeFocused();
});

test("non-modal keeps the page active and ignores outside pointers", async ({ page }) => {
  await visit(page, "/preview/drawer/non-modal", "#drawer-non-modal-trigger");

  const trigger = page.getByRole("button", { name: "Non Modal", exact: true });
  const popup = page.locator("#drawer-non-modal-popup");

  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(page.locator("#drawer-non-modal-backdrop")).toHaveCount(0);
  await expect.poll(() => page.evaluate(() => document.body.style.overflow)).toBe("");

  await page.mouse.click(20, 20);
  await expect(popup).toBeVisible();

  await popup.getByRole("button", { name: "Close", exact: true }).click();
  await expect(popup).toBeHidden();
  await expect(trigger).toBeFocused();
});

test("nested Escape closes only the front drawer", async ({ page }) => {
  await visit(page, "/preview/drawer/nested", "#drawer-nested-trigger");

  const popups = [1, 2, 3, 4].map((level) =>
    page.locator(`#drawer-nested${level === 1 ? "" : `-${level}`}-popup`),
  );
  const triggerNames = [
    "Open Drawer",
    "Open Nested Drawer",
    "Open Third Drawer",
    "Open Fourth Drawer",
  ];

  for (let index = 0; index < popups.length; index += 1) {
    await page.getByRole("button", { name: triggerNames[index], exact: true }).click();
    await expect(popups[index]).toBeVisible();
  }

  await expect(popups[0]).toHaveAttribute("data-nested-drawer-open", "");
  await expect(popups[0]).toHaveCSS("--nested-drawers", "3");

  await page.keyboard.press("Escape");
  await expect(popups[3]).toBeHidden();
  await expect(popups[0]).toBeVisible();
  await expect(popups[1]).toBeVisible();
  await expect(popups[2]).toBeVisible();

  await page.keyboard.press("Escape");
  await expect(popups[2]).toBeHidden();
  await expect(popups[0]).toBeVisible();
  await expect(popups[1]).toBeVisible();
});

test("swipe handle closes the drawer after a downward drag", async ({ page }) => {
  await visit(page, "/preview/drawer/swipe-handle", "#drawer-swipe-handle-trigger");

  const trigger = page.getByRole("button", { name: "Open Drawer", exact: true });
  const popup = page.locator("#drawer-swipe-handle-popup");
  const handle = popup.locator("[data-slot='drawer-swipe-handle']");

  await trigger.click();
  await expect(popup).toBeVisible();

  const box = await handle.boundingBox();
  expect(box).not.toBeNull();
  const x = box.x + box.width / 2;
  const y = box.y + box.height / 2;

  await page.mouse.move(x, y);
  await page.mouse.down();
  await page.mouse.move(x, y + 240, { steps: 5 });
  await expect(popup).toHaveAttribute("data-swiping", "");
  await page.mouse.up();

  await expect(popup).toBeHidden();
  await expect(trigger).toBeFocused();
});

test("snap points move between compact and full states", async ({ page }) => {
  await visit(page, "/preview/drawer/snap-points", "#drawer-snap-points-trigger");

  const trigger = page.getByRole("button", { name: "Open Snap Drawer", exact: true });
  const popup = page.locator("#drawer-snap-points-popup");
  const handle = popup.locator("[data-slot='drawer-swipe-handle']");
  const overlay = page.locator("#drawer-snap-points-backdrop");

  await trigger.click();
  await expect(popup).toBeVisible();
  await expect.poll(() => snapOffset(popup)).toBeGreaterThan(0);
  await expect(overlay).toHaveCSS("opacity", "0.5");

  await dragBy(page, handle, 0, -160);
  await expect.poll(() => snapOffset(popup)).toBe(0);
  await expect(overlay).toHaveCSS("opacity", "1");

  await dragBy(page, handle, 0, 160);
  await expect.poll(() => snapOffset(popup)).toBeGreaterThan(0);
  await expect(popup).toBeVisible();

  await dragBy(page, handle, 0, 240);
  await expect(popup).toBeHidden();
  await expect(trigger).toBeFocused();
});

test("responsive example uses a dialog on desktop", async ({ page }) => {
  await visit(page, "/preview/drawer/dialog", "#drawer-dialog-responsive");

  const desktop = page.locator("[data-lb-desktop]");
  const mobile = page.locator("[data-lb-mobile]");
  const trigger = desktop.getByRole("button", { name: "Edit Profile", exact: true });
  const popup = page.locator("#drawer-dialog-desktop-popup");

  await expect(desktop).toBeVisible();
  await expect(mobile).toBeHidden();
  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(popup).toHaveRole("dialog");
  await expect(popup.getByLabel("Email")).toHaveValue("shadcn@example.com");
  await expect(popup.getByLabel("Username")).toHaveValue("@shadcn");
});

test("responsive example uses a drawer on a small screen", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await visit(page, "/preview/drawer/dialog", "#drawer-dialog-responsive");

  const desktop = page.locator("[data-lb-desktop]");
  const mobile = page.locator("[data-lb-mobile]");
  const trigger = mobile.getByRole("button", { name: "Edit Profile", exact: true });
  const popup = page.locator("#drawer-dialog-mobile-popup");

  await expect(desktop).toBeHidden();
  await expect(mobile).toBeVisible();
  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(popup).toHaveRole("dialog");
  await expect(popup).toHaveAttribute("data-swipe-direction", "down");
  await expect(popup.getByLabel("Email")).toHaveValue("shadcn@example.com");
  await expect(popup.getByLabel("Username")).toHaveValue("@shadcn");
});

test("default selects a delivery time and confirms", async ({ page }) => {
  await visit(page, "/preview/drawer/default", "#drawer-demo-trigger");

  const trigger = page.getByRole("button", { name: "Open Drawer", exact: true });
  const popup = page.locator("#drawer-demo-popup");
  const first = page.locator("#delivery-asap");
  const later = page.locator("#delivery-5-30");

  await trigger.click();
  await expect(first).toBeChecked();

  await page.locator("label[for='delivery-5-30']").click();
  await expect(later).toBeChecked();
  await expect(first).not.toBeChecked();

  await popup.getByRole("button", { name: "Confirm Delivery Time", exact: true }).click();
  await expect(popup).toBeHidden();
  await expect(trigger).toBeFocused();
});

test("modal closes when the user points outside it", async ({ page }) => {
  await visit(page, "/preview/drawer/default", "#drawer-demo-trigger");

  const trigger = page.getByRole("button", { name: "Open Drawer", exact: true });
  const popup = page.locator("#drawer-demo-popup");

  await trigger.click();
  await expect(popup).toBeVisible();

  await page.mouse.click(20, 20);
  await expect(popup).toBeHidden();
  await expect(trigger).toBeFocused();
});

async function dragBy(page, locator, deltaX, deltaY) {
  const box = await locator.boundingBox();
  expect(box).not.toBeNull();
  const x = box.x + box.width / 2;
  const y = box.y + box.height / 2;

  await page.mouse.move(x, y);
  await page.mouse.down();
  await page.mouse.move(x + deltaX, y + deltaY, { steps: 5 });
  await page.mouse.up();
}

async function snapOffset(locator) {
  return locator.evaluate((element) =>
    Number.parseFloat(getComputedStyle(element).getPropertyValue("--drawer-snap-point-offset")),
  );
}
