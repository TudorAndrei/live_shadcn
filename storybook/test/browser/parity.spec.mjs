// Every reviewed port beside its upstream React reference.
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

import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { expect, test } from "@playwright/test";

import {
  collect,
  compare,
  describeRow,
  outline,
  PROPERTIES,
  SEMANTIC_ATTRIBUTES,
} from "./measure.mjs";
import { gated, source } from "./registries.mjs";
import {
  enterVisualState,
  installBrowserFixtures,
  visualStateIdentity,
  visualStates,
  waitForTimedExample,
} from "./visual-states.mjs";
import { rejectEvidenceStateFilter } from "./evidence-run.mjs";
import { beginStateCoverage } from "./report-provenance.mjs";
import { parityTimeoutMs } from "./parity-timeout.mjs";
import { connected } from "./live.mjs";
import { waitForMessageScrollerFinalLayout } from "./message-scroller-readiness.mjs";
import { inScope, noScopedPagesMessage, scopeFromEnvironment } from "./preview-scope.mjs";
import { hasOfficialReactReference } from "./react-references.mjs";
import { comparisonApplies } from "./verification-policy.mjs";

// Enough of a tree to find a difference in, and not so much that the report
// becomes the thing nobody reads.
const OUTLINE_ROWS = 400;

const here = dirname(fileURLToPath(import.meta.url));
const scope = scopeFromEnvironment();

// Written by `mix snapshot`. Read rather than fetched, because Playwright
// collects tests before it starts a server.
const previews = JSON.parse(readFileSync(join(here, "../../../registry/snapshot/index.json")));

// Where a reviewed port deliberately does not draw what upstream draws,
// by the slot the two disagree on. Everything else on the page still gates at
// zero, and a slot that stops differing fails the run. See the file.
const { divergences } = JSON.parse(readFileSync(join(here, "parity-divergence.json")));

// `plan > card: only in React` and `plan: width — React 720, Phoenix 448` are
// both about `plan > card` and `plan`. The slot is what a decision is recorded
// against, because a decision moves twenty numbers and none of them is the
// reason.
const subject = (difference) => difference.slice(0, difference.indexOf(":"));
const hasOfficialReference = (component, example) =>
  hasOfficialReactReference(source(component), `${component}.${example}`);

// Every shadcn example. `registries.mjs` says why the AI Elements ones are not
// compared.
const pages = Object.entries(previews)
  .filter(([component]) => gated(component))
  .flatMap(([component, examples]) => examples.map((example) => ({ component, example })))
  .filter(({ component, example }) => comparisonApplies(source(component), component, example))
  .filter(({ component, example }) => inScope(`${component}.${example}`, scope, source));

if (pages.length === 0) {
  test("there is a parity example to compare", () => {
    throw new Error(noScopedPagesMessage("parity", scope));
  });
}

// One test for the whole gap, rather than one failure per component. A page
// nobody ported is a page nothing compares, and that is worth saying once and
// completely.
test("every example has a React reference", () => {
  const missing = pages
    .map(({ component, example }) => `${component}.${example}`)
    .filter((name) => {
      const [component, ...id] = name.split(".");
      return !hasOfficialReference(component, id.join("."));
    });

  expect(missing, `add parity/src/examples/<name>.tsx for each`).toEqual([]);
});

// A decision recorded against an example this check does not compare is a
// decision nobody is reading — whether the example was deleted or the registry
// it belongs to stopped being gated. The same rule `pixel-budget.json` is held
// to.
test("every recorded divergence names an example this check compares", () => {
  const named = new Set(pages.map(({ component, example }) => `${component}.${example}`));
  const stale = Object.keys(divergences)
    .filter((name) => inScope(name, scope, source))
    .filter((name) => !named.has(name));

  expect(stale, "remove these from parity-divergence.json").toEqual([]);
});

for (const { component, example } of pages) {
  if (!hasOfficialReference(component, example)) continue;

  test(`${component} / ${example} draws what React draws`, async ({ page }, testInfo) => {
    await installBrowserFixtures(page);
    const selector = `[data-preview='${component}']`;
    const parity = testInfo.project.use.parityURL;
    const reactURL = `${parity}/preview/${component}/${example}`;
    const phoenixURL = `/preview/${component}/${example}`;
    const name = `${component}.${example}`;

    if (process.env.PARITY_DEBUG === name) {
      await page.addInitScript(() => {
        const original = Element.prototype.scrollTo;
        Element.prototype.scrollTo = function (...args) {
          if (this.getAttribute?.("data-slot") === "message-scroller-viewport") {
            window.__parityScrollCalls ||= [];
            window.__parityScrollCalls.push({
              args,
              before: {
                scrollTop: this.scrollTop,
                scrollHeight: this.scrollHeight,
                clientHeight: this.clientHeight,
              },
            });
          }
          return original.apply(this, args);
        };
      });
    }

    const reactStates = await statesAt(page, reactURL, selector);
    testInfo.setTimeout(parityTimeoutMs(reactStates.length));
    const phoenixStates = await statesAt(page, phoenixURL, selector);

    expect(
      phoenixStates.map(visualStateIdentity),
      `${name}: React and Phoenix must expose the same render states`,
    ).toEqual(reactStates.map(visualStateIdentity));

    const recorded = divergences[name]?.slots ?? [];
    const all = [];
    const differences = [];
    let where;

    const coverage = beginStateCoverage(testInfo, name,
      reactStates.map((state) => JSON.stringify(visualStateIdentity(state))));
    const selectedStates = process.env.PARITY_DEBUG_STATE
      ? reactStates.filter(({ name: stateName }) => stateName === process.env.PARITY_DEBUG_STATE)
      : reactStates;

    rejectEvidenceStateFilter();

    if (selectedStates.length === 0) {
      throw new Error(
        `${name}: no parity state named ${JSON.stringify(process.env.PARITY_DEBUG_STATE)}`,
      );
    }

    for (const state of selectedStates) {
      const react = await renderState(page, reactURL, selector, state);
      const phoenix = await renderState(page, phoenixURL, selector, state);
      if (process.env.PARITY_DEBUG === name) {
        console.log(
          JSON.stringify({ state: state.name, react: react.debug, phoenix: phoenix.debug }, null, 2)
        );
      }
      const stateDifferences = described(compare(react.measured, phoenix.measured));
      coverage.complete(JSON.stringify(visualStateIdentity(state)));

      all.push(...stateDifferences);

      const unexpected = stateDifferences.filter(
        (difference) => !recorded.includes(subject(difference)),
      );

      differences.push(...unexpected.map((difference) => `${state.name} / ${difference}`));

      // Only on a failure. A passing example has nothing to explain, and 66 of
      // these attached to every green run is a way of hiding the six that are not.
      if (unexpected.length > 0 && !where) {
        where = `${state.name}: ${divergence(react.tree, phoenix.tree)}`;

        await testInfo.attach(`outline-react-${safeName(state.name)}.txt`, {
          body: react.tree.map(describeRow).join("\n"),
          contentType: "text/plain",
        });
        await testInfo.attach(`outline-phoenix-${safeName(state.name)}.txt`, {
          body: phoenix.tree.map(describeRow).join("\n"),
          contentType: "text/plain",
        });
      }
    }

    expect(differences, where).toEqual([]);

    // A decision that has stopped costing anything is a decision to delete.
    // Either the recipe changed or upstream did, and a list nobody prunes is
    // the tolerance problem wearing a different coat.
    const settled = recorded.filter((slot) => !all.some((d) => subject(d) === slot));

    expect(settled, `${name}: these agree now — remove them from parity-divergence.json`).toEqual(
      []
    );
  });
}

async function statesAt(page, url, selector) {
  await page.goto(url);
  if (url.startsWith("/")) await connected(page);
  return visualStates(page, selector);
}

async function renderState(page, url, selector, state) {
  await page.goto(url);
  if (url.startsWith("/")) await connected(page);
  await enterVisualState(page, selector, state);

  const animationsBeforeMeasurement =
    process.env.PARITY_DEBUG == null
      ? []
      : await page.evaluate(() =>
          document.getAnimations().map((animation) => {
            const effect = animation.effect;
            const target = effect?.target;
            const timing = effect?.getComputedTiming?.() ?? {};

            return {
              animationName: animation.animationName ?? null,
              currentTime: animation.currentTime,
              playState: animation.playState,
              target: target && {
                id: target.id,
                slot: target.getAttribute?.("data-slot"),
                messageId: target.getAttribute?.("data-message-id"),
                className: target.getAttribute?.("class"),
              },
              timing: {
                activeDuration: timing.activeDuration,
                delay: timing.delay,
                endTime: timing.endTime,
                progress: timing.progress,
              },
              keyframes:
                effect?.getKeyframes?.().map(({ offset, opacity, transform }) => ({
                  offset,
                  opacity,
                  transform,
                })) ?? [],
            };
          }),
        );

  return {
    measured: await measured(page, selector),
    tree: await page.evaluate(outline, { selector, limit: OUTLINE_ROWS }),
    debug:
      process.env.PARITY_DEBUG == null
        ? null
        : {
            animations: animationsBeforeMeasurement,
            ...(await page.evaluate(() => {
            const popup = document.querySelector("[data-slot='context-menu-content']:not([hidden])");
            const positioner = popup?.parentElement;
            const view = document.documentElement;
            const messageViewport = document.querySelector("[data-slot=\"message-scroller-viewport\"]");
            const messageContent = document.querySelector("[data-slot=\"message-scroller-content\"]");

            return {
              scrollCalls: window.__parityScrollCalls ?? [],
              messageScroller: messageViewport && {
                scrollTop: messageViewport.scrollTop,
                scrollHeight: messageViewport.scrollHeight,
                clientHeight: messageViewport.clientHeight,
                distanceToEnd:
                  messageViewport.scrollHeight -
                  messageViewport.scrollTop -
                  messageViewport.clientHeight,
                contentBox: messageContent?.getBoundingClientRect().toJSON(),
                items: [...(messageContent?.querySelectorAll("[data-slot=\"message-scroller-item\"]") || [])].map((item) => ({
                  id: item.getAttribute("data-message-id"),
                  box: item.getBoundingClientRect().toJSON(),
                  visible: item.checkVisibility?.({ contentVisibilityAuto: true }),
                })),
              },
              popup: popup && {
                box: popup.getBoundingClientRect().toJSON(),
                availableHeight: getComputedStyle(popup).getPropertyValue("--available-height"),
                maxHeight: getComputedStyle(popup).maxHeight,
              },
              positioner: positioner && {
                box: positioner.getBoundingClientRect().toJSON(),
                side: positioner.getAttribute("data-side"),
                requestedSide: positioner.getAttribute("data-lb-side"),
                pointX: positioner.getAttribute("data-lb-point-x"),
                pointY: positioner.getAttribute("data-lb-point-y"),
                style: positioner.getAttribute("style"),
              },
              viewport: {
                width: view.clientWidth,
                height: view.clientHeight,
                offsetTop: window.visualViewport?.offsetTop,
              },
            };
          })),
          },
  };
}

const safeName = (name) => name.replace(/[^a-z0-9]+/gi, "-").replace(/^-|-$/g, "");

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
  await waitForTimedExample(page, selector);

  // A component can position every child outside its preview root. The root is
  // still the comparison origin, even when it has no visible box itself.
  await expect(page.locator(selector)).toBeAttached();

  // The two pages are loaded one after the other. A pulse or transition would
  // otherwise be sampled at different points in the same upstream animation.
  await page.addStyleTag({ content: "*,::before,::after{animation:none!important;transition:none!important}" });

  await page.evaluate(async () => {
    const finiteAnimations = document
      .getAnimations({ subtree: true })
      .filter((animation) => {
        const endTime = animation.effect?.getComputedTiming().endTime;

        return Number.isFinite(endTime) &&
          ["pending", "running"].includes(animation.playState);
      });

    await Promise.allSettled(finiteAnimations.map((animation) => animation.finished));
  });

  const options = {
    selector,
    properties: PROPERTIES,
    attributes: SEMANTIC_ATTRIBUTES,
  };

  await page.waitForFunction(
    (selector) => {
      const root = document.querySelector(selector);
      if (!root) return false;

      const scrollContainers = [root, ...root.querySelectorAll("*")]
        .filter((element) => {
          const { overflowX, overflowY } = getComputedStyle(element);
          return ["auto", "scroll"].includes(overflowX) ||
            ["auto", "scroll"].includes(overflowY);
        })
        .map((element) => {
          const { top, left, width, height } = element.getBoundingClientRect();

          return [
            element.scrollTop,
            element.scrollLeft,
            element.scrollHeight,
            element.scrollWidth,
            element.clientHeight,
            element.clientWidth,
            top,
            left,
            width,
            height,
          ];
        });
      const snapshot = JSON.stringify({
        root: root.getBoundingClientRect().toJSON(),
        scrollContainers,
      });
      const prior = window.__parityLayoutState;
      const frames = prior?.snapshot === snapshot ? prior.frames + 1 : 0;
      window.__parityLayoutState = { snapshot, frames };

      return frames >= 2;
    },
    selector,
    { polling: "raf" }
  );

  await waitForMessageScrollerFinalLayout(page, selector);

  return page.evaluate(collect, options);
}

// A difference read as a sentence. `padding-left: React 0.5rem, Phoenix 8px` is
// the whole of what a reviewer needs, and a JSON dump of two objects is not.
function described(differences) {
  return differences.map((difference) => {
    if (difference.kind) return `${difference.slot}: ${difference.kind}`;

    return `${difference.slot}: ${difference.property} — React ${difference.react}, Phoenix ${difference.phoenix}`;
  });
}
