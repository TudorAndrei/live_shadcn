// Opening a preview page, and knowing when it is ready to be driven.
//
// `page.goto` resolves when the HTML has loaded, and the HTML is rendered by
// the server — every trigger is in the document, visible and clickable, before
// the LiveView has connected. Until it has, `phx-click` sends nothing and no
// hook has mounted, so a click or a key pressed into that window is dropped.
//
// On a quiet machine the window is too small to hit. Under a full run it is
// not, which is what made three of these suites look flaky in different tests
// on different runs: `tabs` failed to walk its row, `dialog` failed to close on
// Escape, `accordion` failed to open on Space. One cause, three symptoms, and
// each looked like its own timing bug.
//
// `resizable.spec.mjs` was already waiting for this. Everything else waited for
// an element to be visible, which is a different question with the same answer
// most of the time.
import { expect } from "@playwright/test";

/**
 * Navigate to a preview page and wait until the LiveView can be driven.
 *
 * @param page     the Playwright page
 * @param path     the preview path, e.g. `/preview/tabs/default`
 * @param selector something the page renders, waited for before the socket so
 *                 a wrong path fails on what is missing rather than on a
 *                 timeout
 */
export async function visit(page, path, selector) {
  await page.goto(path);

  if (selector) await expect(page.locator(selector)).toBeVisible();

  await connected(page);
}

/** Wait until this page's LiveView has connected. */
export async function connected(page) {
  await page.waitForFunction(
    () =>
      window.liveSocket?.isConnected() &&
        document.querySelector("[data-phx-main].phx-connected") !== null,
  );
}

/** Server-rendered reference controls are usable after React commits. */
export async function referenceReady(page) {
  await page.waitForFunction(() =>
    !document.documentElement.hasAttribute("data-reference-page") ||
    document.documentElement.dataset.referenceReady === "true",
  );
}

/** Deliver animation callbacks on real browser frames at a lower rate. */
export async function slowAnimationFrames(page) {
  await page.addInitScript(() => {
    const request = window.requestAnimationFrame.bind(window);
    const cancel = window.cancelAnimationFrame.bind(window);
    const pending = new Map();
    window.requestAnimationFrame = (callback) => {
      let remaining = 8;
      let handle;
      const advance = (timestamp) => {
        if (!pending.has(handle)) return;
        if (--remaining === 0) {
          pending.delete(handle);
          callback(timestamp);
        } else pending.set(handle, request(advance));
      };
      handle = request(advance);
      pending.set(handle, handle);
      return handle;
    };
    window.cancelAnimationFrame = (handle) => {
      cancel(pending.get(handle) ?? handle);
      pending.delete(handle);
    };
  });
}
