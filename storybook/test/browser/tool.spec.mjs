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
