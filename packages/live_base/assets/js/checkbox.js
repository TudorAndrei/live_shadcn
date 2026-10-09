const INPUT_SELECTOR = "input[data-lb-checkbox-input]";

function controlFor(input) {
  if (!(input instanceof HTMLInputElement) || !input.matches(INPUT_SELECTOR)) return null;
  const control = input.previousElementSibling;
  return control?.matches("[role='checkbox']") ? control : null;
}

export function installCheckboxBehavior(root = document) {
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
