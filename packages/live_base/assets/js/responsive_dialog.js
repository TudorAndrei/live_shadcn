// Keeps a responsive dialog example on the same media-query branch as the
// upstream React component. The hidden branch has no visual or accessibility
// presence and changes when the query changes.

export const ResponsiveDialog = {
  mounted() {
    this.query = window.matchMedia("(min-width: 768px)");
    this.onChange = () => this.sync();
    this.query.addEventListener("change", this.onChange);
    this.sync();
  },

  updated() {
    this.sync();
  },

  destroyed() {
    this.query?.removeEventListener("change", this.onChange);
  },

  sync() {
    const desktop = this.el.querySelector(":scope > [data-lb-desktop]");
    const mobile = this.el.querySelector(":scope > [data-lb-mobile]");
    if (desktop) desktop.hidden = !this.query.matches;
    if (mobile) mobile.hidden = this.query.matches;
  },
};
