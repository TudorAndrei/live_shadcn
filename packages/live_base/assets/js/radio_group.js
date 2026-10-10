// Keep visible radio controls in step when a label activates a native input.

export const RadioGroup = {
  mounted() {
    this.onRadioFocus = (event) => this.radioFocus(event);
    this.el.addEventListener("focusin", this.onRadioFocus);
    this.onRadioChange = (event) => this.radioChange(event);
    this.el.addEventListener("change", this.onRadioChange);
  },

  destroyed() {
    this.el.removeEventListener("change", this.onRadioChange);
    this.el.removeEventListener("focusin", this.onRadioFocus);
  },

  radioFocus(event) {
    const input = event.target;
    if (!(input instanceof HTMLInputElement) || input.type !== "radio") return;
    document.getElementById(`${input.id}-control`)?.focus();
  },

  radioChange(event) {
    const input = event.target;
    if (!(input instanceof HTMLInputElement) || input.type !== "radio" || !input.checked) return;

    for (const radio of this.el.querySelectorAll("input[type='radio']")) {
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
  },
};
