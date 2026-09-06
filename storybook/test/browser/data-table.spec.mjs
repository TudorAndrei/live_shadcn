import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test.describe("the Base Data Table examples", () => {
  test("persists a row selection on the server", async ({ page }) => {
    await visit(page, "/preview/data-table/default", "#data-table");

    await page.getByRole("checkbox", { name: "Select row", exact: true }).first().click();

    await expect(page.locator("#data-table-summary")).toHaveText("1 of 5 row(s) selected.");
    await expect(page.getByRole("checkbox", { name: "Select all", exact: true })).toHaveAttribute(
      "aria-checked",
      "mixed",
    );
  });

  test("filters, sorts, selects rows, and hides a column", async ({ page }) => {
    await page.addInitScript(() => {
      window.__dataTableClipboard = null;
      Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: {
          writeText: async (value) => {
            window.__dataTableClipboard = value;
          },
        },
      });
    });

    await visit(page, "/preview/data-table/default", "#data-table");

    await expect(page.getByRole("button", { name: "Previous" })).toBeDisabled();
    await expect(page.getByRole("button", { name: "Next" })).toBeDisabled();
    await expect
      .poll(() => page.locator("#data-table-summary").evaluate((element) => element.textContent))
      .toBe("0 of 5 row(s) selected.");
    await expect
      .poll(() =>
        page.locator("#data-table-summary").evaluate((element) =>
          [...element.childNodes]
            .filter((node) => node.nodeType === Node.TEXT_NODE)
            .map((node) => node.nodeValue),
        ),
      )
      .toEqual(["0", " of", " ", "5", " row(s) selected."]);
    await expect
      .poll(() =>
        page.evaluate(() => {
          const buttons = [...document.querySelectorAll("#data-table button[disabled]")];
          const previous = buttons.find((button) => button.textContent?.trim() === "Previous");
          const next = buttons.find((button) => button.textContent?.trim() === "Next");
          const summary = document.querySelector("#data-table-summary");
          if (!previous || !next || !summary) return null;
          const summaryBox = summary.getBoundingClientRect();
          const previousBox = previous.getBoundingClientRect();
          const nextBox = next.getBoundingClientRect();
          return {
            buttons: nextBox.left - previousBox.right,
            summary: previousBox.left - summaryBox.right,
          };
        }),
      )
      .toEqual({ buttons: 8, summary: 8 });
    await expect
      .poll(() =>
        page.evaluate(() => {
          const toolbar = document.querySelector("#data-table > div");
          const columns = toolbar?.querySelector(":scope > [data-slot='dropdown-menu-trigger']");
          const footer = document.querySelector("#data-table > div:last-child");
          const buttons = footer
            ? [...footer.querySelectorAll(":scope > div:last-child > button")]
            : [];

          return {
            toolbarClass: toolbar?.className,
            directColumns: columns?.textContent?.trim(),
            footerClass: footer?.className,
            buttonDisplays: buttons.map((button) => getComputedStyle(button).display),
            buttonMargins: buttons.map((button) => getComputedStyle(button).marginRight),
          };
        }),
      )
      .toEqual({
        toolbarClass: "flex items-center py-4",
        directColumns: "Columns",
        footerClass: "flex items-center justify-end space-x-2 py-4",
        buttonDisplays: ["inline-flex", "inline-flex"],
        buttonMargins: ["8px", "0px"],
      });

    await page.locator("#data-table-filter").fill("carmella");
    await expect(page.locator("#data-table tbody tr")).toHaveCount(1);
    await expect(page.locator("#data-table tbody tr")).toContainText("carmella@example.com");

    await page.locator("#data-table-filter").fill("");
    await page.getByRole("button", { name: "Email" }).click();
    await expect(page.locator("#data-table tbody tr").first()).toContainText("Abe45@example.com");

    await page.locator("#data-table-m5gr84i9-control").click();
    await expect(page.locator("#data-table-m5gr84i9-control")).toHaveAttribute("aria-checked", "true");
    await expect(page.locator("#data-table-m5gr84i9-control").locator("xpath=ancestor::tr")).toHaveAttribute(
      "data-state",
      "selected",
    );
    await expect(page.locator("#data-table-summary")).toContainText("1 of 5 row(s) selected.");

    await page.getByRole("checkbox", { name: "Select all" }).click();
    await expect(page.locator("#data-table-summary")).toContainText("5 of 5 row(s) selected.");

    await page.getByRole("button", { name: "Columns" }).click();
    const columnsPopup = page.locator("#data-table-columns-popup");
    await expect(columnsPopup).toHaveClass(/w-44/);
    await page.getByRole("menuitemcheckbox", { name: "amount" }).click();
    await expect(page.locator("#data-table thead")).not.toContainText("Amount");
    await page.keyboard.press("Escape");
    await expect(columnsPopup).toBeHidden();

    await page.locator("#data-table-actions-m5gr84i9-trigger").click();
    const actionsPopup = page.locator("#data-table-actions-m5gr84i9-popup");
    await expect(page.locator("#data-table-actions-m5gr84i9-trigger")).toHaveAttribute("aria-expanded", "true");
    await expect(page.locator("#data-table-actions-m5gr84i9-trigger")).toHaveAttribute("data-popup-open", "");
    await expect(actionsPopup).toHaveClass(/w-44/);
    await page.getByRole("menuitem", { name: "Copy payment ID" }).click();
    await expect.poll(() => page.evaluate(() => window.__dataTableClipboard)).toBe("m5gr84i9");
  });

  test("renders the Arabic published example right to left", async ({ page }) => {
    await visit(page, "/preview/data-table/rtl", "#data-table-rtl");

    await expect(page.locator("#data-table-rtl")).not.toHaveAttribute("dir");
    await expect(page.getByRole("button", { name: "الأعمدة" })).toBeVisible();
    await expect(page.locator("#data-table-rtl tbody tr")).toHaveCount(5);
    await expect(page.locator("#data-table-rtl")).toContainText("‏٣١٦٫٠٠ US$");
    await expect
      .poll(() =>
        page.locator("#data-table-rtl-summary").evaluate((element) =>
          [...element.childNodes]
            .filter((node) => node.nodeType === Node.TEXT_NODE)
            .map((node) => node.nodeValue),
        ),
      )
      .toEqual(["0", " ", "من", " ", "5", " ", "صف(وف) محدد."]);

    await page.getByRole("button", { name: "الأعمدة" }).click();
    const columnsPopup = page.locator("#data-table-rtl-columns-popup");
    await expect(columnsPopup).toContainText("status");
    await expect(columnsPopup).toContainText("email");
    await expect(columnsPopup).toContainText("amount");
    await page.keyboard.press("Escape");
    await expect(columnsPopup).toBeHidden();

    await page.locator("#data-table-rtl-actions-m5gr84i9-trigger").click();
    await expect(page.locator("#data-table-rtl-actions-m5gr84i9-popup")).toHaveClass(/w-40/);
  });
});
