import { expect, test } from "@playwright/test";

import { clipboardContract } from "./ai-contracts.mjs";
import { visit } from "./live.mjs";

test.beforeEach(async ({ context }) => {
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
});

test("the streaming example appends output and completes its running state", async ({ page }) => {
  await visit(page, "/preview/terminal/streaming", "[data-terminal-content]");
  const output = page.locator("[data-terminal-content]");
  await expect(page.getByText("Running...", { exact: true })).toBeVisible();
  await expect(output).toContainText("Installing dependencies...", { timeout: 5000 });
  await expect(output).toContainText("Done! Installed 3 packages in 1.2s", { timeout: 6000 });
  await expect(page.getByText("Running...", { exact: true })).toBeHidden();
  await expect(output).toContainText("$ npm install");
});

test("a terminal follows new output, can retain its position, and clears through its caller", async ({ page }) => {
  await visit(page, "/preview/terminal/contract", "#streaming-terminal");
  const terminal = page.locator("#streaming-terminal");
  const output = terminal.locator("[data-terminal-content]");
  const gap = () => output.evaluate((node) => node.scrollHeight - node.clientHeight - node.scrollTop);
  await expect(terminal.getByText("Running...", { exact: true })).toBeVisible();
  await expect.poll(gap).toBeLessThanOrEqual(1);
  await expect(output).toContainText("Build error");

  await output.evaluate((node) => { node.scrollTop = 0; });
  await page.getByRole("button", { name: "Append output" }).click();
  await expect(output).toContainText("Build line 60");
  await expect.poll(gap).toBeLessThanOrEqual(1);

  await page.getByRole("button", { name: "Keep scroll position" }).click();
  await expect(terminal).toHaveAttribute("data-auto-scroll", "false");
  await output.evaluate((node) => { node.scrollTop = 0; });
  await page.getByRole("button", { name: "Append output" }).click();
  await expect(output).toContainText("Build line 80");
  await expect.poll(() => output.evaluate((node) => node.scrollTop)).toBe(0);
  await terminal.getByRole("button", { name: "Clear output", exact: true }).click();
  await expect(output).toHaveText("");
  await expect(terminal.getByText("Running...", { exact: true })).toBeHidden();
});

test("the terminal copies its output", async ({ page }) => {
  await clipboardContract(
    page,
    "terminal",
    "#copy-output",
    "Compiling 4 files (.ex)",
  );
});
