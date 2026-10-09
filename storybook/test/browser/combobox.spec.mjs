import { expect, test } from "@playwright/test";

import { connected, referenceReady, visit } from "./live.mjs";

const controller = (page, id) => page.locator(`[data-lb-combobox][data-combobox-controller='${id}']`);
const input = (page, id) =>
  page.locator(
    `[data-combobox-controller='${id}']:is([data-slot='input-group-control'], [data-slot='combobox-chip-input'])`,
  );
const content = (page, id) =>
  page.locator(`[data-slot='combobox-content'][data-combobox-controller='${id}']`);
const item = (page, id, value) => content(page, id).locator(`[data-slot='combobox-item'][data-value='${value}']`);
const chipRemove = (chips, value) =>
  chips.locator(`[data-combobox-chip='${value}'] [data-slot='combobox-chip-remove']`);

test("Combobox add-on triggers use the pinned accessible name", async ({ page }, testInfo) => {
  for (const example of ["groups", "input-group"]) {
    const selector = "[data-slot='input-group-button']";
    const path = `/preview/combobox/${example}`;

    await page.goto(`${testInfo.project.use.parityURL}${path}`);
    await referenceReady(page);
    const upstreamName = await page.locator(selector).ariaSnapshot();

    await visit(page, path);
    await expect(page.locator(selector)).toMatchAriaSnapshot(upstreamName);
  }
});

async function selectSvelteKitWithKeyboard(page, id) {
  const root = controller(page, id);
  const control = input(page, id);
  const popup = content(page, id);
  const svelte = item(page, id, "SvelteKit");
  const next = item(page, id, "Next.js");

  await expect(control).toHaveAttribute("aria-autocomplete", "list");
  await expect(control).toHaveAttribute("aria-expanded", "false");
  await control.click();
  await expect(popup).toBeVisible();
  await expect(control).toHaveAttribute("aria-expanded", "true");

  await control.fill("Svelte");
  await expect(svelte).toBeVisible();
  await expect(next).toBeHidden();
  await control.press("ArrowDown");
  await expect(svelte).toHaveAttribute("data-highlighted", "");
  await expect(control).toHaveAttribute("aria-activedescendant", await svelte.getAttribute("id"));

  await control.press("Enter");

  await expect(root).toHaveAttribute("data-combobox-value", "SvelteKit");
  await expect(control).toHaveValue("SvelteKit");
  await expect(svelte).toHaveAttribute("aria-selected", "true");
  await expect(popup).toBeHidden();
  await expect(control).toHaveAttribute("aria-expanded", "false");
  await expect(control).toBeFocused();
}

test("Combobox Default filters, keyboard-selects, closes, and retains input focus", async ({ page }) => {
  await visit(page, "/preview/combobox/default");
  await selectSvelteKitWithKeyboard(page, "combobox-default");
});

test("Combobox Basic filters, keyboard-selects, closes, and retains input focus", async ({ page }) => {
  await visit(page, "/preview/combobox/basic");
  await expect(input(page, "combobox-basic")).toHaveAttribute("placeholder", "Select a framework");
  await selectSvelteKitWithKeyboard(page, "combobox-basic");
});

for (const side of ["React", "Phoenix"]) {
  test(`Combobox Popup keeps its inside add-on exposed, selects, and restores focus on ${side}`, async ({ page }, testInfo) => {
    const path = "/preview/combobox/popup";
    await page.goto(side === "React" ? `${testInfo.project.use.parityURL}${path}` : path);
    await (side === "React" ? referenceReady(page) : connected(page));
    const trigger = page.locator("[data-preview='combobox'] [data-slot='combobox-trigger']");
    const popup = page.locator("[data-slot='combobox-content']");
    const control = popup.getByRole("combobox");
    const argentina = popup.getByRole("option", { name: "Argentina", exact: true });
    const addon = popup.locator("[data-slot='input-group-addon']");

    await expect(trigger).toHaveText("Select country");
    await trigger.click();
    await expect(popup).toBeVisible();
    await expect(control).toBeFocused();
    await expect(addon).toHaveCount(1);
    await expect(addon).not.toHaveAttribute("aria-hidden");
    await argentina.click();
    if (side === "Phoenix") await expect(trigger).toHaveAttribute("data-combobox-value", "argentina");
    await expect(trigger).toHaveText("Argentina");
    await expect(popup).toBeHidden();

    await trigger.click();
    await expect(control).toBeFocused();
    await expect(argentina).toHaveAttribute("aria-selected", "true");
    await expect(addon).not.toHaveAttribute("aria-hidden");
    await control.press("Escape");
    await expect(popup).toBeHidden();
    await expect(trigger).toBeFocused();
  });
}

test("Combobox Multiple keeps initial chips, updates selected options, and returns input focus", async ({ page }) => {
  const id = "combobox-multiple";
  await page.goto(`/preview/combobox/multiple`);

  const root = controller(page, id);
  const chips = page.locator(`#${id}-chips`);
  const control = input(page, id);
  const next = item(page, id, "Next.js");
  const remix = item(page, id, "Remix");

  await expect(root).toHaveAttribute("data-combobox-value", "Next.js");
  await expect(chips.locator("[data-combobox-chip='Next.js']")).toHaveText("Next.js");
  await expect(chipRemove(chips, "Next.js")).toBeVisible();
  await expect(next).toHaveAttribute("aria-selected", "true");

  await control.click();
  await expect(control).toBeFocused();
  await remix.click();

  await expect(next).toHaveAttribute("aria-selected", "true");
  await expect(remix).toHaveAttribute("aria-selected", "true");
  await expect(root).toHaveAttribute("data-combobox-value", "Next.js\u001fRemix");
  await expect(chips.locator("[data-combobox-chip='Remix']")).toHaveText("Remix");
  await expect(control).toBeFocused();

  await control.press("Escape");
  await expect(content(page, id)).toBeHidden();
  await expect(chipRemove(chips, "Remix")).toBeVisible();
  await chipRemove(chips, "Next.js").click();

  await expect(next).toHaveAttribute("aria-selected", "false");
  await expect(root).toHaveAttribute("data-combobox-value", "Remix");
  await expect(chips.locator("[data-combobox-chip='Next.js']")).toHaveCount(0);
  await expect(control).toBeFocused();
});

test("Combobox Clear preserves its initial value, clears it, and selects a new value", async ({ page }) => {
  const id = "combobox-clear";
  await visit(page, "/preview/combobox/clear");

  const root = controller(page, id);
  const control = input(page, id);
  const clear = control.locator("xpath=..").getByRole("button", { name: "Clear selection" });
  const next = item(page, id, "Next.js");
  const svelte = item(page, id, "SvelteKit");
  const popup = content(page, id);

  await expect(root).toHaveAttribute("data-combobox-value", "Next.js");
  await expect(control).toHaveValue("Next.js");
  await expect(next).toHaveAttribute("aria-selected", "true");
  await expect(clear).toBeVisible();
  await expect(clear).toHaveAttribute("data-visible", "");

  await clear.click();

  await expect(root).toHaveAttribute("data-combobox-value", "");
  await expect(control).toHaveValue("");
  await expect(next).toHaveAttribute("aria-selected", "false");
  await expect(clear).toBeHidden();

  await control.fill("Svelte");
  await expect(popup).toBeVisible();
  await expect(svelte).toBeVisible();
  await expect(next).toBeHidden();
  await svelte.click();

  await expect(root).toHaveAttribute("data-combobox-value", "SvelteKit");
  await expect(control).toHaveValue("SvelteKit");
  await expect(svelte).toHaveAttribute("aria-selected", "true");
  await expect(popup).toBeHidden();
  await expect(control).toBeFocused();
});

test("Combobox RTL filters, selects, removes Arabic chips, and preserves input focus", async ({ page }) => {
  const id = "combobox-rtl";
  await visit(page, "/preview/combobox/rtl");

  const root = controller(page, id);
  const chips = page.locator(`#${id}-chips`);
  const control = input(page, id);
  const popup = content(page, id);
  const list = popup.locator("[role='listbox']");
  const technology = item(page, id, "technology");
  const design = item(page, id, "design");

  await expect(popup).toHaveAttribute("dir", "rtl");
  await expect(popup).toHaveAttribute("data-lang", "ar");
  await expect(list).toHaveCSS("direction", "rtl");
  await expect(root).toHaveAttribute("data-combobox-value", "technology");
  await expect(chips.locator("[data-combobox-chip='technology']")).toHaveText("التكنولوجيا");
  await expect(technology).toHaveAttribute("aria-selected", "true");

  await control.fill("التصميم");
  await expect(popup).toBeVisible();
  await expect(design).toBeVisible();
  await expect(technology).toBeHidden();
  await design.click();

  await expect(root).toHaveAttribute("data-combobox-value", "technology\u001fdesign");
  await expect(chips.locator("[data-combobox-chip='design']")).toHaveText("التصميم");
  await expect(design).toHaveAttribute("aria-selected", "true");
  await expect(control).toBeFocused();

  await chipRemove(chips, "technology").click();

  await expect(root).toHaveAttribute("data-combobox-value", "design");
  await expect(chips.locator("[data-combobox-chip='technology']")).toHaveCount(0);
  await expect(technology).toHaveAttribute("aria-selected", "false");
  await expect(control).toBeFocused();
});

test("Combobox Multiple keeps its independent selection state", async ({ page }) => {
  await visit(page, "/preview/combobox/multiple");
  const multiple = input(page, "combobox-multiple");
  await expect(controller(page, "combobox-multiple")).toHaveAttribute("data-combobox-value", "Next.js");
  await multiple.press("ArrowDown");
  await item(page, "combobox-multiple", "Next.js").click();
  await item(page, "combobox-multiple", "Remix").click();
  await expect(item(page, "combobox-multiple", "Next.js")).toHaveAttribute("aria-selected", "false");
  await expect(item(page, "combobox-multiple", "Remix")).toHaveAttribute("aria-selected", "true");
  await expect(controller(page, "combobox-multiple")).toHaveAttribute("data-combobox-value", "Remix");
});

test("Combobox Groups filters groups, preserves separators, selects, and returns focus to the input", async ({ page }) => {
  await visit(page, "/preview/combobox/groups");
  const id = "combobox-groups";
  const control = input(page, id);
  const popup = content(page, id);
  const groups = popup.locator("[data-slot='combobox-group']");
  const separators = popup.locator("[data-slot='combobox-separator']");
  const london = item(page, id, "(GMT+0) London");

  await control.click();
  await expect(popup).toBeVisible();
  await expect(control).toHaveAttribute("aria-expanded", "true");
  await expect(groups).toHaveCount(3);
  await expect(separators).toHaveCount(2);

  await control.fill("London");

  await expect(groups.nth(0)).toBeHidden();
  await expect(groups.nth(1)).toBeVisible();
  await expect(groups.nth(2)).toBeHidden();
  await expect(separators.nth(0)).toBeHidden();
  await expect(separators.nth(1)).toBeVisible();
  await expect(london).toBeVisible();

  await london.click();

  await expect(london).toHaveAttribute("aria-selected", "true");
  await expect(controller(page, id)).toHaveAttribute("data-combobox-value", "(GMT+0) London");
  await expect(control).toHaveValue("(GMT+0) London");
  await expect(popup).toBeHidden();
  await expect(control).toHaveAttribute("aria-expanded", "false");
  await expect(control).not.toHaveAttribute("aria-controls");
  await expect(control).toBeFocused();
});

for (const side of ["React", "Phoenix"]) {
  test(`Combobox Input Group hides both outside add-ons, filters, selects, and returns focus on ${side}`, async ({ page }, testInfo) => {
    const path = "/preview/combobox/input-group";
    await page.goto(side === "React" ? `${testInfo.project.use.parityURL}${path}` : path);
    await (side === "React" ? referenceReady(page) : connected(page));
    const scope = page.locator("[data-preview='combobox']");
    const control = scope.getByRole("combobox");
    const group = scope.locator("[data-slot='input-group']");
    const addons = group.locator("[data-slot='input-group-addon']");
    const trigger = group.locator("[data-slot='input-group-button']");
    const popup = page.locator("[data-slot='combobox-content']");
    const paris = popup.getByRole("option", { name: "(GMT+1) Paris", exact: true });

    async function expectAddons(hidden) {
      await expect(addons).toHaveCount(2);
      for (const addon of await addons.all()) {
        if (hidden) await expect(addon).toHaveAttribute("aria-hidden", "true");
        else await expect(addon).not.toHaveAttribute("aria-hidden");
      }
    }

    await expect(control).toHaveAttribute("data-slot", "input-group-control");
    await expect(control).toHaveAttribute("aria-haspopup", "listbox");
    await expect(trigger).toHaveAttribute("data-slot", "input-group-button");
    await expect(trigger).toHaveAttribute("aria-haspopup", "listbox");
    await expect(trigger).toHaveAttribute("data-placeholder", "");
    await expect(trigger).toHaveAttribute("tabindex", "0");
    await expectAddons(false);
    await control.click();
    await expect(popup).toBeVisible();
    await expect(control).toHaveAttribute("aria-expanded", "true");
    await expect(trigger).toHaveAttribute("aria-expanded", "true");
    await expectAddons(true);
    await control.press("Escape");
    await expect(popup).toBeHidden();
    await expect(control).toBeFocused();
    await expectAddons(false);

    await trigger.click();
    await expect(popup).toBeVisible();
    await expect(control).toBeFocused();
    await expectAddons(true);
    await control.fill("Paris");
    await expect(paris).toBeVisible();
    await expect(popup.getByText("Americas", { exact: true })).toBeHidden();
    await expect(popup.getByText("Europe", { exact: true })).toBeVisible();
    await expect(popup.getByText("Asia/Pacific", { exact: true })).toBeHidden();
    await paris.click();
    if (side === "Phoenix") await expect(controller(page, "combobox-input-group")).toHaveAttribute("data-combobox-value", "(GMT+1) Paris");
    await expect(control).toHaveValue("(GMT+1) Paris");
    await expect(popup).toBeHidden();
    await expect(control).toBeFocused();
    await expectAddons(false);

    await control.click();
    await expect(popup).toBeVisible();
    await expect(paris).toHaveAttribute("aria-selected", "true");
    await expectAddons(true);
    await control.press("Escape");
    await expect(popup).toBeHidden();
    await expectAddons(false);
  });
}

test("Combobox Custom filters labels, preserves item content, selects, and retains input focus", async ({ page }) => {
  const id = "combobox-custom";
  await visit(page, "/preview/combobox/custom");

  const root = controller(page, id);
  const control = input(page, id);
  const popup = content(page, id);
  const argentina = item(page, id, "argentina");

  await control.fill("Argentina");
  await expect(popup).toBeVisible();
  await expect(argentina).toBeVisible();
  await expect(argentina.getByText("Argentina", { exact: true })).toBeVisible();
  await expect(argentina.getByText("South America (ar)", { exact: true })).toBeVisible();

  await argentina.click();

  await expect(root).toHaveAttribute("data-combobox-value", "argentina");
  await expect(control).toHaveValue("Argentina");
  await expect(argentina).toHaveAttribute("aria-selected", "true");
  await expect(popup).toBeHidden();
  await expect(control).toBeFocused();
});

test("Combobox Invalid retains its error state while it filters, selects, and focuses", async ({ page }) => {
  const id = "combobox-invalid";
  await visit(page, "/preview/combobox/invalid");

  const root = controller(page, id);
  const control = input(page, id);
  const popup = content(page, id);
  const svelte = item(page, id, "SvelteKit");

  await expect(control).toHaveAttribute("aria-invalid", "true");
  await control.fill("Svelte");
  await expect(popup).toBeVisible();
  await expect(svelte).toBeVisible();

  await svelte.click();

  await expect(root).toHaveAttribute("data-combobox-value", "SvelteKit");
  await expect(control).toHaveValue("SvelteKit");
  await expect(svelte).toHaveAttribute("aria-selected", "true");
  await expect(control).toHaveAttribute("aria-invalid", "true");
  await expect(popup).toBeHidden();
  await expect(control).toBeFocused();
});

test("Combobox Disabled cannot open, filter, or select", async ({ page }) => {
  const id = "combobox-disabled";
  await visit(page, "/preview/combobox/disabled");

  const root = controller(page, id);
  const control = input(page, id);
  const popup = content(page, id);
  const next = item(page, id, "Next.js");

  await expect(control).toBeDisabled();
  await expect(control).toHaveAttribute("role", "combobox");
  await expect(control).toHaveAttribute("aria-haspopup", "listbox");
  await expect(control).toHaveAttribute("aria-expanded", "false");
  await expect(control).toHaveValue("");

  await control.click({ force: true });
  await control.press("ArrowDown");
  await next.evaluate((option) => option.click());

  await expect(popup).toBeHidden();
  await expect(root).toHaveAttribute("data-combobox-value", "");
  await expect(control).toHaveValue("");
  await expect(next).toHaveAttribute("aria-selected", "false");
  await expect(control).toHaveAttribute("aria-expanded", "false");
});

test("Combobox Auto Highlight highlights, selects, closes, and retains input focus", async ({ page }) => {
  const id = "combobox-auto-highlight";
  const path = "/preview/combobox/auto-highlight";

  await visit(page, path);
  const root = controller(page, id);
  const control = input(page, id);
  const popup = content(page, id);
  const next = item(page, id, "Next.js");
  const trigger = page.locator(
    `[data-slot='input-group']:has([data-combobox-controller='${id}']) [data-slot='input-group-button']`,
  );

  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(next).not.toHaveAttribute("data-highlighted");
  await expect(control).not.toHaveAttribute("aria-activedescendant");
  await control.press("Escape");
  await expect(popup).toBeHidden();
  await expect(control).toBeFocused();

  await visit(page, path);
  const keyboardControl = input(page, id);
  const keyboardPopup = content(page, id);
  const keyboardNext = item(page, id, "Next.js");

  await keyboardControl.focus();
  await expect(keyboardPopup).toBeVisible();
  await expect(keyboardNext).not.toHaveAttribute("data-highlighted");
  await keyboardControl.press("ArrowDown");
  await expect(keyboardNext).toHaveAttribute("data-highlighted", "");
  await expect(keyboardControl).toHaveAttribute(
    "aria-activedescendant",
    await keyboardNext.getAttribute("id"),
  );
  await keyboardControl.press("Enter");

  await expect(root).toHaveAttribute("data-combobox-value", "Next.js");
  await expect(keyboardControl).toHaveValue("Next.js");
  await expect(keyboardNext).toHaveAttribute("aria-selected", "true");
  await expect(keyboardPopup).toBeHidden();
  await expect(keyboardControl).toBeFocused();
});

test("the popup trigger, keyboard close, and RTL chip input preserve public accessibility contracts", async ({ page }) => {
  await visit(page, "/preview/combobox/popup");
  const trigger = controller(page, "combobox-popup");
  await trigger.click();
  await expect(content(page, "combobox-popup")).toBeVisible();
  await expect(input(page, "combobox-popup")).toBeFocused();
  await input(page, "combobox-popup").press("Escape");
  await expect(content(page, "combobox-popup")).toBeHidden();
  await expect(trigger).toBeFocused();

  await visit(page, "/preview/combobox/rtl");
  await expect(content(page, "combobox-rtl")).toHaveAttribute("dir", "rtl");
  await expect(content(page, "combobox-rtl")).toHaveAttribute("data-lang", "ar");
  await expect(input(page, "combobox-rtl")).toHaveAttribute("placeholder", "أضف فئات");
  await expect(controller(page, "combobox-rtl")).toHaveAttribute("data-combobox-value", "technology");
  await input(page, "combobox-rtl").click();
  await expect(page.locator("[data-combobox-label-for='combobox-rtl']")).toHaveAttribute(
    "aria-hidden",
    "true",
  );
  await expect(content(page, "combobox-rtl").locator("[role='listbox']")).toHaveAttribute(
    "aria-multiselectable",
    "true",
  );
  await input(page, "combobox-rtl").press("Escape");
  await expect(page.locator("[data-combobox-label-for='combobox-rtl']")).not.toHaveAttribute(
    "aria-hidden",
  );
});
