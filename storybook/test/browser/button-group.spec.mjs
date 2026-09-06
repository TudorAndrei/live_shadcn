import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("the default group opens its menu and changes the submenu radio choice", async ({ page }) => {
  await visit(page, "/preview/button-group/default", "#button-more-options-trigger");

  await page.locator("#button-more-options-trigger").click();
  await expect(page.locator("#button-more-options-popup")).toBeVisible();

  await page.locator("#button-more-options-label-trigger").click();
  const personal = page.locator("#button-more-options-label-item-personal");
  const work = page.locator("#button-more-options-label-item-work");

  await expect(personal).toHaveAttribute("aria-checked", "true");
  await work.click();
  await expect(work).toHaveAttribute("aria-checked", "true");
  await expect(personal).toHaveAttribute("aria-checked", "false");
});

test("the dropdown trigger is a direct button group child and dismisses", async ({ page }) => {
  await visit(page, "/preview/button-group/dropdown", "#button-group-follow-trigger");

  const trigger = page.locator("#button-group-follow-trigger");
  const popup = page.locator("#button-group-follow-popup");
  await expect(
    page.locator("[data-preview='button-group'] [data-slot='button-group'] > #button-group-follow-trigger"),
  ).toHaveCount(1);

  await trigger.click();
  await expect(popup).toBeVisible();
  await page.locator("#button-group-follow-item-copy").click();
  await expect(popup).toBeHidden();
});

test("the nested example opens its Voice Mode tooltip", async ({ page }) => {
  await visit(page, "/preview/button-group/nested", "input[placeholder='Send a message...']");

  await page.locator("#button-group-nested-voice-trigger").hover();
  await expect(page.locator("#button-group-nested-voice-popup")).toBeVisible();
});

test("the input group Voice Mode button opens by hover and focus without changing input state", async ({ page }) => {
  await visit(page, "/preview/button-group/input-group", "#button-group-voice-trigger");

  const voice = page.locator("#button-group-voice-trigger");
  const message = page.locator("#button-group-message");
  const popup = page.locator("#button-group-voice-popup");

  await voice.hover();
  await expect(popup).toBeVisible();
  await expect(voice).toHaveAttribute("aria-pressed", "false");
  await expect(message).toBeEnabled();
  await expect(message).toHaveAttribute("placeholder", "Send a message...");

  await page.mouse.move(0, 0);
  await message.focus();
  await expect(popup).toBeHidden();
  await voice.focus();
  await expect(popup).toBeVisible();
  await expect(voice).toHaveAttribute("aria-pressed", "false");
  await expect(message).toBeEnabled();
  await expect(message).toHaveAttribute("placeholder", "Send a message...");

  await voice.click();
  await expect(voice).toHaveAttribute("aria-pressed", "true");
  await expect(voice).toHaveAttribute("data-active", "true");
  await expect(message).toBeDisabled();
  await expect(message).toHaveAttribute("placeholder", "Record and send audio...");

  await voice.click();
  await expect(voice).toHaveAttribute("aria-pressed", "false");
  await expect(voice).toHaveAttribute("data-active", "false");
  await expect(message).toBeEnabled();
  await expect(message).toHaveAttribute("placeholder", "Send a message...");
});

test("the select changes currency and keeps its trigger anchor", async ({ page }) => {
  await visit(page, "/preview/button-group/select", "#button-group-currency-trigger");

  const trigger = page.locator("#button-group-currency-trigger");
  await trigger.click();
  await expect(page.locator("#button-group-currency-positioner")).toHaveAttribute(
    "data-lb-anchor",
    "button-group-currency-trigger",
  );

  await page.getByRole("option", { name: "€ Euro" }).click();
  await expect(trigger).toContainText("€");
  await expect(page.locator("#button-group-currency-input")).toHaveValue("€");
  await expect(page.locator("#button-group-currency-popup")).toBeHidden();
});

test("the popover trigger is a direct button group child and dismisses", async ({ page }) => {
  await visit(page, "/preview/button-group/popover", "#button-group-copilot-trigger");

  const trigger = page.locator("#button-group-copilot-trigger");
  const popup = page.locator("#button-group-copilot-popup");
  await expect(
    page.locator("[data-preview='button-group'] > [data-slot='button-group'] > #button-group-copilot-trigger"),
  ).toHaveCount(1);

  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(page.locator("#button-group-task")).toBeFocused();
  await page.keyboard.press("Escape");
  await expect(popup).toBeHidden();
});

test("the RTL menu keeps its Arabic direction through its submenu", async ({ page }) => {
  await visit(page, "/preview/button-group/rtl", "#button-group-rtl-more-options-trigger");

  await page.locator("#button-group-rtl-more-options-trigger").click();
  await expect(page.locator("#button-group-rtl-more-options-popup")).toHaveAttribute("dir", "rtl");
  await expect(page.locator("#button-group-rtl-more-options-popup")).toHaveAttribute(
    "data-lang",
    "ar",
  );

  await page.locator("#button-group-rtl-more-options-label-trigger").click();
  await expect(page.locator("#button-group-rtl-more-options-label-popup")).toHaveAttribute("dir", "rtl");
});
