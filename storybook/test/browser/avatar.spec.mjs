import { expect, test } from "@playwright/test";

import { connected, referenceReady, visit } from "./live.mjs";
import { discoverInteractionProbes } from "./interaction-parity.mjs";
import { installBrowserFixtures } from "./visual-states.mjs";

test("the avatar dropdown follows the menu interaction contract", async ({ page }) => {
  await visit(page, "/preview/avatar/dropdown", "#avatar-dropdown-trigger");

  const trigger = page.locator("#avatar-dropdown-trigger");
  const popup = page.locator("#avatar-dropdown-popup");

  await expect(trigger).toHaveAttribute("aria-haspopup", "menu");
  await expect(trigger).toHaveAttribute("aria-expanded", "false");

  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(popup).toHaveRole("menu");
  await expect(trigger).toHaveAttribute("aria-expanded", "true");

  await page.keyboard.press("ArrowDown");
  await expect(page.locator("#avatar-dropdown-item-profile")).toBeFocused();

  await page.locator("body").click({ position: { x: 5, y: 5 } });
  await expect(popup).toBeHidden();
  await expect(trigger).toHaveAttribute("aria-expanded", "false");
});


test("a failed avatar keeps its fallback and menu responsive", async ({ page }) => {
  test.setTimeout(8_000);
  let releaseImage;
  const heldImage = new Promise((resolve) => {
    releaseImage = resolve;
  });
  await page.route("https://github.com/*.png", async (route) => {
    if (route.request().url().endsWith("avatar-recovered.png")) {
      await route.fulfill({
        status: 200,
        contentType: "image/svg+xml",
        body: '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32"><rect width="32" height="32" fill="blue"/></svg>',
      });
    } else {
      await heldImage;
      await route.fulfill({ status: 404, contentType: "text/plain", body: "Image not found" });
    }
  });
  try {
    await page.goto("/preview/avatar/dropdown", { waitUntil: "domcontentloaded" });
    await connected(page);
    releaseImage();
    await page.waitForLoadState("load");
    const trigger = page.locator("#avatar-dropdown-trigger");
    const fallback = trigger.locator("[data-slot='avatar-fallback']");
    const popup = page.locator("#avatar-dropdown-popup");
    await expect(fallback).toBeVisible();
    await expect(fallback).toHaveText("CN");
    await expect(trigger.locator("[data-slot='avatar-image']")).toBeHidden();
    await trigger.focus();
    await trigger.press("Enter");
    await expect(popup).toBeVisible();
    await page.keyboard.press("Escape");
    await expect(popup).toBeHidden();
    await expect(trigger).toBeFocused();

    const image = trigger.locator("[data-slot='avatar-image']");
    await image.evaluate((element) => {
      element.src = "https://github.com/avatar-recovered.png";
    });
    await expect(image).toBeVisible();
    await expect(fallback).toBeHidden();
    await image.evaluate((element) => {
      element.src = "https://github.com/avatar-failed-again.png";
    });
    await expect(fallback).toBeVisible();
    await expect(image).toBeHidden();
    await trigger.press("Enter");
    await expect(popup).toBeVisible();
  } finally {
    releaseImage();
  }
});


test("behavior probes wait for an Avatar image loaded after React commits", async ({ page }, testInfo) => {
  await installBrowserFixtures(page);
  let releaseImage;
  const heldImage = new Promise((resolve) => { releaseImage = resolve; });
  let imageRequested;
  const requested = new Promise((resolve) => { imageRequested = resolve; });
  await page.route("https://github.com/*.png", async (route) => {
    imageRequested();
    await heldImage;
    await route.fallback();
  });

  try {
    await page.goto(`${testInfo.project.use.parityURL}/preview/avatar/dropdown`, {
      waitUntil: "domcontentloaded",
    });
    await referenceReady(page);
    await requested;
    const scope = page.locator("[data-preview='avatar']");
    await expect(scope.locator("[aria-expanded]")).toHaveText("CN");

    const discovered = discoverInteractionProbes(scope);
    await page.evaluate(() => new Promise((resolve) =>
      requestAnimationFrame(() => requestAnimationFrame(resolve))));
    releaseImage();

    expect((await discovered)
      .filter((probe) => probe.kind === "disclosure")
      .map((probe) => probe.name)).toEqual([""]);
  } finally {
    releaseImage();
  }
});
