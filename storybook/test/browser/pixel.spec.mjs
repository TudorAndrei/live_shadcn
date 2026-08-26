// Every generated component, photographed beside the React it was generated
// from.
//
// `parity.spec.mjs` compares numbers and strings: box geometry and 37 computed
// properties, per `data-slot`. That catches a padding, a colour, a font weight.
// What it cannot see is what was painted — a shadow, a gradient, an `::after`,
// a transform, a z-order, an SVG glyph — or anything at all on an element
// without a `data-slot`.
//
// So this one looks at the pixels. It is a fifth check rather than a
// replacement for the fourth: geometry names the fix in the vocabulary a recipe
// is written in, and pixels catch what geometry cannot see but name only a
// region. Each is the other's triage tool.
//
// There are no committed baselines. See `shoot.mjs` for why that is the
// decision everything else follows from.

import { readFileSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { expect, test } from "@playwright/test";
import { PNG } from "pngjs";

import { gated } from "./registries.mjs";

import {
  MINIMUM_HEIGHT,
  compare,
  documentHeight,
  localise,
  paintedBox,
  settle,
  shoot,
  union,
} from "./shoot.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const only = process.env.PREVIEW_COMPONENT;

const previews = JSON.parse(readFileSync(join(here, "../../../registry/snapshot/index.json")));
const budget = JSON.parse(readFileSync(join(here, "pixel-budget.json")));

const ported = new Set(
  readdirSync(join(here, "../../../parity/src/examples"))
    .filter((name) => name.endsWith(".tsx"))
    .map((name) => name.replace(/\.tsx$/, "")),
);

// Every shadcn example. `registries.mjs` says why the AI Elements ones are not
// photographed.
const pages = Object.entries(previews)
  .filter(([component]) => gated(component))
  .filter(([component]) => !only || component === only)
  .flatMap(([component, examples]) => examples.map((example) => ({ component, example })));

const named = (component, example) => `${component}.${example}`;

// A budget or a skip for an example this check does not photograph is a check
// that quietly stopped running — whether the example was deleted or the
// registry it belongs to stopped being gated. Say so rather than carry it.
test("every budget and skip names an example this check compares", () => {
  const all = new Set(
    Object.entries(previews)
      .filter(([component]) => gated(component))
      .flatMap(([c, es]) => es.map((e) => named(c, e))),
  );

  const stale = [
    ...Object.keys(budget.budgets),
    ...budget.pending,
    ...Object.keys(budget.skips),
  ].filter((name) => !all.has(name));

  expect(stale, "remove these from pixel-budget.json").toEqual([]);
});

// One test for the whole gap, the same shape `parity.spec.mjs` uses for its
// missing references. An example nobody has measured is *pending*, never
// green-by-omission — and adding a component without deciding its budget shows
// up here, in review, rather than as a silence.
test("every example has a budget or is pending", () => {
  const decided = new Set([
    ...Object.keys(budget.budgets),
    ...budget.pending,
    ...Object.keys(budget.skips),
  ]);

  const undecided = pages
    .filter(({ component, example }) => ported.has(named(component, example)))
    .map(({ component, example }) => named(component, example))
    .filter((name) => !decided.has(name));

  expect(undecided, "add each to budgets, pending, or skips").toEqual([]);
});

for (const { component, example } of pages) {
  const name = named(component, example);

  test(`${component} / ${example} paints what React paints`, async ({ page }, testInfo) => {
    // Named rather than passed over. A `continue` here left an example out of
    // the run with nothing in the output to say so, and a check that cannot
    // tell "did not run" from "passed" is worse than no check.
    test.skip(!ported.has(name), `no React reference: add parity/src/examples/${name}.tsx`);

    const selector = `[data-preview='${component}']`;
    const parity = testInfo.project.use.parityURL;

    const reactURL = `${parity}/preview/${component}/${example}`;
    const phoenixURL = `/preview/${component}/${example}`;

    // One viewport for both sides, tall enough for either document, then one
    // clip rectangle covering what either side paints. Equal dimensions are a
    // hard requirement of the diff; tight framing is what makes a percentage
    // mean anything.
    await page.setViewportSize({ width: 1280, height: MINIMUM_HEIGHT });
    await page.goto(reactURL);
    const reactHeight = await documentHeight(page);
    await page.goto(phoenixURL);
    const phoenixHeight = await documentHeight(page);
    const height = Math.max(MINIMUM_HEIGHT, reactHeight, phoenixHeight);

    const viewport = { width: 1280, height };
    await page.setViewportSize(viewport);

    await page.goto(reactURL);
    await settle(page, selector);
    const reactPaint = await paintedBox(page, selector);

    await page.goto(phoenixURL);
    await settle(page, selector);
    const phoenixPaint = await paintedBox(page, selector);

    const clip = union(reactPaint, phoenixPaint, viewport);

    const react = await shoot(page, reactURL, selector, height, clip);
    const phoenix = await shoot(page, phoenixURL, selector, height, clip);

    const { differing, diff, width } = compare(react.image, phoenix.image);

    await testInfo.attach("react.png", { body: PNG.sync.write(react.image), contentType: "image/png" });
    await testInfo.attach("phoenix.png", { body: PNG.sync.write(phoenix.image), contentType: "image/png" });
    await testInfo.attach("diff.png", { body: PNG.sync.write(diff), contentType: "image/png" });

    const scale = width / clip.width;

    const hottest = localise(diff.data, width, height, phoenix.measured?.slots, {
      origin: phoenix.origin,
      clip,
      scale,
    })
      .slice(0, 4)
      .map(({ slot, count }) => `${slot} (${count} px)`)
      .join(", ");

    // A percentage of the component now, not of a mostly-blank page. That was
    // the point of clipping: `calendar` differs by about 5% of itself, and a
    // viewport shot reported the same difference as 0.019%.
    const share = ((differing / (width * height)) * 100).toFixed(2);
    const report = `${differing} px differ (${share}%) — hottest: ${hottest || "nothing"}`;

    if (budget.skips[name]) {
      // A skip that would now pass is a skip to delete.
      expect(differing, `${name} passes at zero now — remove the skip`).toBeGreaterThan(0);
      test.info().annotations.push({ type: "skipped", description: budget.skips[name] });
      return;
    }

    if (budget.pending.includes(name)) {
      test.info().annotations.push({ type: "pending", description: report });
      // Printed, not only annotated. A census whose numbers live in an HTML
      // report is a census nobody reads, and these numbers are the whole point
      // of the pending state: they are what turns an estimated budget into a
      // measured one.
      process.stdout.write(`PENDING ${name} ${differing}\n`);
      return;
    }

    const allowed = budget.budgets[name] ?? 0;

    // A budget far above what the example actually differs by is a blanket
    // rather than a measurement. Lower it.
    if (allowed > 0 && differing * 10 < allowed) {
      throw new Error(
        `${name}: budget ${allowed} is more than ten times the ${differing} px observed. ` +
          "Lower it — a slack budget hides the next regression.",
      );
    }

    expect(differing, report).toBeLessThanOrEqual(allowed);
  });
}
