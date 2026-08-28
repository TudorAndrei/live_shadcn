export const WebPreview = {
  mounted() {
    this.address = this.el.querySelector("[data-web-preview-url]");
    this.frame = this.el.querySelector("[data-web-preview-body]");

    this.onKeyDown = (event) => {
      if (event.key !== "Enter") return;
      event.preventDefault();
      this.load(this.address.value);
    };

    this.address?.addEventListener("keydown", this.onKeyDown);

    if (this.el.dataset.defaultUrl) {
      if (this.address && !this.address.value) this.address.value = this.el.dataset.defaultUrl;
      this.load(this.el.dataset.defaultUrl);
    }
  },

  destroyed() {
    this.address?.removeEventListener("keydown", this.onKeyDown);
  },

  load(url) {
    if (!url || !this.frame) return;
    this.frame.src = url;
    this.el.dataset.url = url;
    this.el.dispatchEvent(
      new CustomEvent("live_ai_elements:url-change", { bubbles: true, detail: { url } }),
    );
  },
};
