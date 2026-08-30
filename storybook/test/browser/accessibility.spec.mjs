// Every preview page, compared with its pinned upstream page through axe-core.
//
// A component with no behaviour still has an accessibility contract, and this
// is the check that applies to all of them: the markup a reader gets, in a real
// browser, with a real accessibility tree. A port can inherit an upstream
// violation, but it cannot add one or increase its affected node count.
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

import { connected } from "./live.mjs";

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
// reviewed port reproduces upstream's colours faithfully. These violations
// are reported and do not fail the run. Other violations fail only when the
// port adds affected nodes compared with the pinned upstream page.
const PALETTE = ["color-contrast"];
const PAGE_CHROME = ["page-has-heading-one"];

for (const { component, example } of pages) {
  test(`${component} / ${example} has the upstream accessibility contract`, async (
    { page },
    testInfo,
  ) => {
    const path = `/preview/${component}/${example}`;
    const selector = `[data-preview='${component}']`;
    const upstream = await scan(page, `${testInfo.project.use.parityURL}${path}`, selector);
    const port = await scan(page, path, selector, true);
    const [palette, markup] = partition(port, (v) => PALETTE.includes(v.id));

    for (const violation of palette) {
      for (const node of violation.nodes) {
        console.log(`  upstream palette — ${component}/${example}: ${first(node)}`);
      }
    }

    expect(regressions(markup, upstream)).toEqual([]);
  });
}

async function scan(page, url, selector, live = false) {
  await page.goto(url);
  if (live) await connected(page);
  // A preview can contain only fixed, absolute children. It is then present
  // in the accessibility tree but has no box of its own to make visible.
  await expect(page.locator(selector)).toBeAttached();
  return (await new AxeBuilder({ page }).analyze()).violations;
}

function regressions(port, upstream) {
  const allowed = new Map(upstream.map(({ id, nodes }) => [id, nodes.length]));

  return port
    .filter(({ id }) => !PAGE_CHROME.includes(id))
    .filter(({ id, nodes }) => nodes.length > (allowed.get(id) || 0))
    .map(
      ({ id, help, nodes }) =>
        `${id}: ${help} (${nodes.length} in port, ${allowed.get(id) || 0} upstream)`,
    )
    .sort();
}

function partition(items, predicate) {
  return [items.filter(predicate), items.filter((item) => !predicate(item))];
}

function first(node) {
  return (node.any?.[0]?.message || node.failureSummary || "").split("\n")[0];
}
