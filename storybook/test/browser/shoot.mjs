// Photographing both sides, and saying where they differ.
//
// The geometric check in `measure.mjs` compares numbers and strings. It never
// looks at what was painted, so it cannot see a shadow, a gradient, an
// `::after`, a transform, a z-order, an SVG glyph, or anything at all on an
// element without a `data-slot`. This is the other half.
//
// ── No committed baselines ──
//
// Both sides are photographed in the same run, in the same browser, on the same
// machine, and diffed in memory. The React render is the baseline, recomputed
// every time.
//
// That one decision removes the whole class of screenshot-test misery:
// platform-suffixed goldens, `--update-snapshots` churn, baselines that go
// stale the moment `registry/UPSTREAM.json` moves, and macOS-against-Linux font
// differences. Every environmental variable cancels because both images come
// out of one Chromium — so only the components can differ.
//
// It also keeps the rule the rest of this repository is held to: a difference
// is a finding about the reader or the recipe, because the reference side is
// rebuilt from unmodified upstream at the pinned commit on every run.

import pixelmatch from "pixelmatch";
import { PNG } from "pngjs";

import { collect, PROPERTIES } from "./measure.mjs";

// How different two pixels must be before they count. pixelmatch measures in
// YIQ colour distance and detects anti-aliasing on its own, so this absorbs
// rasteriser noise on a curved edge and nothing else.
const THRESHOLD = 0.1;

// Wide enough for every example, and the same on both sides by construction —
// pixelmatch requires identical dimensions, and equal viewports give them.
const WIDTH = 1280;
const MINIMUM_HEIGHT = 2048;

/**
 * Freezes everything that would make two photographs of the same page differ.
 *
 * The settle discipline is `parity.spec.mjs`'s, and the comment there is worth
 * repeating: visible is not finished. A panel that starts open is
 * `h-(--accordion-panel-height)`, and the hook that sets the variable runs
 * after `liveSocket.isConnected()` first says yes.
 */
export async function settle(page, selector) {
  await page.addStyleTag({
    content: `*, *::before, *::after {
      animation: none !important;
      transition: none !important;
      caret-color: transparent !important;
      scroll-behavior: auto !important;
    }`,
  });

  await page.evaluate(() => {
    // A CSS override cannot stop a Web Animations API animation, and Sonner and
    // the chart library both use one.
    for (const animation of document.getAnimations({ subtree: true })) {
      try {
        animation.finish();
      } catch {
        animation.cancel();
      }
    }

    // No stray focus ring left over from navigating here.
    document.activeElement?.blur?.();
  });

  // A no-op while the styling layer uses system fonts, and the thing that stops
  // this check going mad the day a webfont lands.
  await page.evaluate(() => document.fonts?.ready);

  // Both sides are asked when they stop moving, not when they say they are
  // ready — the same question for a React render, a LiveView hook, and a CSS
  // transition.
  await page.waitForFunction(
    (css) => {
      const root = document.querySelector(css);
      if (!root) return false;

      const now = root.getBoundingClientRect().height;
      const settled = window.__settledHeight === now;
      window.__settledHeight = now;
      return settled;
    },
    selector,
    { polling: 100 },
  );
}

/** The document's full height, so one viewport can hold the whole component. */
export async function documentHeight(page) {
  return page.evaluate(() => document.documentElement.scrollHeight);
}

/**
 * One side: size the viewport, settle, photograph, and record the slot boxes.
 *
 * A viewport screenshot rather than an element one, deliberately. A preview
 * root can have a zero-height box — `measure.mjs` documents a component that
 * positions every child outside it — and a portal paints outside it too. A
 * viewport shot catches both, because `position: fixed` is viewport-relative
 * however the DOM is arranged.
 */
export async function shoot(page, url, selector, height) {
  await page.setViewportSize({ width: WIDTH, height });
  await page.goto(url);

  // A reference that does not exist must fail loudly. `parity/src/main.tsx`
  // renders a `data-missing` marker rather than a blank page precisely so this
  // cannot be mistaken for a component that draws nothing.
  const missing = await page.locator("[data-missing]").count();
  if (missing > 0) {
    throw new Error(`no React reference is mounted at ${url}`);
  }

  await settle(page, selector);

  const measured = await page.evaluate(collect, { selector, properties: PROPERTIES });
  const image = PNG.sync.read(await page.screenshot());

  return { image, measured };
}

/**
 * Where the two images differ, named by the anatomy rather than by coordinates.
 *
 * A pixel count on its own is not actionable. The existing check prints
 * `padding-left: React 0.5rem, Phoenix 8px`, and this has to be as useful — so
 * each differing pixel is attributed to the innermost slot whose box contains
 * it, and the ones inside no slot at all get their own bucket. That bucket is
 * what the geometric check is structurally blind to, and naming it is the point
 * of photographing anything.
 */
export function localise(diff, width, height, slots) {
  const counts = new Map();
  const boxes = (slots ?? []).map(({ slot, box }) => ({ slot, box }));

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      // pixelmatch paints a difference red; an unchanged pixel keeps the
      // faded original, whose channels stay equal.
      const at = (y * width + x) * 4;
      if (diff[at] < 200 || diff[at + 1] > 100) continue;

      const hit = innermost(boxes, x, y);
      const name = hit ?? "outside any slot";
      counts.set(name, (counts.get(name) ?? 0) + 1);
    }
  }

  return [...counts.entries()]
    .sort(([, a], [, b]) => b - a)
    .map(([slot, count]) => ({ slot, count }));
}

// The smallest box containing the point, so a difference inside a button is
// reported against the button rather than against the card around it.
function innermost(boxes, x, y) {
  let best = null;
  let area = Infinity;

  for (const { slot, box } of boxes) {
    if (x < box.x || y < box.y || x > box.x + box.width || y > box.y + box.height) continue;

    const size = box.width * box.height;
    if (size < area) {
      area = size;
      best = slot;
    }
  }

  return best;
}

/** Diffs two equally-sized images and returns the count plus a diff PNG. */
export function compare(react, phoenix) {
  const { width, height } = react;
  const diff = new PNG({ width, height });

  const differing = pixelmatch(react.data, phoenix.data, diff.data, width, height, {
    threshold: THRESHOLD,
    includeAA: false,
  });

  return { differing, diff, width, height };
}

export { MINIMUM_HEIGHT, WIDTH };
