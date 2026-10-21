import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("Code Block copies exact source, announces success, and restores its label", async ({ page, context }) => {
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
  await visit(page, "/preview/shadcn-code-block/header", "[data-slot=code-block-copy-button]");
  const copy = page.locator("[data-slot=code-block-copy-button]");
  await expect(copy).toHaveAccessibleName("Copy");
  await expect(copy).toHaveAttribute("data-lb-ready", "");
  const source = await copy.getAttribute("data-lb-clipboard");
  await copy.click();
  await expect.poll(() => page.evaluate(() => navigator.clipboard.readText())).toBe(source);
  await expect(copy).toHaveAccessibleName("Copied");
  await expect(page.locator("[aria-live=polite]")).toHaveText("Copied");
  await expect(copy).toHaveAccessibleName("Copy", { timeout: 3000 });
  await expect(page.locator("[aria-live=polite]")).toBeEmpty();
});

test("Code Block expands its source and switches files", async ({ page }) => {
  await visit(page, "/preview/shadcn-code-block/show-more", "[data-slot=code-block-content]");
  await page.getByRole("button", { name: "Show more" }).click();
  await expect(page.getByRole("button", { name: "Show less" })).toHaveAttribute("aria-expanded", "true");
  await expect(page.locator("[data-slot=code-block-content]")).not.toHaveClass(/max-h-64/);
  await visit(page, "/preview/shadcn-code-block/tabs", "[role=tablist]");
  await page.getByRole("tab", { name: ".env.local" }).click();
  await expect(page.getByRole("tabpanel").filter({ visible: true })).toContainText("AI_GATEWAY_API_KEY=your-api-key");
});


test("Code Block replay streams all blocks and enables copying when complete", async ({ page }) => {
  await visit(page, "/preview/shadcn-code-block/streaming", "[data-preview=shadcn-code-block]");
  const code = page.locator("[data-slot=code-block-code]");
  const complete = await code.allTextContents();
  const replay = page.getByRole("button", { name: "Replay" });
  await replay.click();
  await expect(replay).toBeDisabled();
  await expect(page.locator("[data-slot=code-block-copy-button]").first()).toBeDisabled();
  await expect(replay).toBeEnabled({ timeout: 20_000 });
  expect(await code.allTextContents()).toEqual(complete);
  expect(await page.locator("[data-slot=code-block-copy-button]:disabled").count()).toBe(0);
});
