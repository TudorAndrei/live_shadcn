// Every reviewed port, photographed beside its upstream React reference.
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

import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { expect, test as base } from "@playwright/test";
import { PNG } from "pngjs";

import { gated, source } from "./registries.mjs";
import {
  enterVisualState,
  installBrowserFixtures,
  visualStateIdentity,
  visualStates,
} from "./visual-states.mjs";
import { connected } from "./live.mjs";
import { inScope, noScopedPagesMessage, scopeFromEnvironment } from "./preview-scope.mjs";
import { pixelTimeoutMs } from "./pixel-timeout.mjs";
import { hasOfficialReactReference } from "./react-references.mjs";
import { comparisonApplies } from "./verification-policy.mjs";

import {
  MINIMUM_HEIGHT,
  compare,
  documentHeight,
  localise,
  paintedBox,
  settle,
  shootCurrent,
  union,
} from "./shoot.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const scope = scopeFromEnvironment();

const previews = JSON.parse(readFileSync(join(here, "../../../registry/snapshot/index.json")));
const budget = JSON.parse(readFileSync(join(here, "pixel-budget.json")));

const test = base.extend({
  referencePage: async ({ context }, use) => {
    const page = await context.newPage();
    try {
      await installBrowserFixtures(page);
      await use(page);
    } finally {
      await page.close();
    }
  },
});

// Every example. `registries.mjs` says which of them this gates. Both
// registries use the same DOM, style, pixel, behavior, and accessibility rules.
const pages = Object.entries(previews)
  .filter(([component]) => gated(component))
  .flatMap(([component, examples]) => examples.map((example) => ({ component, example })))
  .filter(({ component, example }) => comparisonApplies(source(component), component, example))
  .filter(({ component, example }) => inScope(`${component}.${example}`, scope, source));

const named = (component, example) => `${component}.${example}`;
const hasOfficialReference = (component, example) =>
  hasOfficialReactReference(source(component), named(component, example));

if (pages.length === 0) {
  test("there is an example to compare", () => {
    throw new Error(
      noScopedPagesMessage("pixel", scope),
    );
  });
}

// A budget or a skip for an example this check does not photograph is a check
// that quietly stopped running — whether the example was deleted or the
// registry it belongs to stopped being gated. Say so rather than carry it.
test("every budget and skip names an example this check compares", () => {
  const all = new Set(
    pages
      .filter(({ component, example }) => hasOfficialReference(component, example))
      .map(({ component, example }) => named(component, example)),
  );

  const stale = [
    ...Object.keys(budget.budgets),
    ...budget.pending,
    ...Object.keys(budget.skips),
  ]
    .filter((name) => inScope(name, scope, source))
    .filter((name) => !all.has(name));

  expect(stale, "remove these from pixel-budget.json").toEqual([]);
});

test("every gated snapshot example has a React reference", () => {
  const missing = pages
    .map(({ component, example }) => named(component, example))
    .filter((name) => {
      const [component, ...id] = name.split(".");
      return !hasOfficialReference(component, id.join("."));
    });

  expect(missing, "add parity/src/examples/<name>.tsx for each").toEqual([]);
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
    .filter(({ component, example }) => hasOfficialReference(component, example))
    .map(({ component, example }) => named(component, example))
    .filter((name) => !decided.has(name));

  expect(undecided, "add each to budgets, pending, or skips").toEqual([]);
});

for (const { component, example } of pages) {
  const name = named(component, example);

  test(`${component} / ${example} paints what React paints`, async ({ page, referencePage }, testInfo) => {
    // Named rather than passed over. A `continue` here left an example out of
    // the run with nothing in the output to say so, and a check that cannot
    // tell "did not run" from "passed" is worse than no check.
    test.skip(!hasOfficialReference(component, example), `no official React reference for ${name}`);
    await installBrowserFixtures(page);

    const selector = `[data-preview='${component}']`;
    const parity = testInfo.project.use.parityURL;

    const reactURL = `${parity}/preview/${component}/${example}`;
    const phoenixURL = `/preview/${component}/${example}`;

    const reactStates = await statesAt(referencePage, reactURL, selector);
    const phoenixStates = await statesAt(page, phoenixURL, selector);

    expect(
      phoenixStates.map(visualStateIdentity),
      `${name}: React and Phoenix must expose the same render states`,
    ).toEqual(reactStates.map(visualStateIdentity));

    test.setTimeout(pixelTimeoutMs(reactStates.length));

    const observations = [];

    for (const state of reactStates) {
      // One viewport for both sides, tall enough for either document in this
      // state, then one clip rectangle covering what either side paints.
      await page.setViewportSize({ width: 1280, height: MINIMUM_HEIGHT });
      await referencePage.setViewportSize({ width: 1280, height: MINIMUM_HEIGHT });
      await referencePage.goto(reactURL);
      await enterVisualState(referencePage, selector, state);
      const reactHeight = await documentHeight(referencePage);
      await page.goto(phoenixURL);
      await connected(page);
      await enterVisualState(page, selector, state);
      const phoenixHeight = await documentHeight(page);
      const height = Math.max(MINIMUM_HEIGHT, reactHeight, phoenixHeight);

      const viewport = { width: 1280, height };
      await page.setViewportSize(viewport);
      await referencePage.setViewportSize(viewport);

      await referencePage.goto(reactURL);
      await enterVisualState(referencePage, selector, state);
      await settle(referencePage, selector);
      const reactPaint = await paintedBox(referencePage, selector);

      await page.goto(phoenixURL);
      await connected(page);
      await enterVisualState(page, selector, state);
      await settle(page, selector);
      const phoenixPaint = await paintedBox(page, selector);

      const clip = union(reactPaint, phoenixPaint);

      // Both pages contain the measured state at the final viewport size.
      // Capture those pages, then reset them on the next state.
      const phoenix = await shootCurrent(page, selector, clip);
      const react = await shootCurrent(referencePage, selector, clip);

      const { differing, diff, width } = compare(react.image, phoenix.image);
      const suffix = safeName(state.name);

      // Attach images only when they explain an actual difference. Encoding
      // three large PNGs for every zero-pixel state drives Node CPU and keeps
      // report artifacts alive without adding verification evidence.
      if (differing > 0) {
        await testInfo.attach(`react-${suffix}.png`, {
          body: PNG.sync.write(react.image),
          contentType: "image/png",
        });
        await testInfo.attach(`phoenix-${suffix}.png`, {
          body: PNG.sync.write(phoenix.image),
          contentType: "image/png",
        });
        await testInfo.attach(`diff-${suffix}.png`, {
          body: PNG.sync.write(diff),
          contentType: "image/png",
        });
      }

      const hottest =
        differing === 0
          ? ""
          : localise(diff.data, width, height, phoenix.measured?.slots, {
              origin: phoenix.origin,
              clip: phoenix.clip,
              scale: width / clip.width,
            })
              .slice(0, 4)
              .map(({ slot, count }) => `${slot} (${count} px)`)
              .join(", ");

      // A percentage of the component, not of a mostly-blank page.
      const share = ((differing / (width * height)) * 100).toFixed(2);
      const report = `${state.name}: ${differing} px differ (${share}%) — hottest: ${hottest || "nothing"}`;

      observations.push({ differing, report });
    }

    const largest = Math.max(...observations.map(({ differing }) => differing));

    if (budget.skips[name]) {
      // A skip that would now pass in every state is a skip to delete.
      expect(largest, `${name} passes at zero now — remove the skip`).toBeGreaterThan(0);
      test.info().annotations.push({ type: "skipped", description: budget.skips[name] });
      return;
    }

    if (!gated(component) || budget.pending.includes(name)) {
      test.info().annotations.push({
        type: "pending",
        description: observations.map(({ report }) => report).join("; "),
      });
      // Printed, not only annotated. A census whose numbers live in an HTML
      // report is a census nobody reads, and these numbers are the whole point
      // of the pending state: they are what turns an estimated budget into a
      // measured one.
      process.stdout.write(`PENDING ${name} ${largest}\n`);
      return;
    }

    const allowed = budget.budgets[name] ?? 0;

    // A budget far above what the example actually differs by is a blanket
    // rather than a measurement. Lower it.
    if (allowed > 0 && largest * 10 < allowed) {
      throw new Error(
        `${name}: budget ${allowed} is more than ten times the ${largest} px observed. ` +
          "Lower it — a slack budget hides the next regression.",
      );
    }

    for (const { differing, report } of observations) {
      expect(differing, report).toBeLessThanOrEqual(allowed);
    }
  });
}

async function statesAt(page, url, selector) {
  await page.goto(url);
  if (url.startsWith("/")) await connected(page);
  return visualStates(page, selector);
}

const safeName = (name) => name.replace(/[^a-z0-9]+/gi, "-").replace(/^-|-$/g, "");
