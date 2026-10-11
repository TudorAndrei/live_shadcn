import { expect, test } from "@playwright/test";
import { PNG } from "pngjs";

import { compare, paintedBox, settle, shootCurrent, union } from "./shoot.mjs";

import { referenceReady, visit } from "./live.mjs";

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


test("native keyboard selection paints only the visible OTP slots", async ({ page, context }, testInfo) => {
  const reference = await context.newPage();
  const selector = "[data-preview='input-otp']";
  try {
    await reference.goto(`${testInfo.project.use.parityURL}/preview/input-otp/default`);
    await referenceReady(reference);
    await visit(page, "/preview/input-otp/default");
    for (const current of [reference, page]) {
      const input = otpInput(current);
      await current.bringToFront();
      await input.focus();
      await expect.poll(() => input.evaluate(element => [element.selectionStart, element.selectionEnd])).toEqual([5, 6]);
      await input.pressSequentially("9");
      await expect(input).toHaveValue("123459");
      await expect(slots(current).nth(5)).toHaveText("9");
      await expect(input).toBeFocused();
      await expect.poll(() => input.evaluate(element => [element.selectionStart, element.selectionEnd])).toEqual([5, 6]);
      await settle(current, selector);
    }
    const clip = union(await paintedBox(reference, selector), await paintedBox(page, selector));
    await page.bringToFront();
    const phoenix = await shootCurrent(page, selector, clip);
    await reference.bringToFront();
    const react = await shootCurrent(reference, selector, clip);
    const result = compare(react.image, phoenix.image);
    if (result.differing) {
      await testInfo.attach("otp-selection-react.png", {body:PNG.sync.write(react.image),contentType:"image/png"});
      await testInfo.attach("otp-selection-phoenix.png", {body:PNG.sync.write(phoenix.image),contentType:"image/png"});
      await testInfo.attach("otp-selection-diff.png", {body:PNG.sync.write(result.diff),contentType:"image/png"});
    }
    expect(result.differing, "native selection must not cover the visible slots").toBe(0);
  } finally {
    await reference.close();
  }
});

for (const [name, options, extraWidth] of [
  ["native pointer detection", {}, 40],
  ["password manager marker", { noPointerBadge: true, marker: true }, 40],
  ["no detected badge", { noPointerBadge: true }, 0],
  ["insufficient space", { clipped: true }, 0],
  ["none strategy", { strategy: "none" }, 0],
]) {
  test(`password manager space follows ${name}`, async ({ page }) => {
    await visit(page, "/preview/input-otp/default");
    const input = otpInput(page);
    const root = page.locator("[data-input-otp-container]");
    await root.evaluate((element, options) => {
      if (options.noPointerBadge) {
        element.style.pointerEvents = "auto";
        for (const child of element.querySelectorAll("*")) child.style.pointerEvents = "none";
      }
      if (options.marker) {
        const badge = document.createElement("span");
        badge.setAttribute("data-lastpass-icon-root", "");
        badge.textContent = "Password manager";
        document.body.appendChild(badge);
      }
      if (options.clipped) element.style.overflow = "hidden";
      if (options.strategy) element.dataset.inputOtpPasswordManagerStrategy = options.strategy;
    }, options);
    await page.clock.install();
    await input.focus();
    await page.clock.fastForward(6100);
    await expect.poll(async () => {
      const inputBox = await input.boundingBox();
      const rootBox = await root.boundingBox();
      return inputBox.width - rootBox.width;
    }).toBe(extraWidth);
    await expect(input).toHaveCSS("clip-path", extraWidth ? "inset(0px 40px 0px 0px)" : "none");
    await input.pressSequentially("9");
    await expect(input).toHaveValue("123459");
    await expect(slots(page).nth(5)).toHaveText("9");
    await expect.poll(() => input.evaluate(element => [element.selectionStart, element.selectionEnd]))
      .toEqual([5, 6]);
  });
}

test("password manager reservation follows space changes and input lifecycle", async ({ page }) => {
  await visit(page, "/preview/input-otp/default");
  const input = otpInput(page);
  const root = page.locator("[data-input-otp-container]");
  await input.focus();
  await expect(input).toHaveCSS("clip-path", "inset(0px 40px 0px 0px)");
  await root.evaluate(element => { element.style.overflow = "hidden"; });
  await expect(input).toHaveCSS("clip-path", "none");
  await root.evaluate(element => { element.style.overflow = "visible"; });
  await expect(input).toHaveCSS("clip-path", "inset(0px 40px 0px 0px)");

  await root.evaluate(element => { element.dataset.inputOtpPasswordManagerStrategy = "none"; });
  await expect(input).toHaveCSS("clip-path", "none");
  await root.evaluate(element => { element.dataset.inputOtpPasswordManagerStrategy = "increase-width"; });
  await expect(input).toHaveCSS("clip-path", "inset(0px 40px 0px 0px)");

  const removed = await root.evaluateHandle(element => { element.remove(); return element; });
  await expect.poll(() => removed.evaluate(element => element.querySelector("input").style.width)).toBe("100%");
  await removed.evaluate(element => { element.querySelector("input").style.width = "73px"; });
  await page.waitForTimeout(1100);
  expect(await removed.evaluate(element => element.querySelector("input").style.width)).toBe("73px");
  await removed.evaluate(element => {
    element.querySelector("input").style.width = "100%";
    document.querySelector("[data-preview='input-otp']").appendChild(element);
  });
  await input.focus();
  await expect(input).toHaveCSS("clip-path", "inset(0px 40px 0px 0px)");
  await expect(input).toHaveValue("123456");
  const removedInput = await input.evaluateHandle(element => { element.remove(); return element; });
  await expect.poll(() => removedInput.evaluate(element => element.style.width)).toBe("100%");
  await removedInput.evaluate(element => { element.style.width = "73px"; });
  await page.waitForTimeout(1100);
  expect(await removedInput.evaluate(element => element.style.width)).toBe("73px");
  await removedInput.evaluate(element => {
    element.style.width = "100%";
    document.querySelector("[data-input-otp-container] > div:last-child").appendChild(element);
  });
  await input.focus();
  await expect(input).toHaveCSS("clip-path", "inset(0px 40px 0px 0px)");
});
