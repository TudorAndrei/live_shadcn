import { expect, test } from "@playwright/test";

import { clipboardContract } from "./ai-contracts.mjs";
import { visit } from "./live.mjs";

test.beforeEach(async ({ context }) => {
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
});

test("a trace filters internal frames and sends a selected file location to its caller", async ({ page }) => {
  await visit(page, "/preview/stack-trace/contract", "#trace-frames");
  await expect(page.locator("#empty-trace")).toHaveText("No stack frames");
  const source = page.getByRole("button", { name: "parser.ex:42:7", exact: true });
  const internal = page.getByRole("button", { name: "node:internal/task:95:5", exact: true });
  await expect(source).toBeVisible();
  await expect(internal).toBeHidden();
  await source.click();
  await expect(page.getByRole("status")).toHaveText("Selected parser.ex:42:7");

  await page.getByRole("button", { name: "Include internal frames" }).click();
  await expect(internal).toBeVisible();
  await page.getByRole("button", { name: "Hide stack frames", exact: true }).press("Enter");
  await expect(source).toBeHidden();
  await page.getByRole("button", { name: "Show stack frames", exact: true }).press(" ");
  await expect(source).toBeVisible();
  await expect(internal).toBeVisible();
});

test("the stack trace copies its raw text", async ({ page }) => {
  await clipboardContract(
    page,
    "stack-trace",
    "#copy-trace",
    "TypeError: Cannot read properties of undefined (reading 'slots')",
    true,
  );
});
