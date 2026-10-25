import { expect, test } from "@playwright/test";

import { discoverInteractionProbes, enterInteractionProbe } from "./interaction-parity.mjs";
import { connected, referenceReady, slowAnimationFrames, visit } from "./live.mjs";

const standardExamples = [
  ["default", "drawer-demo", "Open Drawer"],
  ["sides", "drawer-sides", "Open Left Drawer"],
  ["swipe-handle", "drawer-swipe-handle", "Open Drawer"],
];

const nestedTitles = ["Drawer", "Nested Drawer", "Third Drawer", "Fourth Drawer"];
const nestedTriggers = ["Open Drawer", "Open Nested Drawer", "Open Third Drawer", "Open Fourth Drawer"];

function nestedPopups(page, selector = "[data-slot='drawer-popup']") {
  return nestedTitles.map((title) => page.locator(selector).filter({
    has: page.locator("[data-slot='drawer-title']", { hasText: new RegExp(`^\\s*${title}\\s*$`) }),
  }));
}

async function visitSide(page, testInfo, side, example) {
  const path = `/preview/drawer/${example}`;
  await page.goto(side === "Phoenix" ? path : `${testInfo.project.use.parityURL}${path}`);
  if (side === "Phoenix") await connected(page);
  else await referenceReady(page);
}

async function popupEntryFinished(popup) {
  await popup.evaluate(async (element) => {
    // LiveView focus commands repeat after two frames for show/hide chains.
    await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)));
    await Promise.all(element.getAnimations({ subtree: true })
      .filter((animation) => Number.isFinite(animation.effect?.getComputedTiming().endTime))
      .map((animation) => animation.finished.catch(() => {})));
  });
}

for (const side of ["React", "Phoenix"]) {
  for (const [example, , triggerName] of standardExamples) {
    test(`${example} opens and closes through its public controls on ${side}`, async ({ page }, testInfo) => {
      await visitSide(page, testInfo, side, example);
      const trigger = page.locator("[data-slot='drawer-trigger']");
      const popup = page.locator("[data-slot='drawer-popup']");

      await trigger.click();
      await expect(popup).toBeVisible();
      await expect(popup).toHaveRole("dialog");
      await expect(trigger).toHaveAttribute("aria-expanded", "true");
      await expect(popup).toBeFocused();
      await expect(page.getByRole("button", { name: triggerName, exact: true })).toHaveCount(0);
      if (example === "default") {
        await expect(page.getByRole("region", { name: /^Notifications/ })).toHaveCount(1);
      }

      await popup.getByRole("button", { name: /^(Cancel|Close)$/ }).click();
      await expect(popup).toBeHidden();
      await expect(trigger).toHaveAttribute("aria-expanded", "false");
      await expect(trigger).toBeFocused();
      await expect(page.getByRole("button", { name: triggerName, exact: true })).toBeVisible();
    });
  }
}

test("snap-points opens at its compact point and closes with Escape", async ({ page }) => {
  await visit(page, "/preview/drawer/snap-points", "#drawer-snap-points-trigger");

  const trigger = page.getByRole("button", { name: "Open Snap Drawer", exact: true });
  const popup = page.locator("#drawer-snap-points-popup");

  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(popup).toHaveRole("dialog");
  await popupEntryFinished(popup);

  await page.keyboard.press("Escape");
  await expect(popup).toBeHidden();
  await expect(trigger).toBeFocused();
});

test("non-modal keeps the page active and ignores outside pointers", async ({ page }) => {
  await visit(page, "/preview/drawer/non-modal", "#drawer-non-modal-trigger");

  const trigger = page.getByRole("button", { name: "Non Modal", exact: true });
  const popup = page.locator("#drawer-non-modal-popup");

  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(page.locator("#drawer-non-modal-backdrop")).toHaveCount(0);
  await expect(popup).toBeFocused();
  await expect(page.getByRole("button", { name: "Non Modal", exact: true })).toBeVisible();
  await expect.poll(() => page.evaluate(() => document.body.style.overflow)).toBe("");

  await page.mouse.click(20, 20);
  await expect(popup).toBeVisible();

  await popup.getByRole("button", { name: "Close", exact: true }).click();
  await expect(popup).toBeHidden();
  await expect(trigger).toBeFocused();
});

for (const side of ["React", "Phoenix"]) {
  test(`nested Tab and Escape preserve front access and size after parent resize on ${side}`, async ({ page }, testInfo) => {
    await visitSide(page, testInfo, side, "nested");
    const popups = nestedPopups(page);
    const triggerNames = nestedTriggers;

    for (let index = 0; index < popups.length; index += 1) {
      await page.getByRole("button", { name: triggerNames[index], exact: true }).click();
      const popup = popups[index];
      await expect(popup).toBeVisible();
      await expect(popup).toBeFocused();
      await popupEntryFinished(popup);
      const close = popup.getByRole("button", { name: "Close", exact: true });
      await page.keyboard.press("Tab");
      if (index < popups.length - 1) {
        const next = popup.getByRole("button", { name: triggerNames[index + 1], exact: true });
        await expect(next).toBeFocused();
        await page.keyboard.press("Tab");
        await expect(close).toBeFocused();
        await page.keyboard.press("Shift+Tab");
        await expect(next).toBeFocused();
        await page.keyboard.press("Shift+Tab");
      }
      await expect(close).toBeFocused();
    }
    await expect(page.getByRole("dialog")).toHaveCount(1);
    await expect(page.getByRole("button", { name: "Open Drawer", exact: true })).toHaveCount(0);

    await expect(popups[0]).toHaveAttribute("data-nested-drawer-open", "");
    await expect(popups[0]).toHaveCSS("--nested-drawers", "3");
    // A caller can change popup width while its nested drawers remain open.
    await popups[0].evaluate((element) => { element.style.width = "400px"; });
    for (let index = popups.length - 1; index >= 0; index -= 1) {
      await page.keyboard.press("Escape");
      await expect(popups[index]).toBeHidden();
      if (index > 0) {
        await expect(popups[index - 1]).toBeVisible();
        await expect(popups[index - 1].getByRole("button", { name: triggerNames[index], exact: true })).toBeFocused();
        await expect(page.getByRole("dialog")).toHaveCount(1);
        if (index === 1) {
          await popupEntryFinished(popups[0]);
          await expect.poll(() => popups[0].evaluate((element) =>
            element.getBoundingClientRect().height,
          )).toBe(page.viewportSize().height);
        }
      }
    }
    await expect(page.getByRole("button", { name: "Open Drawer", exact: true })).toBeFocused();
    await expect.poll(() => page.evaluate(() => document.body.style.overflow)).toBe("");
  });
}

for (const host of ["React", "Phoenix preview", "Phoenix docs"]) {
  test(`nested mobile direction and swipe preserve state across the breakpoint on ${host}`, async ({ page }, testInfo) => {
    await page.setViewportSize({ width: 390, height: 844 });
    if (host === "Phoenix docs") await visit(page, "/docs/drawer", "#drawer-nested-trigger");
    else await visitSide(page, testInfo, host === "React" ? "React" : "Phoenix", "nested");
    const popups = nestedPopups(page, host === "Phoenix docs"
      ? "[data-slot='drawer-popup'][id^='drawer-nested']" : undefined);
    const trigger = host === "React"
      ? page.getByRole("button", { name: "Open Drawer", exact: true })
      : page.locator("#drawer-nested-trigger");
    if (host !== "React") await expect(popups[0]).toHaveAttribute("data-swipe-direction", "down");

    for (let index = 0; index < popups.length; index += 1) {
      await (index === 0 ? trigger : popups[index - 1].getByRole("button", {
        name: nestedTriggers[index], exact: true,
      })).click();
      await expect(popups[index]).toBeVisible();
      await popupEntryFinished(popups[index]);
      await expect(popups[index]).toHaveAttribute("data-swipe-direction", "down");
      await expect(popups[index]).toHaveAttribute("data-swipe-axis", "y");
      await expect(popups[index].locator("[data-slot='drawer-swipe-handle']")).toBeVisible();
    }

    for (const [width, direction, axis] of [[768, "right", "x"], [767, "down", "y"]]) {
      await page.setViewportSize({ width, height: 844 });
      for (const popup of popups) {
        await expect(popup).toBeVisible();
        await expect(popup).toHaveAttribute("data-swipe-direction", direction);
        await expect(popup).toHaveAttribute("data-swipe-axis", axis);
        if (direction === "down") await expect(popup.locator("[data-slot='drawer-swipe-handle']")).toBeVisible();
        else await expect(popup.locator("[data-slot='drawer-swipe-handle']")).toBeHidden();
      }
      await expect(popups[3]).toBeFocused();
      await expect(page.getByRole("dialog")).toHaveCount(1);
      await popupEntryFinished(popups[3]);
    }

    await dragBy(page, popups[3].locator("[data-slot='drawer-swipe-handle']"), 0, 240);
    await expect(popups[3]).toBeHidden();
    await expect(popups[2].getByRole("button", { name: "Open Fourth Drawer", exact: true })).toBeFocused();
    for (let index = 2; index >= 0; index -= 1) {
      await page.keyboard.press("Escape");
      await expect(popups[index]).toBeHidden();
    }
    await expect(trigger).toBeFocused();
    await expect.poll(() => page.evaluate(() => document.body.style.overflow)).toBe("");
  });
}

test("modal background attributes follow document changes and restore on close", async ({ page }) => {
  await visit(page, "/preview/drawer/default", "#drawer-demo-trigger");
  await page.evaluate(() => {
    for (const [id, value] of [["authored-false", "false"], ["authored-true", "true"]]) {
      const node = document.createElement("aside");
      node.id = id;
      node.setAttribute("aria-hidden", value);
      node.textContent = id;
      document.body.append(node);
    }
    document.body.style.overflow = "scroll";
    document.body.style.paddingRight = "7px";
  });
  const trigger = page.locator("#drawer-demo-trigger");
  await trigger.click();
  await expect(page.locator("#authored-false")).toHaveAttribute("aria-hidden", "true");
  await expect(page.getByRole("region", { name: /^Notifications/ })).toHaveCount(1);
  await page.evaluate(() => {
    document.querySelector("#authored-false").setAttribute("aria-hidden", "false");
    const node = document.createElement("aside");
    node.id = "late-background";
    node.textContent = "Added while the modal is open";
    document.body.append(node);
  });
  await expect(page.locator("#authored-false")).toHaveAttribute("aria-hidden", "true");
  await expect(page.locator("#late-background")).toHaveAttribute("aria-hidden", "true");
  await page.keyboard.press("Escape");
  await expect(page.locator("#drawer-demo-popup")).toBeHidden();
  await expect(page.locator("#authored-false")).toHaveAttribute("aria-hidden", "false");
  await expect(page.locator("#authored-true")).toHaveAttribute("aria-hidden", "true");
  await expect(page.locator("#late-background")).not.toHaveAttribute("aria-hidden", /.*/);
  await expect(trigger).toBeFocused();
  await expect.poll(() => page.evaluate(() => [document.body.style.overflow, document.body.style.paddingRight])).toEqual(["scroll", "7px"]);
});

test("modal locks survive an earlier close and release when the view is removed", async ({ page }) => {
  await visit(page, "/docs/drawer", "#drawer-demo-trigger");
  await page.evaluate(() => {
    document.body.style.overflow = "scroll";
    document.body.style.paddingRight = "7px";
  });
  await page.locator("#drawer-demo-trigger").click();
  await expect(page.locator("#drawer-demo-popup")).toBeVisible();
  // An application can open another root while a modal is already open.
  await page.locator("#drawer-swipe-handle-trigger").evaluate((element) => element.click());
  const front = page.locator("#drawer-swipe-handle-popup");
  await expect(front).toBeVisible();
  await page.locator("#drawer-demo-popup [data-slot='drawer-close']").evaluate((element) => element.click());
  await expect(page.locator("#drawer-demo-popup")).toBeHidden();
  await expect(front).toBeVisible();
  await expect(page.getByRole("dialog")).toHaveCount(1);
  await expect.poll(() => page.evaluate(() => document.body.style.overflow)).toBe("hidden");
  await page.keyboard.press("Tab");
  await expect(front.getByRole("button", { name: "Close", exact: true })).toBeFocused();
  await page.keyboard.press("Escape");
  await expect(front).toBeHidden();
  await expect.poll(() => page.evaluate(() => [document.body.style.overflow, document.body.style.paddingRight])).toEqual(["scroll", "7px"]);

  await page.locator("#drawer-demo-trigger").click();
  await expect(page.locator("#drawer-demo-popup")).toBeVisible();
  // Live navigation destroys the old view and its portalled popup hooks.
  await page.locator("a[href='/docs/button']").first().evaluate((element) => element.click());
  await expect(page).toHaveURL(/\/docs\/button$/);
  await connected(page);
  await expect(page.locator("#drawer-demo-popup")).toHaveCount(0);
  await expect.poll(() => page.evaluate(() => [document.body.style.overflow, document.body.style.paddingRight])).toEqual(["scroll", "7px"]);
});

test("swipe handle closes the drawer after a downward drag", async ({ page }) => {
  await visit(page, "/preview/drawer/swipe-handle", "#drawer-swipe-handle-trigger");

  const trigger = page.getByRole("button", { name: "Open Drawer", exact: true });
  const popup = page.locator("#drawer-swipe-handle-popup");
  const handle = popup.locator("[data-slot='drawer-swipe-handle']");

  await trigger.click();
  await expect(popup).toBeVisible();

  const box = await handle.boundingBox();
  expect(box).not.toBeNull();
  const x = box.x + box.width / 2;
  const y = box.y + box.height / 2;

  await page.mouse.move(x, y);
  await page.mouse.down();
  await page.mouse.move(x, y + 240, { steps: 5 });
  await expect(popup).toHaveAttribute("data-swiping", "");
  await page.mouse.up();

  await expect(popup).toBeHidden();
  await expect(trigger).toBeFocused();
});

test("snap points move between compact and full states", async ({ page }) => {
  await visit(page, "/preview/drawer/snap-points", "#drawer-snap-points-trigger");

  const trigger = page.getByRole("button", { name: "Open Snap Drawer", exact: true });
  const popup = page.locator("#drawer-snap-points-popup");
  const handle = popup.locator("[data-slot='drawer-swipe-handle']");
  const overlay = page.locator("#drawer-snap-points-backdrop");

  await trigger.click();
  await expect(popup).toBeVisible();
  await expect.poll(() => snapOffset(popup)).toBeGreaterThan(0);
  await expect(overlay).toHaveCSS("opacity", "0.5");

  await dragBy(page, handle, 0, -160);
  await expect.poll(() => snapOffset(popup)).toBe(0);
  await expect(overlay).toHaveCSS("opacity", "1");

  await dragBy(page, handle, 0, 160);
  await expect.poll(() => snapOffset(popup)).toBeGreaterThan(0);
  await expect(popup).toBeVisible();
  await popupEntryFinished(popup);

  await dragBy(page, handle, 0, 240);
  await expect(popup).toBeHidden();
  await expect(trigger).toBeFocused();
});

test("responsive example uses a dialog on desktop", async ({ page }) => {
  await visit(page, "/preview/drawer/dialog", "#drawer-dialog-responsive");

  const desktop = page.locator("[data-lb-desktop]");
  const mobile = page.locator("[data-lb-mobile]");
  const trigger = desktop.getByRole("button", { name: "Edit Profile", exact: true });
  const popup = page.locator("#drawer-dialog-desktop-popup");

  await expect(desktop).toBeVisible();
  await expect(mobile).toBeHidden();
  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(popup).toHaveRole("dialog");
  await expect(popup.getByLabel("Email")).toHaveValue("shadcn@example.com");
  await expect(popup.getByLabel("Username")).toHaveValue("@shadcn");
  await expect(popup.getByLabel("Email")).toBeFocused();
  await page.keyboard.press("Escape");
  await expect(popup).toBeHidden();
  await expect(trigger).toBeFocused();
});

test("responsive example uses a drawer on a small screen", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await visit(page, "/preview/drawer/dialog", "#drawer-dialog-responsive");

  const desktop = page.locator("[data-lb-desktop]");
  const mobile = page.locator("[data-lb-mobile]");
  const trigger = mobile.getByRole("button", { name: "Edit Profile", exact: true });
  const popup = page.locator("#drawer-dialog-mobile-popup");

  await expect(desktop).toBeHidden();
  await expect(mobile).toBeVisible();
  await trigger.click();
  await expect(popup).toBeVisible();
  await expect(popup).toHaveRole("dialog");
  await expect(popup).toHaveAttribute("data-swipe-direction", "down");
  await expect(popup).toBeFocused();
  await expect(popup.getByLabel("Email")).toHaveValue("shadcn@example.com");
  await expect(popup.getByLabel("Username")).toHaveValue("@shadcn");
  await page.keyboard.press("Escape");
  await expect(popup).toBeHidden();
  await expect(trigger).toBeFocused();
});

for (const side of ["React", "Phoenix"]) {
  for (const [id, label] of [
    ["delivery-asap", "Standard delivery"],
    ["delivery-5-30", "5:30 PM – 5:45 PM"],
  ]) {
    test(`default confirms ${id} with a notice on ${side}`, async ({ page }, testInfo) => {
      await visitSide(page, testInfo, side, "default");

      const trigger = page.getByRole("button", { name: "Open Drawer", exact: true });
      const popup = page.locator("[data-slot='drawer-popup']");
      const selected = page.locator(`#${id}`);
      await trigger.click();
      await expect(page.locator("#delivery-asap")).toBeChecked();
      if (id !== "delivery-asap") {
        await page.locator(`label[for='${id}']`).click();
        await expect(selected).toBeChecked();
        await expect(page.locator("#delivery-asap")).not.toBeChecked();
      }

      await popup.getByRole("button", { name: "Confirm Delivery Time", exact: true }).click();
      await expect(popup).toBeHidden();
      await expect(trigger).toBeFocused();
      const notice = page.locator("[data-sonner-toast]");
      await expect(notice.locator("[data-title]")).toHaveText("Delivery time confirmed", { timeout: 2000 });
      await expect(notice.locator("[data-description]")).toHaveText(label);

      await trigger.click();
      await expect(selected).toBeChecked();
      await page.keyboard.press("Escape");
      await expect(popup).toBeHidden();
      await expect(trigger).toBeFocused();
    });
  }
}

for (const side of ["React", "Phoenix"]) {
  test(`modal closes during entry and returns focus after an outside pointer on ${side}`, async ({ page }, testInfo) => {
    await slowAnimationFrames(page);
    await visitSide(page, testInfo, side, "default");
    const trigger = page.locator("[data-slot='drawer-trigger']");
    const popup = page.locator("[data-slot='drawer-popup']");
    await trigger.click();
    await expect(popup).toBeVisible();
    await page.mouse.click(20, 20);
    await expect(popup).toBeHidden();
    await expect(trigger).toBeFocused();
  });
}

async function dragBy(page, locator, deltaX, deltaY) {
  const box = await locator.boundingBox();
  expect(box).not.toBeNull();
  const x = box.x + box.width / 2;
  const y = box.y + box.height / 2;

  await page.mouse.move(x, y);
  await page.mouse.down();
  await page.mouse.move(x + deltaX, y + deltaY, { steps: 5 });
  await page.mouse.up();
}

async function snapOffset(locator) {
  return locator.evaluate((element) =>
    Number.parseFloat(getComputedStyle(element).getPropertyValue("--drawer-snap-point-offset")),
  );
}

for (const side of ["React", "Phoenix"]) {
  test(`a modal disclosure probe keeps its original trigger on ${side}`, async ({ page }, testInfo) => {
    await visitSide(page, testInfo, side, "default");
    const scope = page.locator("[data-preview='drawer']");
    const probes = await discoverInteractionProbes(scope);
    const probe = probes.find(({ kind }) => kind === "disclosure");
    expect(probe).toBeDefined();
    const result = await enterInteractionProbe(page, scope, probe);
    expect(result.opened.target.expanded).toBe("true");
    expect(result.opened.popup).toEqual({ role: "dialog", visible: true, expanded: null });
    expect(result.closed.target.expanded).toBe("false");
    expect(result.closed.popup).toBeNull();
    await expect(scope.getByRole("button", { name: "Open Drawer", exact: true })).toBeFocused();
  });
}
