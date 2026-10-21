import { expect, test } from "@playwright/test";

import { actionControlSelector, enterVisualState, visualStates } from "./visual-states.mjs";
import { discoverInteractionProbes, enterInteractionProbe } from "./interaction-parity.mjs";
import { referenceReady, slowAnimationFrames, visit } from "./live.mjs";
import { regressions, stableViolations } from "./accessibility.mjs";
import { collect } from "./measure.mjs";

async function visitPreview(page, path) {
  if (path.startsWith("/")) await visit(page, path);
  else await page.goto(path);
}

test("accessibility targets identify the visible tab panel across mount strategies", async ({ page }) => {
  const scan = async (hidden) => {
    await page.setContent(`<main data-preview="tabs"><div data-slot="tabs"><div data-slot="tabs-content"><span id="target">request</span></div>${hidden ? '<div data-slot="tabs-content" hidden>Other file</div>' : ''}</div></main>`);
    return stableViolations(page, [{ id: "color-contrast", nodes: [{ target: ["#target"] }] }], "[data-preview=tabs]");
  };
  const upstream = await scan(false);
  const native = await scan(true);
  expect(regressions(native, upstream)).toEqual([]);
});

test("disclosure observations wait for entry and ignore closed panels", async ({ page }) => {
  test.setTimeout(5000);
  for (const remove of [false, true]) {
    await page.setContent('<main data-preview="disclosure"><button aria-controls="panel" aria-expanded="false">Details</button><div id="panel" style="height:0;max-height:120px;width:100px;overflow:hidden">Output</div></main>');
    await page.locator("button").evaluate((button, remove) => {
      button.onclick = () => {
        const open = button.getAttribute("aria-expanded") !== "true";
        button.setAttribute("aria-expanded", String(open));
        const panel = document.getElementById("panel");
        if (!open && remove) panel.remove();
        else if (open) setTimeout(() => { panel.style.height = "20px"; }, 200);
        else panel.style.height = "0px";
      };
    }, remove);
    const selector = "[data-preview=disclosure]";
    const [probe] = await discoverInteractionProbes(page.locator(selector));
    const result = await enterInteractionProbe(page, selector, probe);
    expect(result.opened.popup).toMatchObject({ visible: true });
    expect(result.closed.popup).toBeNull();
  }
});

test("a show-more disclosure returns to its visible clipped state", async ({ page }) => {
  await page.setContent(`<main data-preview="clipped"><button aria-controls="source" aria-expanded="false">Show more</button><pre id="source" style="max-height:20px;overflow-y:hidden">one\ntwo\nthree\nfour</pre></main>`);
  await page.locator("button").evaluate(button => {
    button.onclick = () => {
      const expanded = button.getAttribute("aria-expanded") !== "true";
      button.setAttribute("aria-expanded", String(expanded));
      document.getElementById("source").style.maxHeight = expanded ? "none" : "20px";
    };
  });
  const selector = "[data-preview=clipped]";
  const states = await visualStates(page, selector);
  expect(states.some(state => state.kind === "expanded")).toBe(true);
  await expect(page.locator("#source")).toBeVisible();
  if (await page.locator("button").getAttribute("aria-expanded") === "true") {
    await page.locator("button").click();
  }
  const [probe] = await discoverInteractionProbes(page.locator(selector));
  const result = await enterInteractionProbe(page, selector, probe);
  expect(result.opened.target.expanded).toBe("true");
  expect(result.closed.target.expanded).toBe("false");
  await expect(page.locator("#source")).toHaveCSS("max-height", "20px");
});

test("semantic observations follow inherited hidden state", async ({ page }, testInfo) => {
  await page.goto(`${testInfo.project.use.parityURL}/preview/dialog/default`);
  await referenceReady(page);
  const selector = "[data-preview='dialog']";
  const state = (await visualStates(page, selector)).find(({ name }) => name === "expanded:Open Dialog");
  expect(state).toBeDefined();
  await enterVisualState(page, selector, state);
  const trigger = page.locator("[data-slot='dialog-trigger']");
  const observedHidden = async () => {
    const rows = await page.evaluate(collect, { selector, properties: [], attributes: ["aria-hidden"] });
    return rows.slots.find(({ slot }) => slot === "dialog-trigger").semantic.states["aria-hidden"];
  };

  await expect(page.getByRole("button", { name: "Open Dialog", exact: true })).toHaveCount(0);
  expect(await observedHidden()).toBe("true");
  await trigger.evaluate((element) => element.setAttribute("aria-hidden", "false"));
  await expect(page.getByRole("button", { name: "Open Dialog", exact: true })).toHaveCount(0);
  expect(await observedHidden()).toBe("true");
  await page.locator("main").evaluate((element) => element.setAttribute("aria-hidden", "false"));
  await expect(page.getByRole("button", { name: "Open Dialog", exact: true })).toBeVisible();
  expect(await observedHidden()).toBe("false");
});

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
  test(`sidebar / default finishes initial motion before the header action on ${side}`, async ({ page }, testInfo) => {
    const selector = "[data-preview='sidebar']";
    const path = side === "Phoenix"
      ? "/preview/sidebar/default"
      : `${testInfo.project.use.parityURL}/preview/sidebar/default`;
    await page.setViewportSize({ width: 1280, height: 2144 });
    await visitPreview(page, path);
    const states = (await visualStates(page, selector))
      .filter(({ name }) => name === "action:Toggle Sidebar");
    expect(states.map(({ kind, index }) => ({ kind, index }))).toEqual([
      { kind: "interactive-action", index: 1 },
      { kind: "interactive-action", index: 2 },
    ]);
    const controls = page.locator(selector).locator(actionControlSelector());
    await expect(controls.nth(1)).toHaveAttribute("data-slot", "sidebar-rail");
    await expect(controls.nth(2)).toHaveAttribute("data-slot", "sidebar-trigger");

    // A reload can start finite horizontal motion before the first action.
    // Keep that motion long enough to exercise native pointer stability retries.
    await visitPreview(page, path);
    await enterVisualState(page, selector, { kind: "default" });
    const trigger = page.locator("[data-slot='sidebar-trigger']");
    const pointerDown = trigger.evaluate((element) => new Promise((resolve) => {
      const motion = element.animate(
        [{ transform: "translateX(4px)" }, { transform: "translateX(0px)" }],
        { duration: 150 },
      );
      element.addEventListener("pointerdown", () => resolve({
        slot: element.dataset.slot,
        scrollY,
        y: element.getBoundingClientRect().y,
        initialMotion: motion.playState,
      }), { once: true });
    }));
    await enterVisualState(page, selector, states[1]);
    const entry = await pointerDown;
    await testInfo.attach("sidebar-header-pointer-entry", {
      body: JSON.stringify(entry), contentType: "application/json",
    });
    expect(entry).toMatchObject({ slot: "sidebar-trigger", scrollY: 0, initialMotion: "finished" });
    expect(entry.y).toBeGreaterThan(0);

    await expect(trigger).toBeFocused();
    await expect(page.locator("[data-slot='sidebar']")).toHaveAttribute("data-state", "collapsed");
    expect(await page.evaluate(() => ({ scrollY, scrollTop: document.scrollingElement.scrollTop })))
      .toEqual({ scrollY: 0, scrollTop: 0 });
    expect((await trigger.boundingBox()).y).toBeGreaterThan(0);
  });
  for (const [example, action] of [["time", "open"], ["natural-language", "typed-open"]]) {
    test(`date-picker / ${example} finishes entry before observation on ${side}`, async ({ page }, testInfo) => {
      const selector = "[data-preview='date-picker']";
      const path = side === "Phoenix"
        ? `/preview/date-picker/${example}`
        : `${testInfo.project.use.parityURL}/preview/date-picker/${example}`;

      await visitPreview(page, path);
      const state = (await visualStates(page, selector)).find(({ name }) => name === `action:${action}`);
      expect(state).toBeDefined();
      await enterVisualState(page, selector, state);

      const opacity = await page.locator("[data-slot='popover-content']:visible")
        .evaluate((element) => getComputedStyle(element).opacity);
      expect(opacity).toBe("1");
    });
  }

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

for (const side of ["React", "Phoenix"]) {
  test(`Select expanded state clears hover after popup entry on slow frames on ${side}`, async ({ page }, testInfo) => {
    await slowAnimationFrames(page);
    const path = side === "Phoenix" ? "/preview/select/scrollable"
      : `${testInfo.project.use.parityURL}/preview/select/scrollable`;
    const selector = "[data-preview='select']";
    await visitPreview(page, path);
    const states = await visualStates(page, selector);
    const expanded = states.find((state) => state.kind === "expanded");
    expect(expanded).toBeDefined();

    await visitPreview(page, path);
    await referenceReady(page);
    await enterVisualState(page, selector, expanded);
    const popup = page.locator("[data-slot='select-content']:visible");
    expect(await popup.locator("[data-highlighted]").allTextContents()).toEqual([]);
    await expect(popup).toBeFocused();
    await expect(page.getByRole("combobox")).toContainText("Select a timezone");
  });
}

for (const side of ["React", "Phoenix"]) {
  test(`nested Drawer states finish entry and clear incidental hover on ${side}`, async ({ page }, testInfo) => {
    await slowAnimationFrames(page);
    const path = side === "Phoenix" ? "/preview/drawer/nested"
      : `${testInfo.project.use.parityURL}/preview/drawer/nested`;
    const selector = "[data-preview='drawer']";
    await visitPreview(page, path);
    const state = (await visualStates(page, selector)).find(({ name }) =>
      name === "expanded:Open Drawer > Open Nested Drawer > Open Third Drawer");
    expect(state).toBeDefined();

    await visitPreview(page, path);
    const entries = [];
    await page.exposeFunction("recordDrawerEntry", entry => entries.push(entry));
    await page.evaluate(() => {
      document.addEventListener("pointerdown", event => {
        const trigger = event.target.closest("[data-slot='drawer-trigger']");
        const popup = trigger?.closest("[data-slot='drawer-popup']");
        if (!popup) return;
        window.recordDrawerEntry({
          trigger: trigger.textContent.trim(),
          starting: popup.hasAttribute("data-starting-style"),
          moving: popup.getAnimations().some(animation =>
            animation.pending || animation.playState === "running"),
        });
      }, true);
    });
    await enterVisualState(page, selector, state);

    expect(entries).toEqual([
      { trigger: "Open Nested Drawer", starting: false, moving: false },
      { trigger: "Open Third Drawer", starting: false, moving: false },
    ]);
    const fourth = page.getByRole("button", { name: "Open Fourth Drawer", exact: true });
    await expect(fourth).toHaveAttribute("aria-expanded", "false");
    expect(await fourth.evaluate(element => element.matches(":hover"))).toBe(false);
    await expect(fourth).toHaveCSS("background-color", "oklch(1 0 0)");
    const front = page.getByRole("dialog").filter({ has: page.getByRole("heading", { name: "Third Drawer", exact: true }) });
    await expect(front).toBeFocused();
  });
}

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
  await page.route(`${testInfo.project.use.parityURL}/preview/chart/**`, async (route) => {
    const response = await route.fetch();
    const html = await response.text();
    await route.fulfill({ response, body: html.replace("<head>",
      '<head><style id="delayed-chart-size">.recharts-responsive-container { width: 0 !important; }</style>') });
  });
  const paths = [
    "/preview/chart/example-tooltip",
    "/preview/chart/example-legend",
    `${testInfo.project.use.parityURL}/preview/chart/example-legend`,
    `${testInfo.project.use.parityURL}/preview/chart/example-tooltip`,
  ];

  for (const path of paths) {
    await visitPreview(page, path);
    await referenceReady(page);
    await page.evaluate(() => {
      setTimeout(() => document.getElementById("delayed-chart-size")?.remove(), 750);
    });
    const states = await visualStates(page, selector);

    expect(states).toEqual([
      { name: "default", kind: "default" },
      { name: "chart-hover:first-series", kind: "chart-hover", index: 0 },
    ]);

    await enterVisualState(page, selector, states[1]);
    await expect(page.locator(".recharts-tooltip-wrapper")).toBeVisible();
  }
  for (const path of ["/preview/chart/tooltip", `${testInfo.project.use.parityURL}/preview/chart/tooltip`]) {
    await visitPreview(page, path);
    expect(await visualStates(page, selector)).toEqual([{ name: "default", kind: "default" }]);
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

for (const { example, labels } of [
  { example: "default", labels: ["Getting started", "Components", "With Icon"] },
  { example: "rtl", labels: ["البدء", "المكونات", "مع أيقونة"] },
]) {
  test(`navigation menu / ${example} preserves native reading order and dismissal`, async ({ page }, testInfo) => {
    const selector = "[data-preview='navigation-menu']";
    const paths = [
      `${testInfo.project.use.parityURL}/preview/navigation-menu/${example}`,
      `/preview/navigation-menu/${example}`,
    ];
    const referenceTrees = new Map();

    for (const path of paths) {
      await visitPreview(page, path);
      const states = await visualStates(page, selector);
      expect(states.map(({ name }) => name)).toEqual([
        "default", ...labels.map((label) => `expanded:${label}`),
      ]);

      for (const state of states.slice(1)) {
        await visitPreview(page, path);
        await enterVisualState(page, selector, state);
        const trigger = page.locator("[data-slot='navigation-menu-trigger']").nth(state.path[0].index);
        const popup = page.locator(".cn-navigation-menu-popup:visible");
        const tree = await page.locator("[data-slot='navigation-menu']").ariaSnapshot();
        if (path.startsWith("/")) expect(tree, state.name).toBe(referenceTrees.get(state.name));
        else referenceTrees.set(state.name, tree);
        await expect(trigger).toBeFocused();

        await trigger.click();
        await expect(trigger).toHaveAttribute("aria-expanded", "false");
        await expect(popup).toBeHidden();
        await expect(trigger).toBeFocused();

        await trigger.click();
        await expect(trigger).toHaveAttribute("aria-expanded", "true");
        await popup.getByRole("link").first().focus();
        await expect(popup.getByRole("link").first()).toBeFocused();
        await page.keyboard.press("Escape");
        await expect(trigger).toHaveAttribute("aria-expanded", "false");
        await expect(popup).toBeHidden();
        await expect(trigger).toBeFocused();

        await trigger.click();
        await expect(trigger).toHaveAttribute("aria-expanded", "true");
        await page.locator("body").click({ position: { x: 5, y: 5 } });
        await expect(trigger).toHaveAttribute("aria-expanded", "false");
        await expect(popup).toBeHidden();
      }
    }
  });
}

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
    await slowAnimationFrames(page);
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

for (const side of ["React", "Phoenix"]) {
  test(`compact Drawer Close replays through a reachable keyboard action on ${side}`, async ({ page }, testInfo) => {
    const path = side === "Phoenix" ? "/preview/drawer/snap-points"
      : `${testInfo.project.use.parityURL}/preview/drawer/snap-points`;
    const selector = "[data-preview='drawer']";
    await visitPreview(page, path);
    if (side === "React") await referenceReady(page);
    const states = await visualStates(page, selector);
    const close = states.find(({ kind, name }) => kind === "nested-action" && name.endsWith("button:Close"));
    expect(close).toBeDefined();
    await visitPreview(page, path);
    if (side === "React") await referenceReady(page);
    await enterVisualState(page, selector, close);
    await expect(page.getByRole("dialog")).toBeHidden();
    await expect(page.getByRole("button", { name: "Open Snap Drawer", exact: true })).toBeFocused();
  });
}
