import { expect, test } from "@playwright/test";

import { clipboardContract } from "./ai-contracts.mjs";
import { visit } from "./live.mjs";

test.beforeEach(async ({ context }) => {
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
});

test("plain source keeps its whitespace and markup when rendered and copied", async ({ page }) => {
  const source = '<script>alert("example")</script>\n\n  return value;\n';
  await visit(page, "/preview/code-block/contract", "#plain-code");
  const code = page.locator("#plain-code code");
  expect(await code.textContent()).toBe(source);
  await expect(code.locator("script")).toHaveCount(0);

  const copy = page.getByRole("button", { name: "Copy source" });
  await expect(copy).toHaveAttribute("data-lb-ready", "");
  await copy.click();
  await expect.poll(() => page.evaluate(() => navigator.clipboard.readText())).toBe(source);
  await expect(copy.locator("[data-lb-state='copied']")).toBeVisible();

  const keyword = page.locator("#highlighted-code code span").filter({ hasText: /^const$/ }).last();
  await expect(keyword).toHaveCSS("color", "rgb(0, 0, 255)");
  await expect(keyword).toHaveCSS("font-weight", "700");
  await expect(page.locator("#highlighted-code code")).toHaveText("const count = 1;");
});

test("the code block copies its code", async ({ page }) => {
  await clipboardContract(page, "code-block", "#copy-code", "mix ui.spec");
});
