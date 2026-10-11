import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const trigger = (page) => page.locator("#read-spec-trigger");
const panel = (page) => page.locator("#read-spec-panel");

test.describe("a tool result", () => {
  test("starts open with an upward chevron", async ({ page }) => {
    await visit(page, "/preview/tool/default", "#read-spec");

    await expect(trigger(page)).toHaveAttribute("aria-expanded", "true");
    await expect(panel(page)).toBeVisible();
    await expect(trigger(page).locator(".lucide-chevron-down")).toHaveCSS("rotate", "180deg");
  });

  test("a click closes the result without a server event", async ({ page }) => {
    const frames = [];
    page.on("websocket", (socket) =>
      socket.on("framesent", ({ payload }) => frames.push(String(payload))),
    );

    await visit(page, "/preview/tool/default", "#read-spec");
    await trigger(page).click();

    await expect(trigger(page)).toHaveAttribute("aria-expanded", "false");
    await expect(panel(page)).toBeHidden();
    expect(frames.filter((frame) => frame.includes("event"))).toHaveLength(0);
  });
});

for (const [state, label, name, content] of [
  ["input-available", "Running", "image_generation", "A futuristic cityscape at sunset with flying cars"],
  ["input-streaming", "Pending", "web_search", "latest AI market trends 2024"],
  ["output-available", "Completed", "database_query", "charlie@example.com"],
  ["output-error", "Error", "api_request", "Connection timeout: The request took longer than 5000ms to complete."],
]) {
  test(`tool ${state} shows its status and disclosed payload`, async ({ page }) => {
    await visit(page, `/preview/tool/${state}`, "#variant-tool");
    const trigger = page.locator("#variant-tool-trigger");
    const panel = page.locator("#variant-tool-panel");
    await expect(trigger).toContainText(name);
    await expect(trigger.locator("[data-slot=badge]")).toHaveText(label);
    await expect(panel).toBeHidden();
    await trigger.click();
    await expect(panel).toBeVisible();
    await expect(panel).toContainText(content);
    await trigger.press("Enter");
    await expect(panel).toBeHidden();
  });
}
