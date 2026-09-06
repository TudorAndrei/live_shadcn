import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("the link Items preserve their anchor contract", async ({ page }) => {
  await visit(page, "/preview/item/link", "a[data-slot='item']:has-text('Visit our documentation')");

  const items = page.locator("a[data-slot='item']");

  await expect(items).toHaveCount(2);
  await expect(items.nth(0)).toHaveAttribute("href", "#");
  await expect(items.nth(1)).toHaveAttribute("target", "_blank");
  await expect(items.nth(1)).toHaveAttribute("rel", "noopener noreferrer");
});

test("the dropdown exposes each Item in an open menu", async ({ page }) => {
  await visit(page, "/preview/item/dropdown", "#item-dropdown-trigger");

  const trigger = page.locator("#item-dropdown-trigger");
  const popup = page.locator("#item-dropdown-popup");

  await expect(trigger).toHaveAttribute("aria-haspopup", "menu");
  await expect(trigger).toHaveAttribute("aria-expanded", "false");
  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(popup.locator("[data-slot='dropdown-menu-group'][role='group']")).toHaveCount(1);
  await expect(popup.locator("[data-slot='dropdown-menu-group'] [role='menuitem']")).toHaveCount(3);
  await expect(popup.locator("[data-slot='item']")).toHaveCount(3);
  await expect(popup.getByText("shadcn@vercel.com")).toBeVisible();
  await expect(popup.getByText("maxleiter@vercel.com")).toBeVisible();
  await expect(popup.getByText("evilrabbit@vercel.com")).toBeVisible();
});
