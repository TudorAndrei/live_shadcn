import { expect, test } from "@playwright/test";

import AxeBuilder from "@axe-core/playwright";
import { regressions, stableViolations } from "./accessibility.mjs";
import { enterVisualState } from "./visual-states.mjs";

import { connected, referenceReady } from "./live.mjs";

const sides = [
  { name: "official React", live: false },
  { name: "Phoenix port", live: true },
];

async function visitSide(page, testInfo, side, example = "default") {
  const path = `/preview/command/${example}`;
  await page.goto(side.live ? path : `${testInfo.project.use.parityURL}${path}`);
  if (side.live) await connected(page);
  else await referenceReady(page);

  await expect(page.locator("[data-preview='command']")).toBeAttached();
}

function item(page, name) {
  return page
    .locator("[data-slot='command-item']")
    .filter({ hasText: name })
    .first();
}

for (const side of sides) {
  test.describe(`${side.name} command`, () => {
    test.beforeEach(async ({ page }, testInfo) => {
      await visitSide(page, testInfo, side);
    });

    test("filters items and shows the empty state", async ({ page }) => {
      const input = page.getByRole("combobox");

      await input.fill("bill");
      await expect(page.locator("[data-slot='command-item']:visible")).toHaveCount(1);
      await expect(item(page, "Billing")).toBeVisible();
      await expect(item(page, "Billing")).toHaveAttribute("aria-selected", "true");
      await expect(page.locator("[data-slot='command-empty']")).toBeHidden();
      await expect(page.locator("[data-slot='command-separator']:visible")).toHaveCount(0);

      await input.fill("nothing matches this");
      await expect(page.locator("[data-slot='command-item']:visible")).toHaveCount(0);
      await expect(page.locator("[data-slot='command-empty']")).toBeVisible();
    });

    test("moves selection with arrow keys and skips disabled items", async ({ page }) => {
      const input = page.getByRole("combobox");
      const calendar = item(page, "Calendar");
      const emoji = item(page, "Search Emoji");
      const profile = item(page, "Profile");

      await expect(calendar).toHaveAttribute("aria-selected", "true");
      await input.focus();
      await page.keyboard.press("ArrowDown");
      await expect(emoji).toHaveAttribute("aria-selected", "true");
      await expect(input).toBeFocused();

      await page.keyboard.press("ArrowDown");
      await expect(profile).toHaveAttribute("aria-selected", "true");
      await expect(input).toBeFocused();
    });

    test("does not select a disabled item", async ({ page }) => {
      const calendar = item(page, "Calendar");
      const calculator = item(page, "Calculator");

      await expect(calculator).toHaveAttribute("aria-disabled", "true");
      await calculator.hover({ force: true });
      await calculator.click({ force: true });
      await expect(calculator).toHaveAttribute("aria-selected", "false");
      await expect(calendar).toHaveAttribute("aria-selected", "true");
    });

    test("selects the item under the pointer", async ({ page }) => {
      const billing = item(page, "Billing");

      await billing.hover();
      await expect(billing).toHaveAttribute("aria-selected", "true");
    });
  });

  test(`${side.name} dialog moves focus in and returns it on Escape`, async ({
    page,
  }, testInfo) => {
    await visitSide(page, testInfo, side, "basic");

    const trigger = page.getByRole("button", { name: "Open Menu" });
    await trigger.click();

    await expect(page.getByRole("dialog")).toBeVisible();
    await expect(page.getByRole("combobox")).toBeFocused();

    await page.keyboard.press("Escape");
    await expect(page.getByRole("dialog")).toBeHidden();
    await expect(trigger).toBeFocused();
  });

  test(`${side.name} shortcut dialog opens its pinned settings commands`, async ({ page }, testInfo) => {
    await visitSide(page, testInfo, side, "shortcuts");

    const trigger = page.getByRole("button", { name: "Open Menu" });
    await trigger.click();

    const dialog = page.getByRole("dialog");
    await expect(dialog).toBeVisible();
    await expect(dialog.getByRole("combobox")).toBeFocused();
    await expect(dialog.getByRole("group", { name: "Settings", exact: true })).toBeVisible();
    await expect(dialog.locator("[data-slot='command-shortcut']")).toHaveText(["⌘P", "⌘B", "⌘S"]);

    await page.keyboard.press("Escape");
    await expect(dialog).toBeHidden();
    await expect(trigger).toBeFocused();
  });

  test(`${side.name} grouped dialog keeps its pinned group boundary`, async ({ page }, testInfo) => {
    await visitSide(page, testInfo, side, "groups");

    await page.getByRole("button", { name: "Open Menu" }).click();

    const dialog = page.getByRole("dialog");
    await expect(dialog).toBeVisible();
    await expect(dialog.getByRole("group", { name: "Suggestions", exact: true })).toBeVisible();
    await expect(dialog.getByRole("group", { name: "Settings", exact: true })).toBeVisible();
    await expect(dialog.locator("[data-slot='command-separator']")).toHaveCount(1);
    await expect(dialog.locator("[data-slot='command-item']")).toHaveCount(6);
  });

  test(`${side.name} scrollable dialog scrolls through its pinned command list`, async ({ page }, testInfo) => {
    await visitSide(page, testInfo, side, "scrollable");

    await page.getByRole("button", { name: "Open Menu" }).click();

    const dialog = page.getByRole("dialog");
    const list = dialog.locator("[data-slot='command-list']");
    await expect(dialog).toBeVisible();
    await expect(list).toBeVisible();

    const geometry = await list.evaluate((element) => ({
      clientHeight: element.clientHeight,
      scrollHeight: element.scrollHeight,
    }));
    expect(geometry.scrollHeight).toBeGreaterThan(geometry.clientHeight);

    await list.evaluate((element) => element.scrollTo({ top: element.scrollHeight, behavior: "auto" }));
    await expect.poll(() => list.evaluate((element) => element.scrollTop)).toBeGreaterThan(0);
    await expect(dialog.getByText("Code Editor", { exact: true })).toBeVisible();
  });
}

test("grouped Command accessibility keeps popup ownership and distinct failing targets", async ({ page }, testInfo) => {
  const selector = "[data-preview='command']";
  async function scan() {
    const result = await new AxeBuilder({ page }).include(selector).include("[data-slot]").analyze();
    return stableViolations(page, result.violations, selector);
  }
  async function open(side) {
    await visitSide(page, testInfo, side, "groups");
    await enterVisualState(page, selector, { kind: "dialog", index: 0 });
    await expect(page.getByRole("dialog")).toBeVisible();
  }
  await open(sides[0]);
  const upstream = await scan();
  const inherited = upstream.find(({ id }) => id === "aria-required-children");
  expect(inherited?.nodes).toHaveLength(1);

  await open(sides[1]);
  const port = await scan();
  expect(port.find(({ id }) => id === "aria-required-children")?.nodes).toHaveLength(1);
  expect(regressions(port, upstream)).toEqual([]);

  // An additional invalid listbox is a current accessibility regression. It
  // must not inherit the warning on the original listbox just because the rule
  // and popup owner are the same.
  await page.locator("[data-slot='command-list']").evaluate((list) => {
    const extra = document.createElement("div");
    extra.setAttribute("data-slot", "command-extra-list");
    extra.setAttribute("role", "listbox");
    extra.setAttribute("aria-label", "Additional commands");
    extra.innerHTML = '<div role="separator"></div>';
    list.parentElement.append(extra);
  });
  const added = regressions(await scan(), upstream).filter((failure) => failure.startsWith("aria-required-children:"));
  expect(added).toHaveLength(1);
  expect(added[0]).toContain("slot:command-extra-list");

  await page.locator("[data-slot='command-extra-list']").evaluate((list) => list.setAttribute("data-slot", "command-list"));
  const repeated = await scan();
  const listTargets = repeated.find(({ id }) => id === "aria-required-children").nodes.map(({ stableTarget }) => stableTarget);
  expect(new Set(listTargets).size).toBe(2);
  expect(regressions(repeated, upstream).filter((failure) => failure.startsWith("aria-required-children:"))).toHaveLength(2);

  await page.locator("[data-slot='command-list']").last().evaluate((list) => {
    const dialog = list.closest("[role='dialog']");
    list.remove();
    const other = document.createElement("section");
    other.setAttribute("data-preview", "unrelated");
    other.innerHTML = '<div data-slot="dialog-content"><div data-slot="command"><div role="listbox" aria-label="Other commands" data-slot="command-list"><div role="separator"></div></div></div></div>';
    dialog.append(other);
  });
  await expect(page.getByRole("listbox", { name: "Other commands", exact: true })).toHaveCount(1);
  const unrelated = regressions(await scan(), upstream).filter((failure) => failure.startsWith("aria-required-children:"));
  expect(unrelated).toHaveLength(1);
  expect(unrelated[0]).toContain("preview:unrelated");
});
