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

import { connected, referenceReady, visit } from "./live.mjs";

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

for (const side of ["React", "Phoenix"]) {
  test(`checkbox table keeps partial, full, and cleared selection aligned on ${side}`, async ({ page }, testInfo) => {
    const path = "/preview/checkbox/table";
    await page.goto(side === "React" ? `${testInfo.project.use.parityURL}${path}` : path);
    await (side === "React" ? referenceReady(page) : connected(page));
    const scope = page.locator("[data-preview='checkbox']");
    const header = scope.locator("thead [role='checkbox']");
    const rows = scope.locator("tbody [role='checkbox']");
    const nativeValue = side === "React" ? "on" : "true";

    async function expectSelection(selected) {
      const all = selected.every(Boolean);
      await expect(header).toHaveAttribute("aria-checked", String(all));
      for (let index = 0; index < selected.length; index += 1) {
        await expect(rows.nth(index)).toHaveAttribute("aria-checked", String(selected[index]));
      }
      await expect(scope.locator("tbody tr[data-state='selected']")).toHaveCount(selected.filter(Boolean).length);
      const submitted = await scope.locator("input[type='checkbox']").evaluateAll((inputs) =>
        inputs.filter((input) => input.checked && !input.disabled).map((input) => [input.name, input.value]),
      );
      const expected = all ? [["select-all-checkbox", nativeValue]] : [];
      selected.forEach((checked, index) => {
        if (checked) expected.push([`row-${index + 1}-checkbox`, nativeValue]);
      });
      expect(submitted).toEqual(expected);
    }

    await expectSelection([true, false, false, false]);
    await rows.nth(1).click();
    await expectSelection([true, true, false, false]);
    await header.click();
    await expectSelection([true, true, true, true]);
    await rows.nth(0).click();
    await expectSelection([false, true, true, true]);
    await header.click();
    await expectSelection([true, true, true, true]);
    await header.click();
    await expectSelection([false, false, false, false]);
  });
}

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
