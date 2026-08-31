/**
 * Find render states that a reader can enter from the initial page.
 *
 * `aria-expanded` is the shared browser contract for disclosure, menu,
 * popover, combobox, and accordion triggers. React and LiveView can use
 * different ids and transport attributes. They must expose this same state.
 */
export async function visualStates(page, selector) {
  const states = [{ name: "default", kind: "default" }];
  await discoverExpandedStates(page, page.locator(selector), [], [], states);

  for (const kind of ["hover", "context"]) {
    const special = page.locator(specialTriggers(selector, kind));
    for (let index = 0; index < (await special.count()); index += 1) {
      const trigger = special.nth(index);
      const label = await trigger.evaluate(accessibleName);
      states.push({ name: `${kind}:${label || index + 1}`, kind, index });
    }
  }

  return states;
}

async function discoverExpandedStates(page, scope, path, labels, states) {
  const triggers = actionableTriggers(scope);
  const count = await triggers.count();

  for (let index = 0; index < count; index += 1) {
    const trigger = triggers.nth(index);
    if ((await trigger.getAttribute("aria-expanded")) !== "false") continue;

    const label = (await trigger.evaluate(accessibleName)) || String(index + 1);
    const nextPath = [...path, { index }];
    const nextLabels = [...labels, label];

    states.push({
      name: `expanded:${nextLabels.join(" > ")}`,
      kind: "expanded",
      path: nextPath,
    });

    await trigger.click();
    await waitForExpanded(trigger, "true");
    const controls = await trigger.getAttribute("aria-controls");

    if (controls) {
      const controlled = page.locator(`[id=${JSON.stringify(controls)}]`);
      let visible = false;

      try {
        await controlled.waitFor({ state: "visible", timeout: 1_000 });
        visible = true;
      } catch {
        // Some disclosure libraries keep aria-controls on a region that they
        // do not show. The expanded root state still belongs in the run. It
        // has no visible child trigger to discover.
      }

      if (visible) {
        await discoverExpandedStates(page, controlled, nextPath, nextLabels, states);
      }
    }

    // A later root trigger needs the initial page state. The last trigger does
    // not need to close because each measured state starts on a new page.
    if (path.length === 0 && index < count - 1) {
      await closeRootState(page, trigger);
    }
  }
}

/** Enter one state returned by `visualStates`. */
export async function enterVisualState(page, selector, state) {
  if (state.kind === "default") return;

  if (state.kind === "hover" || state.kind === "context") {
    const trigger = page.locator(specialTriggers(selector, state.kind)).nth(state.index);
    const triggerSlot = await trigger.getAttribute("data-slot");
    const contentSlot = triggerSlot.replace(/-trigger$/, "-content");

    await page.mouse.move(0, 0);

    if (state.kind === "hover") await trigger.hover();
    else await trigger.click({ button: "right" });

    await page.locator(`[data-slot='${contentSlot}']:visible`).waitFor();
    return;
  }

  let scope = page.locator(selector);
  // Clear hover before the interaction starts. Do not move the pointer after
  // a nested menu opens: upstream closes that menu when the pointer leaves it.
  await page.mouse.move(0, 0);

  const path = state.path ?? [{ index: state.index }];

  for (const [position, step] of path.entries()) {
    const trigger = actionableTriggers(scope).nth(step.index);

    if (path.length === 1) {
      // A listbox can open under the pointer. Use a DOM click so the expanded
      // state does not also become an item-hover state. Menus and disclosures
      // need their real pointer event, followed by a move away from the popup.
      if ((await trigger.getAttribute("aria-haspopup")) === "listbox") {
        await trigger.evaluate((element) => element.click());
      } else {
        await trigger.click();
        await page.mouse.move(0, 0);
      }
    } else {
      await trigger.click();
    }

    await waitForExpanded(trigger, "true");
    const controls = await trigger.getAttribute("aria-controls");

    if (controls && position < path.length - 1) {
      scope = page.locator(`[id=${JSON.stringify(controls)}]`);
      await scope.waitFor({ state: "visible" });
    }
  }

}

function actionableTriggers(scope) {
  return scope.locator("[aria-expanded]:not([aria-disabled='true']):not(:disabled):visible");
}

async function waitForExpanded(trigger, value) {
  await trigger.evaluate(async (element, expected) => {
    while (element.getAttribute("aria-expanded") !== expected) {
      await new Promise((resolve) => requestAnimationFrame(resolve));
    }
  }, value);
}

async function closeRootState(page, trigger) {
  if ((await trigger.getAttribute("aria-haspopup")) === null) {
    await trigger.click();
    await waitForExpanded(trigger, "false");
    return;
  }

  for (let attempt = 0; attempt < 8; attempt += 1) {
    if ((await trigger.getAttribute("aria-expanded")) === "false") return;
    await page.keyboard.press("Escape");
    await page.evaluate(() => new Promise((resolve) => requestAnimationFrame(resolve)));
  }

  await waitForExpanded(trigger, "false");
}

function specialTriggers(selector, kind) {
  if (kind === "context") return `${selector} [data-slot='context-menu-trigger']:visible`;
  return `${selector} [data-slot='tooltip-trigger']:visible, ${selector} [data-slot='hover-card-trigger']:visible`;
}

function accessibleName(element) {
  const label = element.getAttribute("aria-label");
  if (label) return label.trim();

  const labelledBy = element.getAttribute("aria-labelledby");
  if (labelledBy) {
    const text = labelledBy
      .split(/\s+/)
      .map((id) => document.getElementById(id)?.textContent ?? "")
      .join(" ")
      .trim();

    if (text) return text;
  }

  return element.innerText?.replace(/\s+/g, " ").trim() ?? "";
}

/** Give browser-owned examples the same deterministic devices in both renderers. */
export async function installBrowserFixtures(page) {
  await page.addInitScript(() => {
    const devices = [
      {
        deviceId: "built-in",
        groupId: "local",
        kind: "audioinput",
        label: "Built-in microphone",
        toJSON() {
          return this;
        },
      },
      {
        deviceId: "usb",
        groupId: "external",
        kind: "audioinput",
        label: "USB microphone",
        toJSON() {
          return this;
        },
      },
    ];
    const events = new EventTarget();

    Object.defineProperty(navigator, "mediaDevices", {
      configurable: true,
      value: {
        addEventListener: events.addEventListener.bind(events),
        removeEventListener: events.removeEventListener.bind(events),
        enumerateDevices: async () => devices,
        getUserMedia: async () => ({
          getTracks: () => [{ stop() {} }],
        }),
      },
    });
  });
}
