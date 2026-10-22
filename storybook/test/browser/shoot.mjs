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

import { collect, PROPERTIES, SEMANTIC_ATTRIBUTES } from "./measure.mjs";
import { waitForMessageScrollerFinalLayout } from "./message-scroller-readiness.mjs";
import { enterVisualState, waitForTimedExample } from "./visual-states.mjs";
import { connected } from "./live.mjs";

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
  await waitForTimedExample(page, selector);

  await page.addStyleTag({
    content: `*, *::before, *::after {
      animation: none !important;
      transition: none !important;
      caret-color: transparent !important;
      scroll-behavior: auto !important;
    }

    [class~="text-transparent"] {
      background-position: 0% center !important;
    }`,
  });

  await page.evaluate(() => {
    // A CSS override cannot stop a Web Animations API animation, and Sonner and
    // the chart library both use one.
    for (const animation of document.getAnimations({ subtree: true })) {
      const endTime = animation.effect?.getComputedTiming().endTime;

      if (endTime === Number.POSITIVE_INFINITY) {
        animation.currentTime = 0;
        animation.pause();
      } else {
        try {
          animation.finish();
        } catch {
          animation.cancel();
        }
      }
    }

    // Motion drives simple gradients with requestAnimationFrame instead of
    // exposing a Web Animation. Put each shimmer at its final keyframe on both
    // pages so the photograph compares the gradient, not two clock readings.
    for (const element of document.querySelectorAll(".text-transparent")) {
      if (getComputedStyle(element).backgroundImage !== "none") {
        element.style.backgroundPosition = "0% center";
      }
    }

    // SMIL animations do not appear in document.getAnimations(). Pause each
    // SVG at the same instant so an animated marker cannot move between shots.
    for (const svg of document.querySelectorAll("svg")) {
      svg.pauseAnimations?.();
      svg.setCurrentTime?.(0);
    }

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

      const height = root.getBoundingClientRect().height;
      const scroll = [root, ...root.querySelectorAll("*")]
        .map((element) => `${element.scrollTop}:${element.scrollLeft}`)
        .join("|");
      // Recharts animates `d`, `x`, `y`, `width`, and `height` values with
      // requestAnimationFrame. The root height stays fixed while every bar is
      // still moving. Include the SVG paint data, or the check can capture one
      // renderer during the animation and the other after it.
      const svg = [...root.querySelectorAll("svg")]
        .map((element) => element.innerHTML)
        .join("|");
      const now = `${height}|${scroll}|${svg}`;
      const settled = window.__settledPaint === now;
      window.__settledPaint = now;
      return settled;
    },
    selector,
    { polling: 100 },
  );

  await waitForMessageScrollerFinalLayout(page, selector);

  // Motion can write one more requestAnimationFrame value while the layout is
  // stable. Apply the shared final shimmer keyframe immediately before capture.
  await page.evaluate(() => {
    for (const element of document.querySelectorAll(".text-transparent")) {
      if (getComputedStyle(element).backgroundImage !== "none") {
        element.style.backgroundPosition = "0% center";
      }
    }
  });
}

/** The document's full height, so one viewport can hold the whole component. */
export async function documentHeight(page) {
  return page.evaluate(() => document.documentElement.scrollHeight);
}

/**
 * The rectangle the component actually paints into.
 *
 * Not the preview root's box. That box is the wrapper — 720px wide for every
 * example — so a shot clipped to it is mostly blank page, and a difference that
 * is 5% of a component reads as 0.019% of the image. A cap that a
 * five-percent-wrong component passes comfortably is not a cap.
 *
 * Nor is it the root's box narrowed to the component, because plenty of
 * components paint outside their root entirely. `toast` is the honest example:
 * its preview root is **zero pixels tall**, and React portals 38 elements to
 * `document.body`. An element screenshot of that root photographs nothing at
 * all.
 *
 * So: the union of the root and everything painted outside it — portalled
 * content, fixed overlays, backdrops. Taken on both sides and unioned again, so
 * one rectangle frames both images. If a component paints somewhere on one side
 * and nowhere on the other, that shows up as painted against blank, which is
 * exactly the finding wanted.
 */
export async function paintedBox(page, selector) {
  return page.evaluate(paintedBoxInDocument, selector);
}

// This function runs in the browser through `page.evaluate`. Keeping it named
// also lets the Node test use a small fake document to check its layout reads.
export function paintedBoxInDocument(css) {
  const root = document.querySelector(css);
  if (!root) return null;

  const origin = root.getBoundingClientRect();
  const boxes = [];

  for (const part of root.querySelectorAll("[data-slot]")) {
    const box = part.getBoundingClientRect();
    if (box.width > 0 && box.height > 0) boxes.push(box);
  }

  for (const own of root.children) {
    const box = own.getBoundingClientRect();
    if (box.width > 0 && box.height > 0) boxes.push(box);
  }

  for (const element of root.querySelectorAll("*")) {
    if (element === root || element.hasAttribute("data-slot")) continue;
    if (!visibleInDocument(element)) continue;
    if (clippedByAncestor(element, root)) continue;
    if (offscreenLazyDescendant(element, root)) continue;

    const box = element.getBoundingClientRect();
    if (box.width > 0 && box.height > 0) boxes.push(box);
  }

  for (const element of document.body.querySelectorAll("*")) {
    if (element.contains(root)) continue;
    if (root.contains(element)) continue;

    const box = element.getBoundingClientRect();
    if (box.width <= 0 || box.height <= 0) continue;

    const position = getComputedStyle(element).position;
    const portalled = element.parentElement === document.body;
    if (position === "fixed" || portalled) boxes.push(box);
  }

  if (boxes.length === 0) boxes.push(root.getBoundingClientRect());

  const left = Math.min(...boxes.map((b) => b.left));
  const top = Math.min(...boxes.map((b) => b.top));
  const right = Math.max(...boxes.map((b) => b.right));
  const bottom = Math.max(...boxes.map((b) => b.bottom));

  return {
    left: left - origin.left,
    top: top - origin.top,
    right: right - origin.left,
    bottom: bottom - origin.top,
  };

  function visibleInDocument(element) {
    if (element.hidden) return false;
    if (element.getAttribute("aria-hidden") === "true") return false;

    if (typeof element.checkVisibility === "function") {
      return element.checkVisibility({ checkOpacity: true, checkVisibilityCSS: true });
    }

    const style = getComputedStyle(element);
    return (
      style.display !== "none" &&
      style.visibility !== "hidden" &&
      Number.parseFloat(style.opacity || "1") > 0
    );
  }

  function clippedByAncestor(element, root) {
    const box = element.getBoundingClientRect();
    let node = element.parentElement;

    while (node && node !== root && root.contains(node)) {
      const style = getComputedStyle(node);

      if (overflowClips(style)) {
        const clip = node.getBoundingClientRect();

        if (
          box.left < clip.left - 0.5 ||
          box.top < clip.top - 0.5 ||
          box.right > clip.right + 0.5 ||
          box.bottom > clip.bottom + 0.5
        ) {
          return true;
        }
      }

      node = node.parentElement;
    }

    return false;
  }

  function overflowClips(style) {
    return (
      ["hidden", "clip"].includes(style.overflow) ||
      ["hidden", "clip"].includes(style.overflowX) ||
      ["hidden", "clip"].includes(style.overflowY)
    );
  }

  function offscreenLazyDescendant(element, root) {
    let scrollViewport = null;
    let node = element;

    while (node && node !== root) {
      const style = getComputedStyle(node);

      if (["auto", "scroll"].includes(style.overflowY)) {
        scrollViewport = node;
      }

      node = node.parentElement;
    }

    if (!scrollViewport) return false;

    const style = getComputedStyle(element);
    if (style.contentVisibility !== "auto") return false;

    const lazyBox = element.getBoundingClientRect();
    const viewportBox = scrollViewport.getBoundingClientRect();

    return lazyBox.bottom <= viewportBox.top || lazyBox.top >= viewportBox.bottom;
  }
}

/** One component-relative rectangle covering what either side paints. */
export function union(a, b) {
  const margin = 4;

  const left = Math.floor(Math.min(a.left, b.left)) - margin;
  const top = Math.floor(Math.min(a.top, b.top)) - margin;
  const right = Math.ceil(Math.max(a.right, b.right)) + margin;
  const bottom = Math.ceil(Math.max(a.bottom, b.bottom)) + margin;

  return { x: left, y: top, width: Math.max(1, right - left), height: Math.max(1, bottom - top) };
}

/**
 * One side: size the viewport, settle, photograph, and record the slot boxes.
 *
 * `clip` rather than `element.screenshot()`, and the difference matters.
 * Clipping to an element's own box gives each side a different image whenever
 * the two components are different sizes — which is the thing under test, and
 * pixelmatch refuses images of different dimensions. One rectangle computed
 * across both sides keeps the framing tight *and* the dimensions equal.
 */
export async function shoot(page, url, selector, height, clip, state) {
  await page.setViewportSize({ width: WIDTH, height });
  await page.goto(url);
  if (url.startsWith("/")) await connected(page);

  // A reference that does not exist must fail loudly. `parity/src/main.tsx`
  // renders a `data-missing` marker rather than a blank page precisely so this
  // cannot be mistaken for a component that draws nothing.
  const missing = await page.locator("[data-missing]").count();
  if (missing > 0) {
    throw new Error(`no React reference is mounted at ${url}`);
  }

  await enterVisualState(page, selector, state);
  await settle(page, selector);

  return shootCurrent(page, selector, clip);
}

/**
 * Photograph the current, already-settled page.
 *
 * Pixel comparison first measures the React and Phoenix paint bounds to make
 * their shared clip rectangle. The second side is still settled when that
 * rectangle is known, so reloading it only to take the same photograph wastes
 * one renderer load per visual state.
 */
export async function shootCurrent(page, selector, clip) {

  const measured = await page.evaluate(collect, {
    selector,
    properties: PROPERTIES,
    attributes: SEMANTIC_ATTRIBUTES,
  });

  // Where the root sits on the page. `collect` reports every slot relative to
  // it, and the image is clipped somewhere else entirely, so this is what lets
  // a differing pixel be named after the part it fell in.
  const origin = await page.evaluate((css) => {
    const { x, y } = document.querySelector(css).getBoundingClientRect();
    return { x, y };
  }, selector);

  const pageClip = clip
    ? {
        x: clip.x + origin.x,
        y: clip.y + origin.y,
        width: clip.width,
        height: clip.height,
      }
    : null;
  const image = PNG.sync.read(await captureCurrentPaint(page, pageClip ? { clip: pageClip } : {}));

  return { image, measured, origin, clip: pageClip };
}

async function captureCurrentPaint(page, options) {
  // Browser validation prompts animate outside document.getAnimations().
  const nativeValidation = await page.evaluate(() => {
    const control = document.activeElement;
    return (control instanceof HTMLInputElement || control instanceof HTMLTextAreaElement ||
      control instanceof HTMLSelectElement) && control.form !== null &&
      control.matches(":user-invalid") && !control.validity.valid;
  });
  if (!nativeValidation) return page.screenshot(options);

  await page.bringToFront();
  let previous;
  let stable = 0;
  for (let attempt = 0; attempt < 60; attempt += 1) {
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(resolve)));
    const current = await page.screenshot(options);
    stable = previous && current.equals(previous) ? stable + 1 : 0;
    if (stable >= 3) return current;
    previous = current;
  }
  throw new Error("native validation prompt paint did not become stable after 60 samples");
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
export function localise(diff, width, height, slots, into) {
  const counts = new Map();

  // Slot boxes arrive relative to the component root, in CSS pixels. The image
  // is clipped to somewhere else on the page and rendered at a device scale
  // factor, so both have to be applied before a coordinate means anything.
  const { origin, clip, scale } = into ?? { origin: { x: 0, y: 0 }, clip: { x: 0, y: 0 }, scale: 1 };

  const boxes = (slots ?? [])
    .filter(({ box }) => box)
    .map(({ slot, box }) => ({
      slot,
      box: {
        x: (box.x + origin.x - clip.x) * scale,
        y: (box.y + origin.y - clip.y) * scale,
        width: box.width * scale,
        height: box.height * scale,
      },
    }));

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      // pixelmatch paints a changed pixel in exactly its diff colour, which is
      // pure red by default. Anything looser than an exact test counts faded
      // originals too — an earlier version reported 3.5 million differing
      // pixels out of 8,077, which is the kind of number that tells you the
      // test is wrong rather than the component.
      const at = (y * width + x) * 4;
      if (diff[at] !== 255 || diff[at + 1] !== 0 || diff[at + 2] !== 0) continue;

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
  const options = {
    threshold: THRESHOLD,
    includeAA: false,
  };
  const differing = pixelmatch(react.data, phoenix.data, undefined, width, height, options);

  // Green comparisons need only the exact count. A full RGBA diff buffer is
  // large at the two-times device scale and is useful only when there is a
  // difference to report.
  if (differing === 0) return { differing, width, height };

  const diff = new PNG({ width, height });
  pixelmatch(react.data, phoenix.data, diff.data, width, height, options);

  return { differing, diff, width, height };
}

export { MINIMUM_HEIGHT, WIDTH };
