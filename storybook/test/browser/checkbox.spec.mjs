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

const checkboxControl = (page, id) => ({
  control: page.locator(`#${id}-control`),
  input: page.locator(`#${id}`),
});

test.describe("a checkbox", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/checkbox/default", "#terms-checkbox-control");
  });

  test("says what it is to a screen reader", async ({ page }) => {
    const { control: box } = checkboxControl(page, "terms-checkbox-2");

    await expect(box).toHaveRole("checkbox");
    await expect(box).toHaveAttribute("aria-checked", "true");
  });

  test("an unchecked control marks itself unchecked, not merely not checked", async ({ page }) => {
    const { control: box } = checkboxControl(page, "terms-checkbox");

    await expect(box).toHaveAttribute("data-unchecked", "");
    await expect(box).not.toHaveAttribute("data-checked", "");
  });

  test("a click flips both the control and the input a form submits", async ({ page }) => {
    const { control: box, input } = checkboxControl(page, "terms-checkbox");

    await expect(input).not.toBeChecked();

    await box.click();

    await expect(box).toHaveAttribute("aria-checked", "true");
    await expect(box).toHaveAttribute("data-checked", "");
    await expect(input).toBeChecked();
  });

  test("a second click flips it back", async ({ page }) => {
    const { control: box, input } = checkboxControl(page, "terms-checkbox-2");

    await box.click();

    await expect(box).toHaveAttribute("aria-checked", "false");
    await expect(box).toHaveAttribute("data-unchecked", "");
    await expect(input).not.toBeChecked();
  });

  test("interacting with it marks it touched, which the server never sees", async ({ page }) => {
    const { control: box } = checkboxControl(page, "terms-checkbox");

    await expect(box).not.toHaveAttribute("data-touched", "");

    await box.click();

    await expect(box).toHaveAttribute("data-touched", "");
    await expect(box).toHaveAttribute("data-dirty", "");
  });

  test("a disabled control does not flip", async ({ page }) => {
    const { control: box, input } = checkboxControl(page, "toggle-checkbox");

    await expect(box).toHaveAttribute("data-disabled", "");
    await box.click({ force: true });

    await expect(box).toHaveAttribute("aria-checked", "false");
    await expect(input).not.toBeChecked();
  });

  test("the input is out of the accessibility tree, because the control is in it", async ({
    page,
  }) => {
    const { input } = checkboxControl(page, "terms-checkbox");

    await expect(input).toHaveAttribute("aria-hidden", "true");
    await expect(input).toHaveAttribute("tabindex", "-1");
  });

  test("the control is reachable by keyboard and flips on Space", async ({ page }) => {
    await page.locator("#terms-checkbox-control").focus();
    await expect(page.locator("#terms-checkbox-control")).toBeFocused();

    await page.keyboard.press(" ");

    await expect(page.locator("#terms-checkbox-control")).toHaveAttribute("aria-checked", "true");
  });
});

test.describe("a switch", () => {
  test("carries the same contract, drawn differently", async ({ page }) => {
    await visit(page, "/preview/switch/default");
    const box = page.locator("#airplane-mode-control");
    const input = page.locator("#airplane-mode");

    await expect(box).toHaveAttribute("data-unchecked", "");
    await expect(input).not.toBeChecked();

    await box.click();

    await expect(box).toHaveAttribute("data-checked", "");
    await expect(input).toBeChecked();
  });
});

test.describe("checkbox table selection", () => {
  test("select all changes every row", async ({ page }) => {
    await visit(page, "/preview/checkbox/table", "#checkbox-table");
    const { control: selectAll } = checkboxControl(page, "select-all-checkbox");

    await selectAll.click();

    await expect(page.locator("tbody [role='checkbox'][aria-checked='true']")).toHaveCount(4);
    await expect(page.locator("tbody tr[data-state='selected']")).toHaveCount(4);
  });

  test("one row changes its selected state", async ({ page }) => {
    await visit(page, "/preview/checkbox/table", "#checkbox-table");
    const { control: second } = checkboxControl(page, "row-2-checkbox");

    await second.click();
    await expect(second).toHaveAttribute("aria-checked", "true");
    await expect(second.locator("xpath=ancestor::tr")).toHaveAttribute("data-state", "selected");
  });
});

test.describe("a radio group", () => {
  test("choosing one unchooses the others, which is what makes it a radio", async ({ page }) => {
    await visit(page, "/preview/radio-group/default");

    const comfortable = checkboxControl(page, "r2");
    const compact = checkboxControl(page, "r3");

    await expect(comfortable.control).toHaveAttribute("aria-checked", "true");
    await expect(comfortable.input).toBeChecked();

    await compact.control.click();

    await expect(compact.control).toHaveAttribute("aria-checked", "true");
    await expect(compact.input).toBeChecked();

    await expect(comfortable.control).toHaveAttribute("aria-checked", "false");
    await expect(comfortable.control).toHaveAttribute("data-unchecked", "");
    await expect(comfortable.input).not.toBeChecked();
  });

  test("each radio says it is a radio, not a checkbox", async ({ page }) => {
    await visit(page, "/preview/radio-group/default");

    await expect(page.locator("#r2-control")).toHaveRole("radio");
  });
});

test.describe("a toggle", () => {
  test("says pressed rather than checked, because it is a button", async ({ page }) => {
    await visit(page, "/preview/toggle/default");
    const bookmark = page.locator("#bookmark");

    await expect(bookmark).toHaveAttribute("aria-pressed", "false");

    await bookmark.click();

    await expect(bookmark).toHaveAttribute("aria-pressed", "true");
    await expect(bookmark).toHaveAttribute("data-pressed", "");
  });
});
