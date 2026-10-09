import { expect, test } from "@playwright/test";

import { enterVisualState, visualStates } from "./visual-states.mjs";
import { discoverInteractionProbes } from "./interaction-parity.mjs";
import { referenceReady, visit } from "./live.mjs";

async function visitPreview(page, path) {
  if (path.startsWith("/")) await visit(page, path);
  else await page.goto(path);
}

test("the default render state waits for finite color and font transitions", async ({ page }) => {
  await page.setContent('<main data-preview="transition"><button>Button</button></main>');
  await page.locator("button").evaluate((element) => {
    element.animate(
      [{ color: "#000000", fontSize: "12px" }, { color: "#ffffff", fontSize: "14px" }],
      { duration: 600, fill: "forwards" },
    );
  });

  await enterVisualState(page, "[data-preview='transition']", { kind: "default" });

  const style = await page.locator("button").evaluate((element) => {
    const computed = getComputedStyle(element);
    return { color: computed.color, fontSize: computed.fontSize };
  });
  expect(style).toEqual({ color: "rgb(255, 255, 255)", fontSize: "14px" });
});

test("state names use a control's native label", async ({ page }) => {
  await page.setContent(`
    <main data-preview="labelled-control">
      <label for="billing-month">الشهر</label>
      <button id="billing-month" role="switch" aria-checked="false">MM</button>
    </main>
  `);

  const states = await visualStates(page, "[data-preview='labelled-control']");

  expect(states.map(({ name }) => name)).toEqual(["default", "checked:الشهر"]);
});

for (const side of ["Phoenix", "React"]) {
  test(`popover / default exposes settled closed and expanded states on ${side}`, async ({ page }, testInfo) => {
    const selector = "[data-preview='popover']";
    const path = side === "Phoenix"
      ? "/preview/popover/default"
      : `${testInfo.project.use.parityURL}/preview/popover/default`;

    await visitPreview(page, path);
    const states = await visualStates(page, selector);
    expect(states.map(({ name }) => name)).toEqual([
      "default",
      "action:Open popover > editable:Width",
      "action:Open popover > editable:Max. width",
      "action:Open popover > editable:Height",
      "action:Open popover > editable:Max. height",
      "expanded:Open popover",
    ]);

    await visitPreview(page, path);
    await page.addStyleTag({ content: `
      [data-slot='popover-content'] {
        transition-duration: 600ms !important;
        animation-duration: 600ms !important;
      }
    ` });
    await enterVisualState(page, selector, states[5]);

    const opacity = await page.locator("[data-slot='popover-content']")
      .evaluate((element) => getComputedStyle(element).opacity);
    expect(opacity).toBe("1");
    await expect(page.getByRole("dialog")).toBeVisible();
  });
}

test("editable comboboxes use a user click to enter the expanded state", async ({ page }, testInfo) => {
  const selector = "[data-preview='combobox']";
  const paths = [
    "/preview/combobox/default",
    `${testInfo.project.use.parityURL}/preview/combobox/default`,
  ];

  for (const path of paths) {
    await visitPreview(page, path);
    const states = await visualStates(page, selector);

    expect(states.map(({ kind, path }) => ({ kind, path }))).toEqual([
      { kind: "default", path: undefined },
      { kind: "editable", path: undefined },
      { kind: "expanded", path: [{ index: 0 }] },
      { kind: "expanded", path: [{ index: 1 }] },
    ]);

    await visitPreview(page, path);
    await enterVisualState(page, selector, states[2]);
    await expect(page.getByRole("combobox", { name: "Select a framework" })).toHaveAttribute(
      "aria-expanded",
      "true",
    );
    await expect(page.getByRole("listbox")).toBeVisible();
  }
});

test("disclosure states keep an initially open panel open during replay", async ({ page }, testInfo) => {
  const selector = "[data-preview='accordion']";
  const paths = [
    "/preview/accordion/card",
    `${testInfo.project.use.parityURL}/preview/accordion/card`,
  ];

  for (const path of paths) {
    await visitPreview(page, path);
    const first = page.locator(`${selector} [data-slot='accordion-trigger']`).first();
    await expect(first).toHaveAttribute("aria-expanded", "true");
    const states = await visualStates(page, selector);
    const expanded = states.find((state) => state.kind === "expanded" && state.path[0].index === 0);
    expect(expanded).toBeDefined();

    await visitPreview(page, path);
    await enterVisualState(page, selector, expanded);
    await expect(first).toHaveAttribute("aria-expanded", "true");
    const controls = await first.getAttribute("aria-controls");
    await expect(page.locator(`[id=${JSON.stringify(controls)}]`)).toBeVisible();
  }
});

test("disabled disclosures do not become render states", async ({ page }) => {
  await visitPreview(page, "/preview/accordion/disabled");

  const states = await visualStates(page, "[data-preview='accordion']");

  expect(states.map(({ name }) => name)).toEqual([
    "default",
    "expanded:Can I access my account history?",
    "expanded:How do I update my email address?",
  ]);
});

test("tooltip exposes its hover state", async ({ page }) => {
  const selector = "[data-preview='tooltip']";
  await visitPreview(page, "/preview/tooltip/default");

  const states = await visualStates(page, selector);
  expect(states).toEqual([
    { name: "default", kind: "default" },
    { name: "action:Hover", kind: "interactive-action", index: 0 },
    { name: "hover:Hover", kind: "hover", index: 0 },
  ]);

  await enterVisualState(page, selector, states[2]);
  await expect(page.locator("[data-slot='tooltip-content']")).toBeVisible();
});

test("chart tooltip examples expose their hover state", async ({ page }, testInfo) => {
  const selector = "[data-preview='chart']";
  const paths = [
    "/preview/chart/example-tooltip",
    `${testInfo.project.use.parityURL}/preview/chart/example-tooltip`,
  ];

  for (const path of paths) {
    await visitPreview(page, path);
    const states = await visualStates(page, selector);

    expect(states).toEqual([
      { name: "default", kind: "default" },
      { name: "chart-hover:first-series", kind: "chart-hover", index: 0 },
    ]);

    await visitPreview(page, path);
    await enterVisualState(page, selector, states[1]);
    await expect(page.locator(".recharts-tooltip-wrapper")).toBeVisible();
  }
});

test("context menu exposes its right-click state", async ({ page }) => {
  const selector = "[data-preview='context-menu']";
  await visitPreview(page, "/preview/context-menu/default");

  const states = await visualStates(page, selector);
  expect(states.map(({ name }) => name)).toEqual(["default", "context:Right click here"]);

  await enterVisualState(page, selector, states[1]);
  await expect(page.locator("[data-slot='context-menu-content']")).toBeVisible();
});

test("dropdown menu exposes its nested menu state", async ({ page }, testInfo) => {
  const selector = "[data-preview='dropdown-menu']";
  const paths = [
    "/preview/dropdown-menu/default",
    `${testInfo.project.use.parityURL}/preview/dropdown-menu/default`,
  ];

  for (const path of paths) {
    await visitPreview(page, path);
    const states = await visualStates(page, selector);

    expect(states.map(({ name }) => name)).toEqual([
      "default",
      "expanded:Open",
      "expanded:Open > Invite users",
    ]);

    await visitPreview(page, path);
    await enterVisualState(page, selector, states[2]);
    await expect(page.locator("[data-slot='dropdown-menu-sub-content']")).toBeVisible();
  }
});

test("nested radio replay keeps both menu levels open", async ({ page }, testInfo) => {
  const selector = "[data-preview='button']";
  const paths = [
    `${testInfo.project.use.parityURL}/preview/button/group-demo`,
    "/preview/button/group-demo",
  ];

  for (const path of paths) {
    await visitPreview(page, path);
    const states = await visualStates(page, selector);
    const state = states.find(
      ({ name }) => name === "action:More Options > Label As... > checked:Work",
    );
    expect(state).toBeDefined();

    await visitPreview(page, path);
    await enterVisualState(page, selector, state);
    await expect(page.getByRole("menuitemradio", { name: "Work", exact: true })).toHaveAttribute(
      "aria-checked", "true",
    );
    await expect(page.getByRole("menuitemradio", { name: "Personal", exact: true })).toHaveAttribute(
      "aria-checked", "false",
    );
    await expect(page.getByRole("button", { name: "More Options", exact: true })).toHaveAttribute(
      "aria-expanded", "true",
    );
    await expect(page.getByRole("menuitem", { name: "Label As...", exact: true })).toHaveAttribute(
      "aria-expanded", "true",
    );
  }
});

test("table actions expose each menu as a separate render state", async ({ page }, testInfo) => {
  const selector = "[data-preview='table']";
  const paths = [
    "/preview/table/actions",
    `${testInfo.project.use.parityURL}/preview/table/actions`,
  ];

  for (const path of paths) {
    await visitPreview(page, path);
    const states = await visualStates(page, selector);

    expect(states.map(({ name }) => name)).toEqual([
      "default",
      "expanded:Open menu",
      "expanded:Open menu",
      "expanded:Open menu",
    ]);
  }
});

test("navigation menu exposes each content state", async ({ page }, testInfo) => {
  const selector = "[data-preview='navigation-menu']";
  const paths = [
    "/preview/navigation-menu/default",
    `${testInfo.project.use.parityURL}/preview/navigation-menu/default`,
  ];

  for (const path of paths) {
    await visitPreview(page, path);
    const states = await visualStates(page, selector);

    expect(states.map(({ name }) => name)).toEqual([
      "default",
      "expanded:Getting started",
      "expanded:Components",
      "expanded:With Icon",
    ]);
  }
});

test("toast exposes each action result and the completed Promise", async ({ page }, testInfo) => {
  const selector = "[data-preview='toast']";
  const paths = [
    "/preview/toast/promise",
    `${testInfo.project.use.parityURL}/preview/toast/promise`,
  ];

  for (const path of paths) {
    await visitPreview(page, path);
    const states = await visualStates(page, selector);

    expect(states.map(({ name }) => name)).toEqual([
      "default",
      "action:Create Event",
      "action-settled:Create Event",
    ]);

    await visitPreview(page, path);
    await enterVisualState(page, selector, states[1]);
    await expect(page.locator("[data-slot='toast-description']")).toHaveText("Creating event…");

    await visitPreview(page, path);
    await enterVisualState(page, selector, states[2]);
    await expect(page.locator("[data-slot='toast-description']")).toHaveText("Event created.");
  }
});

for (const side of ["Phoenix", "React"]) {
  test(`carousel / spacing returns a settled visual action on ${side}`, async ({ page }, testInfo) => {
    const selector = "[data-preview='carousel']";
    const path = side === "Phoenix"
      ? "/preview/carousel/spacing"
      : `${testInfo.project.use.parityURL}/preview/carousel/spacing`;
    await visitPreview(page, path);
    const states = await visualStates(page, selector);
    const next = states.find(({ name }) => name === "action:Next slide");
    expect(next).toBeDefined();

    await visitPreview(page, path);
    await referenceReady(page);
    const track = page.locator("[data-slot='carousel-content'] > div");
    const initial = await track.evaluate((element) => new DOMMatrixReadOnly(getComputedStyle(element).transform).m41);
    const positions = await page.locator("[data-slot='carousel-item']").evaluateAll((items) =>
      items.slice(0, 2).map((item) => item.getBoundingClientRect().x),
    );
    const advance = positions[1] - positions[0];
    await enterVisualState(page, selector, next);
    const position = await track.evaluate((element) => new DOMMatrixReadOnly(getComputedStyle(element).transform).m41);
    expect(Math.abs(position - initial)).toBeCloseTo(advance, 0);
    const laterPositions = await track.evaluate(async (element) => {
      const positions = [];
      for (let frame = 0; frame < 32; frame += 1) {
        await new Promise((resolve) => requestAnimationFrame(resolve));
        positions.push(new DOMMatrixReadOnly(getComputedStyle(element).transform).m41);
      }
      return positions;
    });
    expect([...new Set(laterPositions)]).toEqual([position]);
  });
}

for (const side of ["Phoenix", "React"]) {
  test(`read-only Share fields survive every declared state on ${side}`, async ({ page }, testInfo) => {
    const path = side === "Phoenix" ? "/preview/dialog/close-button"
      : `${testInfo.project.use.parityURL}/preview/dialog/close-button`;
    const selector = "[data-preview='dialog']";
    await visitPreview(page, path);
    const states = await visualStates(page, selector);
    const open = states.find((state) => state.kind === "expanded");
    expect(open).toBeDefined();
    for (const state of states) {
      await visitPreview(page, path);
      await enterVisualState(page, selector, state);
    }
    await visitPreview(page, path);
    await enterVisualState(page, selector, open);
    const link = page.getByRole("textbox", { name: "Link", exact: true });
    await expect(link).toHaveAttribute("readonly", "");
    await expect(link).toHaveValue("https://ui.shadcn.com/docs/installation");
    const probes = await discoverInteractionProbes(page.getByRole("dialog"));
    expect(probes.filter(({ kind }) => kind === "editable-text")).toEqual([]);

    const editablePath = side === "Phoenix" ? "/preview/dialog/default"
      : `${testInfo.project.use.parityURL}/preview/dialog/default`;
    await visitPreview(page, editablePath);
    const editableStates = await visualStates(page, selector);
    const edit = editableStates.find((state) => state.controlKind === "editable");
    expect(edit).toBeDefined();
    await visitPreview(page, editablePath);
    await enterVisualState(page, selector, edit);
    await expect(page.getByRole("textbox", { name: "Name", exact: true })).toHaveValue("Parity text");
  });
}

for (const side of ["React", "Phoenix"]) {
  test(`nested text replay keeps focus on the edited Username field on ${side}`, async ({ page }, testInfo) => {
    // Deliver callbacks on real browser frames at a lower rate to expose
    // opening focus that can finish after the next action on a busy page.
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
    const path = side === "Phoenix" ? "/preview/dialog/default"
      : `${testInfo.project.use.parityURL}/preview/dialog/default`;
    const selector = "[data-preview='dialog']";
    await visitPreview(page, path);
    const states = await visualStates(page, selector);
    const state = states.find(({ name, kind }) => kind === "nested-native-control" && name.endsWith("editable:Username"));
    expect(state).toBeDefined();
    await visitPreview(page, path);
    await enterVisualState(page, selector, state);
    const username = page.getByRole("textbox", { name: "Username", exact: true });
    await expect(username).toHaveValue("Parity text");
    expect(await username.evaluate((element) => document.activeElement === element)).toBe(true);
    await expect(page.getByRole("textbox", { name: "Name", exact: true })).toHaveValue("Pedro Duarte");
  });
}
