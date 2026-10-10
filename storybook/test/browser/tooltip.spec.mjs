import { expect, test } from "@playwright/test";

import { connected } from "./live.mjs";

test.beforeEach(async ({ page }) => {
  await page.goto("/preview/tooltip/default");
  await connected(page);
});

test("hover opens a positioned tooltip without disclosure state", async ({ page }, testInfo) => {
  const trigger = page.locator("#tooltip-default-trigger");
  const positioner = page.locator("#tooltip-default-positioner");
  const popup = page.locator("#tooltip-default-popup");
  const expandedState = await trigger.evaluateHandle((node) => {
    const expandedValues = [];
    const record = (records) => {
      for (const mutation of records) {
        if (mutation.oldValue !== null) expandedValues.push(mutation.oldValue);
      }
      const current = node.getAttribute("aria-expanded");
      if (current !== null) expandedValues.push(current);
    };
    const observer = new MutationObserver(record);
    observer.observe(node, {
      attributes: true,
      attributeFilter: ["aria-expanded"],
      attributeOldValue: true,
    });
    record([]);
    return {
      values() {
        record(observer.takeRecords());
        return expandedValues;
      },
      disconnect() {
        observer.disconnect();
      },
    };
  });

  try {
    await trigger.hover();
    await popup.waitFor({ state: "visible" });
    const opened = {
      renderer: "Phoenix",
      triggerId: await trigger.getAttribute("id"),
      popupVisible: await popup.isVisible(),
      side: await positioner.getAttribute("data-side"),
      expandedValues: await expandedState.evaluate((state) => state.values()),
    };
    await testInfo.attach("tooltip-open-state", {
      body: Buffer.from(JSON.stringify(opened, null, 2)),
      contentType: "application/json",
    });
    expect(opened.popupVisible).toBe(true);
    expect(opened.side).toMatch(/top|right|bottom|left/);
    expect(opened.expandedValues).toEqual([]);

    await page.keyboard.press("Escape");
    await popup.waitFor({ state: "hidden" });
    const closed = {
      renderer: "Phoenix",
      triggerId: await trigger.getAttribute("id"),
      popupVisible: await popup.isVisible(),
      expandedValues: await expandedState.evaluate((state) => state.values()),
    };
    await testInfo.attach("tooltip-closed-state", {
      body: Buffer.from(JSON.stringify(closed, null, 2)),
      contentType: "application/json",
    });
    expect(closed.popupVisible).toBe(false);
    expect(closed.expandedValues).toEqual([]);
  } finally {
    await expandedState.evaluate((state) => state.disconnect());
    await expandedState.dispose();
  }
});
