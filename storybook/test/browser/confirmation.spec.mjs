import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const alert = (page) => page.locator("[data-slot='alert']");

async function open(page, example) {
  await visit(page, `/preview/confirmation/${example}`, "[data-slot='alert']");
}

test.describe("a confirmation", () => {
  test("shows the default request and its two native action buttons", async ({ page }) => {
    await open(page, "default");

    await expect(alert(page)).toHaveAttribute("role", "alert");
    await expect(page.getByText("This tool wants to delete the file")).toBeVisible();
    await expect(page.locator("code")).toHaveText("/tmp/example.txt");
    await expect(page.getByRole("button", { name: "Reject" })).toHaveAttribute("type", "button");
    await expect(page.getByRole("button", { name: "Approve" })).toHaveAttribute("type", "button");
    await expect(page.getByText("You approved this tool execution")).toHaveCount(0);
    await expect(page.getByText("You rejected this tool execution")).toHaveCount(0);
  });

  test("shows the request state with its block query and actions", async ({ page }) => {
    await open(page, "request");

    await expect(page.getByText("This tool wants to execute a query on the production database:")).toBeVisible();
    await expect(page.locator("code")).toHaveText("SELECT * FROM users WHERE role = 'admin'");
    await expect(page.getByRole("button", { name: "Reject" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Approve" })).toBeVisible();
    await expect(page.getByText("You approved this tool execution")).toHaveCount(0);
    await expect(page.getByText("You rejected this tool execution")).toHaveCount(0);
  });

  test("shows only the accepted response after approval", async ({ page }) => {
    await open(page, "accepted");

    await expect(page.getByText("You approved this tool execution")).toBeVisible();
    await expect(page.getByText("You rejected this tool execution")).toHaveCount(0);
    await expect(page.getByText("This tool wants to delete the file")).toHaveCount(0);
    await expect(page.getByRole("button")).toHaveCount(0);
  });

  test("shows only the rejected response after denial", async ({ page }) => {
    await open(page, "rejected");

    await expect(page.getByText("You rejected this tool execution")).toBeVisible();
    await expect(page.getByText("You approved this tool execution")).toHaveCount(0);
    await expect(page.getByText("This tool wants to delete the file")).toHaveCount(0);
    await expect(page.getByRole("button")).toHaveCount(0);
  });
});
