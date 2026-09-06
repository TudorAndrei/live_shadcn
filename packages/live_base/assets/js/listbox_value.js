// Keeps a listbox trigger's visible value in sync with LiveView.JS.
//
// `JS.set_attribute` owns the selected label because it survives a server
// render. Text nodes are not a LiveView.JS target, so this narrow hook copies
// that client-owned attribute into the visible value.
export const ListboxValue = {
  mounted() {
    this.observer = new MutationObserver(() => this.sync());
    this.observer.observe(this.el, {
      attributes: true,
      attributeFilter: ["data-label"],
    });
    this.sync();
  },

  updated() {
    this.sync();
  },

  destroyed() {
    this.observer?.disconnect();
  },

  sync() {
    const label = this.el.getAttribute("data-label");
    if (label !== null) this.el.textContent = label;
  },
};
