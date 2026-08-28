import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test.describe("prompt input", () => {
  test("Enter submits and Shift+Enter adds a new line", async ({ page }) => {
    await visit(page, "/preview/prompt-input/default", "textarea");

    const textarea = page.locator("textarea");
    const submit = page.getByRole("button", { name: "Submit" });

    await expect(submit).toHaveAttribute("type", "submit");

    await page.locator("form").evaluate((form) => {
      window.promptSubmits = 0;
      form.addEventListener("submit", (event) => {
        event.preventDefault();
        window.promptSubmits += 1;
      });
    });

    await textarea.fill("First line");
    await textarea.press("Shift+Enter");
    await expect(textarea).toHaveValue("First line\n");
    expect(await page.evaluate(() => window.promptSubmits)).toBe(0);

    await textarea.press("Enter");
    await expect.poll(() => page.evaluate(() => window.promptSubmits)).toBe(1);
    await expect(textarea).toHaveValue("First line\n");
  });

  test("Enter does not submit through a disabled button", async ({ page }) => {
    await visit(page, "/preview/prompt-input/default", "textarea");

    await page.getByRole("button", { name: "Submit" }).evaluate((button) => {
      button.disabled = true;
    });
    await page.locator("form").evaluate((form) => {
      window.promptSubmits = 0;
      form.addEventListener("submit", (event) => {
        event.preventDefault();
        window.promptSubmits += 1;
      });
    });

    const textarea = page.locator("textarea");
    await textarea.fill("Keep editing");
    await textarea.press("Enter");

    expect(await page.evaluate(() => window.promptSubmits)).toBe(0);
    await expect(textarea).toHaveValue("Keep editing\n");
  });
});
