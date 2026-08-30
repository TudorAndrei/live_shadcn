/**
 * Find render states that a reader can enter from the initial page.
 *
 * `aria-expanded` is the shared browser contract for disclosure, menu,
 * popover, combobox, and accordion triggers. React and LiveView can use
 * different ids and transport attributes. They must expose this same state.
 */
export async function visualStates(page, selector) {
  const triggers = page.locator(actionableTriggers(selector));
  const states = [{ name: "default", kind: "default" }];

  for (let index = 0; index < (await triggers.count()); index += 1) {
    const trigger = triggers.nth(index);
    if ((await trigger.getAttribute("aria-expanded")) !== "false") continue;
    const label = await trigger.evaluate(accessibleName);

    states.push({
      name: `expanded:${label || index + 1}`,
      kind: "expanded",
      index,
    });
  }

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

/** Enter one state returned by `visualStates`. */
export async function enterVisualState(page, selector, state) {
  if (state.kind === "default") return;

  if (state.kind === "hover" || state.kind === "context") {
    const trigger = page.locator(specialTriggers(selector, state.kind)).nth(state.index);
    const triggerSlot = await trigger.getAttribute("data-slot");
    const contentSlot = triggerSlot.replace(/-trigger$/, "-content");

    if (state.kind === "hover") await trigger.hover();
    else await trigger.click({ button: "right" });

    await page.locator(`[data-slot='${contentSlot}']:visible`).waitFor();
    return;
  }

  const triggers = page.locator(actionableTriggers(selector));
  const trigger = triggers.nth(state.index);

  await trigger.click();
  // The state comparison is not a hover comparison. Move the pointer away so
  // a popup that changes the hit-test tree cannot leave only one trigger in a
  // hover state.
  await page.mouse.move(0, 0);
  await page.waitForFunction(
    ({ selector, index }) => {
      const root = document.querySelector(selector);
      const triggers = [...(root?.querySelectorAll("[aria-expanded]") ?? [])].filter((element) =>
        element.getClientRects().length > 0 &&
        element.getAttribute("aria-disabled") !== "true" &&
        !element.disabled
      );

      return triggers[index]?.getAttribute("aria-expanded") === "true";
    },
    { selector, index: state.index },
  );
}

function actionableTriggers(selector) {
  return `${selector} [aria-expanded]:not([aria-disabled='true']):not(:disabled):visible`;
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
