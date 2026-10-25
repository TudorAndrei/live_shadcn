import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("Trace opens nested command output and keeps a controlled trigger in sync", async ({ page }) => {
  await visit(page, "/preview/trace/open", "[data-preview=trace]");
  const trigger = page.getByRole("button", { name: "Ran pnpm --version" });
  await expect(trigger).toHaveAttribute("aria-expanded", "false");
  await page.getByRole("button", { name: "Show the pnpm output" }).click();
  await expect(trigger).toHaveAttribute("aria-expanded", "true");
  await expect(page.locator("[data-slot=code-block-content]").filter({ hasText: "10.33.4" })).toBeVisible();
  await trigger.click();
  await expect(page.getByRole("button", { name: "Show the pnpm output" })).toBeVisible();
  await expect(trigger).toHaveAttribute("aria-expanded", "false");
});


test("Trace streams a reply, completes it, and resets the conversation", async ({ page }) => {
  await visit(page, "/preview/trace/thinking", "[data-preview=trace]");
  await page.getByRole("button", { name: "Send message" }).click();
  await expect(page.locator("[data-slot=trace-line][data-status=running]").first()).toBeVisible();
  const reset = page.getByRole("button", { name: "Reset", exact: true });
  await expect(reset).toBeVisible({ timeout: 20_000 });
  await expect(page.locator("[data-slot=message]")).toHaveCount(2);
  await reset.click();
  await expect(page.getByRole("button", { name: "Send message" })).toBeVisible();
  await expect(page.locator("[data-slot=message]")).toHaveCount(0);
});
