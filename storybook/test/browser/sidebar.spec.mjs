import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("opening the footer menu does not scroll the page", async ({ page }) => {
  await visit(page, "/preview/sidebar/default", "#sidebar-user-trigger");
  await page.evaluate(() => window.scrollTo(0, 0));

  await page.locator("#sidebar-user-trigger").click();

  await expect(page.locator("#sidebar-user-popup")).toBeVisible();
  expect(await page.evaluate(() => window.scrollY)).toBe(0);
});

test("the default sidebar selects teams, opens navigation, and collapses", async ({ page }) => {
  await visit(page, "/preview/sidebar/default", "#sidebar-team-trigger");

  const teamTrigger = page.locator("#sidebar-team-trigger");
  const teamPopup = page.locator("#sidebar-team-popup");

  await teamTrigger.click();
  await expect(teamPopup).toBeVisible();
  await page.locator("#sidebar-team-item-acme-corp").click();

  await expect(teamTrigger).toContainText("Acme Corp.");
  await expect(teamTrigger).toContainText("Startup");
  await expect(teamPopup).toBeHidden();

  const modelsTrigger = page.locator("#sidebar-nav-models-trigger");
  const modelsPanel = page.locator("#sidebar-nav-models-panel");

  await expect(modelsTrigger).toHaveAttribute("aria-expanded", "false");
  await expect(modelsPanel).toBeHidden();
  await modelsTrigger.click();
  await expect(modelsTrigger).toHaveAttribute("aria-expanded", "true");
  await expect(modelsPanel).toBeVisible();

  const sidebar = page.locator("#nav");
  const sidebarTrigger = page.locator("[data-slot='sidebar-trigger']");
  const sidebarRail = page.locator("[data-slot='sidebar-rail']");

  await expect(sidebar).toHaveAttribute("data-state", "expanded");
  await sidebarTrigger.click();
  await expect(sidebar).toHaveAttribute("data-state", "collapsed");
  await expect(sidebar).toHaveAttribute("data-collapsible", "icon");
  await expect(sidebarTrigger).toHaveAttribute("aria-expanded", "false");

  await sidebarRail.click();
  await expect(sidebar).toHaveAttribute("data-state", "expanded");
  await expect(sidebar).toHaveAttribute("data-collapsible", "");
  await expect(sidebarTrigger).toHaveAttribute("aria-expanded", "true");
});
