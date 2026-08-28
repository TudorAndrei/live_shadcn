import { expect } from "@playwright/test";

import { visit } from "./live.mjs";

export async function disclosureContract(page, component, root) {
  const frames = [];
  page.on("websocket", (socket) =>
    socket.on("framesent", ({ payload }) => frames.push(String(payload))),
  );

  await visit(page, `/preview/${component}/default`, root);

  const trigger = page.locator(`${root} [data-slot='collapsible-trigger']`);
  const panel = page.locator(`${root} [data-slot='collapsible-content']`);

  await expect(trigger).toHaveAttribute("aria-expanded", "false");
  await expect(panel).toBeHidden();

  await trigger.click();
  await expect(trigger).toHaveAttribute("aria-expanded", "true");
  await expect(panel).toBeVisible();

  await trigger.click();
  await expect(trigger).toHaveAttribute("aria-expanded", "false");
  await expect(panel).toBeHidden();

  expect(frames.filter((frame) => frame.includes('"event"'))).toEqual([]);
}

export async function clipboardContract(page, component, selector, expected, contains = false) {
  await visit(page, `/preview/${component}/default`, selector);

  const copy = page.locator(selector);
  await expect(copy).toHaveAttribute("data-lb-ready", "");
  await copy.click();
  await expect(copy.locator("[data-lb-state='copied']")).toBeVisible();

  const value = await page.evaluate(() => navigator.clipboard.readText());
  if (contains) expect(value).toContain(expected);
  else expect(value).toBe(expected);
}
