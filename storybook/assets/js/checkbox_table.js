export const CheckboxTable = {
  mounted() {
    this.el.addEventListener("change", (event) => this.changed(event));
  },

  changed(event) {
    const input = event.target;
    if (!(input instanceof HTMLInputElement) || input.type !== "checkbox") return;

    const control = input.previousElementSibling;
    if (!control?.matches("[role='checkbox']")) return;

    if (control.hasAttribute("data-select-all")) {
      for (const rowControl of this.rowControls()) {
        this.setControl(rowControl, input.checked);
        rowControl.closest("tr")?.setAttribute("data-state", input.checked ? "selected" : "");
        if (!input.checked) rowControl.closest("tr")?.removeAttribute("data-state");
      }
      return;
    }

    const row = control.closest("tr");
    if (input.checked) row?.setAttribute("data-state", "selected");
    else row?.removeAttribute("data-state");

    const selectAll = this.el.querySelector("[data-select-all]");
    const rows = this.rowControls();
    const selected = rows.filter((item) => this.input(item).checked).length;
    this.setControl(selectAll, selected === rows.length);
  },

  rowControls() {
    return [...this.el.querySelectorAll("[role='checkbox'][data-row-id]")];
  },

  input(control) {
    return control.nextElementSibling;
  },

  setControl(control, checked) {
    if (!control) return;

    control.setAttribute("aria-checked", String(checked));
    control.toggleAttribute("data-checked", checked);
    control.toggleAttribute("data-unchecked", !checked);
    control.toggleAttribute("data-filled", checked);

    const indicator = control.querySelector("[data-slot='checkbox-indicator']");
    if (indicator) indicator.hidden = !checked;

    const input = this.input(control);
    input.toggleAttribute("checked", checked);
  },
};
