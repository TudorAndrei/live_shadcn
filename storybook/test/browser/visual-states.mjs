import { isOfficialInteractiveShadcnComponent } from "./official-interactive-components.mjs";
import { referenceReady } from "./live.mjs";
import {
  waitForMessageScrollerAnchorGeometry,
  waitForMessageScrollerEntryAnimations,
} from "./message-scroller-readiness.mjs";

/**
 * Find render states that a reader can enter from the initial page.
 *
 * `aria-expanded` is the shared browser contract for disclosure, menu,
 * popover, combobox, and accordion triggers. React and LiveView can use
 * different ids and transport attributes. They must expose this same state.
 */
export async function visualStates(page, selector) {
  await referenceReady(page);
  const states = [{ name: "default", kind: "default" }];
  const scope = page.locator(selector);
  const model = await visualActionModel(scope);
  const component = await scope.getAttribute("data-preview");

  if (model?.kind === "data-table") return dataTableVisualStates(model.example);

  await discoverControlStates(scope, states, model);
  await discoverEditableControlStates(scope, states, component, model);
  await discoverActionStates(scope, states, model, component);
  if (!model && isOfficialInteractiveShadcnComponent(component)) {
    await discoverNestedInteractiveStates(page, scope, [], [], states);
  }
  await discoverControlledDialogStates(page, scope, states);
  if (!model?.claimsExpandedStates)
    await discoverExpandedStates(page, scope, [], [], states);
  await discoverChartHoverState(scope, states);

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

/** Compare a state by its stable control path, not by dynamic visible text. */
export function visualStateIdentity(state) {
  return {
    kind: state.kind,
    index: state.index ?? null,
    path: state.path ?? null,
    settleMs: state.settleMs ?? null,
    action: state.action ?? null,
    controlKind: state.controlKind ?? null,
    selector: state.selector ?? null,
    value: state.value ?? null,
  };
}

const click = (role, name) => ({ type: "click", role, name });
const hover = (role, name) => ({ type: "hover", role, name });
const menuItem = (index) => ({ type: "menu-item", index });
const outlineChoice = (index) => ({ type: "outline-choice", index });
const select = (name) => ({ type: "select", name });
const slider = (name, value) => ({ type: "slider", name, value });
const scroll = (position) => ({ type: "scroll", position });
const clearHover = () => ({ type: "clear-hover" });

export const messageScrollerAnimationPreset = (scope) =>
  scope.getByRole("combobox", { name: "Animation preset", exact: true });

export async function waitForMessageScrollerCommandControls(trigger) {
  return trigger.evaluate(async (element) => {
    while (true) {
      const controls = element.getAttribute("aria-controls");
      if (element.getAttribute("aria-expanded") === "true" && controls) return controls;
      await new Promise((resolve) => requestAnimationFrame(resolve));
    }
  });
}

const COMBOBOX_EMPTY_MARKER = "\u2060";
const COMBOBOX_EMPTY_MARKER_RESET_MS = 200;
const COMBOBOX_EMPTY_MARKER_TIMEOUT_MS = COMBOBOX_EMPTY_MARKER_RESET_MS * 3;

/**
 * Base UI can append U+2060 to an Empty live region on its first mount, then
 * restores the text after 200 ms. It can also finish that one-shot marker
 * before this capture starts. Measure only settled visible text.
 */
export async function waitForComboboxEmptyLiveRegion(page, selector, state) {
  if (state.kind !== "editable") return;

  await page.waitForFunction(
    async ({ selector, marker, resetMs }) => {
      const preview = document.querySelector(selector);
      const controls = preview
        ?.querySelector("[role='combobox'][aria-controls]")
        ?.getAttribute("aria-controls");
      const list = controls ? document.getElementById(controls) : null;
      const controlledEmpty = list?.parentElement?.querySelector("[data-slot='combobox-empty']");
      const empty =
        controlledEmpty ||
        [...(preview?.querySelectorAll("[data-slot='combobox-empty']") || [])].find((candidate) =>
          candidate.checkVisibility?.({ contentVisibilityAuto: true }),
        );
      if (!empty?.checkVisibility?.({ contentVisibilityAuto: true })) return true;

      await new Promise((resolve) => setTimeout(resolve, resetMs));
      return (
        !empty.isConnected ||
        !empty.checkVisibility?.({ contentVisibilityAuto: true }) ||
        !empty.textContent.includes(marker)
      );
    },
    { selector, marker: COMBOBOX_EMPTY_MARKER, resetMs: COMBOBOX_EMPTY_MARKER_RESET_MS },
    { timeout: COMBOBOX_EMPTY_MARKER_TIMEOUT_MS + 500 },
  );
}

export async function messageScrollerCommandMenuPopup(page, scope) {
  const trigger = scope.getByRole("button", { name: "Jump to...", exact: true });
  const controls = await waitForMessageScrollerCommandControls(trigger);
  const popup = page.locator(`[id=${JSON.stringify(controls)}][role="menu"]:visible`);
  if ((await popup.count()) !== 1)
    throw new Error("Message Scroller command menu did not open exactly once");
  return popup;
}

export function messageScrollerSelectedControlMatches(root, { role, name, value }) {
  const control = root.querySelector(
    `button[role=${JSON.stringify(role)}][aria-label=${JSON.stringify(name)}]`,
  );
  return control?.querySelector("[data-slot='select-value']")?.textContent?.trim() === value;
}

// These are reader-visible states in the official Message Scroller examples.
// The controls use their accessible names because React and LiveView have
// different implementation ids but the same reader contract.
const MESSAGE_SCROLLER_ACTIONS = {
  default: [
    {
      name: "send-busy",
      steps: [click("button", "Send")],
      expect: { items: 1, busy: true, position: "start" },
    },
    {
      name: "send-reply",
      steps: [
        click("button", "Send"),
        { type: "wait", expect: { items: 1, busy: true, position: "start" } },
        { type: "remember-scroll", key: "after-send" },
        { type: "reply" },
      ],
      expect: {
        items: 2,
        busy: false,
        position: "start",
        scrollEquals: "after-send",
        buttonActive: true,
      },
    },
    {
      name: "scroll-to-end",
      steps: [
        click("button", "Send"),
        { type: "reply" },
        click("button", "Scroll to end"),
      ],
      expect: { items: 2, busy: false, position: "end", buttonActive: false },
    },
    {
      name: "reset",
      steps: [
        click("button", "Send"),
        { type: "reply" },
        click("button", "Reset conversation"),
        clearHover(),
      ],
      expect: { items: 0, empty: "Morning, shadcn!" },
    },
  ],
  anchoring: [
    {
      name: "append",
      steps: [click("button", "Send Message")],
      expect: { items: 1 },
    },
    {
      name: "reset",
      steps: [
        click("button", "Send Message"),
        click("button", "Reset anchored turns"),
      ],
      expect: { items: 0, empty: "No anchored messages yet" },
    },
  ],
  "group-chat": [
    {
      name: "append-marker",
      steps: [click("button", "Add Rocky")],
      expect: { items: 4, text: "Rocky has joined the chat" },
    },
    {
      name: "append-reply",
      steps: [
        click("button", "Add Rocky"),
        click("button", "Send Message as Rocky"),
      ],
      expect: { items: 5, messageId: "group-5" },
    },
    {
      name: "reset",
      steps: [
        click("button", "Add Rocky"),
        click("button", "Send Message as Rocky"),
        click("button", "Reset conversation"),
        clearHover(),
      ],
      expect: {
        items: 3,
        absentText: "Rocky has joined the chat",
        absentMessageId: "group-5",
      },
    },
  ],
  "previous-context": [
    {
      name: "peek-128",
      steps: [slider("Previous context peek", 128)],
      expect: { slider: ["Previous context peek", 128], text: "128px" },
    },
    {
      name: "send-busy",
      steps: [click("button", "Send")],
      expect: { items: 3, busy: true },
    },
    {
      name: "send-reply",
      steps: [click("button", "Send"), { type: "reply" }],
      expect: { items: 4, busy: false },
    },
    {
      name: "reset",
      steps: [
        slider("Previous context peek", 128),
        click("button", "Send"),
        { type: "reply" },
        click("button", "Reset context example"),
        clearHover(),
      ],
      expect: {
        items: 2,
        busy: false,
        slider: ["Previous context peek", 64],
        text: "64px",
      },
    },
  ],
  streaming: [
    {
      name: "send-busy",
      steps: [click("button", "Send")],
      expect: { items: 1, busy: true },
    },
    {
      name: "send-reply",
      steps: [click("button", "Send"), { type: "reply" }],
      expect: { items: 2, busy: false },
    },
    {
      name: "reset",
      steps: [
        click("button", "Send"),
        { type: "reply" },
        click("button", "Reset stream"),
        clearHover(),
      ],
      expect: { items: 0, empty: "Ready to Stream" },
    },
  ],
  animation: [
    ...[
      "Fade",
      "Slide Up",
      "Slide Side",
      "Pop",
      "Spring Bounce",
      "Blur Fade",
      "Scale Fade",
    ].map((name) => ({
      name: `preset-${name.toLowerCase().replaceAll(" ", "-")}`,
      steps: [select(name)],
      expect: {
        selected: { role: "combobox", name: "Animation preset", value: name },
      },
    })),
    {
      name: "send-busy",
      steps: [click("button", "Send Message")],
      expect: { items: 1, busy: true },
    },
    {
      name: "send-reply",
      steps: [click("button", "Send Message"), { type: "reply" }],
      expect: { items: 2, busy: false },
    },
    {
      name: "reset",
      steps: [
        click("button", "Send Message"),
        { type: "reply" },
        click("button", "Reset animated messages"),
      ],
      expect: { items: 0, empty: "No Messages Yet" },
    },
  ],
  "load-history": [
    {
      name: "load-history",
      steps: [click("button", "Load History")],
      expect: { items: 11, button: "History Loaded" },
    },
    {
      name: "reset",
      steps: [
        click("button", "Load History"),
        click("button", "Reset loaded messages"),
        clearHover(),
      ],
      expect: { items: 6, button: "Load History" },
    },
  ],
  "opening-position": [
    {
      name: "opening-start",
      steps: [click("tab", "start")],
      expect: { tab: "start", position: "start" },
    },
    {
      name: "opening-end",
      steps: [click("tab", "end")],
      expect: { tab: "end", position: "end" },
    },
    {
      name: "opening-last-anchor",
      steps: [
        click("tab", "end"),
        { type: "wait", expect: { tab: "end", position: "end" } },
        click("tab", "last-anchor"),
      ],
      expect: {
        tab: "last-anchor",
        position: "message:open-3",
        scrollMargin: 64,
      },
    },
  ],
  commands: [
    "command-activation",
    "command-compare",
    "command-experiment",
    "command-risk",
  ].map((id, index) => ({
    name: id,
    steps: [click("button", "Jump to..."), menuItem(index)],
    expect: { position: `message:${id}` },
  })),
  visibility: ["vis-brief", "vis-impact", "vis-actions", "vis-checklist"].map(
    (id, index) => ({
      name: `outline-${id}`,
      steps: [hover("button", "Open transcript outline"), outlineChoice(index)],
      expect: { position: `message:${id}` },
    }),
  ),
  scrollable: [
    {
      name: "scroll-top",
      steps: [scroll("top")],
      expect: { text: "You are at the top. You can only scroll down." },
    },
    {
      name: "scroll-middle",
      steps: [scroll("middle")],
      expect: { text: "You can scroll both ways." },
    },
    {
      name: "scroll-bottom",
      steps: [scroll("bottom")],
      expect: { text: "You are at the bottom. You can only scroll up." },
    },
  ],
};

// The two pinned Data Table sources have more application state than a
// generic disclosure walk can prove. These actions cover filtering, sorting,
// row selection, column visibility, and one representative row menu. The
// other row menus have the same official structure and differ only by data.
const DATA_TABLE_ACTIONS = {
  default: [
    {
      name: "filter-carmella",
      steps: [
        { type: "filter", placeholder: "Filter emails...", value: "carmella" },
      ],
      expect: { rows: 1, text: "carmella@example.com" },
    },
    {
      name: "sort-email",
      steps: [click("button", "Email")],
      expect: { firstRowText: "Abe45@example.com" },
    },
    {
      name: "select-first-row",
      steps: [{ type: "checkbox", name: "Select row" }],
      expect: { checked: "Select row", text: "1 of 5 row(s) selected." },
    },
    {
      name: "select-all",
      steps: [{ type: "checkbox", name: "Select all" }],
      expect: { checked: "Select all", text: "5 of 5 row(s) selected." },
    },
    {
      name: "columns-menu",
      steps: [click("button", "Columns")],
      expect: { menuText: ["status", "email", "amount"] },
    },
    {
      name: "actions-menu",
      steps: [click("button", "Open menu")],
      expect: {
        menuText: [
          "Actions",
          "Copy payment ID",
          "View customer",
          "View payment details",
        ],
      },
    },
  ],
  rtl: [
    {
      name: "filter-carmella",
      steps: [
        {
          type: "filter",
          placeholder: "تصفية البريد الإلكتروني...",
          value: "carmella",
        },
      ],
      expect: { rows: 1, text: "carmella@example.com" },
    },
    {
      name: "sort-email",
      steps: [click("button", "البريد الإلكتروني")],
      expect: { firstRowText: "Abe45@example.com" },
    },
    {
      name: "select-first-row",
      steps: [{ type: "checkbox", name: "تحديد الصف" }],
      expect: { checked: "تحديد الصف", text: "1 من 5 صف(وف) محدد." },
    },
    {
      name: "select-all",
      steps: [{ type: "checkbox", name: "تحديد الكل" }],
      expect: { checked: "تحديد الكل", text: "5 من 5 صف(وف) محدد." },
    },
    {
      name: "columns-menu",
      steps: [click("button", "الأعمدة")],
      expect: { menuText: ["status", "email", "amount"] },
    },
    {
      name: "actions-menu",
      steps: [click("button", "فتح القائمة")],
      expect: {
        menuText: [
          "الإجراءات",
          "نسخ معرف الدفع",
          "عرض العميل",
          "عرض تفاصيل الدفع",
        ],
      },
    },
  ],
};

// A Date Picker has state inside its calendar and inputs. A generic
// disclosure walk only finds the open popover. These actions cover each
// pinned source, including date selection, typed input, time, and RTL.
const DATE_PICKER_ACTIONS = {
  default: [
    {
      name: "open",
      steps: [{ type: "date-picker-open" }],
      expect: { open: true },
    },
    {
      name: "select",
      steps: [
        { type: "date-picker-open" },
        { type: "date-picker-select", index: 10 },
      ],
      expect: { open: true, singleSelected: true },
    },
  ],
  basic: [
    {
      name: "open",
      steps: [{ type: "date-picker-open" }],
      expect: { open: true },
    },
    {
      name: "select",
      steps: [
        { type: "date-picker-open" },
        { type: "date-picker-select", index: 10 },
      ],
      expect: { open: true, singleSelected: true },
    },
  ],
  range: [
    {
      name: "open",
      steps: [{ type: "date-picker-open" }],
      expect: { open: true, rangeSelected: true },
    },
    {
      name: "select-range",
      steps: [
        { type: "date-picker-open" },
        { type: "date-picker-select", index: 14 },
        { type: "date-picker-select", index: 18 },
      ],
      expect: { open: true, rangeSelected: true },
    },
  ],
  dob: [
    {
      name: "open",
      steps: [{ type: "date-picker-open" }],
      expect: { open: true, dropdowns: true },
    },
    {
      name: "select",
      steps: [
        { type: "date-picker-open" },
        { type: "date-picker-select", index: 10 },
      ],
      expect: { open: false, triggerChangedFrom: "Select date" },
    },
  ],
  input: [
    {
      name: "invalid-open",
      steps: [
        {
          type: "date-picker-fill",
          selector: "#date-required",
          value: "not a date",
        },
        { type: "date-picker-arrow-down", selector: "#date-required" },
      ],
      expect: {
        open: true,
        input: ["#date-required", "not a date"],
        singleSelected: true,
      },
    },
    {
      name: "select",
      steps: [
        {
          type: "date-picker-remember-input",
          selector: "#date-required",
          key: "input",
        },
        { type: "date-picker-arrow-down", selector: "#date-required" },
        { type: "date-picker-select", index: 10 },
      ],
      expect: { open: false, changedInput: ["#date-required", "input"] },
    },
  ],
  time: [
    {
      name: "open",
      steps: [{ type: "date-picker-open" }],
      expect: { open: true, dropdowns: true },
    },
    {
      name: "select-with-time",
      steps: [
        {
          type: "date-picker-fill",
          selector: "#time-picker-optional",
          value: "11:45:30",
        },
        { type: "date-picker-open" },
        { type: "date-picker-select", index: 10 },
      ],
      expect: {
        open: false,
        triggerChangedFrom: "Select date",
        input: ["#time-picker-optional", "11:45:30"],
      },
    },
  ],
  "natural-language": [
    {
      name: "typed-open",
      steps: [
        {
          type: "date-picker-fill",
          selector: "#date-optional",
          value: "tomorrow",
        },
        { type: "date-picker-arrow-down", selector: "#date-optional" },
      ],
      expect: {
        open: true,
        input: ["#date-optional", "tomorrow"],
        singleSelected: true,
        dropdowns: true,
      },
    },
    {
      name: "select",
      steps: [
        {
          type: "date-picker-remember-input",
          selector: "#date-optional",
          key: "natural-language",
        },
        { type: "date-picker-arrow-down", selector: "#date-optional" },
        { type: "date-picker-select", index: 10 },
      ],
      expect: {
        open: false,
        changedInput: ["#date-optional", "natural-language"],
      },
    },
  ],
  rtl: [
    {
      name: "open",
      steps: [{ type: "date-picker-open" }],
      expect: { open: true, rtl: true },
    },
    {
      name: "select",
      steps: [
        { type: "date-picker-open" },
        { type: "date-picker-select", index: 10 },
      ],
      expect: { open: true, singleSelected: true, rtl: true },
    },
  ],
};

// A calendar exposes many date buttons with the same selection semantics.
// Scan one representative selected-date state instead of making a separate
// accessibility scan for every day in each displayed month.
const CALENDAR_ACTIONS = [{ name: "select-day" }];

/** The action-state contract for one official Message Scroller example. */
export function messageScrollerActionStates(example) {
  const actions = messageScrollerActionDefinitions(example);

  return actions.map(({ name }) => ({
    name: `action:${name}`,
    kind: "message-scroller-action",
    action: name,
  }));
}

/** The concrete actions for one official Message Scroller source. */
export function messageScrollerActionDefinitions(example) {
  const actions = MESSAGE_SCROLLER_ACTIONS[example];
  if (!actions) throw new Error(`unknown Message Scroller example: ${example}`);
  return actions;
}

/** The action-state contract for one official Data Table example. */
export function dataTableActionStates(example) {
  const actions = dataTableActionDefinitions(example);

  return actions.map(({ name }) => ({
    name: `action:${name}`,
    kind: "data-table-action",
    action: name,
  }));
}

/** The complete state set for one official Data Table example. */
export function dataTableVisualStates(example) {
  return [
    { name: "default", kind: "default" },
    ...dataTableActionStates(example),
  ];
}

/** The Data Table model owns its checkbox and menu states. */
export function dataTableVisualModel(example) {
  const actions = dataTableActionDefinitions(example);

  return {
    kind: "data-table",
    example,
    actions,
    claimedControlKinds: ["checked"],
    claimsExpandedStates: true,
  };
}

/** The concrete actions for one Data Table source. */
export function dataTableActionDefinitions(example) {
  const actions = DATA_TABLE_ACTIONS[example];
  if (!actions) throw new Error(`unknown Data Table example: ${example}`);
  return actions;
}

/** The action-state contract for one official Date Picker example. */
export function datePickerActionStates(example) {
  const actions = DATE_PICKER_ACTIONS[example];
  if (!actions) throw new Error(`unknown Date Picker example: ${example}`);

  return actions.map(({ name }) => ({
    name: `action:${name}`,
    kind: "date-picker-action",
    action: name,
  }));
}

/** The representative accessibility action for every Calendar example. */
export function calendarActionStates() {
  return CALENDAR_ACTIONS.map(({ name }) => ({
    name: `action:${name}`,
    kind: "calendar-action",
    action: name,
  }));
}

async function visualActionModel(scope) {
  const component = await scope.getAttribute("data-preview");
  const declared = await scope.getAttribute("data-visual-actions");

  const id = await scope.getAttribute("id");

  if (component === "message-scroller") {
    if (declared !== "message-scroller") {
      throw new Error(
        "Message Scroller must declare data-visual-actions=message-scroller",
      );
    }

    const prefix = "preview-message-scroller-";
    if (!id?.startsWith(prefix))
      throw new Error("Message Scroller preview must have a stable example id");

    const example = id.slice(prefix.length);
    const actions = MESSAGE_SCROLLER_ACTIONS[example];
    if (!actions)
      throw new Error(`unknown Message Scroller example: ${example}`);

    return {
      kind: "message-scroller",
      actions,
      claimedControlKinds: example === "opening-position" ? ["tab"] : [],
    };
  }

  if (component === "data-table") {
    if (declared !== "data-table") {
      throw new Error("Data Table must declare data-visual-actions=data-table");
    }

    const prefix = "preview-data-table-";
    if (!id?.startsWith(prefix))
      throw new Error("Data Table preview must have a stable example id");

    const example = id.slice(prefix.length);
    return dataTableVisualModel(example);
  }

  if (component === "date-picker") {
    if (declared !== "date-picker") {
      throw new Error(
        "Date Picker must declare data-visual-actions=date-picker",
      );
    }

    const prefix = "preview-date-picker-";
    if (!id?.startsWith(prefix))
      throw new Error("Date Picker preview must have a stable example id");

    const example = id.slice(prefix.length);
    const actions = DATE_PICKER_ACTIONS[example];
    if (!actions) throw new Error(`unknown Date Picker example: ${example}`);

    return { kind: "date-picker", actions, claimsExpandedStates: true };
  }

  if (component === "calendar") {
    return { kind: "calendar", actions: CALENDAR_ACTIONS };
  }

  return null;
}

// A controlled React dialog can use an ordinary button and application state.
// That button has no aria-expanded or aria-controls, so the disclosure walk
// cannot find the open state. The stable evidence is the Dialog header that is
// already in the example and a Dialog content part that appears after a click.
async function discoverControlledDialogStates(page, scope, states) {
  if ((await scope.locator("[data-slot='dialog-header']").count()) === 0)
    return;

  const controls = actionControls(scope);

  for (let index = 0; index < (await controls.count()); index += 1) {
    const control = controls.nth(index);
    const before = await page
      .locator("[data-slot='dialog-content']:visible")
      .count();
    await control.evaluate((element) => element.click());

    let opened = false;

    try {
      await page.waitForFunction(
        (count) =>
          document.querySelectorAll(
            "[data-slot='dialog-content']:not([hidden])",
          ).length > count,
        before,
        { timeout: 1_000 },
      );
      opened = true;
    } catch {
      // This action did not open a Dialog. It is not a render state here.
    }

    if (!opened) continue;

    const label = (await control.evaluate(accessibleName)) || String(index + 1);
    states.push({ name: `dialog:${label}`, kind: "dialog", index });

    await page.keyboard.press("Escape");
    await page.waitForFunction(
      (count) =>
        document.querySelectorAll("[data-slot='dialog-content']:not([hidden])")
          .length <= count,
      before,
    );
  }
}

async function discoverActionStates(scope, states, model, component) {
  if (model) {
    for (const action of model.actions) {
      states.push({
        name: `action:${action.name}`,
        kind: `${model.kind}-action`,
        action: action.name,
      });
    }
    return;
  }

  const declared = await scope.getAttribute("data-visual-actions");
  const officialInteractive = isOfficialInteractiveShadcnComponent(component);

  if (declared === null && !officialInteractive) return;

  const controls = actionControls(scope);
  const settleMs = Number(
    (await scope.getAttribute("data-visual-action-settle-ms")) ?? 0,
  );

  for (let index = 0; index < (await controls.count()); index += 1) {
    const control = controls.nth(index);
    const label = (await control.evaluate(accessibleName)) || String(index + 1);
    const kind = declared === null ? "interactive-action" : "action";
    states.push({ name: `action:${label}`, kind, index });

    if (kind === "action" && settleMs > 0) {
      states.push({
        name: `action-settled:${label}`,
        kind: "action-settled",
        index,
        settleMs,
      });
    }
  }
}

// Named component suites also drive native fields. Role-based controls belong
// to `discoverControlStates`; these native controls have no role in the React
// source and would otherwise have no visual render state.
async function discoverEditableControlStates(scope, states, component, model) {
  if (model || !isOfficialInteractiveShadcnComponent(component)) return;

  const controls = scope.locator(nativeVisualControlSelector());

  for (let index = 0; index < (await controls.count()); index += 1) {
    const control = controls.nth(index);
    if (!(await control.isVisible()) || (await control.isDisabled())) continue;

    const descriptor = await nativeControlDescriptor(control);

    if (descriptor.kind === "native-select" && descriptor.value === null)
      continue;

    const label = descriptor.label || String(index + 1);
    states.push({
      name: `${descriptor.kind}:${label}`,
      kind: descriptor.kind,
      index,
      selector: nativeVisualControlSelector(),
      value: descriptor.value,
    });
  }
}

// A control marked aria-hidden is an implementation proxy, not a control a
// reader can use. Base UI Select uses one for browser autofill. Keep real,
// visible editable fields in the state model. Read-only fields remain visible
// during expanded-state scans, but have no text mutation state.
export function nativeVisualControlSelector() {
  return [
    "input:not([type]):not([readonly]):not([aria-hidden='true']):visible, input[type='text']:not([readonly]):not([aria-hidden='true']):visible, input[type='search']:not([readonly]):not([aria-hidden='true']):visible",
    "input[type='email']:not([readonly]):not([aria-hidden='true']):visible, input[type='url']:not([readonly]):not([aria-hidden='true']):visible, input[type='tel']:not([readonly]):not([aria-hidden='true']):visible",
    "input[type='password']:not([readonly]):not([aria-hidden='true']):visible, textarea:not([readonly]):not([aria-hidden='true']):visible, input[type='checkbox']:not([aria-hidden='true']):visible",
    "input[type='radio']:not([aria-hidden='true']):visible, input[type='range']:not([aria-hidden='true']):visible, select:not([aria-hidden='true']):visible",
  ].join(", ");
}

const nativeControlDescriptor = (control) =>
  control.evaluate((element) => {
    const input = element instanceof HTMLInputElement ? element : null;
    const kind =
      element instanceof HTMLSelectElement
        ? "native-select"
        : input?.type === "checkbox" || input?.type === "radio"
          ? "native-checked"
          : input?.type === "range"
            ? "native-range"
            : "editable";
    const label =
      element.getAttribute("aria-label") ||
      Array.from(element.labels ?? [])
        .map((label) => label.textContent || "")
        .join(" ") ||
      element.getAttribute("name") ||
      element.getAttribute("id") ||
      "";
    const option =
      element instanceof HTMLSelectElement
        ? Array.from(element.options).find(
            (candidate) =>
              !candidate.disabled && candidate.value !== element.value,
          )
        : null;

    return {
      kind,
      label: label.replace(/\s+/g, " ").trim(),
      value: option?.value ?? null,
    };
  });

async function discoverControlStates(scope, states, model) {
  for (const kind of ["pressed", "checked", "tab"]) {
    if (model?.claimedControlKinds?.includes(kind)) continue;
    const controls = stateControls(scope, kind);
    const count = await controls.count();

    for (let index = 0; index < count; index += 1) {
      const control = controls.nth(index);
      const label =
        (await control.evaluate(accessibleName)) || String(index + 1);
      states.push({ name: `${kind}:${label}`, kind, index });
    }
  }
}

// A menu item is not visible until its trigger is open. Walk each disclosure
// branch once so visual checks also cover the selected, typed, and clicked
// states that the named behaviour suites enter inside menus and panels.
async function discoverNestedInteractiveStates(
  page,
  scope,
  path,
  labels,
  states,
) {
  const triggers = actionableTriggers(scope);
  const count = await triggers.count();

  for (let index = 0; index < count; index += 1) {
    const trigger = triggers.nth(index);
    if ((await trigger.getAttribute("aria-expanded")) === "true") continue;

    const label = (await trigger.evaluate(accessibleName)) || String(index + 1);
    const nextPath = [...path, { index }];
    const nextLabels = [...labels, label];
    const triggerElement = await trigger.elementHandle();

    if ((await trigger.getAttribute("aria-haspopup")) === "listbox") {
      await openListboxBeforeClearingHover(page, trigger);
    } else {
      await trigger.evaluate((element) => element.click());
    }

    await waitForElementExpanded(triggerElement, "true");
    const controls = await triggerElement.evaluate((element) =>
      element.getAttribute("aria-controls"),
    );

    if (controls) {
      const controlled = page.locator(`[id=${JSON.stringify(controls)}]`);

      try {
        await controlled.waitFor({ state: "visible", timeout: 1_000 });
        await discoverNestedControlStates(
          controlled,
          nextPath,
          nextLabels,
          states,
        );
        await discoverNestedInteractiveStates(
          page,
          controlled,
          nextPath,
          nextLabels,
          states,
        );
      } catch {
        // The branch has no visible controlled content. Its open state is
        // still measured by `discoverExpandedStates` below.
      }
    }

    await closeRootState(page, trigger);
  }
}

async function discoverNestedControlStates(scope, path, labels, states) {
  for (const controlKind of ["pressed", "checked", "tab"]) {
    const controls = stateControls(scope, controlKind);

    for (let index = 0; index < (await controls.count()); index += 1) {
      const control = controls.nth(index);
      const label =
        (await control.evaluate(accessibleName)) || String(index + 1);
      states.push({
        name: `action:${labels.join(" > ")} > ${controlKind}:${label}`,
        kind: "nested-control",
        controlKind,
        index,
        path,
      });
    }
  }

  const nativeControls = scope.locator(nativeVisualControlSelector());
  for (let index = 0; index < (await nativeControls.count()); index += 1) {
    const control = nativeControls.nth(index);
    if (await control.isDisabled()) continue;

    const descriptor = await nativeControlDescriptor(control);
    if (descriptor.kind === "native-select" && descriptor.value === null)
      continue;

    states.push({
      name: `action:${labels.join(" > ")} > ${descriptor.kind}:${descriptor.label || index + 1}`,
      kind: "nested-native-control",
      controlKind: descriptor.kind,
      index,
      path,
      selector: nativeVisualControlSelector(),
      value: descriptor.value,
    });
  }

  const buttons = actionControls(scope);
  for (let index = 0; index < (await buttons.count()); index += 1) {
    const button = buttons.nth(index);
    const label = (await button.evaluate(accessibleName)) || String(index + 1);
    states.push({
      name: `action:${labels.join(" > ")} > button:${label}`,
      kind: "nested-action",
      index,
      path,
    });
  }
}

async function discoverExpandedStates(page, scope, path, labels, states) {
  const triggers = actionableTriggers(scope);
  const count = await triggers.count();

  for (let index = 0; index < count; index += 1) {
    const trigger = triggers.nth(index);
    if ((await trigger.getAttribute("aria-expanded")) === "true") continue;

    const label = (await trigger.evaluate(accessibleName)) || String(index + 1);
    const nextPath = [...path, { index }];
    const nextLabels = [...labels, label];

    states.push({
      name: `expanded:${nextLabels.join(" > ")}`,
      kind: "expanded",
      path: nextPath,
    });

    const triggerElement = await trigger.elementHandle();

    // Discovery records branches, but it does not measure them. Most
    // disclosures can use a DOM click. Base UI listboxes require a real user
    // click, so move the pointer away after they open.
    if ((await trigger.getAttribute("aria-haspopup")) === "listbox") {
      await openListboxBeforeClearingHover(page, trigger);
    } else {
      await trigger.evaluate((element) => element.click());
    }
    await waitForElementExpanded(triggerElement, "true");
    const controls = await triggerElement.evaluate((element) =>
      element.getAttribute("aria-controls"),
    );

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
        await discoverExpandedStates(
          page,
          controlled,
          nextPath,
          nextLabels,
          states,
        );
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
  await referenceReady(page);
  if (state.kind === "default") {
    await settleInteraction(page, { waitForTransitions: true });
    return;
  }

  if (state.kind === "message-scroller-action") {
    const scope = page.locator(selector);
    const model = await visualActionModel(scope);
    const action = model.actions.find(({ name }) => name === state.action);
    if (!action)
      throw new Error(`unknown Message Scroller action: ${state.action}`);

    const context = {};
    for (const step of action.steps)
      await runMessageScrollerStep(page, scope, step, context);
    await waitForMessageScrollerAction(
      page,
      scope,
      resolveMessageScrollerContract(action.expect, context),
    );
    await settleMessageScrollerActionVisualState(page, selector);
    return;
  }

  if (state.kind === "data-table-action") {
    const scope = page.locator(selector);
    const model = await visualActionModel(scope);
    const action = model.actions.find(({ name }) => name === state.action);
    if (!action) throw new Error(`unknown Data Table action: ${state.action}`);

    for (const step of action.steps) await runDataTableStep(scope, step);
    await waitForDataTableAction(page, scope, action.expect);
    await settleInteraction(page, { waitForTransitions: true });
    return;
  }

  if (state.kind === "date-picker-action") {
    const scope = page.locator(selector);
    const model = await visualActionModel(scope);
    const action = model.actions.find(({ name }) => name === state.action);
    if (!action) throw new Error(`unknown Date Picker action: ${state.action}`);

    const context = {};
    for (const step of action.steps)
      await runDatePickerStep(page, scope, step, context);
    await waitForDatePickerAction(page, scope, action.expect, context);
    await settleInteraction(page, { waitForTransitions: true });
    return;
  }

  if (state.kind === "calendar-action") {
    const scope = page.locator(selector);
    const day = scope
      .locator(
        "button[data-day]:not(:disabled), button[data-lb-calendar-day]:not(:disabled)",
      )
      .first();

    await day.click();
    await settleInteraction(page, { waitForTransitions: true });
    return;
  }

  if (state.kind === "chart-hover") {
    const scope = page.locator(selector);
    const hook = scope.locator("[phx-hook='ChartTooltip'], [phx-hook='ChartDemoTooltip']");
    if ((await hook.count()) > 0) {
      await hook.waitFor({ state: "attached" });
      await page.waitForFunction(
        (element) => element?.getAttribute("data-chart-ready") === "true",
        await hook.elementHandle(),
      );
    }
    await scope
      .locator(".recharts-rectangle:not(.recharts-tooltip-cursor)")
      .nth(state.index)
      .hover();
    await scope
      .locator(".recharts-tooltip-wrapper")
      .waitFor({ state: "visible" });
    await settleInteraction(page);
    return;
  }

  if (state.kind === "interactive-action") {
    const scope = page.locator(selector);
    await actionControls(scope).nth(state.index).click();
    await settleInteraction(page, { waitForTransitions: true });
    await waitForCarouselMotion(page, selector);
    return;
  }

  if (
    ["editable", "native-checked", "native-range", "native-select"].includes(
      state.kind,
    )
  ) {
    const control = page
      .locator(selector)
      .locator(state.selector)
      .nth(state.index);

    await enterNativeVisualControl(control, state.kind, state.value);

    await settleInteraction(page, { waitForTransitions: true });
    await waitForComboboxEmptyLiveRegion(page, selector, state);
    return;
  }

  if (state.kind === "nested-control") {
    const scope = await enterNestedInteractionPath(page, selector, state.path);
    await stateControls(scope, state.controlKind).nth(state.index).click();
    await settleInteraction(page, { waitForTransitions: true });
    return;
  }

  if (state.kind === "nested-native-control") {
    const scope = await enterNestedInteractionPath(page, selector, state.path);
    const control = scope.locator(state.selector).nth(state.index);
    await enterNativeVisualControl(control, state.controlKind, state.value);

    await settleInteraction(page, { waitForTransitions: true });
    return;
  }

  if (state.kind === "nested-action") {
    const scope = await enterNestedInteractionPath(page, selector, state.path);
    const action = actionControls(scope).nth(state.index);
    // A compact snap point can place a footer outside the fixed viewport.
    // Follow the real Tab path before activating that button with Enter.
    const outsideSnapViewport = await action.evaluate((element) => {
      if (!element.closest("[data-slot='drawer-popup'][data-snap-points]")) return false;
      const box = element.getBoundingClientRect();
      return box.bottom <= 0 || box.top >= innerHeight || box.right <= 0 || box.left >= innerWidth;
    });
    if (outsideSnapViewport) {
      const limit = await scope.locator("a[href], button, input, select, textarea, [tabindex]").count() + 1;
      for (let step = 0; step < limit && !(await action.evaluate((element) => element === element.ownerDocument.activeElement)); step += 1) {
        await page.keyboard.press("Tab");
      }
      if (!(await action.evaluate((element) => element === element.ownerDocument.activeElement))) {
        throw new Error("compact Drawer action is not reachable through Tab");
      }
      await page.keyboard.press("Enter");
    } else {
      await action.click();
    }

    await settleInteraction(page, { waitForTransitions: true });
    return;
  }

  if (state.kind === "action" || state.kind === "action-settled") {
    const scope = page.locator(selector);
    const before = await page.locator("[data-slot='toast']").count();
    await actionControls(scope).nth(state.index).click();
    await page.waitForFunction(
      (count) =>
        document.querySelectorAll("[data-slot='toast']").length > count,
      before,
    );

    if (state.kind === "action-settled")
      await page.waitForTimeout(state.settleMs);
    await settleInteraction(page);
    return;
  }

  if (state.kind === "dialog") {
    const scope = page.locator(selector);
    await actionControls(scope).nth(state.index).click();
    await page.locator("[data-slot='dialog-content']:visible").waitFor();
    await settleInteraction(page);
    return;
  }

  if (["pressed", "checked", "tab"].includes(state.kind)) {
    const control = stateControls(page.locator(selector), state.kind).nth(
      state.index,
    );
    await control.click();
    await settleInteraction(page);
    return;
  }

  if (state.kind === "hover" || state.kind === "context") {
    const trigger = page
      .locator(specialTriggers(selector, state.kind))
      .nth(state.index);
    const triggerSlot = await trigger.getAttribute("data-slot");
    const contentSlot = triggerSlot.replace(/-trigger$/, "-content");

    await page.mouse.move(0, 0);

    if (state.kind === "hover") await trigger.hover();
    else await trigger.click({ button: "right" });

    await page.locator(`[data-slot='${contentSlot}']:visible`).waitFor();
    await settleInteraction(page, { waitForTransitions: true });
    return;
  }

  let scope = page.locator(selector);
  // Clear hover before the interaction starts. Do not move the pointer after
  // a nested menu opens: upstream closes that menu when the pointer leaves it.
  await page.mouse.move(0, 0);

  const path = state.path ?? [{ index: state.index }];

  for (const [position, step] of path.entries()) {
    const trigger = actionableTriggers(scope).nth(step.index);
    const triggerElement = await trigger.elementHandle();

    if ((await trigger.getAttribute("aria-expanded")) !== "true") {
      // A listbox can open under the pointer. Finish popup entry before
      // leaving it, so both hosts clear the same option-hover state.
      if ((await trigger.getAttribute("aria-haspopup")) === "listbox") {
        await openListboxBeforeClearingHover(page, trigger);
      } else {
        await trigger.click();
        if (path.length === 1) await page.mouse.move(0, 0);
      }
    }

    await waitForElementExpanded(triggerElement, "true");
    const controls = await triggerElement.evaluate((element) =>
      element.getAttribute("aria-controls"),
    );

    if (controls && position < path.length - 1) {
      scope = page.locator(`[id=${JSON.stringify(controls)}]`);
      await scope.waitFor({ state: "visible" });
    }
  }

  await settleInteraction(page, { waitForTransitions: true });
}

async function openListboxBeforeClearingHover(page, trigger) {
  await trigger.click();
  await waitForExpanded(trigger, "true");
  const controls = await trigger.getAttribute("aria-controls");
  if (!controls) throw new Error("expanded listbox trigger has no controlled content");
  await page.locator(`[id=${JSON.stringify(controls)}]`).waitFor({ state: "visible" });
  await settleInteraction(page, { waitForTransitions: true });
  await page.mouse.move(0, 0);
}

async function enterNativeVisualControl(control, kind, value) {
  if (kind === "editable") {
    await control.fill("Parity text");
    return;
  }

  if (kind === "native-range") {
    await control.focus();
    await control.press("End");
    return;
  }

  if (kind === "native-select") {
    await control.selectOption(value);
    return;
  }

  await control.click();
}

async function enterNestedInteractionPath(page, selector, path) {
  let scope = page.locator(selector);
  await page.mouse.move(0, 0);

  for (const [position, step] of path.entries()) {
    const trigger = actionableTriggers(scope).nth(step.index);
    const triggerElement = await trigger.elementHandle();
    const listbox = (await trigger.getAttribute("aria-haspopup")) === "listbox";

    if ((await trigger.getAttribute("aria-expanded")) !== "true") {
      if (listbox) {
        await openListboxBeforeClearingHover(page, trigger);
      } else {
        await trigger.click();
        // Leaving a nested menu closes the pinned React submenu.
        if (position === 0) await page.mouse.move(0, 0);
      }
    }

    await waitForElementExpanded(triggerElement, "true");
    const controls = await triggerElement.evaluate((element) =>
      element.getAttribute("aria-controls"),
    );
    if (!controls)
      throw new Error("nested visual action trigger has no controlled content");

    scope = page.locator(`[id=${JSON.stringify(controls)}]`);
    await scope.waitFor({ state: "visible" });
  }

  // Opening focus can run again in a later animation frame. Finish popup
  // entry before a nested action edits a field or moves selection.
  await settleInteraction(page, { waitForTransitions: true });
  return scope;
}

async function runMessageScrollerStep(page, scope, step, context) {
  if (step.type === "clear-hover") {
    await page.mouse.move(0, 0);
    return;
  }

  if (step.type === "reply") {
    await waitForMessageScrollerReply(page, scope);
    return;
  }

  if (step.type === "wait") {
    await waitForMessageScrollerAction(page, scope, step.expect);
    return;
  }

  if (step.type === "remember-scroll") {
    context[step.key] = await scope
      .locator("[data-slot='message-scroller-viewport']")
      .evaluate((viewport) => viewport.scrollTop);
    return;
  }

  if (step.type === "select") {
    const trigger = messageScrollerAnimationPreset(scope);
    await trigger.click();
    const option = page.getByRole("option", { name: step.name, exact: true });
    await option.click();
    return;
  }

  if (step.type === "slider") {
    let control = scope.getByRole("slider", { name: step.name, exact: true });
    if ((await control.count()) === 0) {
      control = scope
        .getByRole("group", { name: step.name, exact: true })
        .getByRole("slider");
    }
    const count = await control.count();
    if (count !== 1) {
      throw new Error(
        `expected one ${step.name} slider at ${page.url()}, found ${count}`,
      );
    }
    await control.focus();
    await control.press(step.value === 128 ? "End" : "Home");
    return;
  }

  if (step.type === "scroll") {
    await scope
      .locator("[data-slot='message-scroller-viewport']")
      .evaluate((viewport, position) => {
        const maximum = viewport.scrollHeight - viewport.clientHeight;
        const top =
          position === "top"
            ? 0
            : position === "bottom"
              ? maximum
              : maximum / 2;
        viewport.scrollTo({ top, behavior: "auto" });
      }, step.position);
    return;
  }

  if (step.type === "menu-item") {
    const popup = await messageScrollerCommandMenuPopup(page, scope);
    const item = popup.locator("[role='menuitem']").nth(step.index);
    await item.click();
    return;
  }

  if (step.type === "outline-choice") {
    const popup = page.locator("[data-slot='hover-card-content']:visible");
    if ((await popup.count()) !== 1)
      throw new Error("Message Scroller outline did not open exactly once");
    const choice = popup.getByRole("button").nth(step.index);
    await choice.click();
    return;
  }

  const control = scope.getByRole(step.role, { name: step.name, exact: true });
  if (step.type === "hover") {
    await control.hover();
    await page.locator("[data-slot='hover-card-content']:visible").waitFor();
  } else {
    await control.click();
  }
}

async function runDataTableStep(scope, step) {
  if (step.type === "filter") {
    const input = scope.getByPlaceholder(step.placeholder, { exact: true });
    if ((await input.count()) !== 1)
      throw new Error(`Data Table filter ${step.placeholder} is not unique`);
    await input.fill(step.value);
    return;
  }

  if (step.type === "checkbox") {
    const control = scope
      .getByRole("checkbox", { name: step.name, exact: true })
      .first();
    await control.click();
    return;
  }

  const control = scope
    .getByRole(step.role, { name: step.name, exact: true })
    .first();
  await control.click();
}

async function waitForDataTableAction(page, scope, contract) {
  const root = await scope.elementHandle();
  if (!root) throw new Error("Data Table preview is not attached");

  const matches = ({ root, contract }) => {
    const normalized = (value) => value.replace(/\s+/g, " ").trim();
    const rows = root.querySelectorAll("tbody tr");
    const rootText = normalized(root.textContent || "");

    if (contract.rows != null && rows.length !== contract.rows) return false;
    if (contract.text && !rootText.includes(contract.text)) return false;
    if (
      contract.firstRowText &&
      !normalized(rows[0]?.textContent || "").includes(contract.firstRowText)
    ) {
      return false;
    }

    if (contract.checked) {
      const control = [...root.querySelectorAll("[role='checkbox']")].find(
        (element) => element.getAttribute("aria-label") === contract.checked,
      );
      if (!control || control.getAttribute("aria-checked") !== "true")
        return false;
    }

    if (contract.menuText) {
      const popup = [
        ...document.querySelectorAll("[data-slot='dropdown-menu-content']"),
      ].find((element) => {
        const style = getComputedStyle(element);
        return (
          !element.hidden &&
          style.display !== "none" &&
          style.visibility !== "hidden"
        );
      });
      const popupText = normalized(popup?.textContent || "");
      if (
        !popup ||
        !contract.menuText.every((text) => popupText.includes(text))
      )
        return false;
    }

    return true;
  };

  try {
    await page.waitForFunction(
      matches,
      { root, contract },
      { timeout: 10_000 },
    );
  } catch {
    const actual = await scope.evaluate((element) => ({
      rows: element.querySelectorAll("tbody tr").length,
      text: element.textContent?.replace(/\s+/g, " ").trim() ?? "",
      checked: [...element.querySelectorAll("[role='checkbox']")]
        .filter((control) => control.getAttribute("aria-checked") === "true")
        .map((control) => control.getAttribute("aria-label")),
      menus: [
        ...document.querySelectorAll("[data-slot='dropdown-menu-content']"),
      ]
        .filter((popup) => !popup.hidden)
        .map((popup) => popup.textContent?.replace(/\s+/g, " ").trim() ?? ""),
    }));
    throw new Error(
      `Data Table action contract failed at ${page.url()}: expected ${JSON.stringify(contract)}, got ${JSON.stringify(actual)}`,
    );
  }
}

function datePickerPopup(page) {
  return page.locator("[data-slot='popover-content']:visible").last();
}

/** Settle a Message Scroller action before its visual state is measured. */
export async function settleMessageScrollerActionVisualState(page, selector) {
  await settleInteraction(page);
  await waitForMessageScrollerEntryAnimations(page, selector);
}

async function runDatePickerStep(page, scope, step, context) {
  if (step.type === "date-picker-open") {
    const trigger = scope.locator("[aria-haspopup='dialog']").first();
    if ((await trigger.count()) !== 1) {
      throw new Error(
        `Date Picker must have one dialog trigger at ${page.url()}`,
      );
    }
    await trigger.click();
    await datePickerPopup(page).waitFor({ state: "visible" });
    return;
  }

  if (step.type === "date-picker-fill") {
    await scope.locator(step.selector).fill(step.value);
    return;
  }

  if (step.type === "date-picker-arrow-down") {
    await scope.locator(step.selector).press("ArrowDown");
    await datePickerPopup(page).waitFor({ state: "visible" });
    return;
  }

  if (step.type === "date-picker-remember-input") {
    context[step.key] = await scope.locator(step.selector).inputValue();
    return;
  }

  if (step.type === "date-picker-select") {
    const days = datePickerPopup(page).locator(
      "[role='gridcell'] button[data-day]:not(:disabled)",
    );
    const count = await days.count();
    if (count <= step.index) {
      throw new Error(
        `Date Picker has ${count} enabled days, cannot select index ${step.index}`,
      );
    }
    await days.nth(step.index).click();
    return;
  }

  throw new Error(`unknown Date Picker action step: ${step.type}`);
}

async function waitForDatePickerAction(page, scope, contract, context) {
  const root = await scope.elementHandle();
  if (!root) throw new Error("Date Picker preview is not attached");

  const matches = ({ root, contract, context }) => {
    const visible = (element) => {
      const style = getComputedStyle(element);
      return (
        !element.hidden &&
        style.display !== "none" &&
        style.visibility !== "hidden"
      );
    };
    const popup = [
      ...document.querySelectorAll("[data-slot='popover-content']"),
    ].find(visible);

    if (contract.open != null && Boolean(popup) !== contract.open) return false;

    const calendarRoot = popup || document;
    const selectedSingle = calendarRoot.querySelector(
      "button[data-selected-single]:not([data-selected-single='false'])",
    );
    const rangeStart = calendarRoot.querySelector(
      "button[data-range-start]:not([data-range-start='false'])",
    );
    const rangeEnd = calendarRoot.querySelector(
      "button[data-range-end]:not([data-range-end='false'])",
    );

    if (contract.singleSelected && !selectedSingle) return false;
    if (contract.rangeSelected && (!rangeStart || !rangeEnd)) return false;

    if (contract.dropdowns && popup?.querySelectorAll("select").length < 2)
      return false;

    if (
      contract.rtl &&
      (popup?.getAttribute("dir") !== "rtl" ||
        !popup.querySelector("[dir='rtl']"))
    ) {
      return false;
    }

    if (contract.input) {
      const [selector, value] = contract.input;
      if (root.querySelector(selector)?.value !== value) return false;
    }

    if (contract.changedInput) {
      const [selector, key] = contract.changedInput;
      const value = root.querySelector(selector)?.value;
      if (value == null || value === context[key]) return false;
    }

    if (contract.triggerChangedFrom) {
      const trigger = root.querySelector("[aria-haspopup='dialog']");
      if (
        !trigger ||
        trigger.textContent?.trim() === contract.triggerChangedFrom
      )
        return false;
    }

    return true;
  };

  try {
    await page.waitForFunction(
      matches,
      { root, contract, context },
      { timeout: 10_000 },
    );
  } catch {
    const actual = await scope.evaluate((element) => {
      const visible = (popup) => {
        const style = getComputedStyle(popup);
        return (
          !popup.hidden &&
          style.display !== "none" &&
          style.visibility !== "hidden"
        );
      };
      const popup = [
        ...document.querySelectorAll("[data-slot='popover-content']"),
      ].find(visible);
      return {
        popup: popup
          ? {
              dir: popup.getAttribute("dir"),
              selects: popup.querySelectorAll("select").length,
            }
          : null,
        selectedSingle: document.querySelectorAll(
          "button[data-selected-single]:not([data-selected-single='false'])",
        ).length,
        rangeStarts: document.querySelectorAll(
          "button[data-range-start]:not([data-range-start='false'])",
        ).length,
        rangeEnds: document.querySelectorAll(
          "button[data-range-end]:not([data-range-end='false'])",
        ).length,
        inputs: [...element.querySelectorAll("input")].map((input) => ({
          id: input.id,
          value: input.value,
        })),
      };
    });
    throw new Error(
      `Date Picker action contract failed at ${page.url()}: expected ${JSON.stringify(contract)}, got ${JSON.stringify(actual)}`,
    );
  }
}

async function waitForMessageScrollerReply(page, scope) {
  await scope
    .locator("[data-slot='message-scroller-content'][aria-busy='true']")
    .waitFor();
  const root = await scope.elementHandle();
  await page.waitForFunction(
    (element) =>
      element
        .querySelector("[data-slot='message-scroller-content']")
        ?.getAttribute("aria-busy") === "false",
    root,
  );
}

async function waitForMessageScrollerAction(page, scope, contract) {
  const root = await scope.elementHandle();
  if (!root) throw new Error("Message Scroller preview is not attached");

  if (contract.position?.startsWith("message:") && contract.scrollMargin != null) {
    await waitForMessageScrollerAnchorGeometry(
      page,
      root,
      contract.position.slice("message:".length),
    );
  }

  const matches = ({ root, contract }) => {
    const items = root.querySelectorAll("[data-slot='message-scroller-item']");
    const content = root.querySelector(
      "[data-slot='message-scroller-content']",
    );
    const textMatches = (text) =>
      [...root.querySelectorAll("*")].some(
        (element) => element.textContent?.trim() === text,
      );

    if (contract.items != null && items.length !== contract.items) return false;
    if (
      contract.busy != null &&
      content?.getAttribute("aria-busy") !== String(contract.busy)
    )
      return false;
    if (contract.empty && !textMatches(contract.empty)) return false;
    if (contract.text && !textMatches(contract.text)) return false;
    if (contract.absentText && textMatches(contract.absentText)) return false;
    if (
      contract.messageId &&
      !root.querySelector(
        `[data-message-id=${JSON.stringify(contract.messageId)}]`,
      )
    )
      return false;
    if (
      contract.absentMessageId &&
      root.querySelector(
        `[data-message-id=${JSON.stringify(contract.absentMessageId)}]`,
      )
    )
      return false;
    if (
      contract.button &&
      ![...root.querySelectorAll("button")].some(
        (button) => button.textContent?.trim() === contract.button,
      )
    )
      return false;

    if (contract.slider) {
      const [name, value] = contract.slider;
      const sliders = [
        ...root.querySelectorAll("[role='slider'], input[type='range']"),
      ];
      const namedSlider = sliders.find(
        (element) => element.getAttribute("aria-label") === name,
      );
      const group = [...root.querySelectorAll("[role='group']")].find(
        (element) => element.getAttribute("aria-label") === name,
      );
      const slider =
        namedSlider ||
        group?.querySelector("[role='slider']") ||
        (sliders.length === 1 ? sliders[0] : null);
      const sliderValue =
        slider?.getAttribute("aria-valuenow") ?? slider?.value;
      if (!slider || Number(sliderValue) !== value) return false;
    }

    if (contract.selected) {
      const { role, name, value } = contract.selected;
      const control = root.querySelector(
        `button[role=${JSON.stringify(role)}][aria-label=${JSON.stringify(name)}]`,
      );
      if (control?.querySelector("[data-slot='select-value']")?.textContent?.trim() !== value)
        return false;
    }

    if (contract.tab) {
      const tab = [...root.querySelectorAll("[role='tab']")].find(
        (element) => element.textContent?.trim() === contract.tab,
      );
      if (!tab || tab.getAttribute("aria-selected") !== "true") return false;
    }

    const viewport = root.querySelector(
      "[data-slot='message-scroller-viewport']",
    );
    if (
      contract.scrollTop != null &&
      (!viewport || Math.abs(viewport.scrollTop - contract.scrollTop) > 1)
    )
      return false;
    if (contract.buttonActive != null) {
      const button = root.querySelector(
        "[data-slot='message-scroller-button']",
      );
      if (
        !button ||
        button.getAttribute("data-active") !== String(contract.buttonActive)
      )
        return false;
    }
    if (contract.position === "start" && (!viewport || viewport.scrollTop > 1))
      return false;
    if (
      contract.position === "end" &&
      (!viewport ||
        Math.abs(
          viewport.scrollHeight - viewport.clientHeight - viewport.scrollTop,
        ) > 1)
    )
      return false;

    if (contract.position?.startsWith("message:")) {
      const id = contract.position.slice("message:".length);
      const item = root.querySelector(
        `[data-message-id=${JSON.stringify(id)}]`,
      );
      if (!viewport || !item) return false;
      const viewportBox = viewport.getBoundingClientRect();
      const itemBox = item.getBoundingClientRect();

      if (contract.scrollMargin != null) {
        // This only waits for the official command to finish. The DOM/CSS
        // comparison below checks the exact final geometry. Content
        // visibility can move the official React row after the first scroll
        // write, so an exact position here would reject the reference page.
        return (
          itemBox.bottom > viewportBox.top && itemBox.top < viewportBox.bottom
        );
      }

      if (itemBox.top < viewportBox.top || itemBox.top > viewportBox.top + 80)
        return false;
    }

    return true;
  };

  try {
    await page.waitForFunction(
      matches,
      { root, contract },
      { timeout: 15_000 },
    );
  } catch {
    const actual = await scope.evaluate((element) => {
      const content = element.querySelector(
        "[data-slot='message-scroller-content']",
      );
      const viewport = element.querySelector(
        "[data-slot='message-scroller-viewport']",
      );
      return {
        items: element.querySelectorAll("[data-slot='message-scroller-item']")
          .length,
        busy: content?.getAttribute("aria-busy") ?? null,
        scrollTop: viewport?.scrollTop ?? null,
        scrollMaximum: viewport
          ? viewport.scrollHeight - viewport.clientHeight
          : null,
        text: element.textContent?.replace(/\s+/g, " ").trim() ?? "",
      };
    });
    throw new Error(
      `Message Scroller action contract failed at ${page.url()}: expected ${JSON.stringify(contract)}, got ${JSON.stringify(actual)}`,
    );
  }
}

function resolveMessageScrollerContract(contract, context) {
  if (!contract.scrollEquals) return contract;

  const scrollTop = context[contract.scrollEquals];
  if (scrollTop == null)
    throw new Error(
      `Message Scroller action did not record ${contract.scrollEquals}`,
    );

  const { scrollEquals: _scrollEquals, ...resolved } = contract;
  return { ...resolved, scrollTop };
}

async function discoverChartHoverState(scope, states) {
  // ResponsiveContainer mounts its plot after the first measured size. Tooltip
  // anatomy examples have no responsive container and need no plot wait.
  if (await scope.locator(".recharts-responsive-container").count()) {
    await scope.locator(".recharts-surface").first().waitFor({ state: "visible" });
    await scope.locator(".recharts-rectangle:not(.recharts-tooltip-cursor)").first()
      .waitFor({ state: "visible" });
  }
  const tooltip = scope.locator(".recharts-tooltip-wrapper");
  const bars = scope.locator(
    ".recharts-rectangle:not(.recharts-tooltip-cursor)",
  );

  if ((await tooltip.count()) > 0 && (await bars.count()) > 0) {
    states.push({
      name: "chart-hover:first-series",
      kind: "chart-hover",
      index: 0,
    });
  }
}

/** Wait only when an official example has a deliberate timer. */
export async function waitForTimedExample(page, selector) {
  const delay = Number(
    (await page.locator(selector).getAttribute("data-visual-settle-ms")) ?? 0,
  );

  if (delay > 0) await page.waitForTimeout(delay);
}

function stateControls(scope, kind) {
  if (kind === "pressed") {
    return scope.locator(
      "[aria-pressed]:not([aria-disabled='true']):not(:disabled):visible",
    );
  }

  if (kind === "checked") {
    return scope.locator(
      "[aria-checked]:not([aria-disabled='true']):not(:disabled):not([role='tab']):visible",
    );
  }

  return scope.locator(
    "[role='tab'][aria-selected]:not([aria-disabled='true']):not(:disabled):visible",
  );
}

export function actionControlSelector() {
  return "button:not([aria-expanded]):not([aria-pressed]):not([aria-checked]):not([role='tab']):not([aria-disabled='true']):not(:disabled):visible";
}

function actionControls(scope) {
  return scope.locator(actionControlSelector());
}

async function waitForCarouselMotion(page, selector) {
  await page.evaluate(async (selector) => {
    const tracks = Array.from(
      document.querySelector(selector)?.querySelectorAll("[data-slot='carousel-content'] > div") ?? [],
    );
    if (tracks.length === 0) return;

    const transforms = () => tracks.map((track) => getComputedStyle(track).transform);
    let previous = transforms();
    let stableSince = performance.now();
    const deadline = stableSince + 10_000;

    // Embla writes rounded transforms in requestAnimationFrame. Near its final
    // position, the same rounded value can span several frames before it moves
    // again. Require a quiet interval, rather than two adjacent equal frames.
    while (performance.now() < deadline) {
      await new Promise((resolve) => requestAnimationFrame(resolve));
      const current = transforms();
      const now = performance.now();
      if (current.some((transform, index) => transform !== previous[index])) {
        stableSince = now;
      } else if (now - stableSince >= 400) {
        return;
      }
      previous = current;
    }
    throw new Error("Carousel movement did not stop within 10 seconds");
  }, selector);
}

async function settleInteraction(page, { waitForTransitions = false } = {}) {
  await page.evaluate(
    () =>
      new Promise((resolve) =>
        requestAnimationFrame(() => requestAnimationFrame(resolve)),
      ),
  );

  if (!waitForTransitions) return;

  // `shoot.settle` disables transitions for a deterministic capture. Do not
  // disable a transition while React and LiveView are at different progress
  // points. First let finite transitions reach their shared final paint.
  await page.evaluate(async () => {
    const waitForFrames = () =>
      new Promise((resolve) =>
        requestAnimationFrame(() => requestAnimationFrame(resolve)),
      );

    for (let pass = 0; pass < 2; pass += 1) {
      await waitForFrames();

      const finiteAnimations = document
        .getAnimations({ subtree: true })
        .filter((animation) =>
          Number.isFinite(animation.effect?.getComputedTiming().endTime),
        );

      if (finiteAnimations.length === 0) return;

      await Promise.all(
        finiteAnimations.map((animation) =>
          animation.finished.catch(() => undefined),
        ),
      );
    }
  });
}

function actionableTriggers(scope) {
  return scope.locator(
    ":is([aria-expanded], [role='menuitem'][aria-haspopup='menu'], [data-slot$='sub-trigger']):not([aria-disabled='true']):not(:disabled):visible",
  );
}

// Base UI omits the open submenu's expanded attribute after keyboard entry
// on macOS. Its controlled menu remains the observable open-state contract.
async function waitForDisclosureState(trigger, expected) {
  const matches = () => {
    if (trigger.classList.contains("phx-click-loading")) return false;
    const expanded = trigger.getAttribute("aria-expanded");
    if (expanded !== null) return expanded === expected;
    if (trigger.getAttribute("role") !== "menuitem" ||
        trigger.getAttribute("aria-haspopup") !== "menu") return false;

    const popup = document.getElementById(trigger.getAttribute("aria-controls"));
    const visible = Boolean(popup && popup.getClientRects().length &&
      getComputedStyle(popup).visibility !== "hidden");
    return visible === (expected === "true");
  };

  while (!matches()) {
    await new Promise((resolve) => requestAnimationFrame(resolve));
  }
}

async function waitForExpanded(trigger, value) {
  await trigger.evaluate(waitForDisclosureState, value);
}

async function waitForElementExpanded(element, value) {
  if (!element) throw new Error("expanded-state trigger is not attached");
  await element.evaluate(waitForDisclosureState, value);
}

async function closeRootState(page, trigger) {
  const slot = await trigger.getAttribute("data-slot");

  if (slot === "alert-dialog-trigger") {
    const controls = await trigger.getAttribute("aria-controls");
    const popup = page.locator(`[id=${JSON.stringify(controls)}]`);
    await popup.locator("[data-slot='alert-dialog-cancel']").click();
    await waitForExpanded(trigger, "false");
    await waitForControlledHidden(page, trigger);
    return;
  }

  if (
    (await trigger.getAttribute("aria-haspopup")) === null &&
    slot !== "navigation-menu-trigger"
  ) {
    await trigger.click();
    await waitForExpanded(trigger, "false");
    await waitForControlledHidden(page, trigger);
    return;
  }

  for (let attempt = 0; attempt < 8; attempt += 1) {
    const expanded = await trigger.getAttribute("aria-expanded");
    const controls = await trigger.getAttribute("aria-controls");
    const closedSubmenu = expanded === null && controls &&
      (await trigger.getAttribute("role")) === "menuitem" &&
      (await trigger.getAttribute("aria-haspopup")) === "menu" &&
      !(await page.locator(`[id=${JSON.stringify(controls)}]`).isVisible());
    if (expanded === "false" || closedSubmenu) {
      await waitForControlledHidden(page, trigger);
      return;
    }
    await page.keyboard.press("Escape");
    await page.evaluate(
      () => new Promise((resolve) => requestAnimationFrame(resolve)),
    );
  }

  await waitForExpanded(trigger, "false");
  await waitForControlledHidden(page, trigger);
}

async function waitForControlledHidden(page, trigger) {
  const controls = await trigger.getAttribute("aria-controls");
  if (!controls) return;

  const controlled = page.locator(`[id=${JSON.stringify(controls)}]`);
  if ((await controlled.count()) > 0)
    await controlled.waitFor({ state: "hidden" });
}

function specialTriggers(selector, kind) {
  if (kind === "context")
    return `${selector} [data-slot='context-menu-trigger']:visible`;
  return [
    `${selector} [data-slot='tooltip-trigger']:visible:not(:disabled):not([data-disabled])`,
    `${selector} [data-slot='hover-card-trigger']:visible`,
    `${selector} [data-slot='input-group-addon'][data-lb-open-on-hover]:visible`,
  ].join(", ");
}

function accessibleName(element) {
  const label = element.getAttribute("aria-label");
  if (label) return label.trim();

  const labelledBy = element.getAttribute("aria-labelledby");
  if (labelledBy) {
    const text = labelledBy
      .split(/\s+/)
      .map((id) => document.getElementById(id)?.innerText ?? "")
      .join(" ")
      .replace(/\s+/g, " ")
      .trim();

    if (text) return text;
  }

  const nativeLabel = Array.from(element.labels ?? [])
    .map((label) => label.innerText ?? "")
    .join(" ")
    .replace(/\s+/g, " ")
    .trim();

  if (nativeLabel) return nativeLabel;

  return element.innerText?.replace(/\s+/g, " ").trim() ?? "";
}

/** Give browser-owned examples the same deterministic devices in both renderers. */
export async function installBrowserFixtures(page) {
  await page.route("https://github.com/*.png", async (route) => {
    await route.fulfill({
      contentType: "image/svg+xml",
      body: [
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">',
        '<rect width="32" height="32" fill="#d4d4d4"/>',
        '<circle cx="16" cy="12" r="6" fill="#737373"/>',
        '<path d="M5 32c1-8 5-12 11-12s10 4 11 12" fill="#737373"/>',
        "</svg>",
      ].join(""),
    });
  });

  await page.addInitScript(() => {
    if (!window.__liveShadcnFixtureImages) {
      const images = new Set();
      Object.defineProperty(window, "__liveShadcnFixtureImages", { value: images });
      window.Image = new Proxy(window.Image, {
        construct(target, args, newTarget) {
          const image = Reflect.construct(target, args, newTarget);
          images.add(image);
          return image;
        },
      });
    }

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

/** Wait for native fixture images, including detached Avatar preload images. */
export async function waitForFixtureImages(page) {
  await page.evaluate(async () => {
    const frames = () => new Promise((resolve) =>
      requestAnimationFrame(() => requestAnimationFrame(resolve)));
    const currentImages = () => [...new Set([
      ...(window.__liveShadcnFixtureImages ?? []),
      ...document.images,
    ])].filter((image) => image.src || image.srcset);
    const loaded = (image) => new Promise((resolve) => {
      if (image.complete) return resolve();
      const finish = () => {
        image.removeEventListener("load", finish);
        image.removeEventListener("error", finish);
        resolve();
      };
      image.addEventListener("load", finish, { once: true });
      image.addEventListener("error", finish, { once: true });
      if (image.complete) finish();
    });

    do {
      await Promise.all(currentImages().map(loaded));
      await frames();
    } while (currentImages().some((image) => !image.complete));
  });
}
