import { expect, test } from "@playwright/test";

import { referenceReady, visit } from "./live.mjs";

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

test("caller display classes keep responsive avatars and the Item grid", async ({ page }, testInfo) => {
  for (const side of ["React", "Phoenix"]) {
    const open = async (example) => {
      const path = `/preview/item/${example}`;
      if (side === "React") {
        await page.goto(`${testInfo.project.use.parityURL}${path}`);
        await referenceReady(page);
      } else await visit(page, path);
    };
    await page.setViewportSize({ width: 600, height: 720 });
    await open("avatar");
    const responsive = page.locator("[data-slot='avatar'].hidden");
    await expect(responsive).toHaveCount(2);
    for (const avatar of await responsive.all()) await expect(avatar).toBeHidden();
    await page.setViewportSize({ width: 900, height: 720 });
    for (const avatar of await responsive.all()) {
      await expect(avatar).toBeVisible();
      await expect(avatar).toHaveCSS("display", "flex");
    }
    await open("header");
    const group = page.locator("[data-slot='item-group']");
    await expect(group).toHaveCSS("display", "grid");
    const boxes = await group.locator("[data-slot='item']").evaluateAll(items =>
      items.map(item => item.getBoundingClientRect().toJSON()));
    expect(boxes).toHaveLength(3);
    expect(boxes.map(box => box.y)).toEqual([boxes[0].y, boxes[0].y, boxes[0].y]);
    expect(boxes[0].right).toBeLessThan(boxes[1].x);
    expect(boxes[1].right).toBeLessThan(boxes[2].x);
  }
});
