// Every generated component, beside the React it was generated from.
//
// The other checks in `mix ui.verify` ask whether a component matches its spec,
// its snapshot and its own behaviour. None of them can ask the question that
// matters most: does it look like the thing upstream draws. The spec is a
// reading of upstream and the snapshot is a reading of the spec, so an error in
// the reading is invisible to both — and a component written by hand has
// neither.
//
// `parity/` renders the same upstream sources `mix ui.fetch` downloaded, at the
// commit `registry/UPSTREAM.json` pins, against the same style sheet. So the
// two pages differ only where the components differ.

import { readdirSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { expect, test } from "@playwright/test";

import { collect, compare, PROPERTIES } from "./measure.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const only = process.env.PREVIEW_COMPONENT;

// Written by `mix snapshot`. Read rather than fetched, because Playwright
// collects tests before it starts a server.
const previews = JSON.parse(readFileSync(join(here, "../../../registry/snapshot/index.json")));

// One file per example, named `<component>.<example>.tsx`. The directory is the
// record of what has been ported.
const ported = new Set(
  readdirSync(join(here, "../../../parity/src/examples"))
    .filter((name) => name.endsWith(".tsx"))
    .map((name) => name.replace(/\.tsx$/, ""))
);

const pages = Object.entries(previews)
  .filter(([component]) => !only || component === only)
  .flatMap(([component, examples]) => examples.map((example) => ({ component, example })));

// One test for the whole gap, rather than one failure per component. A page
// nobody ported is a page nothing compares, and that is worth saying once and
// completely.
test("every example has a React reference", () => {
  const missing = pages
    .map(({ component, example }) => `${component}.${example}`)
    .filter((name) => !ported.has(name));

  expect(missing, `add parity/src/examples/<name>.tsx for each`).toEqual([]);
});

for (const { component, example } of pages) {
  if (!ported.has(`${component}.${example}`)) continue;

  test(`${component} / ${example} draws what React draws`, async ({ page }, testInfo) => {
    const selector = `[data-preview='${component}']`;
    const parity = testInfo.project.use.parityURL;

    await page.goto(`${parity}/preview/${component}/${example}`);
    await expect(page.locator(selector)).toBeVisible();
    const react = await page.evaluate(collect, { selector, properties: PROPERTIES });

    await page.goto(`/preview/${component}/${example}`);
    await expect(page.locator(selector)).toBeVisible();
    const phoenix = await page.evaluate(collect, { selector, properties: PROPERTIES });

    expect(described(compare(react, phoenix))).toEqual([]);
  });
}

// A difference read as a sentence. `padding-left: React 0.5rem, Phoenix 8px` is
// the whole of what a reviewer needs, and a JSON dump of two objects is not.
function described(differences) {
  return differences.map((difference) => {
    if (difference.kind) return `${difference.slot}: ${difference.kind}`;

    return `${difference.slot}: ${difference.property} — React ${difference.react}, Phoenix ${difference.phoenix}`;
  });
}
