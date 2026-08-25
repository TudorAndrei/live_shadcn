// Behaviour parity for the select.
//
// A select is a menu that remembers. Choosing an option has to do four things
// at once — mark it, unmark the rest, change what the trigger reads, and change
// what a form would submit — and only the last of those is visible to the
// server. A browser is the only place all four can be checked together.

import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const select = (page) => ({
  trigger: page.locator("#style-select-trigger"),
  popup: page.locator("#style-select-popup"),
  input: page.locator("#style-select-input"),
  option: (value) => page.locator(`#style-select-option-${value}`),
});

test.describe("a select", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/select/default", "#style-select-trigger");
  });

  test("says it opens a list, and starts closed and empty", async ({ page }) => {
    const { trigger, popup, input } = select(page);

    await expect(trigger).toHaveRole("combobox");
    await expect(trigger).toHaveAttribute("aria-haspopup", "listbox");
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
    await expect(popup).toBeHidden();
    await expect(input).toHaveValue("");
  });

  test("reads its placeholder before anything is chosen", async ({ page }) => {
    await expect(select(page).trigger).toContainText("Select");
  });

  test("opens a listbox of options", async ({ page }) => {
    const { trigger, popup, option } = select(page);

    await trigger.click();

    await expect(popup).toBeVisible();
    await expect(popup).toHaveRole("listbox");
    await expect(option("vega")).toHaveRole("option");
    await expect(option("vega")).toHaveAttribute("aria-selected", "false");
  });

  test("choosing an option marks it and unmarks the others", async ({ page }) => {
    const { trigger, option } = select(page);

    await trigger.click();
    await option("nova").click();

    await trigger.click();
    await expect(option("nova")).toHaveAttribute("data-selected", "");
    await expect(option("nova")).toHaveAttribute("aria-selected", "true");
    await expect(option("vega")).not.toHaveAttribute("data-selected", "");
  });

  test("choosing an option is what a form would submit", async ({ page }) => {
    const { trigger, option, input } = select(page);

    await trigger.click();
    await option("maia").click();

    await expect(input).toHaveValue("maia");
  });

  test("choosing an option closes the list", async ({ page }) => {
    const { trigger, popup, option } = select(page);

    await trigger.click();
    await expect(popup).toBeVisible();

    await option("vega").click();
    await expect(popup).toBeHidden();
  });

  test("the arrow keys walk the options without choosing one", async ({ page }) => {
    const { trigger, popup, input } = select(page);

    await trigger.click();
    await expect(popup).toBeVisible();

    await page.keyboard.press("ArrowDown");
    await expect(select(page).option("vega")).toBeFocused();
    await expect(select(page).option("vega")).toHaveAttribute("data-highlighted", "");

    // Walked to, not chosen: nothing has been submitted yet.
    await expect(input).toHaveValue("");
  });

  test("Escape closes it without choosing", async ({ page }) => {
    const { trigger, popup, input } = select(page);

    await trigger.click();
    // Open before Escape. `click()` resolves when the click is dispatched, not
    // when the listbox has opened, and a key pressed into that gap is lost.
    await expect(popup).toBeVisible();

    await page.keyboard.press("Escape");

    await expect(popup).toBeHidden();
    await expect(input).toHaveValue("");
  });

  test("it is positioned against its trigger and reports where it landed", async ({ page }) => {
    const { trigger, popup } = select(page);

    await trigger.click();
    await expect(popup).toBeVisible();

    await expect(page.locator("#style-select-positioner")).toHaveAttribute(
      "data-side",
      /top|right|bottom|left/,
    );
  });
});
