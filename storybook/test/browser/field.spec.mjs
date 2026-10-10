import { expect, test } from "@playwright/test";
import { PNG } from "pngjs";

import { visualStates, enterVisualState } from "./visual-states.mjs";
import { settle, paintedBox, union, shootCurrent, compare } from "./shoot.mjs";

import { connected, referenceReady, visit } from "./live.mjs";

test("the price range label follows both slider values", async ({ page }) => {
  await visit(page, "/preview/field/slider", "#field-price-range");

  const values = page.locator("#field-price-range input[type='range']");
  const description = page.locator("[data-slot='field-description']");

  await expect(values).toHaveCount(2);
  await values.first().fill("300");

  await expect(values.first()).toHaveValue("300");
  await expect(values.last()).toHaveValue("800");
  await expect(description).toContainText("Set your budget range ($300 - 800).");
});

test("the select field chooses a department and updates its form value", async ({ page }) => {
  await visit(page, "/preview/field/select", "#department-trigger");

  const trigger = page.locator("#department-trigger");
  const input = page.locator("#department-input");

  await trigger.click();
  await page.locator("#department-option-engineering").click();

  await expect(trigger).toContainText("Engineering");
  await expect(input).toHaveValue("engineering");
});

for (const side of ["React", "Phoenix"]) {
  test(`choice-card labels keep focus on the visible radio on ${side}`, async ({ page }, testInfo) => {
    const path = "/preview/field/choice-card";
    await page.goto(side === "React" ? `${testInfo.project.use.parityURL}${path}` : path);
    await (side === "React" ? referenceReady(page) : connected(page));
    const scope = page.locator("[data-preview='field']");
    const label = scope.locator("label").filter({ hasText: "Virtual Machine" });
    const radio = label.getByRole("radio");
    await label.click();
    await expect(radio).toHaveAttribute("aria-checked", "true");
    await expect(radio).toBeFocused();
    await expect(scope.locator("input[type='radio']:checked")).toHaveValue("vm");
    await page.mouse.click(0, 0);
    await label.click();
    await expect(radio).toHaveAttribute("aria-checked", "true");
    await expect(radio).toBeFocused();
    await expect(scope.locator("input[type='radio']:checked")).toHaveValue("vm");
  });
}


test("required form Submit paint keeps the native validation prompt on both pages", async ({ page, context }, testInfo) => {
  const reference = await context.newPage();
  const selector = "[data-preview='field']";
  const boxes = [];
  const states = [];
  const inspectInput = (node) => ({
    value: node.value,
    required: node.required,
    valueMissing: node.validity.valueMissing,
    valid: node.validity.valid,
    userInvalid: node.matches(":user-invalid"),
    message: node.validationMessage,
    shadow: getComputedStyle(node).boxShadow,
    outline: getComputedStyle(node).outline,
    focusVisible: node.matches(":focus-visible"),
  });

  try {
    for (const [target, side] of [[reference, "React"], [page, "Phoenix"]]) {
      await target.setViewportSize({ width: 1280, height: 2048 });
      const path = "/preview/field/responsive";
      const url = side === "React" ? `${testInfo.project.use.parityURL}${path}` : path;
      await target.goto(url);
      await (side === "React" ? referenceReady(target) : connected(target));
      const submit = (await visualStates(target, selector)).find(({ name }) => name === "action:Submit");
      expect(submit).toBeDefined();
      await target.goto(url);
      await (side === "React" ? referenceReady(target) : connected(target));
      await enterVisualState(target, selector, submit);
      await settle(target, selector);
      const input = target.locator(`${selector} input`);
      await expect(input).toBeFocused();
      const state = await input.evaluate(inspectInput);
      expect(state.value).toBe("");
      expect(state.required).toBe(true);
      expect(state.valueMissing).toBe(true);
      expect(state.valid).toBe(false);
      expect(state.userInvalid).toBe(true);
      expect(state.message).not.toBe("");
      states.push(state);
      boxes.push(await paintedBox(target, selector));
    }

    const clip = union(...boxes);
    const start = performance.now();
    const phoenix = await shootCurrent(page, selector, clip);
    const phoenixMs = performance.now() - start;
    const reactStart = performance.now();
    const react = await shootCurrent(reference, selector, clip);
    const reactMs = performance.now() - reactStart;
    const comparison = compare(react.image, phoenix.image);
    await testInfo.attach("native-validation-react.png", {
      body: PNG.sync.write(react.image), contentType: "image/png",
    });
    await testInfo.attach("native-validation-phoenix.png", {
      body: PNG.sync.write(phoenix.image), contentType: "image/png",
    });
    if (comparison.diff) {
      await testInfo.attach("native-validation-diff.png", {
        body: PNG.sync.write(comparison.diff), contentType: "image/png",
      });
    }
    await testInfo.attach("native-validation-capture.json", {
      body: JSON.stringify({ differing: comparison.differing, reactMs, phoenixMs, states, clip }),
      contentType: "application/json",
    });
    expect(comparison.differing).toBe(0);

    for (const [target, paint, state, side] of [
      [reference, react, states[0], "react"], [page, phoenix, states[1], "phoenix"],
    ]) {
      const input = target.locator(`${selector} input`);
      await expect(input).toBeFocused();
      expect(await input.evaluate(inspectInput)).toEqual(state);
      await input.press("Tab");
      await input.focus();
      const dismissed = await shootCurrent(target, selector, clip);
      await testInfo.attach(`native-validation-${side}-dismissed.png`, {
        body: PNG.sync.write(dismissed.image), contentType: "image/png",
      });
      expect(compare(paint.image, dismissed.image).differing).toBeGreaterThan(0);
      expect(await input.evaluate(inspectInput)).toEqual(state);
      await expect(input).toBeFocused();
    }
  } finally {
    await reference.close();
  }
});
