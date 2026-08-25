// Behaviour parity for the checkable form controls.
//
// The expectations come from the Base UI checkbox and switch pages: what
// `data-checked` and `data-unchecked` mean, that the control is a `<span>` with
// a hidden `<input>` beside it, and that a disabled control ignores everything.
//
// The last two tests are the ones that matter most. A control that looks right
// and submits nothing is worse than one that looks wrong, and only a browser
// can tell you which you have.

import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const control = (page, id) => ({
  control: page.locator(`#${id}`),
  input: page.locator(`#${id}-input`),
});

test.describe("a checkbox", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/checkbox/default", "#subscribe");
  });

  test("says what it is to a screen reader", async ({ page }) => {
    const { control: box } = control(page, "subscribe");

    await expect(box).toHaveRole("checkbox");
    await expect(box).toHaveAttribute("aria-checked", "true");
  });

  test("an unchecked control marks itself unchecked, not merely not checked", async ({ page }) => {
    const { control: box } = control(page, "beta");

    await expect(box).toHaveAttribute("data-unchecked", "");
    await expect(box).not.toHaveAttribute("data-checked", "");
  });

  test("a click flips both the control and the input a form submits", async ({ page }) => {
    const { control: box, input } = control(page, "beta");

    await expect(input).not.toBeChecked();

    await box.click();

    await expect(box).toHaveAttribute("aria-checked", "true");
    await expect(box).toHaveAttribute("data-checked", "");
    await expect(input).toBeChecked();
  });

  test("a second click flips it back", async ({ page }) => {
    const { control: box, input } = control(page, "subscribe");

    await box.click();

    await expect(box).toHaveAttribute("aria-checked", "false");
    await expect(box).toHaveAttribute("data-unchecked", "");
    await expect(input).not.toBeChecked();
  });

  test("interacting with it marks it touched, which the server never sees", async ({ page }) => {
    const { control: box } = control(page, "beta");

    await expect(box).not.toHaveAttribute("data-touched", "");

    await box.click();

    await expect(box).toHaveAttribute("data-touched", "");
    await expect(box).toHaveAttribute("data-dirty", "");
  });

  test("a disabled control does not flip", async ({ page }) => {
    const { control: box, input } = control(page, "locked");

    await expect(box).toHaveAttribute("data-disabled", "");
    await box.click({ force: true });

    await expect(box).toHaveAttribute("aria-checked", "true");
    await expect(input).toBeChecked();
  });

  test("the input is out of the accessibility tree, because the control is in it", async ({
    page,
  }) => {
    const { input } = control(page, "subscribe");

    await expect(input).toHaveAttribute("aria-hidden", "true");
    await expect(input).toHaveAttribute("tabindex", "-1");
  });

  test("the control is reachable by keyboard and flips on Space", async ({ page }) => {
    await page.locator("#beta").focus();
    await expect(page.locator("#beta")).toBeFocused();

    await page.keyboard.press(" ");

    await expect(page.locator("#beta")).toHaveAttribute("aria-checked", "true");
  });
});

test.describe("a switch", () => {
  test("carries the same contract, drawn differently", async ({ page }) => {
    await visit(page, "/preview/switch/default");
    const { control: box, input } = control(page, "watch");

    await expect(box).toHaveAttribute("data-checked", "");
    await expect(input).toBeChecked();

    await box.click();

    await expect(box).toHaveAttribute("data-unchecked", "");
    await expect(input).not.toBeChecked();
  });
});

test.describe("a radio group", () => {
  test("choosing one unchooses the others, which is what makes it a radio", async ({ page }) => {
    await visit(page, "/preview/radio-group/default");

    const vega = control(page, "style-vega");
    const nova = control(page, "style-nova");

    await expect(vega.control).toHaveAttribute("aria-checked", "true");
    await expect(vega.input).toBeChecked();

    await nova.control.click();

    await expect(nova.control).toHaveAttribute("aria-checked", "true");
    await expect(nova.input).toBeChecked();

    await expect(vega.control).toHaveAttribute("aria-checked", "false");
    await expect(vega.control).toHaveAttribute("data-unchecked", "");
    await expect(vega.input).not.toBeChecked();
  });

  test("each radio says it is a radio, not a checkbox", async ({ page }) => {
    await visit(page, "/preview/radio-group/default");

    await expect(page.locator("#style-vega")).toHaveRole("radio");
  });
});

test.describe("a toggle", () => {
  test("says pressed rather than checked, because it is a button", async ({ page }) => {
    await visit(page, "/preview/toggle/default");
    const bold = page.locator("#bold");

    await expect(bold).toHaveAttribute("aria-pressed", "false");

    await bold.click();

    await expect(bold).toHaveAttribute("aria-pressed", "true");
    await expect(bold).toHaveAttribute("data-pressed", "");
  });
});
