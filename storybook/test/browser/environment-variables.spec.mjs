// Behaviour for a switch that reveals a secret, and a button that copies one.
//
// Two things this component does are decisions rather than markup, and each is
// the opposite of the other:
//
//   * The switch asks the **server**. What it reveals is a secret, so the page
//     is given the value when it asks and not before — one round trip, stated
//     rather than hidden. A page that rendered the value and hid it with CSS
//     would put every secret in the page source.
//   * The copy button asks **nobody**. Copying is `navigator.clipboard`, and the
//     tick afterwards is two seconds of state in one browser.
//
// The switch is also the component's whole accessibility contract. A fold copies
// markup and not behaviour, and what arrived was a `<span>` with no `role`, no
// `tabindex` and no `aria-checked` — which axe reports and is right to.

import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const SECRET = "sup3rs3cr3t";

const toggle = (page) => page.getByRole("switch");
const secret = (page) => page.locator("#copy-secret-key-base");
const copied = (page) => page.locator("#copy-mix-env [data-lb-state='copied']");

async function open(page) {
  await visit(page, "/preview/environment-variables/default", "[data-slot='switch']");
}

test.describe("environment variables", () => {
  test.beforeEach(async ({ context }) => {
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);
  });

  test("the toggle is a switch a keyboard can reach", async ({ page }) => {
    await open(page);

    await expect(toggle(page)).toHaveAttribute("aria-checked", "false");
    await expect(toggle(page)).toBeEnabled();
    await toggle(page).focus();
    await expect(toggle(page)).toBeFocused();
    await expect(toggle(page)).toHaveAttribute("data-state", "unchecked");
  });

  // The contract, not tidiness: the page is given the value when it asks for
  // it. A component that rendered the secret and hid it would pass every other
  // test on this page.
  test("the secret is not in the page before it is asked for", async ({ page }) => {
    await open(page);

    expect(await page.content()).not.toContain(SECRET);
    await expect(secret(page)).toHaveAttribute("data-lb-clipboard", "");
  });

  test("flipping the switch asks the server, and the server answers", async ({ page }) => {
    await open(page);
    await toggle(page).click();

    await expect(toggle(page)).toHaveAttribute("aria-checked", "true");
    await expect(page.getByText(SECRET)).toBeVisible();
    await expect(secret(page)).toHaveAttribute("data-lb-clipboard", SECRET);
  });

  test("the space bar flips it too", async ({ page }) => {
    await open(page);
    await toggle(page).focus();
    await toggle(page).press(" ");

    await expect(toggle(page)).toHaveAttribute("aria-checked", "true");
  });

  test("copying costs no round trip", async ({ page }) => {
    const frames = [];
    page.on("websocket", (socket) =>
      socket.on("framesent", ({ payload }) => frames.push(String(payload)))
    );

    await open(page);
    // A connected socket is not a mounted hook, and a click into that window is
    // dropped.
    await expect(page.locator("#copy-mix-env")).toHaveAttribute("data-lb-ready", "");
    await page.locator("#copy-mix-env").click();

    await expect(copied(page)).toBeVisible();
    expect(await page.evaluate(() => navigator.clipboard.readText())).toBe("prod");
    expect(frames.filter((frame) => frame.includes("event"))).toHaveLength(0);
  });

  test("is clean under axe, hidden and shown", async ({ page }) => {
    await open(page);

    const scan = async () => {
      const { violations } = await new AxeBuilder({ page }).analyze();
      // Contrast is upstream's, and some of shadcn's own colours fall below
      // 4.5:1. Everything else axe reports is markup, which is ours.
      return violations.filter(({ id }) => id !== "color-contrast");
    };

    expect(await scan()).toEqual([]);

    await toggle(page).click();
    await expect(toggle(page)).toHaveAttribute("aria-checked", "true");

    expect(await scan()).toEqual([]);
  });
});
