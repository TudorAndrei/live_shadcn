const TOGGLE = "[data-file-tree-toggle]";

export const FileTree = {
  mounted() {
    this.item = this.el.querySelector("[role='treeitem']");
    this.content = this.el.querySelector("[data-file-tree-content]");
    this.chevron = this.el.querySelector("[data-file-tree-chevron]");
    this.openIcon = this.el.querySelector("[data-file-tree-open-icon]");
    this.closedIcon = this.el.querySelector("[data-file-tree-closed-icon]");

    this.onClick = (event) => {
      if (!event.target.closest(TOGGLE)) return;
      this.draw(this.item?.getAttribute("aria-expanded") !== "true");
    };

    this.el.addEventListener("click", this.onClick);
    this.draw(this.item?.getAttribute("aria-expanded") === "true");
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick);
  },

  draw(expanded) {
    this.item?.setAttribute("aria-expanded", String(expanded));
    this.el.toggleAttribute("open", expanded);
    if (this.content) this.content.hidden = !expanded;
    this.chevron?.classList.toggle("rotate-90", expanded);
    if (this.openIcon) this.openIcon.hidden = !expanded;
    if (this.closedIcon) this.closedIcon.hidden = expanded;
  },
};
