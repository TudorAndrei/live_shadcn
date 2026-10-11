import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("a file tree folder opens and closes", async ({ page }) => {
  await visit(page, "/preview/file-tree/default", "#src-folder");

  const treeFolder = page.locator("#src-folder");
  const folder = treeFolder.locator(":scope > [role='treeitem']");
  const trigger = treeFolder.locator("[data-file-tree-toggle]").first();
  const content = folder.locator(":scope > [data-slot='collapsible-content']");

  await expect(folder).toHaveAttribute("aria-expanded", "true");
  await expect(content).toBeVisible();

  await trigger.click();
  await expect(folder).toHaveAttribute("aria-expanded", "false");
  await expect(content).toBeHidden();

  await trigger.click();
  await expect(folder).toHaveAttribute("aria-expanded", "true");
  await expect(content).toBeVisible();
});

test("file selection updates the caller without closing an expanded folder", async ({ page }) => {
  await visit(page, "/preview/file-tree/selection", "[role='tree']");
  const folder = page.getByRole("button", { name: "Toggle src", exact: true });
  await folder.click();
  const app = page.getByRole("treeitem", { name: "app.tsx", exact: true });
  const packageFile = page.getByRole("treeitem", { name: "package.json", exact: true });

  await app.click();
  await expect(app).toHaveAttribute("aria-selected", "true");
  await expect(folder).toHaveAttribute("aria-expanded", "true");
  await expect(app).toBeVisible();
  await packageFile.press("Enter");
  await expect(packageFile).toHaveAttribute("aria-selected", "true");
  await expect(app).toHaveAttribute("aria-selected", "false");
  await expect(app).toBeVisible();
});

test("a nested folder changes without closing its parent", async ({ page }) => {
  await visit(page, "/preview/file-tree/default", "#src-folder");
  const parent = page.locator("#src-folder > [role='treeitem']");
  const child = page.locator("#components-folder > [role='treeitem']");
  const toggle = page.locator("#components-folder [data-file-tree-toggle]").first();

  await toggle.click();
  await expect(parent).toHaveAttribute("aria-expanded", "true");
  await expect(child).toHaveAttribute("aria-expanded", "false");
  await expect(toggle).toHaveAttribute("aria-expanded", "false");
  await expect(page.getByText("index.ts", { exact: true })).toBeVisible();
  await expect(page.getByText("button.tsx", { exact: true })).toBeHidden();

  await child.focus();
  await child.press("ArrowRight");
  await expect(child).toHaveAttribute("aria-expanded", "true");
  await expect(page.getByText("button.tsx", { exact: true })).toBeVisible();
  await child.press("ArrowLeft");
  await expect(child).toHaveAttribute("aria-expanded", "false");
  await expect(parent).toHaveAttribute("aria-expanded", "true");
});
