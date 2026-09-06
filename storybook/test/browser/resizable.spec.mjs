import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const panel = (page, index) => page.locator('[data-slot="resizable-panel"]').nth(index);
const handle = (page) => page.locator("[data-lb-resizable-handle]").first();
const group = (page, id) => page.locator(`#${id}`);
const groupPanel = (page, id, index) => group(page, id).locator(":scope > [data-slot='resizable-panel']").nth(index);
const groupHandle = (page, id, index = 0) => group(page, id).locator(":scope > [data-lb-resizable-handle]").nth(index);

async function dragBy(page, target, x, y) {
  const box = await target.boundingBox();
  expect(box).not.toBeNull();

  const startX = box.x + box.width / 2;
  const startY = box.y + box.height / 2;
  await page.mouse.move(startX, startY);
  await page.mouse.down();
  await page.mouse.move(startX + x, startY + y);
  await page.mouse.up();
}

test.describe("a resizable panel group", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/resizable/default");
    await expect(handle(page)).toBeVisible();
  });

  test("changes the adjacent panel sizes on drag", async ({ page }) => {
    const initialWidth = await panel(page, 0).evaluate((element) => element.getBoundingClientRect().width);
    const box = await handle(page).boundingBox();

    await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
    await page.mouse.down();
    await page.mouse.move(box.x + box.width / 2 + 60, box.y + box.height / 2);
    await page.mouse.up();

    await expect
      .poll(() => panel(page, 0).evaluate((element) => element.getBoundingClientRect().width))
      .toBeGreaterThan(initialWidth);
  });
});

test("the vertical example changes adjacent panel heights on drag", async ({ page }) => {
  await visit(page, "/preview/resizable/vertical", "#resizable-vertical");
  const header = groupPanel(page, "resizable-vertical", 0);
  const divider = groupHandle(page, "resizable-vertical");
  const before = await header.evaluate((element) => element.getBoundingClientRect().height);

  await expect(group(page, "resizable-vertical")).toHaveAttribute("data-lb-orientation", "vertical");
  await expect(divider).toHaveAttribute("aria-orientation", "horizontal");
  await dragBy(page, divider, 0, 60);

  await expect
    .poll(() => header.evaluate((element) => element.getBoundingClientRect().height))
    .toBeGreaterThan(before);
});

test("the handle example shows its grip and changes adjacent panel widths on drag", async ({ page }) => {
  await visit(page, "/preview/resizable/handle", "#resizable-handle");
  const sidebar = groupPanel(page, "resizable-handle", 0);
  const divider = groupHandle(page, "resizable-handle");
  const before = await sidebar.evaluate((element) => element.getBoundingClientRect().width);

  await expect(divider.locator(":scope > .cn-resizable-handle-icon")).toBeVisible();
  await expect(divider).toHaveAttribute("aria-valuenow", "25");
  await dragBy(page, divider, 60, 0);

  await expect
    .poll(() => sidebar.evaluate((element) => element.getBoundingClientRect().width))
    .toBeGreaterThan(before);
});

test("the RTL example changes the first visible panel width on horizontal drag", async ({ page }) => {
  await visit(page, "/preview/resizable/rtl", "#resizable-rtl");
  const first = groupPanel(page, "resizable-rtl", 0);
  const divider = groupHandle(page, "resizable-rtl");
  const before = await first.evaluate((element) => element.getBoundingClientRect().width);

  await expect(group(page, "resizable-rtl")).toHaveAttribute("dir", "rtl");
  await dragBy(page, divider, 60, 0);

  await expect
    .poll(() => first.evaluate((element) => element.getBoundingClientRect().width))
    .toBeGreaterThan(before);
});
