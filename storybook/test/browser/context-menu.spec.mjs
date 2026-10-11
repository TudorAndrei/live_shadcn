import { expect, test } from "@playwright/test";

import { connected, visit } from "./live.mjs";

const examples = [
  ["default", "context-menu-demo"],
  ["basic", "context-menu-basic"],
  ["submenu", "context-menu-submenu"],
  ["shortcuts", "context-menu-shortcuts"],
  ["groups", "context-menu-groups"],
  ["icons", "context-menu-icons"],
  ["checkboxes", "context-menu-checkboxes"],
  ["radio", "context-menu-radio"],
  ["destructive", "context-menu-destructive"],
  ["rtl", "context-menu-rtl"],
];

for (const [example, id] of examples) {
  test(`${example} opens on right click and closes outside`, async ({ page }) => {
    await visit(page, `/preview/context-menu/${example}`, `#${id}-trigger`);

    const trigger = page.locator(`#${id}-trigger`);
    const popup = page.locator(`#${id}-popup`);

    await trigger.click({ button: "left" });
    await expect(popup).toBeHidden();

    await trigger.click({ button: "right" });
    await expect(popup).toBeVisible();
    await expect(popup).toHaveRole("menu");
    await expect(page.getByRole("heading", { name: "context-menu", exact: true })).toHaveCount(0);
    await expect(page.getByRole("menu")).toHaveCount(1);

    await page.locator("body").click({ position: { x: 5, y: 5 } });
    await expect(popup).toBeHidden();
    await expect(page.getByRole("heading", { name: "context-menu", exact: true })).toHaveCount(1);
  });
}

test("the menu opens at the context gesture point", async ({ page }) => {
  await visit(page, "/preview/context-menu/basic", "#context-menu-basic-trigger");

  const trigger = page.locator("#context-menu-basic-trigger");
  const triggerBox = await trigger.boundingBox();
  expect(triggerBox).not.toBeNull();

  const click = { x: 48, y: 36 };
  await trigger.click({ button: "right", position: click });

  const point = {
    x: triggerBox.x + click.x,
    y: triggerBox.y + click.y,
  };
  const popup = page.locator("#context-menu-basic-popup");

  await expect
    .poll(async () => {
      const popupBox = await popup.boundingBox();

      if (popupBox === null) {
        return Number.POSITIVE_INFINITY;
      }

      return Math.max(
        Math.abs(popupBox.x - point.x),
        Math.abs(popupBox.y - point.y),
      );
    })
    .toBeLessThanOrEqual(8);
});

test("the keyboard skips the disabled Forward item", async ({ page }) => {
  await visit(page, "/preview/context-menu/basic", "#context-menu-basic-trigger");

  const popup = page.locator("#context-menu-basic-popup");
  await page.locator("#context-menu-basic-trigger").click({ button: "right" });
  await expect(popup).toBeFocused();

  await page.keyboard.press("ArrowDown");
  await expect(page.locator("#context-menu-basic-item-back")).toBeFocused();
  await page.keyboard.press("ArrowDown");
  await expect(page.locator("#context-menu-basic-item-reload")).toBeFocused();
  await page.keyboard.press("Enter");
  await expect(popup).toBeHidden();
});

test("checkbox and radio items change state without closing", async ({ page }) => {
  await visit(page, "/preview/context-menu/checkboxes", "#context-menu-checkboxes-trigger");
  await page.locator("#context-menu-checkboxes-trigger").click({ button: "right" });

  const checkboxPopup = page.locator("#context-menu-checkboxes-popup");
  const urls = page.locator("#context-menu-checkboxes-item-urls");
  await expect(urls).toHaveAttribute("aria-checked", "false");
  await urls.click();
  await expect(urls).toHaveAttribute("aria-checked", "true");
  await expect(checkboxPopup).toBeVisible();

  await page.locator("body").click({ position: { x: 5, y: 5 } });
  await visit(page, "/preview/context-menu/radio", "#context-menu-radio-trigger");
  await page.locator("#context-menu-radio-trigger").click({ button: "right" });

  const radioPopup = page.locator("#context-menu-radio-popup");
  const pedro = page.locator("#context-menu-radio-item-pedro");
  const colm = page.locator("#context-menu-radio-item-colm");
  await colm.click();
  await expect(colm).toHaveAttribute("aria-checked", "true");
  await expect(pedro).toHaveAttribute("aria-checked", "false");
  await expect(radioPopup).toBeVisible();
});

test("the submenu stays in the root branch and closes outside", async ({ page }) => {
  await visit(page, "/preview/context-menu/submenu", "#context-menu-submenu-trigger");
  await page.locator("#context-menu-submenu-trigger").click({ button: "right" });

  const root = page.locator("#context-menu-submenu-popup");
  const subTrigger = page.locator("#context-menu-submenu-more-tools-trigger");
  const submenu = page.locator("#context-menu-submenu-more-tools-popup");

  await subTrigger.click();
  await expect(root).toBeVisible();
  await expect(submenu).toBeVisible();
  await expect(root).toHaveAccessibleName("");
  await expect(submenu).toHaveAccessibleName("More Tools");
  await expect(subTrigger).toHaveAttribute("aria-expanded", "true");
  await expect(page.getByRole("menuitem", { name: "Delete" })).toHaveAttribute(
    "data-variant",
    "destructive",
  );

  await expect(page.getByRole("heading", { name: "context-menu", exact: true })).toHaveCount(0);
  await expect(page.getByRole("menu")).toHaveCount(2);
  await submenu.getByRole("menuitem", { name: "Save Page...", exact: true }).click();
  await expect(root).toBeHidden();
  await expect(submenu).toBeHidden();
  await expect(page.getByRole("heading", { name: "context-menu", exact: true })).toHaveCount(1);

  // Keep the existing outside-click contract after the native submenu choice.
  await page.locator("#context-menu-submenu-trigger").click({ button: "right" });
  await subTrigger.click();
  await expect(root).toBeVisible();
  await expect(submenu).toBeVisible();
  await page.locator("body").click({ position: { x: 5, y: 5 } });
  await expect(root).toBeHidden();
  await expect(submenu).toBeHidden();
  await expect(page.getByRole("heading", { name: "context-menu", exact: true })).toHaveCount(1);
});

test("the sides example opens each menu from its own target", async ({ page }) => {
  await visit(page, "/preview/context-menu/sides", "#context-menu-side-top-trigger");
  // These are native outside caller nodes, as in the shared Overlay owner.
  await page.evaluate(() => {
    const visible = document.createElement("aside");
    visible.id = "context-outside-authored-false";
    visible.setAttribute("aria-hidden", "false");
    const control = document.createElement("button");
    control.type = "button";
    control.textContent = "Context outside caller";
    visible.append(control);
    const hidden = document.createElement("aside");
    hidden.id = "context-outside-authored-true";
    hidden.setAttribute("aria-hidden", "true");
    hidden.textContent = "Context hidden caller";
    const live = document.createElement("div");
    live.setAttribute("role", "status");
    live.setAttribute("aria-live", "polite");
    live.textContent = "Context live caller";
    document.body.append(visible, hidden, live);
  });
  const authoredFalse = page.locator("#context-outside-authored-false");
  const authoredTrue = page.locator("#context-outside-authored-true");

  for (const side of ["top", "right", "bottom", "left"]) {
    const id = `context-menu-side-${side}`;
    await page.locator(`#${id}-trigger`).click({ button: "right" });
    await expect(page.locator(`#${id}-popup`)).toBeVisible();
    const positioner = page.locator(`#${id}-positioner`);
    await expect(positioner).toHaveAttribute("data-lb-side", side);
    await expect(positioner).toHaveAttribute("data-side", /^(top|right|bottom|left)$/);
    await expect(page.getByRole("heading", { name: "context-menu", exact: true })).toHaveCount(0);
    await expect(authoredFalse).toHaveAttribute("aria-hidden", "true");
    await expect(page.getByRole("button", { name: "Context outside caller", exact: true })).toHaveCount(0);
    await expect(page.getByRole("status").filter({ hasText: "Context live caller" })).toHaveCount(1);
    await page.locator("body").click({ position: { x: 5, y: 5 } });
    await expect(page.locator(`#${id}-popup`)).toBeHidden();
    await expect(authoredFalse).toHaveAttribute("aria-hidden", "false");
    await expect(authoredTrue).toHaveAttribute("aria-hidden", "true");
    await expect(page.getByRole("button", { name: "Context outside caller", exact: true })).toHaveCount(1);
    await expect(page.getByRole("heading", { name: "context-menu", exact: true })).toHaveCount(1);
  }

  const firstTrigger = page.locator("#context-menu-side-top-trigger");
  const secondTrigger = page.locator("#context-menu-side-right-trigger");
  const firstPopup = page.locator("#context-menu-side-top-popup");
  const secondPopup = page.locator("#context-menu-side-right-popup");
  await firstTrigger.click({ button: "right" });
  await expect(firstPopup).toBeVisible();
  // A caller can run the same public LiveView.JS command that the gesture hook
  // reads. It has no outside click, so two controlled roots can overlap.
  await secondTrigger.evaluate((element) => {
    window.liveSocket.execJS(element, element.getAttribute("phx-click"));
  });
  await expect(firstPopup).toBeVisible();
  await expect(secondPopup).toBeVisible();
  await firstTrigger.evaluate((element) => {
    window.liveSocket.execJS(element, element.getAttribute("phx-click"));
  });
  await expect(firstPopup).toBeHidden();
  await expect(secondPopup).toBeVisible();
  await expect(authoredFalse).toHaveAttribute("aria-hidden", "true");
  await expect(page.getByRole("button", { name: "Context outside caller", exact: true })).toHaveCount(0);
  await page.keyboard.press("Escape");
  await expect(secondPopup).toBeHidden();
  await expect(authoredFalse).toHaveAttribute("aria-hidden", "false");
  await expect(authoredTrue).toHaveAttribute("aria-hidden", "true");
  await expect(page.getByRole("button", { name: "Context outside caller", exact: true })).toHaveCount(1);

  // The existing Docs navigation replaces the real view and its popup hooks.
  await visit(page, "/docs/context-menu", "#context-menu-side-top-trigger");
  await page.evaluate(() => {
    const outside = document.createElement("aside");
    outside.id = "context-removal-outside";
    outside.setAttribute("aria-hidden", "false");
    const control = document.createElement("button");
    control.type = "button";
    control.textContent = "Context removal outside caller";
    outside.append(control);
    document.body.append(outside);
  });
  await page.locator("#context-menu-side-top-trigger").click({ button: "right" });
  await expect(page.locator("#context-menu-side-top-popup")).toBeVisible();
  await expect(page.locator("#context-removal-outside")).toHaveAttribute("aria-hidden", "true");
  await expect(page.getByRole("button", { name: "Context removal outside caller", exact: true })).toHaveCount(0);
  await page.locator("a[href='/docs/button']").first().evaluate((element) => element.click());
  await expect(page).toHaveURL(/\/docs\/button$/);
  await connected(page);
  await expect(page.locator("#context-menu-side-top-popup")).toHaveCount(0);
  await expect(page.locator("#context-removal-outside")).toHaveAttribute("aria-hidden", "false");
  await expect(page.getByRole("button", { name: "Context removal outside caller", exact: true })).toHaveCount(1);
  await expect(page.getByRole("heading", { name: "Button", exact: true })).toHaveCount(1);
});

test("the Arabic root and submenus keep their direction", async ({ page }) => {
  await visit(page, "/preview/context-menu/rtl", "#context-menu-rtl-trigger");
  await page.locator("#context-menu-rtl-trigger").click({ button: "right" });

  const root = page.locator("#context-menu-rtl-popup");
  await expect(root).toHaveAttribute("dir", "rtl");
  await expect(root).toHaveAttribute("data-lang", "ar");

  await page.locator("#context-menu-rtl-navigation-trigger").click();
  const navigation = page.locator("#context-menu-rtl-navigation-popup");
  await expect(navigation).toBeVisible();
  await expect(navigation).toHaveAttribute("dir", "rtl");
  await expect(navigation).toHaveAttribute("data-lang", "ar");
});
