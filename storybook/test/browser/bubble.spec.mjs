import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("the official Bubble choices are native buttons and show their notices", async ({ page }) => {
  await visit(page, "/preview/bubble/link-button");

  const choice = page.getByRole("button", { name: "I forgot my password" });
  await expect(choice).toHaveAttribute("data-slot", "bubble-content");

  await choice.click();
  await expect(page.locator("[data-sonner-toast]")).toContainText(
    "You clicked forgot password",
  );
});

test("the destructive Bubble action reports success", async ({ page }) => {
  await visit(page, "/preview/bubble/reactions");

  await page.getByRole("button", { name: "Yes, run it" }).click();

  const toast = page.locator("[data-sonner-toast]");
  await expect(toast).toHaveAttribute("data-type", "success");
  await expect(toast).toContainText("You clicked yes, running command...");
});

test("the long Bubble answer expands and collapses", async ({ page }) => {
  await visit(page, "/preview/bubble/collapsible", "#bubble-collapsible-trigger");

  const trigger = page.locator("#bubble-collapsible-trigger");
  const fullAnswer = page.getByText("The dialog and drawer are fine.", { exact: false });

  await expect(trigger).toHaveAttribute("aria-expanded", "false");
  await expect(trigger).toContainText("Show more");
  await expect(fullAnswer).toBeHidden();

  await trigger.click();
  await expect(trigger).toHaveAttribute("aria-expanded", "true");
  await expect(trigger).toContainText("Show less");
  await expect(fullAnswer).toBeVisible();

  await trigger.click();
  await expect(fullAnswer).toBeHidden();
});

test("the Bubble read receipt opens its tooltip", async ({ page }) => {
  await visit(page, "/preview/bubble/tooltip", "#bubble-read-receipt-trigger");

  await page.locator("#bubble-read-receipt-trigger").focus();
  await expect(page.locator("#bubble-read-receipt-popup")).toBeVisible();
  await expect(page.locator("#bubble-read-receipt-popup")).toHaveText(
    "Read on Jan 5, 2026 at 4:32 PM",
  );
});

test("the Bubble error popover opens and closes on an outside click", async ({ page }) => {
  await visit(page, "/preview/bubble/popover", "#bubble-error-details-trigger");

  const trigger = page.locator("#bubble-error-details-trigger");
  const popup = page.locator("#bubble-error-details-popup");

  await expect(trigger).toHaveAttribute("aria-label", "Show error details");
  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(popup).toContainText("Command failed with exit code 1");

  await page.locator("body").click({ position: { x: 5, y: 5 } });
  await expect(popup).toBeHidden();
});
