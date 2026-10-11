import { expect, test } from "@playwright/test";

import { referenceReady, visit } from "./live.mjs";
import { enterVisualState } from "./visual-states.mjs";
import {
  waitForMessageScrollerEntryAnimations,
  waitForMessageScrollerFinalLayout,
} from "./message-scroller-readiness.mjs";

const root = (page) => page.locator("[data-preview='message-scroller'] [data-slot='message-scroller']");
const viewport = (page) => root(page).locator("[data-slot='message-scroller-viewport']");
const content = (page) => root(page).locator("[data-slot='message-scroller-content']");
const button = (page, direction = "end") =>
  root(page).locator(`[data-slot='message-scroller-button'][data-direction='${direction}']`);

async function endScrollTop(locator) {
  return locator.evaluate((element) => Math.max(0, element.scrollHeight - element.clientHeight));
}

async function scrollTo(locator, top) {
  await locator.evaluate((element, nextTop) => {
    element.scrollTop = nextTop;
    element.dispatchEvent(new Event("scroll", { bubbles: true }));
  }, top);
}

// This is the message scroller start-alignment contract. It is intentionally
// calculated from the rendered geometry instead of accepting a pixel range.
// A changed padding, margin, peek, or target position must fail this test.
async function exactStartScrollTop(item, { margin = 0, peek = 0 } = {}) {
  return item.evaluate((node, options) => {
    const scroller = node.closest("[data-slot='message-scroller']");
    const viewportElement = scroller.querySelector("[data-slot='message-scroller-viewport']");
    const contentElement = scroller.querySelector("[data-slot='message-scroller-content']");
    const viewportRect = viewportElement.getBoundingClientRect();
    const nodeRect = node.getBoundingClientRect();
    const padding = Number.parseFloat(getComputedStyle(contentElement).paddingBlockStart) || 0;
    const raw =
      nodeRect.top -
      viewportRect.top +
      viewportElement.scrollTop -
      padding -
      options.margin -
      options.peek;
    const max = Math.max(0, viewportElement.scrollHeight - viewportElement.clientHeight);

    return Math.min(max, Math.max(0, Math.round(raw)));
  }, { margin, peek });
}

async function expectExactStartScroll(page, item, options = {}) {
  const preview = "[data-preview='message-scroller']";
  await waitForMessageScrollerEntryAnimations(page, preview);
  await waitForMessageScrollerFinalLayout(page, preview);
  const expected = await exactStartScrollTop(item, options);

  await expect.poll(() => item.evaluate((node) => {
    const scroller = node.closest("[data-slot='message-scroller']");
    return scroller.querySelector("[data-slot='message-scroller-viewport']").scrollTop;
  })).toBe(expected);

  return expected;
}

async function expectExactEndScroll(locator) {
  await expect.poll(() => locator.evaluate(
    (element) => element.scrollTop - Math.max(0, element.scrollHeight - element.clientHeight),
  )).toBe(0);
}

async function messageIds(locator) {
  return locator.evaluateAll((items) => items.map((item) => item.getAttribute("data-message-id")));
}

async function firstVisibleMessage(itemLocator) {
  return itemLocator.evaluateAll((items) => {
    const viewportElement = items[0]
      ?.closest("[data-slot='message-scroller']")
      ?.querySelector("[data-slot='message-scroller-viewport']");

    if (!viewportElement) return null;

    const viewportRect = viewportElement.getBoundingClientRect();
    const item = items.find((candidate) => {
      const rect = candidate.getBoundingClientRect();
      return rect.bottom > viewportRect.top && rect.top < viewportRect.bottom;
    });

    if (!item) return null;

    return {
      id: item.getAttribute("data-message-id"),
      viewportTop: Math.round(item.getBoundingClientRect().top - viewportRect.top),
    };
  });
}

test("the default transcript uses the pinned composer and completes an assistant reply", async ({ page }) => {
  await visit(page, "/preview/message-scroller/default");

  await expect(page.getByText("Morning, shadcn!", { exact: true })).toBeVisible();
  await expect(page.getByRole("button", { name: "Reset conversation" })).toBeEnabled();
  const files = page.getByRole("button", { name: "Add files" });
  await files.click();
  await expect(page.getByRole("menuitem", { name: "Add Photos & Files" })).toBeVisible();
  await expect(page.getByRole("menuitem", { name: "Create Image" })).toBeVisible();
  await expect(page.getByRole("menuitem", { name: "Deep Research" })).toBeVisible();
  await expect(page.getByRole("menuitem", { name: "Web Search" })).toBeVisible();
  await page.keyboard.press("Escape");

  await page.getByRole("button", { name: "Send" }).click();

  await expect(content(page)).toHaveAttribute("role", "log");
  await expect(content(page)).toHaveAttribute("aria-relevant", "additions");
  await expect(viewport(page)).toHaveAttribute("role", "region");
  await expect(viewport(page)).toHaveAttribute("aria-label", "Messages");
  await expect(content(page)).toHaveAttribute("aria-busy", "true");
  await expect(page.getByRole("button", { name: "Send" })).toBeDisabled();
  await expect(page.getByRole("button", { name: "Reset conversation" })).toBeDisabled();
  await expect(content(page).locator("[data-message-id='msg-1']")).toBeVisible();
  const heldScrollTop = await viewport(page).evaluate((element) => element.scrollTop);

  await expect(content(page)).toHaveAttribute("aria-busy", "false");
  await expect(content(page).locator("[data-message-id='msg-2']")).toBeVisible();
  await expect(page.getByRole("button", { name: "Reset conversation" })).toBeEnabled();
  await expect.poll(() => viewport(page).evaluate((element) => element.scrollTop)).toBe(heldScrollTop);
  await expect(button(page)).toHaveAttribute("data-active", "true");
  await expect(button(page)).toHaveAttribute("tabindex", "0");

  await button(page).click();
  await expectExactEndScroll(viewport(page));
  await expect(button(page)).toHaveAttribute("data-active", "false");
  await expect(button(page)).toHaveAttribute("tabindex", "-1");

  await page.getByRole("button", { name: "Reset conversation" }).click();
  await expect(page.getByText("Morning, shadcn!", { exact: true })).toBeVisible();
  await expect(page.getByRole("button", { name: "Send" })).toBeEnabled();
});

test("anchoring uses the selected role, exact position, reset, and re-add flow", async ({ page }) => {
  await visit(page, "/preview/message-scroller/anchoring");
  const send = page.getByRole("button", { name: "Send Message" });
  const rows = content(page).locator("[data-slot='message-scroller-item']");
  const ids = [
    "anchor-1-user",
    "anchor-1-assistant",
    "anchor-2-user",
    "anchor-2-assistant",
    "anchor-3-user",
    "anchor-3-assistant",
  ];

  await expect(page.getByText("No anchored messages yet", { exact: true })).toBeVisible();
  await expect(page.getByRole("button", { name: "Reset anchored turns" })).toBeDisabled();

  for (const id of ids) {
    await send.click();
    await expect(content(page).locator(`[data-message-id='${id}']`)).toBeVisible();
  }

  expect(await messageIds(rows)).toEqual(ids);
  expect(await rows.evaluateAll((items) => items.map((item) => item.getAttribute("data-scroll-anchor")))).toEqual(
    ["true", "false", "true", "false", "true", "false"],
  );
  await expectExactStartScroll(page, rows.nth(4), { peek: 64 });

  await page.getByRole("button", { name: "Reset anchored turns" }).click();
  await expect(page.getByText("No anchored messages yet", { exact: true })).toBeVisible();
  await send.click();
  await expect(content(page).locator("[data-message-id='anchor-1-user']")).toBeVisible();

  await page.getByRole("button", { name: "Anchor assistant messages" }).click();
  await expect(page.getByText("No anchored messages yet", { exact: true })).toBeVisible();
  for (const id of ids) {
    await send.click();
    await expect(content(page).locator(`[data-message-id='${id}']`)).toBeVisible();
  }

  expect(await messageIds(rows)).toEqual(ids);
  expect(await rows.evaluateAll((items) => items.map((item) => item.getAttribute("data-scroll-anchor")))).toEqual(
    ["false", "true", "false", "true", "false", "true"],
  );
  await expectExactStartScroll(page, rows.nth(5), { peek: 64 });

  await page.getByRole("button", { name: "Reset anchored turns" }).click();
  await expect(page.getByText("No anchored messages yet", { exact: true })).toBeVisible();
  await send.click();
  await expect(content(page).locator("[data-message-id='anchor-1-user']")).toBeVisible();
});

for (const action of ["wheel", "Home"]) {
  test(`native reader ${action} keeps the start position after active message entry`, async ({ page }) => {
    await page.addInitScript((input) => {
      const capture = (event) => {
        if (event.type !== input.type || (input.key && event.key !== input.key)) return;
        const viewportElement = event.target.closest?.("[data-slot='message-scroller-viewport']");
        if (!viewportElement || viewportElement.id !== "message-scroller-anchoring-viewport") return;
        const target = viewportElement.querySelector("[data-message-id='anchor-3-user']");
        window.__messageReaderIntent = {
          type: event.type,
          key: event.key ?? null,
          trusted: event.isTrusted,
          activeEntry: target?.hasAttribute("data-lb-message-entry-active") ?? false,
          transform: target ? getComputedStyle(target).transform : null,
          scrollTopBeforeInput: viewportElement.scrollTop,
          scrollRange: viewportElement.scrollHeight - viewportElement.clientHeight,
        };
      };
      document.addEventListener(input.type, capture, { capture: true, passive: true });
    }, { type: action === "wheel" ? "wheel" : "keydown", key: action === "Home" ? "Home" : null });

    await visit(page, "/preview/message-scroller/anchoring");
    const send = page.getByRole("button", { name: "Send Message" });
    for (const id of ["anchor-1-user", "anchor-1-assistant", "anchor-2-user", "anchor-2-assistant"]) {
      await send.click();
      await expect(content(page).locator(`[data-message-id='${id}']`)).toBeVisible();
    }
    const preview = "[data-preview='message-scroller']";
    await waitForMessageScrollerEntryAnimations(page, preview);
    await waitForMessageScrollerFinalLayout(page, preview);
    const scroller = viewport(page);
    const bounds = await scroller.boundingBox();
    expect(bounds).not.toBeNull();

    await send.click();
    const target = content(page).locator("[data-message-id='anchor-3-user']");
    await expect(target).toHaveAttribute("data-lb-message-entry-active", "true");
    if (action === "wheel") {
      await page.mouse.move(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2);
      // A passive wheel observer can run after native scrolling. Read the real
      // pre-input position immediately before dispatch, without blocking scroll.
      const beforeInput = await scroller.evaluate((element) => {
        const row = element.querySelector("[data-message-id='anchor-3-user']");
        return {
          activeEntry: row?.hasAttribute("data-lb-message-entry-active") ?? false,
          transform: row ? getComputedStyle(row).transform : null,
          scrollTop: element.scrollTop,
          scrollRange: element.scrollHeight - element.clientHeight,
        };
      });
      await test.info().attach("native-reader-wheel-before-input", {
        body: JSON.stringify(beforeInput, null, 2),
        contentType: "application/json",
      });
      expect(beforeInput.activeEntry).toBe(true);
      expect(beforeInput.transform).not.toBe("none");
      expect(beforeInput.scrollTop).toBeGreaterThan(0);
      expect(beforeInput.scrollRange).toBeGreaterThan(0);
      await page.mouse.wheel(0, -2000);
    } else {
      await scroller.focus();
      await page.keyboard.press("Home");
    }

    await expect.poll(() => page.evaluate(() => window.__messageReaderIntent?.trusted)).toBe(true);
    const receipt = await page.evaluate(() => window.__messageReaderIntent);
    await test.info().attach("native-reader-entry-input", {
      body: JSON.stringify({ action, receipt }, null, 2),
      contentType: "application/json",
    });
    expect(receipt.activeEntry, "the native input must arrive during actual entry motion").toBe(true);
    expect(receipt.transform).not.toBe("none");
    if (action === "Home") expect(receipt.scrollTopBeforeInput).toBeGreaterThan(0);
    expect(receipt.scrollRange).toBeGreaterThan(0);

    await expect.poll(() => scroller.evaluate((element) => element.scrollTop)).toBe(0);
    await waitForMessageScrollerEntryAnimations(page, preview);
    await waitForMessageScrollerFinalLayout(page, preview);
    expect(await scroller.evaluate((element) => element.scrollTop)).toBe(0);
  });
}


test("group chat keeps its marker anchor through Rocky's reply and reset", async ({ page }) => {
  await visit(page, "/preview/message-scroller/group-chat");
  const rows = content(page).locator("[data-slot='message-scroller-item']");

  expect(await messageIds(rows)).toEqual(["group-1", "group-2", "group-3"]);
  expect(await rows.evaluateAll((items) => items.map((item) => item.getAttribute("data-scroll-anchor")))).toEqual(
    ["false", "false", "true"],
  );
  expect(await rows.evaluateAll((items) => items.map((item) => item.querySelector("[data-slot='message-header']")?.textContent?.trim() || null))).toEqual(
    [null, "Mary (Agent)", null],
  );
  expect(await rows.evaluateAll((items) => items.map((item) => item.querySelector("[data-slot='message']")?.getAttribute("data-align")))).toEqual(
    ["end", "start", "end"],
  );
  expect(await rows.evaluateAll((items) => items.map((item) => item.querySelector("[data-slot='bubble']")?.getAttribute("data-variant")))).toEqual(
    ["muted", "ghost", "muted"],
  );

  await page.getByRole("button", { name: "Add Rocky" }).click();
  await page.getByRole("button", { name: "Reset conversation" }).hover();
  await expect(page.getByText("Reset", { exact: true })).toBeVisible();
  const marker = content(page).getByText("Rocky has joined the chat", { exact: true });
  await expect(marker).toBeVisible();
  const markerRow = marker.locator("xpath=ancestor::*[@data-slot='message-scroller-item']");
  await expect(markerRow).toHaveAttribute("data-scroll-anchor", "true");
  await expectExactStartScroll(page, markerRow, { peek: 64 });

  await page.getByRole("button", { name: "Send Message as Rocky" }).click();
  const rocky = content(page).locator("[data-message-id='group-5']");
  await expect(rocky).toBeVisible();
  await expect(rocky.locator("[data-slot='message-header']")).toHaveText("Rocky");
  await expect(rocky.locator("[data-slot='message']")).toHaveAttribute("data-align", "start");
  await expect(rocky.locator("[data-slot='bubble']")).toHaveAttribute("data-variant", "tinted");
  await expectExactStartScroll(page, markerRow, { peek: 64 });
  await expect(page.getByRole("button", { name: "Send Message as Rocky" })).toBeDisabled();

  await page.getByRole("button", { name: "Reset conversation" }).click();
  await expect(rows).toHaveCount(3);
  expect(await messageIds(rows)).toEqual(["group-1", "group-2", "group-3"]);
  await page.getByRole("button", { name: "Add Rocky" }).click();
  await expect(content(page).getByText("Rocky has joined the chat", { exact: true })).toBeVisible();
});

test("previous context uses the exact margin and peek through its busy, reply, and reset flow", async ({ page }, testInfo) => {
  const preview = "[data-preview='message-scroller']";
  await page.goto(`${testInfo.project.use.parityURL}/preview/message-scroller/previous-context`);
  await referenceReady(page);
  await waitForMessageScrollerFinalLayout(page, preview);
  await expectExactEndScroll(viewport(page));

  // A keyed React reset can resolve lazy rows differently from its first mount.
  // Read its real reset position instead of treating both openings as one state.
  await enterVisualState(page, preview, { kind: "message-scroller-action", action: "reset" });
  await waitForMessageScrollerFinalLayout(page, preview);
  const referenceResetTop = await viewport(page).evaluate((element) => element.scrollTop);

  await visit(page, "/preview/message-scroller/previous-context");
  const peek = page.getByLabel("Previous context peek");
  const rows = content(page).locator("[data-slot='message-scroller-item']");
  await expect(peek).toBeVisible();
  expect(await messageIds(rows)).toEqual(["msg-1", "msg-2"]);
  await waitForMessageScrollerEntryAnimations(page, "[data-preview='message-scroller']");
  await waitForMessageScrollerFinalLayout(page, "[data-preview='message-scroller']");
  await expectExactEndScroll(viewport(page));
  await expect(button(page)).toHaveAttribute("data-active", "false");
  await expect(button(page)).toHaveAttribute("inert", "");
  const initialTop = await viewport(page).evaluate((element) => element.scrollTop);
  await peek.press("End");
  await expect(peek).toHaveValue("128");
  await expect(page.getByText("128px", { exact: true })).toBeVisible();
  await waitForMessageScrollerFinalLayout(page, "[data-preview='message-scroller']");
  await expect.poll(() => viewport(page).evaluate((element) => element.scrollTop)).toBe(initialTop);
  await expect(button(page)).toHaveAttribute("data-active", "false");
  await expect(button(page)).toHaveAttribute("inert", "");

  const files = page.getByRole("button", { name: "Add files" });
  await files.click();
  await expect(page.getByRole("menuitem", { name: "Add Photos & Files" })).toBeVisible();
  await expect(page.getByRole("menuitem", { name: "Create Image" })).toBeVisible();
  await page.keyboard.press("Escape");

  await page.getByRole("button", { name: "Send" }).click();
  await expect(content(page)).toHaveAttribute("aria-busy", "true");
  const anchor = content(page).locator("[data-message-id='msg-3']");
  await expect(anchor).toHaveAttribute("data-scroll-anchor", "true");
  await expectExactStartScroll(page, anchor, { margin: 24, peek: 128 });
  expect(await anchor.evaluate((node) => {
    const scroller = node.closest("[data-slot='message-scroller']");
    const viewportElement = scroller.querySelector("[data-slot='message-scroller-viewport']");
    const contentElement = scroller.querySelector("[data-slot='message-scroller-content']");
    const prior = scroller.querySelector("[data-message-id='msg-2']");
    const viewportRect = viewportElement.getBoundingClientRect();
    const readingLine =
      viewportRect.top +
      (Number.parseFloat(getComputedStyle(contentElement).paddingBlockStart) || 0) +
      24 +
      128;
    const priorRect = prior.getBoundingClientRect();

    return {
      priorIsVisible: priorRect.bottom > viewportRect.top && priorRect.top < viewportRect.bottom,
      priorIsAboveReadingLine: priorRect.bottom <= readingLine,
      anchorIsAtReadingLine: Math.round(node.getBoundingClientRect().top) === Math.round(readingLine),
    };
  })).toEqual({
    priorIsVisible: true,
    priorIsAboveReadingLine: true,
    anchorIsAtReadingLine: true,
  });
  const anchoredTop = await viewport(page).evaluate((element) => element.scrollTop);
  await expect(peek).toBeDisabled();
  await expect(page.getByRole("button", { name: "Send" })).toBeDisabled();
  await expect(page.getByRole("button", { name: "Reset context example" })).toBeDisabled();

  await expect(content(page)).toHaveAttribute("aria-busy", "false");
  await expect(content(page).locator("[data-message-id='msg-4']")).toBeVisible();
  await expect.poll(() => viewport(page).evaluate((element) => element.scrollTop)).toBe(anchoredTop);

  await page.getByRole("button", { name: "Reset context example" }).click();
  await expect.poll(async () => messageIds(rows)).toEqual(["msg-1", "msg-2"]);
  await expect(peek).toHaveValue("64");
  await expect(peek).toBeEnabled();
  await expect(files).toBeEnabled();
  await expect(page.getByRole("button", { name: "Send" })).toBeEnabled();
  await expect(page.getByRole("button", { name: "Reset context example" })).toBeEnabled();
  await waitForMessageScrollerFinalLayout(page, preview);
  await expect.poll(() => viewport(page).evaluate((element) => element.scrollTop)).toBe(referenceResetTop);
});

test("streaming follows the end only until the reader scrolls away", async ({ page }) => {
  await visit(page, "/preview/message-scroller/streaming");
  await expect(page.getByText("Ready to Stream", { exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Send" }).click();
  const scroller = viewport(page);
  await expect(content(page)).toHaveAttribute("aria-busy", "true");
  await expect(content(page).getByText("That's the classic streaming scroll problem.", { exact: false })).toBeVisible();
  await expect(content(page)).toHaveAttribute("aria-busy", "false");
  await expectExactEndScroll(scroller);

  // Complete enough pinned turns to create a real reader position before the
  // next submitted message arrives.
  await page.getByRole("button", { name: "Send" }).click();
  await expect(content(page).getByText("MessageScrollerItem fixes that with turn anchoring.", { exact: false })).toBeVisible();
  await expect(content(page)).toHaveAttribute("aria-busy", "false");
  await expectExactEndScroll(scroller);

  await page.getByRole("button", { name: "Send" }).click();
  await expect(content(page).getByText("You won't. Auto-scroll only runs when the viewport is already pinned to the bottom", { exact: false })).toBeVisible();
  await expect(content(page)).toHaveAttribute("aria-busy", "false");
  await expect.poll(() => scroller.evaluate((element) => element.scrollHeight > element.clientHeight)).toBe(true);
  await expectExactEndScroll(scroller);

  await scrollTo(scroller, 0);
  await expect(button(page)).toHaveAttribute("data-active", "true");
  const before = await scroller.evaluate((element) => element.scrollTop);
  await page.getByRole("button", { name: "Send" }).click();
  await expect(content(page)).toHaveAttribute("aria-busy", "true");
  await expect.poll(() => scroller.evaluate((element) => element.scrollTop)).toBe(before);

  await button(page).click();
  await expectExactEndScroll(scroller);
});

test("opening position applies the initial last anchor and each exact tab position", async ({ page }) => {
  await visit(page, "/preview/message-scroller/opening-position");
  const scroller = viewport(page);
  const scrollerRoot = root(page);
  const anchor = content(page).locator("[data-message-id='open-3']");

  await expect(anchor).toBeVisible();
  await expect(scrollerRoot).toHaveAttribute("data-lb-message-default-position", "end");
  await expect(page.getByRole("tablist")).toHaveClass(/w-full/);
  await expect(page.getByRole("tab", { name: "last-anchor", exact: true })).toHaveAttribute("aria-selected", "true");
  // The pinned initial layout effect uses intrinsic lazy-row size. Do not
  // read aggregate geometry here: that realizes rows and changes the value
  // after the source command. The selected tab and visible anchor are the
  // stable initial contract. The explicit tab actions below stay exact.

  await page.getByRole("tab", { name: "start", exact: true }).click();
  await expect(page.getByRole("tab", { name: "start", exact: true })).toHaveAttribute("aria-selected", "true");
  await expect.poll(() => scroller.evaluate((element) => element.scrollTop)).toBe(0);

  await page.getByRole("tab", { name: "end", exact: true }).click();
  await expect(page.getByRole("tab", { name: "end", exact: true })).toHaveAttribute("aria-selected", "true");
  await expectExactEndScroll(scroller);

  await page.getByRole("tab", { name: "last-anchor", exact: true }).click();
  await expect(page.getByRole("tab", { name: "last-anchor", exact: true })).toHaveAttribute("aria-selected", "true");
  await expectExactStartScroll(page, anchor, { margin: 64 });
});

test("loading history preserves the exact visible row position and supports reset", async ({ page }) => {
  await visit(page, "/preview/message-scroller/load-history");
  const scroller = viewport(page);
  const rows = content(page).locator("[data-slot='message-scroller-item'][data-message-id]");
  expect(await messageIds(rows)).toEqual([
    "history-6",
    "history-7",
    "history-8",
    "history-9",
    "history-10",
  ]);
  await expect(content(page).getByText("End of Conversation", { exact: true })).toBeVisible();

  await scrollTo(scroller, 48);
  await expect.poll(() => scroller.evaluate((element) => element.scrollTop)).toBe(48);
  const firstVisible = await firstVisibleMessage(rows);
  expect(firstVisible).not.toBeNull();

  await page.getByRole("button", { name: "Load History" }).click();
  await expect(page.getByRole("button", { name: "History Loaded" })).toBeDisabled();
  await expect(page.getByText("History loaded", { exact: true })).toBeVisible();
  await expect(page.getByText("Scroll up to see earlier messages.", { exact: true })).toBeVisible();
  expect(await messageIds(rows)).toEqual([
    "history-1",
    "history-2",
    "history-3",
    "history-4",
    "history-5",
    "history-6",
    "history-7",
    "history-8",
    "history-9",
    "history-10",
  ]);
  const preserved = content(page).locator(`[data-message-id='${firstVisible.id}']`);
  await expect(preserved).toBeVisible();
  await expect.poll(() => preserved.evaluate((item) => {
    const viewportElement = item.closest("[data-slot='message-scroller']")
      .querySelector("[data-slot='message-scroller-viewport']");
    return Math.round(item.getBoundingClientRect().top - viewportElement.getBoundingClientRect().top);
  })).toBe(firstVisible.viewportTop);

  await page.getByRole("button", { name: "Reset loaded messages" }).click();
  await expect(page.getByRole("button", { name: "Load History" })).toBeEnabled();
  expect(await messageIds(rows)).toEqual([
    "history-6",
    "history-7",
    "history-8",
    "history-9",
    "history-10",
  ]);
  await expect(content(page).getByText("End of Conversation", { exact: true })).toBeVisible();
  await expect.poll(() => scroller.evaluate((element) => element.scrollTop)).toBe(0);
  await expect(button(page)).toHaveAttribute("data-active", "true");
  await scrollTo(scroller, 48);
  await expect.poll(() => scroller.evaluate((element) => element.scrollTop)).toBe(48);
  const reloadedVisible = await firstVisibleMessage(rows);
  expect(reloadedVisible).not.toBeNull();
  await page.getByRole("button", { name: "Load History" }).click();
  await expect(page.getByRole("button", { name: "History Loaded" })).toBeDisabled();
  const reloaded = content(page).locator(`[data-message-id='${reloadedVisible.id}']`);
  await expect.poll(() => reloaded.evaluate((item) => {
    const viewportElement = item.closest("[data-slot='message-scroller']")
      .querySelector("[data-slot='message-scroller-viewport']");
    return Math.round(item.getBoundingClientRect().top - viewportElement.getBoundingClientRect().top);
  })).toBe(reloadedVisible.viewportTop);
});

test("all animation presets run a real user entry and keep assistant rows static", async ({ page }) => {
  await page.addInitScript(() => {
    const original = Element.prototype.animate;

    Element.prototype.animate = function (keyframes, options) {
      const animation = original.call(this, keyframes, options);

      if (
        this.matches?.(
          "[data-slot=message-scroller-item][data-lb-message-animation]",
        )
      ) {
        window.__messageEntryAnimations ||= [];
        window.__messageEntryAnimations.push({
          preset: this.getAttribute("data-lb-message-animation"),
          keyframes: animation.effect?.getKeyframes().map(({ opacity, transform, filter }) => ({
            opacity,
            transform,
            filter,
          })),
          duration: animation.effect?.getComputedTiming().duration,
        });
      }

      return animation;
    };
  });

  await visit(page, "/preview/message-scroller/animation");
  await expect(page.getByText("No Messages Yet", { exact: true })).toBeVisible();

  const preset = page.getByRole("combobox", { name: "Animation preset" });
  const official = [
    ["Fade", "fade", 220],
    ["Slide Up", "slide-up", 260],
    ["Slide Side", "slide-side", 280],
    ["Pop", "pop", null],
    ["Spring Bounce", "spring-bounce", null],
    ["Blur Fade", "blur-fade", 280],
    ["Scale Fade", "scale-fade", 240],
  ];

  for (const [label, id, duration] of official) {
    await preset.click();
    await page.getByRole("option", { name: label, exact: true }).click();
    await expect(preset).toHaveText(label);

    await page.getByRole("button", { name: "Send Message" }).click();
    const user = content(page).locator("[data-message-id=msg-1]");
    await expect(user).toHaveAttribute("data-lb-message-animation", id);

    await expect
      .poll(() =>
        page.evaluate((presetId) => {
          const records = window.__messageEntryAnimations || [];

          return records.some(
            (record) =>
              record.preset === presetId &&
              record.keyframes?.some((frame) => Number(frame.opacity) === 0) &&
              record.keyframes?.some((frame) => Number(frame.opacity) === 1) &&
              Number(record.duration) > 0,
          );
        }, id),
      )
      .toBe(true);

    if (duration != null) {
      const actualDuration = await page.evaluate((presetId) => {
        const records = window.__messageEntryAnimations || [];
        return records.find(
          (record) =>
            record.preset === presetId &&
            record.keyframes?.some((frame) => frame.opacity !== undefined),
        )?.duration;
      }, id);

      expect(actualDuration).toBe(duration);
    }

    await expect(content(page)).toHaveAttribute("aria-busy", "true");
    await expect(
      content(page).getByText(
        "Yes. Animate the user row with transform and opacity",
        { exact: false },
      ),
    ).toBeVisible();
    await expect(content(page)).toHaveAttribute("aria-busy", "false");

    const assistant = content(page).locator("[data-message-id=msg-2]");
    await expect(assistant).not.toHaveAttribute("data-lb-message-animation");

    await page.getByRole("button", { name: "Reset animated messages" }).click();
    await expect(page.getByText("No Messages Yet", { exact: true })).toBeVisible();
  }
});

test("commands render the pinned transcript and jump to each anchored user message", async ({ page }) => {
  await page.addInitScript(() => {
    let socket;

    Object.defineProperty(window, "liveSocket", {
      configurable: true,
      get: () => socket,
      set: (value) => {
        const root = document.querySelector("[data-lb-message-scroller]");
        const viewport = document.querySelector("[data-lb-message-scroller-viewport]");

        window.__messageOpeningBeforeLiveSocket = {
          applied: viewport?.__liveBaseMessageOpeningApplied === true,
          rootPending: root?.hasAttribute("data-pending-scroll"),
          viewportPending: viewport?.hasAttribute("data-pending-scroll"),
          distanceToEnd:
            viewport &&
            viewport.scrollHeight - viewport.scrollTop - viewport.clientHeight,
        };
        socket = value;
      },
    });
  });

  await visit(page, "/preview/message-scroller/commands");
  expect(await page.evaluate(() => window.__messageOpeningBeforeLiveSocket)).toEqual({
    applied: true,
    rootPending: true,
    viewportPending: true,
    distanceToEnd: 0,
  });
  await waitForMessageScrollerFinalLayout(page, "[data-preview='message-scroller']");
  const opening = await viewport(page).evaluate((element) => ({
    top: element.scrollTop,
    end: Math.max(0, element.scrollHeight - element.clientHeight),
    pending: element.hasAttribute("data-pending-scroll"),
  }));
  expect(opening.pending).toBe(false);
  expect(opening.end).toBeGreaterThan(0);
  expect(opening.top).toBe(opening.end);
  await expect(button(page)).toHaveAttribute("data-active", "false");
  await expect(button(page)).toHaveAttribute("inert", "");
  const scroller = root(page);
  const transcript = content(page);
  const rows = transcript.locator("[data-slot='message-scroller-item']");
  const ids = ["command-activation", "msg-1", "command-compare", "msg-2", "command-experiment", "msg-3", "command-risk", "msg-4"];

  await expect(rows).toHaveCount(8);
  expect(await rows.evaluateAll((items) => items.map((item) => item.getAttribute("data-message-id")))).toEqual(ids);
  expect(await rows.evaluateAll((items) => items.map((item) => item.getAttribute("data-scroll-anchor")))).toEqual(["true", "false", "true", "false", "true", "false", "true", "false"]);
  expect(await rows.evaluateAll((items) => items.map((item) => item.querySelector("[data-slot='message']")?.getAttribute("data-align")))).toEqual(["end", "start", "end", "start", "end", "start", "end", "start"]);
  expect(await rows.evaluateAll((items) => items.map((item) => item.querySelector("[data-slot='bubble']")?.getAttribute("data-variant")))).toEqual(["muted", "ghost", "muted", "ghost", "muted", "ghost", "muted", "ghost"]);
  await expect(scroller).toHaveAttribute("data-lb-message-default-position", "end");
  await expect(viewport(page)).toHaveAttribute("role", "region");
  await expect(viewport(page)).toHaveAttribute("aria-label", "Messages");
  await expect(transcript).toHaveAttribute("role", "log");
  await expect(transcript).toHaveAttribute("aria-relevant", "additions");
  await expect(transcript.getByText("The sharpest drop is between creating the workspace and inviting the first teammate.", { exact: true })).toBeVisible();
  await expect(transcript.getByText("Compare three cohorts:", { exact: true })).toBeVisible();
  await expect(transcript.getByText("Yes. Create a variant that shows a short checklist after workspace creation:", { exact: true })).toBeVisible();
  await expect(transcript.getByText("The main risk is reducing team creation for accounts that already know who they want to invite.", { exact: true })).toBeVisible();

  const trigger = page.getByRole("button", { name: "Jump to..." });
  const commands = [
    ["We're seeing activation dip after works...", "command-activation"],
    ["What should I compare before we change ...", "command-compare"],
    ["Can you turn that into an experiment?", "command-experiment"],
    ["What's the risk if we delay the invite ...", "command-risk"],
  ];

  for (const [label, id] of commands) {
    await trigger.click();
    await expect(trigger).toHaveAttribute("aria-expanded", "true");
    await expect(page.getByText("Conversations", { exact: true })).toBeVisible();
    await expect(page.getByRole("menuitem")).toHaveCount(4);
    await page.getByRole("menuitem", { name: label, exact: true }).click();
    await expect(trigger).toHaveAttribute("aria-expanded", "false");

    const target = transcript.locator(`[data-message-id='${id}']`);
    await expect(target).toBeVisible();
    const targetTop = await expectExactStartScroll(page, target);
    const endTop = await endScrollTop(viewport(page));
    const threshold = Number(await scroller.getAttribute("data-lb-message-scroll-edge-threshold"));
    const active = endTop - targetTop > threshold;

    await expect(button(page)).toHaveAttribute("data-active", String(active));
    await expect(button(page)).toHaveAttribute("tabindex", active ? "0" : "-1");
  }
});

test("visibility renders the pinned transcript and updates its outline target state", async ({ page }) => {
  await visit(page, "/preview/message-scroller/visibility");
  const scroller = root(page);
  const transcript = content(page);
  const rows = transcript.locator("[data-slot='message-scroller-item']");
  const ids = [
    "vis-brief",
    "msg-1",
    "vis-impact",
    "msg-2",
    "vis-actions",
    "msg-3",
    "vis-checklist",
    "msg-4",
  ];
  const choices = [
    ["Review the incident handoff and tell me...", "vis-brief"],
    ["What was the customer impact?", "vis-impact"],
    ["What actions are open?", "vis-actions"],
    ["Give me the follow-up checklist.", "vis-checklist"],
  ];

  await expect(rows).toHaveCount(8);
  expect(await rows.evaluateAll((items) => items.map((item) => item.getAttribute("data-message-id")))).toEqual(ids);
  expect(await rows.evaluateAll((items) => items.map((item) => item.getAttribute("data-scroll-anchor")))).toEqual(["true", "false", "true", "false", "true", "false", "true", "false"]);
  await expect(scroller).toHaveAttribute("data-lb-message-default-position", "end");
  await expect(scroller).toHaveAttribute("data-lb-message-scroll-margin", "12");
  await expect(transcript).toContainText("Start with the summary and the impact section. The regression affected the upload queue, but the recovery path completed for every queued job.");
  await expect(transcript).toContainText("Impact was limited to delayed processing.");
  await expect(transcript).toContainText("The alert should fire on sustained queue growth, not a single short spike.");

  const outline = page.getByRole("button", { name: "Open transcript outline" });
  const bars = page.locator("[data-message-scroller-outline-bar]");
  const currentChoice = page.locator("[data-message-scroller-outline-choice][aria-current='location']");
  await expect(bars).toHaveCount(4);
  // The pinned initial state uses intrinsic lazy-row layout. Reading aggregate
  // scroll geometry realizes the skipped rows and changes that state. The
  // active outline choice is the stable initial contract. Explicit user scroll
  // and outline requests below still use exact geometry checks.
  await expect.poll(() => currentChoice.getAttribute("data-message-scroller-anchor-id")).toBe("vis-checklist");
  await expect(page.locator("#message-scroller-visibility-bar-vis-checklist")).toHaveAttribute("data-current", "true");
  await expect(currentChoice).toHaveCount(1);
  expect(await bars.evaluateAll((items) => items.filter((item) => item.getAttribute("data-current") === "true").length)).toBe(1);

  for (const [, id] of choices) {
    const target = transcript.locator(`[data-message-id='${id}']`);
    const top = await exactStartScrollTop(target, { margin: 12 });
    await scrollTo(viewport(page), top);
    await expect.poll(() => viewport(page).evaluate((element) => element.scrollTop)).toBe(top);

    await expect.poll(() => currentChoice.getAttribute("data-message-scroller-anchor-id")).toBe(id);
    await expect(currentChoice).toHaveCount(1);
    await expect(page.locator(`#message-scroller-visibility-bar-${id}`)).toHaveAttribute("data-current", "true");
    expect(await bars.evaluateAll((items) => items.filter((item) => item.getAttribute("data-current") === "true").length)).toBe(1);
  }

  const outlinePopup = page.locator(`#${await outline.getAttribute("aria-controls")}`);
  await page.mouse.move(0, 0);
  await expect(outlinePopup).toBeHidden();
  await outline.scrollIntoViewIfNeeded();
  const outlineBox = await outline.boundingBox();
  expect(outlineBox).not.toBeNull();
  await page.mouse.click(outlineBox.x + outlineBox.width / 2, outlineBox.y + outlineBox.height / 2);
  await expect(outlinePopup).toBeVisible();
  await outlinePopup.hover();
  await expect(outlinePopup).toBeVisible();

  for (const [label, id] of choices) {
    const choice = page.getByRole("button", { name: label, exact: true });
    if (!(await choice.isVisible())) {
      await outline.hover();
      await expect(choice).toBeVisible();
    }
    await choice.click();
    await expect(choice).toHaveAttribute("aria-current", "location");
    await expect(currentChoice).toHaveCount(1);
    await expect(page.locator(`#message-scroller-visibility-bar-${id}`)).toHaveAttribute("data-current", "true");

    const target = transcript.locator(`[data-message-id='${id}']`);
    await expect(target).toBeVisible();
    await expectExactStartScroll(page, target, { margin: 12 });
    expect(await bars.evaluateAll((items) => items.filter((item) => item.getAttribute("data-current") === "true").length)).toBe(1);

    if (id === choices[0][1]) {
      await page.keyboard.press("Escape");
      await expect(outlinePopup).toBeHidden();
    }
  }
});

test("scrollable matches the pinned transcript and reports native scroll state", async ({ page }) => {
  await visit(page, "/preview/message-scroller/scrollable");
  const transcript = content(page);
  const scroller = viewport(page);
  const rows = transcript.locator("[data-slot='message-scroller-item']");
  const ids = Array.from({ length: 12 }, (_, index) => `scrollable-${index + 1}`);
  const anchors = Array.from({ length: 12 }, (_, index) => String(index % 2 === 0));
  const alignments = Array.from({ length: 12 }, (_, index) => (index % 2 === 0 ? "end" : "start"));
  const variants = Array.from({ length: 12 }, (_, index) => (index % 2 === 0 ? "muted" : "ghost"));
  const statuses = [
    "You can scroll both ways.",
    "You are at the top. You can only scroll down.",
    "You are at the bottom. You can only scroll up.",
    "All messages fit in the viewport.",
  ];

  const assistantParagraphs = (index) => [
    `Checkpoint ${index} is synced. The scrollable hook updates as the viewport moves.`,
    "When the reader is at the first message, the footer should only point them down. Once they move into the middle of the transcript, it should explain that both directions are available.",
    "At the latest message, the footer should switch again and only point them back up.",
  ];

  await expect(rows).toHaveCount(12);
  expect(await rows.evaluateAll((items) => items.map((item) => item.getAttribute("data-message-id")))).toEqual(ids);
  expect(await rows.evaluateAll((items) => items.map((item) => item.getAttribute("data-scroll-anchor")))).toEqual(anchors);
  expect(await rows.evaluateAll((items) => items.map((item) => item.querySelector("[data-slot='message']")?.getAttribute("data-align")))).toEqual(alignments);
  expect(await rows.evaluateAll((items) => items.map((item) => item.querySelector("[data-slot='bubble']")?.getAttribute("data-variant")))).toEqual(variants);
  expect(await rows.evaluateAll((items) => items.map((item) => item.querySelectorAll("[data-slot='bubble-content'] p").length))).toEqual(
    Array.from({ length: 12 }, (_, index) => (index % 2 === 0 ? 1 : 3)),
  );
  expect(await page.locator("[data-lb-message-scroll-status]").allTextContents()).toEqual(statuses);

  for (let index = 1; index <= 12; index += 1) {
    const paragraphs = await rows
      .nth(index - 1)
      .locator("[data-slot='bubble-content'] p")
      .allTextContents();

    expect(paragraphs.map((paragraph) => paragraph.trim())).toEqual(
      index % 2 === 1 ? [`Review scroll checkpoint ${index}.`] : assistantParagraphs(index),
    );
  }

  await expect(root(page)).toHaveAttribute("data-lb-message-default-position", "start");
  await expect.poll(() => scroller.evaluate((element) => element.scrollTop)).toBe(0);
  await expect(root(page).locator("[data-slot='message-scroller-button']")).toHaveCount(1);
  await expect(root(page).locator("[data-slot='message-scroller-button'][data-direction='end']")).toHaveCount(1);
  await expect(root(page).locator("[data-slot='message-scroller-button'][data-direction='start']")).toHaveCount(0);

  await expect(page.getByText("You are at the top. You can only scroll down.", { exact: true })).toBeVisible();
  await expect(button(page, "end")).toHaveAttribute("tabindex", "0");

  await scrollTo(scroller, Math.floor((await scroller.evaluate((element) => element.scrollHeight - element.clientHeight)) / 2));
  await expect(page.getByText("You can scroll both ways.", { exact: true })).toBeVisible();
  await expect(button(page, "end")).toHaveAttribute("tabindex", "0");

  await scrollTo(scroller, await scroller.evaluate((element) => element.scrollHeight));
  await expect(page.getByText("You are at the bottom. You can only scroll up.", { exact: true })).toBeVisible();
  await expect(button(page, "end")).toHaveAttribute("tabindex", "-1");
});
