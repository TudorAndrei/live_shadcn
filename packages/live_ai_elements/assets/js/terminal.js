export const Terminal = {
  mounted() {
    this.scrollToOutput();
  },

  updated() {
    this.scrollToOutput();
  },

  scrollToOutput() {
    if (this.el.dataset.autoScroll === "false") return;
    const content = this.el.querySelector("[data-terminal-content]");
    if (content) content.scrollTop = content.scrollHeight;
  },
};
