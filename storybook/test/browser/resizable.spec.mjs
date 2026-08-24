import { expect, test } from "@playwright/test";

const panel = (page, index) => page.locator('[data-slot="resizable-panel"]').nth(index);
const handle = (page) => page.locator("[data-lb-resizable-handle]");

test.describe("a resizable panel group", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/preview/resizable/default");
    await page.waitForFunction(() => window.liveSocket?.isConnected());
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
