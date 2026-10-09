// Browser behavior for the shadcn Collapsible examples.

import { expect, test } from "@playwright/test";

import { connected, referenceReady, visit } from "./live.mjs";
import { discoverInteractionProbes, enterInteractionProbe } from "./interaction-parity.mjs";

const parts = (page, id) => ({
  root: page.locator(`#${id}`),
  trigger: page.locator(`#${id}-trigger`),
  panel: page.locator(`#${id}-panel`),
});

test.describe("a collapsible", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/collapsible/default", "#collapsible-default-trigger");
  });

  test("starts closed and reports its state", async ({ page }) => {
    const { trigger, panel } = parts(page, "collapsible-default");

    await expect(trigger).toHaveAttribute("aria-expanded", "false");
    await expect(panel).toBeHidden();
  });

  test("opens and closes without a server round trip", async ({ page }) => {
    const { root, trigger, panel } = parts(page, "collapsible-default");

    await trigger.click();
    await expect(trigger).toHaveAttribute("aria-expanded", "true");
    await expect(trigger).toHaveAttribute("data-panel-open", "");
    await expect(root).toHaveAttribute("data-open", "");
    await expect(panel).toBeVisible();

    await trigger.click();
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
    await expect(panel).toBeHidden();
  });

  test("measures the open panel", async ({ page }) => {
    const { trigger, panel } = parts(page, "collapsible-default");

    await trigger.click();
    await expect(panel).toBeVisible();

    const height = await panel.evaluate((element) =>
      getComputedStyle(element).getPropertyValue("--collapsible-panel-height"),
    );

    expect(parseFloat(height)).toBeGreaterThan(0);
  });

  for (const key of ["Enter", " "]) {
    test(`${key === " " ? "Space" : key} opens the focused trigger`, async ({ page }) => {
      const { trigger, panel } = parts(page, "collapsible-default");

      await trigger.focus();
      await page.keyboard.press(key);

      await expect(panel).toBeVisible();
    });
  }
});

test("the Settings trigger changes its icon with the panel", async ({ page }) => {
  await visit(page, "/preview/collapsible/settings", "#collapsible-settings-trigger");
  const { trigger, panel } = parts(page, "collapsible-settings");
  const maximize = trigger.locator(".lucide-maximize");
  const minimize = trigger.locator(".lucide-minimize");

  await expect(maximize).toBeVisible();
  await expect(minimize).toBeHidden();

  await trigger.click();
  await expect(panel).toBeVisible();
  await expect(maximize).toBeHidden();
  await expect(minimize).toBeVisible();
});

test("nested file-tree panels keep independent state", async ({ page }) => {
  await visit(page, "/preview/collapsible/file-tree", "#collapsible-tree-root-components-trigger");
  const components = parts(page, "collapsible-tree-root-components");
  const ui = parts(page, "collapsible-tree-root-components-ui");

  await components.trigger.click();
  await expect(components.panel).toBeVisible();

  await ui.trigger.click();
  await expect(ui.panel).toBeVisible();
  await expect(components.panel).toBeVisible();

  await components.trigger.click();
  await expect(components.panel).toBeHidden();
});

for (const side of ["React", "Phoenix"]) {
  test(`settings observation contains the visible inputs through opening and closing on ${side}`, async ({ page }, testInfo) => {
    const path = "/preview/collapsible/settings";
    await page.goto(side === "React" ? `${testInfo.project.use.parityURL}${path}` : path);
    await (side === "React" ? referenceReady(page) : connected(page));
    const scope = page.locator("[data-preview='collapsible']");
    const probe = (await discoverInteractionProbes(scope)).find((candidate) => candidate.kind === "disclosure");
    const state = await enterInteractionProbe(page, scope, probe);
    const inputs = (controls) => controls.map((control) => ({ tag: control.tag, values: control.values }));
    expect(inputs(state.opened.controls)).toEqual(Array(4).fill({ tag: "input", values: ["0"] }));
    expect(inputs(state.closed.controls)).toEqual(Array(2).fill({ tag: "input", values: ["0"] }));
  });
}
