import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const otpInput = (page) => page.locator("[data-preview='input-otp'] input[data-input-otp]");
const slots = (page) => page.locator("[data-preview='input-otp'] [data-slot='input-otp-slot']");

async function paste(page, input, value) {
  await input.evaluate((element, pasted) => {
    element.focus();
    element.value = pasted;
    element.dispatchEvent(
      new InputEvent("input", { bubbles: true, data: pasted, inputType: "insertFromPaste" }),
    );
  }, value);
}

test("the default OTP mirrors typing, selection, and backspace into its slots", async ({ page }) => {
  await visit(page, "/preview/input-otp/default");
  const input = otpInput(page);

  await expect(input).toHaveValue("123456");
  await expect(slots(page)).toHaveCount(6);
  await expect(slots(page).nth(0)).toHaveText("1");
  await expect(slots(page).nth(5)).toHaveText("6");

  await input.focus();
  await expect(slots(page).nth(5)).toHaveAttribute("data-active", "true");
  await input.press("End");
  await input.press("Backspace");

  await expect(input).toHaveValue("12345");
  await expect(slots(page).nth(5)).toHaveText("");
});

test("patterns reject invalid input and maximum length limits a pasted code", async ({ page }) => {
  await visit(page, "/preview/input-otp/pattern", "#digits-only");
  const digits = otpInput(page);

  await digits.type("12a3");
  await expect(digits).toHaveValue("123");
  await expect(slots(page).nth(2)).toHaveText("3");

  await visit(page, "/preview/input-otp/four-digits");
  await paste(page, otpInput(page), "123456");
  await expect(otpInput(page)).toHaveValue("1234");
  await expect(slots(page)).toHaveCount(4);

  await visit(page, "/preview/input-otp/alphanumeric");
  await paste(page, otpInput(page), "A1b2");
  await expect(otpInput(page)).toHaveValue("A1b2");
  await expect(slots(page).nth(3)).toHaveText("2");
});

test("the disabled OTP and native events keep their browser contracts", async ({ page }) => {
  await visit(page, "/preview/input-otp/disabled", "#disabled");
  await expect(page.locator("#disabled")).toBeDisabled();
  await expect(page.locator("#disabled")).toHaveValue("123456");

  await visit(page, "/preview/input-otp/controlled");
  const input = otpInput(page);
  await input.evaluate((element) => {
    element.dataset.inputEvents = "0";
    element.dataset.changeEvents = "0";
    element.addEventListener("input", () => {
      element.dataset.inputEvents = String(Number(element.dataset.inputEvents) + 1);
    });
    element.addEventListener("change", () => {
      element.dataset.changeEvents = String(Number(element.dataset.changeEvents) + 1);
    });
  });

  await input.type("12");
  await input.blur();

  await expect(input).toHaveAttribute("data-input-events", "2");
  await expect(input).toHaveAttribute("data-change-events", "1");
  await expect(page.locator("#input-otp-controlled-value")).toHaveText("You entered: 12");
});

test("a patch-like slot update is reconciled from the native input", async ({ page }) => {
  await visit(page, "/preview/input-otp/default");

  await page.locator("[data-slot='input-otp-slot']").nth(0).evaluate((slot) => {
    slot.firstChild.data = "stale";
    slot.setAttribute("data-active", "true");
  });

  await expect(slots(page).nth(0)).toHaveText("1");
  await expect(slots(page).nth(0)).toHaveAttribute("data-active", "false");
});

test("controlled, invalid, form, and RTL examples keep their official states", async ({ page }) => {
  await visit(page, "/preview/input-otp/controlled");
  await expect(page.locator("#input-otp-controlled-value")).toHaveText(
    "Enter your one-time password.",
  );

  await visit(page, "/preview/input-otp/invalid");
  await expect(slots(page)).toHaveCount(6);
  await expect(page.locator("[data-slot='input-otp-slot'][aria-invalid='true']")).toHaveCount(6);

  await visit(page, "/preview/input-otp/form", "#otp-verification");
  await expect(page.getByLabel("Verification code")).toHaveAttribute("required", "");
  await expect(page.getByRole("button", { name: "Resend Code" })).toBeVisible();
  await expect(page.getByRole("link", { name: "I no longer have access to this email address." })).toBeVisible();

  await visit(page, "/preview/input-otp/rtl", "#input-otp-rtl");
  await expect(page.getByLabel("رمز التحقق")).toHaveAttribute("dir", "rtl");
  await expect(otpInput(page)).toHaveValue("123456");
});
