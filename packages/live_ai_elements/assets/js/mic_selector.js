// Keep the trigger label with the hidden form value that Listbox changes.
export const MicSelector = {
  mounted() {
    this.onChange = (event) => {
      if (event.target !== this.el.querySelector("input[type='hidden']")) return;
      const value = this.el.querySelector("[data-lb-mic-value]");
      if (value?.dataset.label) value.textContent = value.dataset.label;
    };

    this.el.addEventListener("change", this.onChange);
  },

  destroyed() {
    this.el.removeEventListener("change", this.onChange);
  },
};
