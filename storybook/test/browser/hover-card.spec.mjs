import { expect, test } from "@playwright/test";

import { connected, referenceReady, visit } from "./live.mjs";

test("hover opens the card and leaving both parts closes it", async ({ page }) => {
  await visit(page, "/preview/hover-card/default", "#nextjs-trigger");
  const trigger = page.locator("#nextjs-trigger");
  const popup = page.locator("#nextjs-popup");

  await trigger.hover();
  await expect(popup).toBeVisible();

  await popup.hover();
  await page.waitForTimeout(150);
  await expect(popup).toBeVisible();

  await page.mouse.move(0, 0);
  await expect(popup).toBeHidden();
});

test("keyboard focus opens the card without a pointer delay", async ({ page }) => {
  await visit(page, "/preview/hover-card/default", "#nextjs-trigger");
  const trigger = page.locator("#nextjs-trigger");
  const popup = page.locator("#nextjs-popup");

  await trigger.focus();
  await expect(popup).toBeVisible();
});

for (const side of ["React", "Phoenix"]) {
  test(`pointer click opens the card, permits popup travel, and Escape closes it on ${side}`, async ({ page }, testInfo) => {
    const path = "/preview/hover-card/sides";
    await page.goto(side === "React" ? `${testInfo.project.use.parityURL}${path}` : path);
    await (side === "React" ? referenceReady(page) : connected(page));
    const trigger = page.locator("[data-preview='hover-card'] [data-slot='hover-card-trigger']").first();
    const popup = page.locator("[data-slot='hover-card-content']").first();

    await page.mouse.move(0, 0);
    await expect(trigger).toBeVisible();
    await trigger.scrollIntoViewIfNeeded();
    await expect(popup).toBeHidden();
    const box = await trigger.boundingBox();
    expect(box).not.toBeNull();

    // Observe the real events. Do not change the rendered card or its timers.
    await trigger.evaluate((element) => {
      window.__hoverCardPointerEntry = { enter: null, down: null };
      element.addEventListener("pointerenter", (event) => {
        window.__hoverCardPointerEntry.enter = {
          trusted: event.isTrusted,
          time: performance.now(),
        };
      }, { once: true, passive: true });
      element.addEventListener("pointerdown", (event) => {
        const popup = document.querySelector("[data-slot='hover-card-content']");
        const style = popup && getComputedStyle(popup);
        window.__hoverCardPointerEntry.down = {
          trusted: event.isTrusted,
          pointerType: event.pointerType,
          time: performance.now(),
          popupVisible: Boolean(popup && popup.getClientRects().length &&
            style.visibility !== "hidden" && style.visibility !== "collapse"),
        };
      }, { once: true, passive: true, capture: true });
    });

    // Mouse.click sends move, down, and up without locator action waits.
    await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    const pointerEntry = await page.evaluate(() => window.__hoverCardPointerEntry);
    await testInfo.attach("pointer-entry", {
      body: JSON.stringify(pointerEntry, null, 2),
      contentType: "application/json",
    });
    expect(pointerEntry.enter, "the click must enter the real trigger").not.toBeNull();
    expect(pointerEntry.down, "the real trigger must receive pointer down").not.toBeNull();
    expect(pointerEntry.enter.trusted).toBe(true);
    expect(pointerEntry.down.trusted).toBe(true);
    expect(pointerEntry.down.pointerType).toBe("mouse");
    expect(pointerEntry.down.popupVisible, "the popup must still be closed at pointer down").toBe(false);
    const pressDelay = pointerEntry.down.time - pointerEntry.enter.time;
    expect(pressDelay).toBeGreaterThanOrEqual(0);
    expect(pressDelay, "pointer down must precede the example's 100 ms hover delay").toBeLessThan(100);
    await expect(popup).toBeVisible();

    await popup.hover();
    await expect(popup).toBeVisible();
    await page.keyboard.press("Escape");
    await expect(popup).toBeHidden();
  });
}
