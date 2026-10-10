const INPUT_SELECTOR = "input[data-lb-checkbox-input]";

function controlFor(input) {
  if (!(input instanceof HTMLInputElement) || !input.matches(INPUT_SELECTOR)) return null;
  const control = input.previousElementSibling;
  return control?.matches("[role='checkbox'], [role='switch']") ? control : null;
}

function inputFor(control) {
  const input = control.nextElementSibling;
  return controlFor(input) === control ? input : null;
}

function currentState(control, input) {
  const mixed = control.getAttribute("aria-checked") === "mixed";
  return { checked: mixed ? input.checked : control.getAttribute("aria-checked") === "true", mixed };
}

function applyState(control, input, state) {
  control.setAttribute("aria-checked", state.mixed ? "mixed" : String(state.checked));
  control.toggleAttribute("data-checked", state.checked);
  control.toggleAttribute("data-unchecked", !state.checked);
  control.toggleAttribute("data-filled", state.checked);
  control.toggleAttribute("data-indeterminate", state.mixed);
  for (const indicator of control.querySelectorAll("[data-slot$='-indicator']")) {
    indicator.hidden = !state.checked && !state.mixed;
  }
  for (const thumb of control.querySelectorAll("[data-slot$='-thumb']")) {
    thumb.toggleAttribute("data-checked", state.checked);
    thumb.toggleAttribute("data-unchecked", !state.checked);
  }
  if (input.checked !== state.checked) input.checked = state.checked;
  if (input.indeterminate !== state.mixed) input.indeterminate = state.mixed;
}

export function installCheckboxBehavior(root = document) {
  const declarations = new WeakMap();

  // The marker is server-owned. JS commands keep their own attributes across
  // patches, so a changed marker must restore the caller's new value.
  (root.ownerDocument || root).addEventListener("phx:update", () => {
    for (const control of root.querySelectorAll("[data-lb-checkable-state]")) {
      const input = inputFor(control);
      if (!input) continue;
      const server = control.getAttribute("data-lb-checkable-state");
      let declaration = declarations.get(control);
      if (!declaration) {
        declaration = { server, override: null };
        declarations.set(control, declaration);
      } else if (declaration.server !== server) {
        declaration = {
          server,
          override: { checked: server.startsWith("true:"), mixed: server.endsWith(":true") },
        };
        declarations.set(control, declaration);
      }
      applyState(control, input, declaration.override || currentState(control, input));
    }
  });

  root.addEventListener("change", (event) => {
    const input = event.target;
    const control = controlFor(input);
    if (!control?.hasAttribute("data-lb-checkable-state")) return;
    declarations.set(control, {
      server: control.getAttribute("data-lb-checkable-state"),
      override: null,
    });
    applyState(control, input, currentState(control, input));
  }, true);

  root.addEventListener("live-base:sync-checkable-input", (event) => {
    const control = event.target;
    if (!(control instanceof Element)) return;
    const input = inputFor(control);
    if (!input || input.disabled) return;

    const state = currentState(control, input);
    applyState(control, input, state);
    input.toggleAttribute("checked", state.checked);
    if (event.detail?.change !== false) input.dispatchEvent(new Event("change", { bubbles: true }));
  });

  root.addEventListener("focusin", (event) => {
    const control = controlFor(event.target);
    if (control && !event.target.disabled) control.focus({ preventScroll: true });
  });

  root.addEventListener("click", (event) => {
    if (event.defaultPrevented || !(event.target instanceof Element)) return;
    const label = event.target.closest("label");
    const input = label?.control;
    const control = controlFor(input);
    if (!control) return;

    // Interactive label children keep their own activation behavior.
    if (event.target.closest("a[href], button, input, select, textarea")) return;

    // Use the visible control's command once. Native label activation would
    // toggle only the hidden input and can toggle it again after a span click.
    event.preventDefault();
    if (input.disabled) return;
    control.focus({ preventScroll: true });
    if (!control.contains(event.target)) control.click();
  }, true);
}
