// Keep visible radio controls in step when a label activates a native input.

export const RadioGroup = {
  mounted() {
    this.updateTabStops();
    this.onRadioFocus = (event) => this.radioFocus(event);
    this.el.addEventListener("focusin", this.onRadioFocus);
    this.onRadioChange = (event) => this.radioChange(event);
    this.el.addEventListener("change", this.onRadioChange);
    this.onRadioKeydown = (event) => this.radioKeydown(event);
    this.el.addEventListener("keydown", this.onRadioKeydown);
  },

  updated() {
    this.updateTabStops(document.activeElement);
  },

  destroyed() {
    this.el.removeEventListener("keydown", this.onRadioKeydown);
    this.el.removeEventListener("change", this.onRadioChange);
    this.el.removeEventListener("focusin", this.onRadioFocus);
  },

  radioFocus(event) {
    const target = event.target;
    if (!(target instanceof Element) || target.closest("[role='radiogroup']") !== this.el) return;
    if (target instanceof HTMLInputElement && target.type === "radio") {
      document.getElementById(`${target.id}-control`)?.focus();
    } else if (target.matches("[role='radio']")) {
      this.updateTabStops(target);
    }
  },

  controls() {
    return [...this.el.querySelectorAll("[role='radio']")].filter(
      (control) => control.closest("[role='radiogroup']") === this.el,
    );
  },

  enabledControls() {
    return this.controls().filter(
      (control) => !control.hasAttribute("data-disabled") && control.getAttribute("aria-disabled") !== "true",
    );
  },

  updateTabStops(preferred) {
    const enabled = this.enabledControls();
    const entry = enabled.includes(preferred) ? preferred :
      enabled.find((control) => control.getAttribute("aria-checked") === "true") || enabled[0];
    for (const control of this.controls()) control.tabIndex = control === entry ? 0 : -1;
  },

  radioKeydown(event) {
    const control = event.target;
    const enabled = this.enabledControls();
    const index = enabled.indexOf(control);
    if (index < 0) return;

    // Space on an unchanged value must not send another form change.
    if (event.key === " " && (control.getAttribute("aria-checked") === "true" || control.hasAttribute("data-readonly"))) {
      event.preventDefault();
      event.stopPropagation();
      return;
    }
    if (event.altKey || event.ctrlKey || event.metaKey) return;
    const step = { ArrowDown: 1, ArrowRight: 1, ArrowUp: -1, ArrowLeft: -1 }[event.key];
    if (!step) return;

    event.preventDefault();
    event.stopPropagation();
    const next = enabled[(index + step + enabled.length) % enabled.length];
    if (next !== control && !next.hasAttribute("data-readonly")) next.click();
    next.focus();
    this.updateTabStops(next);
  },

  radioChange(event) {
    const input = event.target;
    if (!(input instanceof HTMLInputElement) || input.type !== "radio" || input.closest("[role='radiogroup']") !== this.el) return;
    const selectedControl = document.getElementById(`${input.id}-control`);
    // A prior change makes the native checked property independent of its
    // attribute. Accept the command's selected control before the form reads it.
    if (!input.checked && selectedControl?.getAttribute("aria-checked") !== "true") return;

    for (const radio of this.el.querySelectorAll("input[type='radio']")) {
      if (radio.closest("[role='radiogroup']") !== this.el) continue;
      const selected = radio === input;
      const control = document.getElementById(`${radio.id}-control`);
      if (!control) continue;

      radio.checked = selected;
      radio.toggleAttribute("checked", selected);
      control.setAttribute("aria-checked", String(selected));
      control.toggleAttribute("data-checked", selected);
      control.toggleAttribute("data-unchecked", !selected);
      control.toggleAttribute("data-filled", selected);
      control
        .querySelector("[data-slot='radio-group-indicator']")
        ?.toggleAttribute("hidden", !selected);
    }
    this.updateTabStops(selectedControl);
  },
};
