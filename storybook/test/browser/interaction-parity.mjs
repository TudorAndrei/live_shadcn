// A small, semantic action inventory for every shadcn behavior check.
// Component suites add deep assertions where their actions change application
// state. This suite proves safe, local browser transitions for every official
// example. It does not guess what an ordinary application button should do.

import { inScope } from "./preview-scope.mjs";

/**
 * Selects official shadcn pages from the common preview scope. The source
 * predicate is intentional: this suite compares only shadcn references.
 */
export function scopedInteractionPages(previews, scope, hasOfficialReference) {
  return Object.entries(previews)
    .flatMap(([component, examples]) =>
      examples.map((example) => ({ component, example })),
    )
    .filter(({ component, example }) =>
      inScope(`${component}.${example}`, scope, () => "shadcn"),
    )
    .filter(({ component, example }) =>
      hasOfficialReference("shadcn", `${component}.${example}`),
    );
}

/** Native editable controls that a reader can use and a probe can safely enter. */
export function editableInteractionSelector() {
  return [
    "textarea:not([aria-hidden='true'])",
    "input:not([type]):not([aria-hidden='true'])",
    "input[type='text']:not([aria-hidden='true'])",
    "input[type='search']:not([aria-hidden='true'])",
    "input[type='email']:not([aria-hidden='true'])",
    "input[type='url']:not([aria-hidden='true'])",
    "input[type='tel']:not([aria-hidden='true'])",
    "input[type='password']:not([aria-hidden='true'])",
  ].join(", ");
}

export function editableInteractionProbeSelector() {
  return editableInteractionSelector()
    .split(", ")
    .map((part) => `${part}:visible`)
    .join(", ");
}

/**
 * Reports the disabled state that browser-owned interaction probes must use.
 * A present `data-disabled="false"` is an explicit enabled state in React
 * component markup, not a boolean HTML attribute.
 */
export function isInteractionControlDisabled(element) {
  const dataDisabled = element.closest("[data-disabled]")?.getAttribute(
    "data-disabled",
  );

  return (
    element.matches(":disabled") ||
    element.getAttribute("aria-disabled") === "true" ||
    dataDisabled === "" ||
    dataDisabled === "true"
  );
}

/**
 * Returns a stable description of each browser-owned transition in `scope`.
 * The descriptor is also the React/Phoenix comparison key. The index is only
 * a locator detail and is intentionally left out of `probeIdentity`.
 */
export async function discoverInteractionProbes(scope, options = {}) {
  const resolved = {
    includeButtons: false,
    includeDisclosures: true,
    includeHover: true,
    includeNativeControls: false,
    includeRanges: false,
    editableSelector: editableInteractionSelector(),
    editableProbeSelector: editableInteractionProbeSelector(),
    ...options,
  };

  return scope.evaluate((root, options) => {
    const visible = (element) => {
      const style = window.getComputedStyle(element);
      const box = element.getBoundingClientRect();
      return (
        element.getAttribute("aria-hidden") !== "true" &&
        style.display !== "none" &&
        style.visibility !== "hidden" &&
        box.width + box.height > 0
      );
    };

    const disabled = (element) => {
      const dataDisabled = element.closest("[data-disabled]")?.getAttribute(
        "data-disabled",
      );

      return (
        element.matches(":disabled") ||
        element.getAttribute("aria-disabled") === "true" ||
        dataDisabled === "" ||
        dataDisabled === "true"
      );
    };

    const name = (element) => {
      const aria = element.getAttribute("aria-label");
      if (aria) return aria.trim();

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

      const labels = Array.from(element.labels ?? [])
        .map((label) => label.innerText ?? "")
        .join(" ")
        .replace(/\s+/g, " ")
        .trim();
      return labels || element.innerText.replace(/\s+/g, " ").trim();
    };

    const descriptors = [];
    const add = (kind, selector, element, index, extra = {}) =>
      descriptors.push({
        kind,
        selector,
        index,
        role: element.getAttribute("role") || "",
        name: name(element),
        ...extra,
      });

    const selects = Array.from(root.querySelectorAll("select")).filter(visible);
    selects.forEach((select, index) => {
      if (disabled(select)) {
        add(
          "disabled-native-select",
          "select:not([aria-hidden='true']):visible",
          select,
          index,
        );
        return;
      }

      const option = Array.from(select.options).find(
        (candidate) => !candidate.disabled && candidate.value !== select.value,
      );
      if (option)
        add(
          "native-select",
          "select:not([aria-hidden='true']):visible",
          select,
          index,
          { value: option.value },
        );
    });

    const editableSelector = options.editableSelector;
    const editableTexts = Array.from(
      root.querySelectorAll(editableSelector),
    ).filter((element) => visible(element) && !disabled(element));
    editableTexts.forEach((element, index) => {
      add("editable-text", options.editableProbeSelector, element, index, {
        value: "Parity text",
      });
    });

    const controls = Array.from(
      root.querySelectorAll(
        "[role='checkbox'], [role='switch'], [role='radio'], [aria-pressed]",
      ),
    ).filter(visible);
    const radioGroups = new Set();

    controls.forEach((control, index) => {
      const role = control.getAttribute("role");

      if (role === "radio") {
        const group =
          control.closest("[role='radiogroup']") || control.parentElement;
        if (radioGroups.has(group) || disabled(control)) return;

        const candidate = Array.from(
          group.querySelectorAll("[role='radio']"),
        ).find(
          (item) =>
            visible(item) &&
            !disabled(item) &&
            item.getAttribute("aria-checked") !== "true",
        );
        if (candidate) {
          const candidateIndex = controls.indexOf(candidate);
          add(
            "radio-group",
            "[role='checkbox']:not([aria-hidden='true']):visible, [role='switch']:not([aria-hidden='true']):visible, [role='radio']:not([aria-hidden='true']):visible, [aria-pressed]:not([aria-hidden='true']):visible",
            candidate,
            candidateIndex,
          );
        }
        radioGroups.add(group);
        return;
      }

      if (disabled(control)) {
        add(
          "disabled-checkable",
          "[role='checkbox']:not([aria-hidden='true']):visible, [role='switch']:not([aria-hidden='true']):visible, [role='radio']:not([aria-hidden='true']):visible, [aria-pressed]:not([aria-hidden='true']):visible",
          control,
          index,
        );
      } else {
        add(
          "checkable",
          "[role='checkbox']:not([aria-hidden='true']):visible, [role='switch']:not([aria-hidden='true']):visible, [role='radio']:not([aria-hidden='true']):visible, [aria-pressed]:not([aria-hidden='true']):visible",
          control,
          index,
        );
      }
    });

    if (options.includeNativeControls) {
      const nativeSelector = "input[type='checkbox'], input[type='radio']";
      const nativeProbeSelector =
        "input[type='checkbox']:not([aria-hidden='true']):visible, input[type='radio']:not([aria-hidden='true']):visible";
      const nativeControls = Array.from(
        root.querySelectorAll(nativeSelector),
      ).filter((element) => visible(element) && !disabled(element));

      nativeControls.forEach((control, index) => {
        add("native-checkable", nativeProbeSelector, control, index);
      });
    }

    if (options.includeRanges) {
      const ranges = Array.from(
        root.querySelectorAll("input[type='range']"),
      ).filter((element) => visible(element) && !disabled(element));

      ranges.forEach((range, index) => {
        add(
          "range",
          "input[type='range']:not([aria-hidden='true']):visible",
          range,
          index,
        );
      });
    }

    if (options.includeButtons) {
      const buttonSelector = [
        "button",
        ":not([aria-expanded])",
        ":not([aria-pressed])",
        ":not([aria-checked])",
        ":not([role='tab'])",
        ":not([data-slot$='trigger'])",
        ":not([data-slot$='close'])",
      ].join("");
      const buttonProbeSelector = `${buttonSelector}:not(:disabled):not([aria-disabled='true']):not([aria-hidden='true']):visible`;
      const buttons = Array.from(root.querySelectorAll(buttonSelector)).filter(
        (element) => visible(element) && !disabled(element),
      );

      buttons.forEach((button, index) => {
        add("button", buttonProbeSelector, button, index);
      });
    }

    if (options.includeDisclosures) {
      const disclosures = Array.from(
        root.querySelectorAll("[aria-expanded]"),
      ).filter(visible);
      disclosures.forEach((trigger, index) => {
        if (
          trigger.getAttribute("aria-expanded") === "false" &&
          !disabled(trigger)
        ) {
          add(
            "disclosure",
            "[aria-expanded]:not([aria-hidden='true']):visible",
            trigger,
            index,
          );
        }
      });
    }

    if (options.includeHover) {
      const hoverTriggers = Array.from(
        root.querySelectorAll(
          "[data-slot='tooltip-trigger'], [data-slot='hover-card-trigger']",
        ),
      ).filter(visible);
      hoverTriggers.forEach((trigger, index) => {
        if (!disabled(trigger)) {
          const slot = trigger
            .getAttribute("data-slot")
            .replace("-trigger", "-content");
          add(
            "hover",
            "[data-slot='tooltip-trigger']:not([aria-hidden='true']):visible, [data-slot='hover-card-trigger']:not([aria-hidden='true']):visible",
            trigger,
            index,
            {
              popupSlot: slot,
            },
          );
        }
      });
    }

    return descriptors;
  }, resolved);
}

export function probeIdentity({ kind, role, name, value, popupSlot }) {
  return {
    kind,
    role,
    name,
    value: value ?? null,
    popupSlot: popupSlot ?? null,
  };
}

export async function enterInteractionProbe(
  page,
  selector,
  probe,
  options = {},
) {
  const scope =
    typeof selector === "string" ? page.locator(selector) : selector;
  const target = scope.locator(probe.selector).nth(probe.index);

  if (probe.kind === "native-select") {
    await target.selectOption(probe.value);
    return observeInteraction(scope, target, probe);
  }

  if (probe.kind === "editable-text") {
    await target.fill(probe.value);
    await settle(page);
    return observeInteraction(scope, target, probe);
  }

  if (probe.kind === "range") {
    await target.focus();
    await target.press("End");
    await settle(page);
    return observeInteraction(scope, target, probe);
  }

  if (
    probe.kind === "disabled-native-select" ||
    probe.kind === "disabled-checkable"
  ) {
    return observeInteraction(scope, target, probe);
  }

  if (probe.kind === "hover") {
    await page.mouse.move(0, 0);
    await target.hover();
    const popup = page.locator(`[data-slot='${probe.popupSlot}']:visible`);
    await popup.waitFor({ timeout: 1_000 });
    const opened = await observeInteraction(scope, target, probe);
    if (options.keepOpen) return { opened };

    await page.mouse.move(0, 0);
    await popup.waitFor({ state: "hidden", timeout: 1_000 });
    return { opened, closed: await observeInteraction(scope, target, probe) };
  }

  await target.click();
  await settle(page);

  if (probe.kind !== "disclosure")
    return observeInteraction(scope, target, probe);

  await waitForAttribute(target, "aria-expanded", "true");
  const popupId = await target.getAttribute("aria-controls");
  const popup = popupId ? page.locator(`#${popupId}`) : null;
  const opened = await observeInteraction(scope, target, probe);
  if (options.keepOpen) return { opened };

  if (await target.getAttribute("aria-haspopup")) {
    await page.keyboard.press("Escape");
  } else {
    await target.click();
  }
  await waitForDisclosureClosed(target, popup);
  return { opened, closed: await observeInteraction(scope, target, probe) };
}

/** Enter a visual action and leave its rendered state on screen. */
export const enterVisualActionProbe = (page, scope, probe) =>
  enterInteractionProbe(page, scope, probe, { keepOpen: true });

async function observeInteraction(scope, target, probe) {
  const scopeHandle = await scope.elementHandle();

  return target.evaluate(
    (element, { root, kind, popupSlot }) => {
      const accessibleName = (node) => {
        const aria = node.getAttribute("aria-label");
        if (aria) return aria.trim();
        const labels = Array.from(node.labels ?? [])
          .map((label) => label.innerText ?? "")
          .join(" ")
          .replace(/\s+/g, " ")
          .trim();
        return labels || node.innerText.replace(/\s+/g, " ").trim();
      };

      const describe = (node) => {
        if (!node) return null;
        const values =
          node instanceof HTMLSelectElement
            ? Array.from(node.selectedOptions).map((option) => option.value)
            : "value" in node && typeof node.value === "string"
              ? [node.value]
              : [];

        return {
          tag: node.tagName.toLowerCase(),
          role: node.getAttribute("role") || "",
          name: accessibleName(node),
          expanded: node.getAttribute("aria-expanded"),
          checked: node.getAttribute("aria-checked"),
          selected: node.getAttribute("aria-selected"),
          pressed: node.getAttribute("aria-pressed"),
          disabled:
            node.matches(":disabled") ||
            node.getAttribute("aria-disabled") === "true",
          values,
        };
      };

      const controls = Array.from(
        root.querySelectorAll(
          "[role='checkbox'], [role='switch'], [role='radio'], [aria-pressed], select, textarea, input:not([type]), input[type='text'], input[type='search'], input[type='email'], input[type='url'], input[type='tel'], input[type='password']",
        ),
      )
        .filter((node) => node.getAttribute("aria-hidden") !== "true")
        .map(describe);
      const controlled = element.getAttribute("aria-controls");
      const popup = controlled ? document.getElementById(controlled) : null;
      const visible = (node) => {
        if (!node) return false;
        const style = window.getComputedStyle(node);
        const box = node.getBoundingClientRect();
        return (
          !node.hidden &&
          style.display !== "none" &&
          style.visibility !== "hidden" &&
          box.width + box.height > 0
        );
      };
      const visiblePopup = popupSlot
        ? Array.from(
            document.querySelectorAll(`[data-slot='${popupSlot}']`),
          ).find(visible)
        : visible(popup)
          ? popup
          : null;
      const active = document.activeElement;

      return {
        target: describe(element),
        controls,
        popup: visiblePopup
          ? {
              role: visiblePopup.getAttribute("role") || "",
              visible: !visiblePopup.hidden,
              expanded: visiblePopup.getAttribute("aria-expanded"),
            }
          : null,
        focus:
          active && (root.contains(active) || visiblePopup?.contains(active))
            ? describe(active)
            : null,
        kind,
      };
    },
    { root: scopeHandle, kind: probe.kind, popupSlot: probe.popupSlot ?? null },
  );
}

async function waitForAttribute(locator, name, value) {
  await locator.evaluate(
    async (element, [attribute, expected]) => {
      while (element.getAttribute(attribute) !== expected) {
        await new Promise((resolve) => requestAnimationFrame(resolve));
      }
    },
    [name, value],
  );
}

export async function waitForDisclosureClosed(target, popup) {
  await waitForAttribute(target, "aria-expanded", "false");
  if (popup) await popup.waitFor({ state: "hidden", timeout: 1_000 });
}

async function settle(page) {
  await page.evaluate(
    () =>
      new Promise((resolve) =>
        requestAnimationFrame(() => requestAnimationFrame(resolve)),
      ),
  );
}
