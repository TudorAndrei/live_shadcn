// Behaviour for a choice the client owns.
//
// `const Icon = isCopied ? CheckIcon : CopyIcon` is upstream's, and the server
// has no answer to it: the browser holds `isCopied` for two seconds, and asking
// the server would cost a round trip and a timer per copy. So the generated
// component draws both icons, marks each with the state it belongs to, and
// hides the one a fresh page is not in — and `LiveBase.Clipboard` swaps them.
//
// A snapshot sees both icons and cannot tell whether either is ever shown, so
// what that swap actually does is only visible here.

import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const COMMAND = "mix ui.add accordion";

const button = (page) => page.locator("#snippet-copy");
const copied = (page) => page.locator("#snippet-copy [data-lb-state='copied']");
const idle = (page) => page.locator("#snippet-copy [data-lb-state='idle']");

// A connected socket is not a mounted hook, and the button does nothing until
// the hook is listening — a click into that window is dropped, which is what
// `data-lb-ready` is for. Waiting for the socket alone made these tests pass or
// fail on how long an unrelated `await` happened to take.
async function ready(page) {
  await visit(page, "/preview/snippet/default", "#snippet-copy");
  await expect(button(page)).toHaveAttribute("data-lb-ready", "");
}

test.describe("a snippet", () => {
  test.beforeEach(async ({ context }) => {
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);
  });

  test("starts in the state the server can be sure of", async ({ page }) => {
    await ready(page);

    await expect(idle(page)).toBeVisible();
    await expect(copied(page)).toBeHidden();
  });

  test("a click writes the text to the clipboard and says so", async ({ page }) => {
    await ready(page);
    await button(page).click();

    await expect(copied(page)).toBeVisible();
    await expect(idle(page)).toBeHidden();

    const written = await page.evaluate(() => navigator.clipboard.readText());
    expect(written).toBe(COMMAND);
  });

  test("copying costs no round trip", async ({ page }) => {
    // Registered before the page is opened: a listener added afterwards sees
    // no frames of a socket that is already connected, and the test would pass
    // by watching nothing.
    const frames = [];
    page.on("websocket", (socket) =>
      socket.on("framesent", ({ payload }) => frames.push(String(payload)))
    );

    await ready(page);
    await button(page).click();
    await expect(copied(page)).toBeVisible();

    expect(frames.filter((frame) => frame.includes("event"))).toHaveLength(0);
  });

  test("the check goes back to a copy icon on its own", async ({ page }) => {
    await ready(page);
    await button(page).click();
    await expect(copied(page)).toBeVisible();

    // `data-lb-timeout` is upstream's two seconds, run by the browser that
    // pressed the button.
    await expect(idle(page)).toBeVisible({ timeout: 5000 });
    await expect(copied(page)).toBeHidden();
  });

  test("is clean under axe, before and after a copy", async ({ page }) => {
    await ready(page);

    const scan = async () => {
      const { violations } = await new AxeBuilder({ page }).analyze();
      // Contrast is upstream's, and some of shadcn's own colours fall below
      // 4.5:1. Everything else axe reports is markup, which is ours.
      return violations.filter(({ id }) => id !== "color-contrast");
    };

    expect(await scan()).toEqual([]);

    await button(page).click();
    await expect(copied(page)).toBeVisible();

    expect(await scan()).toEqual([]);
  });
});
