export const NestedDrawerMedia = {
  mounted() {
    this.media = window.matchMedia("(max-width: 767px)");
    this.syncDirection = () =>
      this.pushEvent("drawer_nested_mobile", { mobile: this.media.matches });
    this.media.addEventListener("change", this.syncDirection);
    this.syncDirection();
  },

  destroyed() {
    this.media?.removeEventListener("change", this.syncDirection);
  },
};
