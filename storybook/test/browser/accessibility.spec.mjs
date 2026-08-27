// Every preview page, checked with axe-core.
//
// A component with no behaviour still has an accessibility contract, and this
// is the check that applies to all of them: the markup a reader gets, in a real
// browser, with a real accessibility tree.
//
// Components that also have behaviour get a suite of their own beside this one.
// This file never replaces that; it is the floor, not the ceiling.
//
// `mix ui.verify` runs it filtered to one component through PREVIEW_COMPONENT.

import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { expect, test } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

const only = process.env.PREVIEW_COMPONENT;

// Written by `mix snapshot`, and read here rather than fetched: Playwright
// collects tests before it starts the server.
const index = join(dirname(fileURLToPath(import.meta.url)), "../../../registry/snapshot/index.json");
const previews = JSON.parse(readFileSync(index, "utf8"));

const pages = Object.entries(previews)
  .filter(([component]) => !only || component === only)
  .flatMap(([component, examples]) => examples.map((example) => ({ component, example })));

if (pages.length === 0) {
  test("there is an example to check", () => {
    throw new Error(
      only
        ? `no preview page for ${only}. Add an example to StorybookWeb.Examples.`
        : "no preview pages at all. Run `mix snapshot` in storybook/ first.",
    );
  });
}

// Contrast is a property of the palette, and the palette is shadcn's. A
// reviewed port reproduces upstream's colours faithfully, which is the
// whole point, so a component cannot be held to a ratio its own style sheet
// does not meet. These are reported and do not fail the run; everything else
// is markup, which is ours, and does.
const PALETTE = ["color-contrast"];

for (const { component, example } of pages) {
  test(`${component} / ${example} is clean under axe-core`, async ({ page }) => {
    await page.goto(`/preview/${component}/${example}`);
    // A preview can contain only fixed, absolute children. It is then present
    // in the accessibility tree but has no box of its own to make visible.
    await expect(page.locator(`[data-preview='${component}']`)).toBeAttached();

    const { violations } = await new AxeBuilder({ page }).analyze();
    const [palette, markup] = partition(violations, (v) => PALETTE.includes(v.id));

    for (const violation of palette) {
      for (const node of violation.nodes) {
        console.log(`  upstream palette — ${component}/${example}: ${first(node)}`);
      }
    }

    expect(markup.map((violation) => `${violation.id}: ${violation.help}`)).toEqual([]);
  });
}

function partition(items, predicate) {
  return [items.filter(predicate), items.filter((item) => !predicate(item))];
}

function first(node) {
  return (node.any?.[0]?.message || node.failureSummary || "").split("\n")[0];
}
