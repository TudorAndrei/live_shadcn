import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test.describe("a toggle group", () => {
  test("multiple mode keeps independent selections", async ({ page }) => {
    await visit(page, "/preview/toggle-group/default");
    const bold = page.getByRole("button", { name: "Toggle bold" });
    const italic = page.getByRole("button", { name: "Toggle italic" });

    await bold.click();
    await italic.click();

    await expect(bold).toHaveAttribute("aria-pressed", "true");
    await expect(italic).toHaveAttribute("aria-pressed", "true");

    await bold.click();
    await expect(bold).toHaveAttribute("aria-pressed", "false");
  });

  test("exclusive mode clears the old item and permits no selection", async ({ page }) => {
    await visit(page, "/preview/toggle-group/outline");
    const all = page.getByRole("button", { name: "Toggle all" });
    const missed = page.getByRole("button", { name: "Toggle missed" });

    await expect(all).toHaveAttribute("aria-pressed", "true");
    await missed.click();
    await expect(all).toHaveAttribute("aria-pressed", "false");
    await expect(missed).toHaveAttribute("aria-pressed", "true");

    await missed.click();
    await expect(missed).toHaveAttribute("aria-pressed", "false");
  });

  test("a disabled group does not change", async ({ page }) => {
    await visit(page, "/preview/toggle-group/disabled");
    const bold = page.getByRole("button", { name: "Toggle bold" });

    await expect(bold).toBeDisabled();
    await bold.click({ force: true });
    await expect(bold).toHaveAttribute("aria-pressed", "false");
  });

  test("a selected value updates its named output", async ({ page }) => {
    await visit(page, "/preview/toggle-group/font-weight-selector");

    await page.getByRole("button", { name: "Light" }).click();
    await expect(page.locator("#font-weight-output")).toHaveText("font-light");

    await page.getByRole("button", { name: "Light" }).click();
    await expect(page.locator("#font-weight-output")).toHaveText("font-");
  });
});
