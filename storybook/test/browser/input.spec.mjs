import { expect, test } from "@playwright/test";

import { connected, referenceReady, visit } from "./live.mjs";

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

for (const side of ["React", "Phoenix"]) {
  test(`the form keeps its Country name and chosen value on ${side}`, async ({ page }, testInfo) => {
    const path = "/preview/input/form";
    await page.goto(side === "React" ? `${testInfo.project.use.parityURL}${path}` : path);
    await (side === "React" ? referenceReady(page) : connected(page));

    const country = page.locator("#form-country");
    const countryInput = page.locator("[data-preview='input'] input[aria-hidden='true']");
    await expect(country).toHaveAccessibleName("Country");
    await expect(countryInput).toHaveValue("us");
    await page.locator("#form-name").fill("Evil Rabbit");
    await page.locator("#form-email").fill("rabbit@example.com");
    await page.locator("#form-phone").fill("+1 555 123 4567");
    await page.locator("#form-address").fill("123 Main St");
    await country.click();
    await page.getByRole("option", { name: "Canada", exact: true }).click();

    await expect(page.locator("#form-name")).toHaveValue("Evil Rabbit");
    await expect(page.locator("#form-email")).toHaveValue("rabbit@example.com");
    await expect(page.locator("#form-phone")).toHaveValue("+1 555 123 4567");
    await expect(page.locator("#form-address")).toHaveValue("123 Main St");
    await expect(country).toContainText("Canada");
    await expect(country).toHaveAccessibleName("Country");
    await expect(countryInput).toHaveValue("ca");
  });
}

test("the Arabic example keeps direction on the field and input", async ({ page }) => {
  await visit(page, "/preview/input/rtl", "#input-rtl-api-key");

  await expect(page.locator("#input-rtl-api-key")).toHaveAttribute("dir", "rtl");
  await expect(page.locator("#input-rtl-api-key").locator("xpath=ancestor::*[@dir='rtl']")).toBeVisible();
  await expect(page.getByText("مفتاح API", { exact: true })).toBeVisible();
  await expect(page.getByText("مفتاح API الخاص بك مشفر ومخزن بأمان.", { exact: true })).toBeVisible();
});
