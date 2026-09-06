import { expect, test } from "@playwright/test";

import { connected } from "./live.mjs";

const sides = [
  { name: "official React", live: false },
  { name: "Phoenix port", live: true },
];

async function visitSide(page, testInfo, side, example) {
  const path = `/preview/attachment/${example}`;
  const url = side.live ? path : `${testInfo.project.use.parityURL}${path}`;

  await page.goto(url);
  if (side.live) await connected(page);

  await expect(page.locator("[data-preview='attachment']")).toBeAttached();
}

for (const side of sides) {
  test.describe(`${side.name} attachment`, () => {
    test("image cards expose links but keep actions independent", async ({ page }, testInfo) => {
      await visitSide(page, testInfo, side, "image");

      const links = page.locator("[data-slot='attachment-trigger']");
      const actions = page.locator("[data-slot='attachment-action']");

      await expect(links).toHaveCount(3);
      await expect(actions).toHaveCount(3);
      await expect(links.first()).toHaveAttribute("href", /photo-1497366754035/);
      await expect(links.first()).toHaveAttribute("target", "_blank");
      await expect(links.first()).toHaveAttribute("rel", "noreferrer");
      await expect(links.first()).toHaveAccessibleName("Open workspace.png");

      const url = page.url();
      await actions.first().click();
      await expect(page).toHaveURL(url);
      await expect(page.locator("[data-preview='attachment']")).toBeAttached();
    });

    test("the full-card trigger opens and closes its dialog", async ({ page }, testInfo) => {
      await visitSide(page, testInfo, side, "trigger");

      const trigger = page.locator("[data-slot='dialog-trigger']");
      const popup = page.locator("[data-slot='dialog-content']");

      await expect(trigger).toHaveAccessibleName("Preview research-summary.pdf");
      await expect(popup).toBeHidden();

      await trigger.click();

      await expect(popup).toBeVisible();
      await expect(popup).toHaveRole("dialog");
      await expect(popup).toHaveAccessibleName("research-summary.pdf");
      await expect(popup).toContainText(
        "The attachment trigger fills the card and opens the dialog, while the actions stay independently clickable above it.",
      );

      await page.keyboard.press("Escape");
      await expect(popup).toBeHidden();
      await expect(trigger).toBeFocused();
    });

    test("card actions do not open the dialog", async ({ page }, testInfo) => {
      await visitSide(page, testInfo, side, "trigger");

      const popup = page.locator("[data-slot='dialog-content']");
      const actions = page.locator("[data-slot='attachment-action']");

      await expect(actions).toHaveCount(2);

      for (const action of await actions.all()) {
        await action.click();
        await expect(popup).toBeHidden();
      }
    });
  });
}
