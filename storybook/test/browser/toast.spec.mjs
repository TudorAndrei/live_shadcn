// Behaviour parity for the toast.
//
// The list belongs to the server, so almost nothing here is about what the
// toasts say. What is tested is the boundary: the hook measures and stacks, the
// server adds and removes, and neither does the other's job.

import { expect, test } from "@playwright/test";

const viewport = (page) => page.locator("[data-lb-toasts]");
const toasts = (page) => page.locator("[data-slot='toast']");

const variable = (locator, name) =>
  locator.evaluate((el, property) => el.style.getPropertyValue(property), name);

// The hook stacks on mount, which is when the LiveView connects. Until then
// every toast sits at index nothing and height nothing, one on top of another.
const stacked = async (page) =>
  page.waitForFunction(
    () => document.querySelector("[data-slot='toast']")?.style.getPropertyValue("--toast-height"),
  );

test.describe("a toaster", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/preview/toast/default");
    // The viewport is a fixed positioning context. Its toast children are
    // absolute, so the viewport itself has no box to make visible.
    await expect(viewport(page)).toBeAttached();
    await stacked(page);
  });

  test("draws one toast per entry the server holds", async ({ page }) => {
    await expect(toasts(page)).toHaveCount(3);
  });

  test("names the region, so a screen reader can reach it", async ({ page }) => {
    await expect(viewport(page)).toHaveAttribute("role", "region");
    await expect(viewport(page)).toHaveAttribute("aria-label", "Notifications");
  });

  test("each toast announces itself politely", async ({ page }) => {
    await expect(toasts(page).first()).toHaveAttribute("role", "status");
    await expect(toasts(page).first()).toHaveAttribute("aria-live", "polite");
  });

  // The newest is at the front. The server writes them in the order it holds
  // them, so the last one in the list is the one that just arrived.
  test("the newest sits at the front and the rest fall behind it", async ({ page }) => {
    expect(await variable(toasts(page).nth(2), "--toast-index")).toBe("0");
    expect(await variable(toasts(page).nth(1), "--toast-index")).toBe("1");
    expect(await variable(toasts(page).nth(0), "--toast-index")).toBe("2");
  });

  test("every toast is measured, because its height is a class string away", async ({ page }) => {
    for (const index of [0, 1, 2]) {
      expect(await variable(toasts(page).nth(index), "--toast-height")).toMatch(/^\d+px$/);
    }
  });

  test("only the one at the front is read", async ({ page }) => {
    await expect(toasts(page).nth(2)).not.toHaveAttribute("data-behind", /.*/);
    await expect(toasts(page).nth(1)).toHaveAttribute("data-behind", "");
  });

  test("marks toasts beyond the visible limit", async ({ page }) => {
    await expect(toasts(page).nth(0)).toHaveAttribute("data-limited", "");
    await expect(toasts(page).nth(1)).not.toHaveAttribute("data-limited", /.*/);
  });

  // The frame stops overlapping its neighbours and the content inside it comes
  // back to full opacity. Two elements, one attribute, and the hook writes it
  // to both because the generator marked both.
  test("a pointer over the stack fans it apart", async ({ page }) => {
    await toasts(page).nth(2).hover();

    await expect(toasts(page).first()).toHaveAttribute("data-expanded", "");
    await expect(toasts(page).first().locator("[data-slot='toast-content']")).toHaveAttribute(
      "data-expanded",
      "",
    );
  });

  test("closing one is an event, and the server is what removes it", async ({ page }) => {
    await toasts(page).nth(2).locator("[data-slot='toast-close']").click();

    await expect(toasts(page)).toHaveCount(2);
    await expect(page.locator("#notices-drift")).toHaveCount(0);
  });

  test("the stack is renumbered once the server has answered", async ({ page }) => {
    await toasts(page).nth(2).locator("[data-slot='toast-close']").click();
    await expect(toasts(page)).toHaveCount(2);

    await expect.poll(() => variable(toasts(page).nth(1), "--toast-index")).toBe("0");
  });
});
