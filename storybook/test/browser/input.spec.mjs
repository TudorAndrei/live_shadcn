import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("the default input keeps the official password field", async ({ page }) => {
  await visit(page, "/preview/input/default", "#input-demo-api-key");

  const input = page.locator("#input-demo-api-key");
  await expect(input).toHaveAttribute("type", "password");
  await expect(input).toHaveAttribute("placeholder", "sk-...");
  await expect(page.getByText("Your API key is encrypted and stored securely.")).toBeVisible();
});

test("the disabled and invalid examples expose their native states", async ({ page }) => {
  await visit(page, "/preview/input/disabled", "#input-demo-disabled");
  const disabledField = page.locator("[data-preview='input'] [data-slot='field'][data-disabled]");
  const disabledInput = page.locator("#input-demo-disabled");
  await expect(disabledField).toHaveAttribute("data-disabled", "true");
  await expect(disabledInput).toBeDisabled();

  await visit(page, "/preview/input/invalid", "#input-invalid");
  const invalidField = page.locator("[data-preview='input'] [data-slot='field'][data-invalid]");
  const invalidInput = page.locator("#input-invalid");
  await expect(invalidField).toHaveAttribute("data-invalid", "true");
  await expect(invalidInput).toHaveAttribute("aria-invalid", "true");
});

test("the required and file examples keep their native input contracts", async ({ page }) => {
  await visit(page, "/preview/input/required", "#input-required");
  await expect(page.locator("#input-required")).toHaveAttribute("required", "");

  await visit(page, "/preview/input/file", "#picture");
  await expect(page.locator("#picture")).toHaveAttribute("type", "file");
});

test("the input group keeps its protocol text and icon", async ({ page }) => {
  await visit(page, "/preview/input/input-group", "#input-group-url");

  await expect(page.locator("#input-group-url")).toHaveAttribute("placeholder", "example.com");
  await expect(page.getByText("https://", { exact: true })).toBeVisible();
  await expect(page.locator("[data-preview='input'] [data-slot='input-group-addon']")).toHaveCount(2);
});

test("the form starts with the official country", async ({ page }) => {
  await visit(page, "/preview/input/form", "#form-country");

  await expect(page.locator("#form-country")).toHaveText("United States");
  await expect(page.locator("#form-name")).toHaveAttribute("required", "");
});

test("the form keeps entered text and the selected country value", async ({ page }) => {
  await visit(page, "/preview/input/form", "#form-name");

  await page.locator("#form-name").fill("Evil Rabbit");
  await page.locator("#form-email").fill("rabbit@example.com");
  await page.locator("#form-phone").fill("+1 555 123 4567");
  await page.locator("#form-address").fill("123 Main St");
  await page.locator("#form-country").click();
  await page.locator("#form-country-option-ca").click();

  await expect(page.locator("#form-name")).toHaveValue("Evil Rabbit");
  await expect(page.locator("#form-email")).toHaveValue("rabbit@example.com");
  await expect(page.locator("#form-phone")).toHaveValue("+1 555 123 4567");
  await expect(page.locator("#form-address")).toHaveValue("123 Main St");
  await expect(page.locator("#form-country")).toContainText("Canada");
  await expect(page.locator("#form-country-input")).toHaveValue("ca");
});

test("the Arabic example keeps direction on the field and input", async ({ page }) => {
  await visit(page, "/preview/input/rtl", "#input-rtl-api-key");

  await expect(page.locator("#input-rtl-api-key")).toHaveAttribute("dir", "rtl");
  await expect(page.locator("#input-rtl-api-key").locator("xpath=ancestor::*[@dir='rtl']")).toBeVisible();
  await expect(page.getByText("مفتاح API", { exact: true })).toBeVisible();
  await expect(page.getByText("مفتاح API الخاص بك مشفر ومخزن بأمان.", { exact: true })).toBeVisible();
});
