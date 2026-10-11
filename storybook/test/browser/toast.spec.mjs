import { readFileSync } from "node:fs";
import { expect, test } from "@playwright/test";

import { referenceReady, visit } from "./live.mjs";

const viewport = (page) => page.locator("[data-lb-toasts]");
const toasts = (page) => page.locator("[data-slot='toast']");

const variable = (locator, name) =>
  locator.evaluate((element, property) => element.style.getPropertyValue(property), name);

const stacked = async (page) =>
  page.waitForFunction(
    () => document.querySelector("[data-slot='toast']")?.style.getPropertyValue("--toast-height")
  );

async function showDefault(page) {
  await page.getByRole("button", { name: "Show Toast" }).click();
  await expect(toasts(page)).toHaveCount(1);
  await stacked(page);
}

async function showTypes(page, names) {
  for (const name of names) {
    await page.getByRole("button", { name, exact: true }).click();
  }

  await expect(toasts(page)).toHaveCount(names.length);
  await stacked(page);
}

test.describe("the official toast examples", () => {
  test("starts with the official trigger and no toast", async ({ page }) => {
    await visit(page, "/preview/toast/default");

    await expect(viewport(page)).toBeAttached();
    await expect(page.getByRole("button", { name: "Show Toast" })).toBeVisible();
    await expect(toasts(page)).toHaveCount(0);
  });

  test("adds the official event toast and its action", async ({ page }) => {
    await visit(page, "/preview/toast/default");
    await showDefault(page);

    await expect(toasts(page)).toContainText("Event created");
    await expect(toasts(page)).toContainText("Sunday, December 3 at 9:00 AM");
    await expect(toasts(page).locator("[data-slot='toast-icon']")).toHaveCount(0);
    await expect(toasts(page).locator("[data-slot='toast-action']")).toHaveText("Undo");

    await toasts(page).locator("[data-slot='toast-action']").click();
    await expect(toasts(page)).toHaveCount(0);
  });

  test("names the region and uses the live dialog contract", async ({ page }) => {
    await visit(page, "/preview/toast/default");
    await showDefault(page);

    await expect(viewport(page)).toHaveAttribute("role", "region");
    await expect(viewport(page)).toHaveAttribute("aria-label", "Notifications");
    await expect(toasts(page)).toHaveAttribute("role", "dialog");
    await expect(toasts(page)).toHaveAttribute("aria-live", "polite");
  });

  test("an urgent toast follows native keyboard focus and announcement ownership", async ({ page }, testInfo) => {
    for (const path of [
      `${testInfo.project.use.parityURL}/preview/toast/types`,
      "/preview/toast/types",
    ]) {
      if (path.startsWith("http")) {
        await page.goto(path);
        await referenceReady(page);
      } else await visit(page, path);

      const trigger = page.getByRole("button", { name: "Error", exact: true });
      await trigger.click();
      const notice = page.locator("[data-slot='toast']");
      const close = notice.locator("[data-slot='toast-close']");
      await expect(notice).toHaveAttribute("role", "alertdialog");
      await expect(notice).toHaveAttribute("aria-hidden", "true");
      await expect(page.getByRole("alert")).toHaveText("The event could not be created.");

      await page.keyboard.press("Tab");
      await expect(notice).toBeFocused();
      await expect(page.getByRole("alertdialog")).toHaveCount(1);
      await expect(page.getByRole("alert")).toHaveCount(0);
      await page.keyboard.press("Tab");
      await expect(close).toBeFocused();
      await expect(close).not.toHaveAttribute("aria-hidden", "true");
      await expect(notice).not.toHaveAttribute("aria-hidden", "true");

      await trigger.focus();
      await expect(notice).toHaveAttribute("aria-hidden", "true");
      await expect(page.getByRole("alert")).toHaveText("The event could not be created.");
    }
  });

  test("toast focus callbacks preserve caller handlers through updates and cleanup", async ({ page }) => {
    await visit(page, "/preview/toast/default");
    await showDefault(page);
    const markup = await page.locator("[data-slot='toast-portal']").evaluate((element) => element.outerHTML);
    await page.goto("about:blank");
    await page.setContent(`${markup}<button id="outside">Outside</button>`);
    await page.keyboard.press("Tab");
    const controller = readFileSync(new URL("../../../packages/live_base/assets/js/toast.js", import.meta.url), "utf8");
    const result = await page.evaluate(async (source) => {
      const { Toast } = await import(`data:text/javascript,${encodeURIComponent(source)}`);
      const viewport = document.querySelector("[data-lb-toasts]");
      const parts = ["toast", "toast-action", "toast-close"].map((slot) =>
        viewport.querySelector(`[data-slot='${slot}']`));
      const outside = document.querySelector("#outside");
      const calls = [0, 0, 0];
      const receivers = [];
      parts.forEach((part, index) => {
        part.onfocus = function () { calls[index]++; receivers.push(this === part); };
      });
      const hook = { ...Toast, el: viewport, pushEvent() {} };
      hook.mounted();
      outside.focus();
      for (const part of parts) part.focus();
      const expanded = viewport.hasAttribute("data-expanded");
      const closeExposed = parts[2].getAttribute("aria-hidden") === "false";
      hook.updated();
      parts[0].focus();
      let replacementCalls = 0;
      parts[2].onfocus = () => replacementCalls++;
      hook.destroyed();
      outside.focus();
      viewport.removeAttribute("data-expanded");
      for (const part of parts) part.focus();
      return { calls, receivers, replacementCalls, expanded, closeExposed,
        expandedAfterCleanup: viewport.hasAttribute("data-expanded") };
    }, controller);
    expect(result).toEqual({ calls: [3, 2, 1], receivers: Array(6).fill(true),
      replacementCalls: 1, expanded: true, closeExposed: true, expandedAfterCleanup: false });
  });

  test("measures, orders, limits, and expands a toast stack", async ({ page }) => {
    await visit(page, "/preview/toast/types");
    await showTypes(page, ["Default", "Success", "Info", "Warning"]);

    for (const index of [0, 1, 2, 3]) {
      expect(await variable(toasts(page).nth(index), "--toast-height")).toMatch(/^\d+px$/);
      expect(await variable(toasts(page).nth(index), "--toast-index")).toBe(String(index));
    }

    await expect(toasts(page).first()).not.toHaveAttribute("data-behind", /.*/);
    await expect(toasts(page).nth(1)).toHaveAttribute("data-behind", "");
    await expect(toasts(page).nth(2)).not.toHaveAttribute("data-limited", /.*/);
    await expect(toasts(page).nth(3)).toHaveAttribute("data-limited", "");

    await toasts(page).first().hover();
    await expect(toasts(page).first()).toHaveAttribute("data-expanded", "");
    await expect(toasts(page).first().locator("[data-slot='toast-content']")).toHaveAttribute(
      "data-expanded",
      ""
    );
  });

  test("closes a toast on the server and renumbers the remaining stack", async ({ page }) => {
    await visit(page, "/preview/toast/types");
    await showTypes(page, ["Default", "Success", "Info"]);

    await toasts(page).first().locator("[data-slot='toast-close']").click();
    await expect(toasts(page)).toHaveCount(2);
    await expect.poll(() => variable(toasts(page).first(), "--toast-index")).toBe("0");
  });

  test("moves the Promise toast from loading to success", async ({ page }) => {
    await visit(page, "/preview/toast/promise");
    await page.getByRole("button", { name: "Create Event" }).click();

    await expect(toasts(page).locator("[data-slot='toast-description']")).toHaveText(
      "Creating event…"
    );
    await expect(toasts(page)).toHaveAttribute("data-type", "loading");
    await expect(toasts(page).locator("[data-slot='toast-icon'] svg")).toHaveClass(/animate-spin/);

    await expect(toasts(page).locator("[data-slot='toast-description']")).toHaveText(
      "Event created.",
      { timeout: 3_000 }
    );
    await expect(toasts(page)).toHaveAttribute("data-type", "success");
  });
});
