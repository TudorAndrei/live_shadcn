// The pinned React Data Table has a controlled filter input without a form.
// LiveView form events require a form owner, so this hook sends the same
// explicit filter event while keeping the official input tree unchanged.
export const DataTableFilter = {
  mounted() {
    this.onInput = () => {
      const event = this.el.dataset.tableFilterEvent;
      if (event) this.pushEvent(event, { action: "filter", filter: this.el.value });
    };

    this.el.addEventListener("input", this.onInput);
  },

  destroyed() {
    this.el.removeEventListener("input", this.onInput);
  },
};
