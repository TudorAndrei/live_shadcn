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
