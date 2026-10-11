// Behaviour parity for the select.
//
// A select is a menu that remembers. Choosing an option has to do four things
// at once — mark it, unmark the rest, change what the trigger reads, and change
// what a form would submit — and only the last of those is visible to the
// server. A browser is the only place all four can be checked together.

import { expect, test } from "@playwright/test";

import { connected, referenceReady, visit } from "./live.mjs";
import { discoverInteractionProbes, enterInteractionProbe } from "./interaction-parity.mjs";

const select = (page) => ({
  trigger: page.locator("#select-fruit-trigger"),
  popup: page.locator("#select-fruit-popup"),
  list: page.locator("#select-fruit-list"),
  input: page.locator("#select-fruit-input"),
  option: (value) => page.locator(`#select-fruit-option-${value}`),
});

test.describe("a select", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/select/default", "#select-fruit-trigger");
  });

  test("says it opens a list, and starts closed and empty", async ({
    page,
  }) => {
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

  test("opens its options", async ({ page }) => {
    const { trigger, popup, list, option } = select(page);

    await trigger.click();

    await expect(popup).toBeVisible();
    await expect(popup).toHaveAttribute("role", "presentation");
    await expect(trigger).toHaveAttribute("aria-controls", "select-fruit-list");
    await expect(list).toHaveRole("listbox");
    await expect(option("apple")).toHaveRole("option");
    await expect(option("apple")).toHaveAttribute("aria-selected", "false");
  });

  test("choosing an option marks it and unmarks the others", async ({
    page,
  }) => {
    const { trigger, option } = select(page);

    await trigger.click();
    await option("banana").click();

    await trigger.click();
    await expect(option("banana")).toHaveAttribute("data-selected", "");
    await expect(option("banana")).toHaveAttribute("aria-selected", "true");
    await expect(option("apple")).not.toHaveAttribute("data-selected", "");
  });

  test("choosing an option is what a form would submit", async ({ page }) => {
    const { trigger, option, input } = select(page);

    await trigger.click();
    await option("blueberry").click();

    await expect(input).toHaveValue("blueberry");
  });

  test("choosing an option closes the list", async ({ page }) => {
    const { trigger, popup, option } = select(page);

    await trigger.click();
    await expect(popup).toBeVisible();

    await option("apple").click();
    await expect(popup).toBeHidden();
  });

  test("pointer and arrow keys move focus without choosing an option", async ({
    page,
  }, testInfo) => {
    for (const side of ["React", "Phoenix"]) {
      const path = "/preview/select/default";
      await page.goto(side === "React" ? `${testInfo.project.use.parityURL}${path}` : path);
      await (side === "React" ? referenceReady(page) : connected(page));

      const trigger = page.getByRole("combobox");
      const popup = page.locator("[data-slot='select-content']:visible");
      const options = page.getByRole("option");
      const apple = page.getByRole("option", { name: "Apple", exact: true });
      const banana = page.getByRole("option", { name: "Banana", exact: true });
      const initialText = await trigger.textContent();

      await trigger.click();
      await expect(popup).toBeVisible();
      await expect(options.first()).toBeFocused();
      const selectedOptions = popup.locator("[role='option'][aria-selected='true']");
      const selected = await selectedOptions.allTextContents();

      await page.keyboard.press("ArrowDown");
      await expect(apple).toBeFocused();
      await expect(apple).toHaveAttribute("data-highlighted", "");

      // Move onto the label, then across the same option's outer box.
      await banana.getByText("Banana", { exact: true }).hover();
      await expect(banana).toBeFocused();
      await expect(banana).toHaveAttribute("data-highlighted", "");
      await expect(apple).not.toHaveAttribute("data-highlighted");
      const box = await banana.boundingBox();
      await page.mouse.move(box.x + 4, box.y + box.height / 2);
      await expect(banana).toBeFocused();
      await expect(banana).toHaveAttribute("data-highlighted", "");

      await page.mouse.move(0, 0);
      await expect(popup.locator("[data-highlighted]")).toHaveCount(0);
      await expect(popup).toBeFocused();
      await page.keyboard.press("ArrowDown");
      await expect(options.first()).toBeFocused();
      await expect(options.first()).toHaveAttribute("data-highlighted", "");

      // A keyboard move keeps its highlight when the idle pointer leaves.
      await apple.hover();
      await expect(apple).toBeFocused();
      await page.keyboard.press("ArrowDown");
      await expect(banana).toBeFocused();
      await page.mouse.move(0, 0);
      await expect(banana).toBeFocused();
      await expect(banana).toHaveAttribute("data-highlighted", "");
      expect(await selectedOptions.allTextContents()).toEqual(selected);
      if (side === "Phoenix") await expect(select(page).input).toHaveValue("");

      await page.keyboard.press("Escape");
      await expect(trigger).toHaveText(initialText);
      await expect(trigger).toHaveAttribute("aria-expanded", "false");
    }
  });

  test("Escape closes it without choosing", async ({ page }) => {
    const { trigger, popup, input } = select(page);

    await trigger.click();
    // Open before Escape. `click()` resolves when the click is dispatched, not
    // when the listbox has opened, and a key pressed into that gap is lost.
    await expect(popup).toBeVisible();

    await page.keyboard.press("Escape");

    await expect(popup).toBeHidden();
    await expect(trigger).not.toHaveAttribute("aria-controls");
    await expect(input).toHaveValue("");
  });

  test("it is positioned against its trigger and reports where it landed", async ({
    page,
  }) => {
    const { trigger, popup } = select(page);

    await trigger.click();
    await expect(popup).toBeVisible();

    await expect(page.locator("#select-fruit-positioner")).toHaveAttribute(
      "data-side",
      /top|right|bottom|left/,
    );
  });
});

test("the align-item example changes its positioned content contract", async ({
  page,
}) => {
  await visit(
    page,
    "/preview/select/align-item",
    "#select-align-fruit-trigger",
  );

  const toggle = page.locator("#align-item-control");
  const trigger = page.locator("#select-align-fruit-trigger");
  const popup = page.locator("#select-align-fruit-popup");
  const positioner = page.locator("#select-align-fruit-positioner");

  await expect(toggle).toHaveAttribute("aria-checked", "true");
  await trigger.click();
  await expect(popup).toHaveAttribute("data-align-trigger", "true");
  await expect(positioner).toHaveAttribute("data-lb-align-item", "");
  await page.keyboard.press("Escape");

  await toggle.click();
  await expect(toggle).toHaveAttribute("aria-checked", "false");
  await trigger.click();
  await expect(popup).toHaveAttribute("data-align-trigger", "false");
  await expect(positioner).not.toHaveAttribute("data-lb-align-item");
});

test("the RTL select chooses an Arabic option and keeps its direction", async ({
  page,
}) => {
  await visit(page, "/preview/select/rtl", "#select-rtl-trigger");

  const trigger = page.locator("#select-rtl-trigger");
  const popup = page.locator("#select-rtl-popup");
  const input = page.locator("#select-rtl-input");

  await expect(trigger).toHaveAttribute("dir", "rtl");
  await trigger.click();
  await expect(popup).toHaveAttribute("dir", "rtl");
  await expect(popup).toHaveAttribute("data-lang", "ar");
  await page.locator("#select-rtl-option-banana").click();

  await expect(trigger).toContainText("موز");
  await expect(input).toHaveValue("banana");
  await expect(popup).toBeHidden();
});

test("the groups select exposes labels and a separator, then chooses the second group", async ({
  page,
}) => {
  await visit(page, "/preview/select/groups", "#select-groups-trigger");

  const trigger = page.locator("#select-groups-trigger");
  const popup = page.locator("#select-groups-popup");
  const list = page.locator("#select-groups-list");
  const vegetables = page.locator("#select-groups-group-1-label");
  const carrot = page.locator("#select-groups-option-carrot");

  await trigger.click();

  await expect(list.getByRole("group")).toHaveCount(2);
  await expect(page.locator("#select-groups-group-0-label")).toHaveText(
    "Fruits",
  );
  await expect(vegetables).toHaveText("Vegetables");
  await expect(list.getByRole("group").nth(1)).toHaveAttribute(
    "aria-labelledby",
    "select-groups-group-1-label",
  );
  await expect(popup.locator("[data-slot='select-separator']")).toHaveAttribute(
    "role",
    "presentation",
  );

  await carrot.click();

  await expect(trigger).toContainText("Carrot");
  await expect(page.locator("#select-groups-input")).toHaveValue("carrot");
  await expect(carrot).toHaveAttribute("aria-selected", "true");
  await expect(popup).toBeHidden();
});

test("the scrollable select chooses an item from a later group", async ({
  page,
}) => {
  await visit(page, "/preview/select/scrollable", "#select-timezone-trigger");

  const trigger = page.locator("#select-timezone-trigger");
  const popup = page.locator("#select-timezone-popup");
  const china = page.locator("#select-timezone-option-cst_china");

  await trigger.click();

  await expect(popup.getByText("North America", { exact: true })).toBeVisible();
  await expect(popup.getByText("Asia", { exact: true })).toBeVisible();
  await china.click();

  await expect(trigger).toContainText("China Standard Time");
  await expect(page.locator("#select-timezone-input")).toHaveValue("cst_china");
  await expect(china).toHaveAttribute("aria-selected", "true");
  await expect(popup).toBeHidden();
});

test("the disabled select cannot open or change", async ({ page }) => {
  await visit(page, "/preview/select/disabled", "#select-disabled-trigger");

  const trigger = page.locator("#select-disabled-trigger");
  const popup = page.locator("#select-disabled-popup");
  const input = page.locator("#select-disabled-input");

  await expect(trigger).toBeDisabled();
  await expect(trigger).toHaveAccessibleName("Select a fruit");
  await expect(trigger).toHaveAttribute("aria-expanded", "false");
  await expect(input).toBeDisabled();
  await expect(input).toHaveValue("");

  await trigger.focus();
  await page.keyboard.press("Enter");

  await expect(popup).toBeHidden();
  await expect(trigger).toHaveAttribute("aria-expanded", "false");
  await expect(input).toHaveValue("");
});

test("the invalid select exposes its error and keeps invalid state after selection", async ({
  page,
}) => {
  await visit(page, "/preview/select/invalid", "#select-invalid-trigger");

  const trigger = page.locator("#select-invalid-trigger");
  const popup = page.locator("#select-invalid-popup");
  const field = page.locator("[data-slot='field']");
  const label = field.locator("[data-slot='field-label']");
  const error = field.locator("[data-slot='field-error']");
  const banana = page.locator("#select-invalid-option-banana");

  await expect(trigger).toHaveAttribute("aria-invalid", "true");
  await expect(label).toHaveText("Fruit");
  await expect(error).toHaveRole("alert");
  await expect(error).toHaveText("Please select a fruit.");
  await expect(trigger).toContainText("Select a fruit");

  await trigger.click();
  await banana.click();

  await expect(trigger).toContainText("Banana");
  await expect(page.locator("#select-invalid-input")).toHaveValue("banana");
  await expect(trigger).toHaveAttribute("aria-invalid", "true");
  await expect(popup).toBeHidden();
});

for (const [example, label] of [["default", "Month"], ["rtl", "الشهر"]]) {
  for (const side of ["React", "Phoenix"]) {
    test(`Field ${example} Select observations retain the label on ${side}`, async ({ page }, testInfo) => {
      const path = `/preview/field/${example}`;
      await page.goto(side === "React" ? `${testInfo.project.use.parityURL}${path}` : path);
      await (side === "React" ? referenceReady(page) : connected(page));
      const scope = page.locator("[data-preview='field']");
      const trigger = scope.getByRole("combobox", { name: label, exact: true });
      await expect(trigger).toHaveAccessibleName(label);
      await expect(trigger).toContainText("MM");

      const probes = await discoverInteractionProbes(scope);
      const probe = probes.find(({ kind, name }) => kind === "disclosure" && name === label);
      expect(probe).toBeDefined();
      const state = await enterInteractionProbe(page, scope, probe);

      expect(state.opened.target.name).toBe(label);
      expect(state.closed.target.name).toBe(label);
      await expect(trigger).toHaveAccessibleName(label);
      await expect(trigger).toHaveAttribute("aria-expanded", "false");
    });
  }
}
