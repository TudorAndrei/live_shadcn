// A Message Scroller can change its opening scroll position after the first
// paint. The pending marker tells us that its hook still owns that work. After
// it clears, the rows can still receive their final offsets from scroll
// anchoring and content visibility on later animation frames.

export const MESSAGE_SCROLLER_STABLE_FRAME_WINDOW = 4;
export const MESSAGE_SCROLLER_TRAILING_FRAMES = 2;

let readinessInvocation = 0;

/**
 * Advance the readiness state with one Message Scroller layout sample.
 *
 * This is deliberately exact. A changed scroll position, extent, viewport
 * height, row offset, or row height starts the frame window again. There is no
 * pixel tolerance because this gate decides when to measure those pixels.
 */
export function advanceMessageScrollerReadiness(
  previous,
  sample,
  {
    stableFrameWindow = MESSAGE_SCROLLER_STABLE_FRAME_WINDOW,
    trailingFrames = MESSAGE_SCROLLER_TRAILING_FRAMES,
  } = {},
) {
  if (!sample.hasMessageScroller) {
    return { hasMessageScroller: false, signature: null, stableFrames: 0, ready: true };
  }

  if (sample.pending) {
    return { hasMessageScroller: true, signature: null, stableFrames: 0, ready: false };
  }

  const stableFrames = previous?.signature === sample.signature ? previous.stableFrames + 1 : 1;

  return {
    hasMessageScroller: true,
    signature: sample.signature,
    stableFrames,
    ready: stableFrames >= stableFrameWindow + trailingFrames,
  };
}

/**
 * Wait for every Message Scroller inside `selector` to reach its final layout.
 *
 * The browser samples on animation frames. It first requires a four-frame
 * unchanged window, then requires two more unchanged frames. This verifies the
 * two final requestAnimationFrame turns instead of sleeping for an estimated
 * duration.
 */
export async function waitForMessageScrollerFinalLayout(page, selector) {
  const invocation = ++readinessInvocation;

  await page.waitForFunction(
    ({ selector, stableFrameWindow, trailingFrames, invocation }) => {
      const rootSelector = "[data-slot='message-scroller'], [data-lb-message-scroller]";
      const viewportSelector =
        "[data-slot='message-scroller-viewport'], [data-lb-message-scroller-viewport]";
      const itemSelector = "[data-slot='message-scroller-item']";
      const scope = document.querySelector(selector);

      if (!scope) return false;

      const roots = [
        ...(scope.matches(rootSelector) ? [scope] : []),
        ...scope.querySelectorAll(rootSelector),
      ].filter((root, index, all) => all.indexOf(root) === index && root.closest(rootSelector) === root);

      const viewports = roots.flatMap((root) =>
        [...root.querySelectorAll(viewportSelector)].filter(
          (viewport) => viewport.closest(rootSelector) === root,
        ),
      );
      const pending = [...roots, ...viewports].some((element) =>
        element.hasAttribute("data-pending-scroll"),
      );
      const signature = JSON.stringify(
        viewports.map((viewport) => [
          viewport.scrollTop,
          viewport.scrollHeight,
          viewport.clientHeight,
          [...viewport.querySelectorAll(itemSelector)]
            .filter((item) => item.closest(rootSelector) === viewport.closest(rootSelector))
            .map((item) => [item.offsetTop, item.offsetHeight]),
        ]),
      );
      const sample = {
        hasMessageScroller: roots.length > 0,
        pending,
        signature,
      };
      const key = "__liveShadcnMessageScrollerReadiness";
      const previous = window[key]?.invocation === invocation ? window[key] : undefined;
      let next;

      if (!sample.hasMessageScroller) {
        next = { hasMessageScroller: false, signature: null, stableFrames: 0, ready: true };
      } else if (sample.pending) {
        next = { hasMessageScroller: true, signature: null, stableFrames: 0, ready: false };
      } else {
        const stableFrames = previous?.signature === sample.signature ? previous.stableFrames + 1 : 1;
        next = {
          hasMessageScroller: true,
          signature: sample.signature,
          stableFrames,
          ready: stableFrames >= stableFrameWindow + trailingFrames,
        };
      }

      window[key] = { ...next, invocation };
      return next.ready;
    },
    {
      selector,
      stableFrameWindow: MESSAGE_SCROLLER_STABLE_FRAME_WINDOW,
      trailingFrames: MESSAGE_SCROLLER_TRAILING_FRAMES,
      invocation,
    },
    { polling: "raf" },
  );
}
