// Keep a toggle group responsive without a server round trip.
//
// The group owns selection. In multiple mode, each item changes on its own.
// In exclusive mode, a new item clears the old item, and a selected item can
// be cleared. A caller can also name a text output for examples and controls
// that show the selected value.

export const ToggleGroup = {
  mounted() {
    this.el.addEventListener("live-base:toggle-group", (event) => this.toggle(event));
  },

  toggle(event) {
    const item = document.getElementById(event.detail.item);
    if (!item || item.disabled || item.getAttribute("aria-disabled") === "true") return;

    const wasPressed = item.getAttribute("aria-pressed") === "true";

    if (this.el.hasAttribute("data-multiple")) {
      this.setPressed(item, !wasPressed);
    } else {
      for (const other of this.items()) this.setPressed(other, false);
      if (!wasPressed) this.setPressed(item, true);
    }

    item.setAttribute("data-dirty", "");
    item.setAttribute("data-touched", "");
    this.updateOutput(item, !wasPressed);
  },

  items() {
    return [...this.el.querySelectorAll("[data-slot='toggle-group-item']")].filter(
      (item) => item.closest("[data-slot='toggle-group']") === this.el,
    );
  },

  setPressed(item, pressed) {
    item.setAttribute("aria-pressed", String(pressed));
    item.toggleAttribute("data-pressed", pressed);
  },

  updateOutput(item, selected) {
    const selector = this.el.getAttribute("data-lb-output");
    if (!selector) return;

    const output = document.querySelector(selector);
    if (output) {
      const prefix = this.el.getAttribute("data-lb-output-prefix") || "";
      // Keep the caller prefix separate from the changing value, as in the
      // initial render. Text-node boundaries affect fractional glyph positions.
      output.replaceChildren(
        document.createTextNode(prefix),
        document.createTextNode(selected ? item.getAttribute("data-lb-value") || "" : ""),
      );
    }
  },
};
