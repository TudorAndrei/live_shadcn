// LiveView preserves a text input's browser-owned value while the input is
// dirty. That is right for typing, including invalid text. A calendar choice
// is different: the official controlled React input replaces the typed text
// with the selected, formatted date. The server marks only that transition
// with a new selection number, so this hook never overwrites active typing.
export const DatePickerInput = {
  mounted() {
    this.selection = this.el.dataset.datePickerSelection;
  },

  updated() {
    const selection = this.el.dataset.datePickerSelection;
    if (selection === this.selection) return;

    this.selection = selection;
    const value = this.el.dataset.datePickerValue;
    if (value !== undefined) this.el.value = value;

    // The close command runs before the server selection patch. That patch can
    // replace the focused calendar trigger, so resolve the current trigger
    // after the controlled value update.
    const focusTarget = this.el.dataset.datePickerFocusTarget;
    if (focusTarget) document.getElementById(focusTarget)?.focus({ preventScroll: true });
  },
};
