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

import { collect, compare, describeRow, outline, PROPERTIES } from "./measure.mjs";

// Enough of a tree to find a difference in, and not so much that the report
// becomes the thing nobody reads.
const OUTLINE_ROWS = 400;

const here = dirname(fileURLToPath(import.meta.url));
const only = process.env.PREVIEW_COMPONENT;

// Written by `mix snapshot`. Read rather than fetched, because Playwright
// collects tests before it starts a server.
const previews = JSON.parse(readFileSync(join(here, "../../../registry/snapshot/index.json")));
const inventory = JSON.parse(readFileSync(join(here, "../../../registry/INVENTORY.json")));
const shadcnComponents = new Set(
  inventory.components
    .filter(({ source }) => source === "shadcn")
    .map(({ name }) => name)
);

function sourceComponent(component) {
  return component === "shadcn-message" ? "message" : component;
}

// One file per example, named `<component>.<example>.tsx`. The directory is the
// record of what has been ported.
const ported = new Set(
  readdirSync(join(here, "../../../parity/src/examples"))
    .filter((name) => name.endsWith(".tsx"))
    .map((name) => name.replace(/\.tsx$/, ""))
);

const pages = Object.entries(previews)
  .filter(([component]) => shadcnComponents.has(sourceComponent(component)))
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
    const react = await measured(page, selector);
    const reactTree = await page.evaluate(outline, { selector, limit: OUTLINE_ROWS });

    await page.goto(`/preview/${component}/${example}`);
    const phoenix = await measured(page, selector);
    const phoenixTree = await page.evaluate(outline, { selector, limit: OUTLINE_ROWS });

    const differences = described(compare(react, phoenix));
    let where;

    // Only on a failure. A passing example has nothing to explain, and 66 of
    // these attached to every green run is a way of hiding the six that are not.
    if (differences.length > 0) {
      where = divergence(reactTree, phoenixTree);

      await testInfo.attach("outline-react.txt", {
        body: reactTree.map(describeRow).join("\n"),
        contentType: "text/plain",
      });
      await testInfo.attach("outline-phoenix.txt", {
        body: phoenixTree.map(describeRow).join("\n"),
        contentType: "text/plain",
      });
    }

    expect(differences, where).toEqual([]);
  });
}

// The rows where the two trees stop agreeing.
//
// `width — React 157.2, Phoenix 165.7` says a component is 8.5px too wide and
// stops there. This says which element is, and the text and class string it
// carries — which is usually the whole diagnosis. The full trees are attached;
// this is the part that belongs in the failure itself.
//
// Aligning by row number does not work: one side having two `sr-only` headings
// the other has not shifts every row after them, and then everything differs.
// So the trees are aligned on position-and-tag first, and only the rows that
// pair up are compared.
function divergence(react, phoenix, rows = 6) {
  const shown = [];

  for (const [left, right] of align(react, phoenix)) {
    if (shown.length >= rows) break;

    if (!left || !right) {
      shown.push(`  React   ${describeRow(left)}\n  Phoenix ${describeRow(right)}`);
      continue;
    }

    const why = [
      left.tag !== right.tag && `tag <${left.tag}> → <${right.tag}>`,
      Math.abs(left.width - right.width) > 0.5 && `width ${left.width} → ${right.width}`,
      Math.abs(left.height - right.height) > 0.5 && `height ${left.height} → ${right.height}`,
      left.text !== right.text && `text ${JSON.stringify(left.text)} → ${JSON.stringify(right.text)}`,
      left.class !== right.class && "class",
    ].filter(Boolean);

    if (why.length === 0) continue;

    shown.push(`  React   ${describeRow(left)}\n  Phoenix ${describeRow(right)}\n  ← ${why.join(", ")}`);
  }

  if (shown.length === 0) return "the element trees agree; the difference is in a computed style";

  return `where the two trees differ (full trees attached):\n${shown.join("\n\n")}`;
}

// Longest common subsequence over "where in the tree, and which part" — so an
// element only one side draws is reported as exactly that, rather than as every
// row after it being wrong.
//
// A `data-slot` identifies a part across both renderers, so where there is one
// it outranks the tag: React's calendar root is a `<div>` and the generated one
// is a `<section>`, and those are the same part drawn differently rather than
// two elements neither side shares.
function align(react, phoenix) {
  const key = (row) => `${row.depth}/${row.slot || row.tag}`;
  const lengths = Array.from({ length: react.length + 1 }, () => new Array(phoenix.length + 1).fill(0));

  for (let a = react.length - 1; a >= 0; a--) {
    for (let b = phoenix.length - 1; b >= 0; b--) {
      lengths[a][b] =
        key(react[a]) === key(phoenix[b])
          ? lengths[a + 1][b + 1] + 1
          : Math.max(lengths[a + 1][b], lengths[a][b + 1]);
    }
  }

  const pairs = [];
  let a = 0;
  let b = 0;

  while (a < react.length && b < phoenix.length) {
    if (key(react[a]) === key(phoenix[b])) pairs.push([react[a++], phoenix[b++]]);
    else if (lengths[a + 1][b] >= lengths[a][b + 1]) pairs.push([react[a++], null]);
    else pairs.push([null, phoenix[b++]]);
  }

  while (a < react.length) pairs.push([react[a++], null]);
  while (b < phoenix.length) pairs.push([null, phoenix[b++]]);

  return pairs;
}

// Visible is not finished.
//
// A panel that starts open is `h-(--accordion-panel-height)`, and the hook that
// sets the variable runs when the LiveView has connected — which is after the
// server-rendered HTML is on the page, and after `liveSocket.isConnected()`
// first says yes. Measuring any earlier reported a collapsed panel on a
// component that draws it correctly a moment later.
//
// So neither side is asked when it says it is ready. Both are asked when they
// stop moving, which is the same question for a React render, a LiveView hook
// and a CSS transition.
async function measured(page, selector) {
  // A component can position every child outside its preview root. The root is
  // still the comparison origin, even when it has no visible box itself.
  await expect(page.locator(selector)).toBeAttached();

  // The two pages are loaded one after the other. A pulse or transition would
  // otherwise be sampled at different points in the same upstream animation.
  await page.addStyleTag({ content: "*,::before,::after{animation:none!important;transition:none!important}" });

  await page.waitForFunction(
    (selector) => {
      const height = document.querySelector(selector)?.getBoundingClientRect().height;
      const before = window.__parityHeight;
      window.__parityHeight = height;

      return before !== undefined && Math.abs(before - height) < 0.01;
    },
    selector,
    { polling: 100 }
  );

  return page.evaluate(collect, { selector, properties: PROPERTIES });
}

// A difference read as a sentence. `padding-left: React 0.5rem, Phoenix 8px` is
// the whole of what a reviewer needs, and a JSON dump of two objects is not.
function described(differences) {
  return differences.map((difference) => {
    if (difference.kind) return `${difference.slot}: ${difference.kind}`;

    return `${difference.slot}: ${difference.property} — React ${difference.react}, Phoenix ${difference.phoenix}`;
  });
}
