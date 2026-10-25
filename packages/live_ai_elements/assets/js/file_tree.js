const TOGGLE = "[data-file-tree-toggle]";

export const FileTree = {
  mounted() {
    this.item = this.el.querySelector("[role='treeitem']");
    this.content = this.el.querySelector("[data-file-tree-content]");
    this.chevron = this.el.querySelector("[data-file-tree-chevron]");
    this.openIcon = this.el.querySelector("[data-file-tree-open-icon]");
    this.closedIcon = this.el.querySelector("[data-file-tree-closed-icon]");
    this.node = `[phx-hook="${this.el.getAttribute("phx-hook")}"]`;

    this.onClick = (event) => {
      const trigger = event.target.closest(TOGGLE);
      if (!trigger || trigger.closest(this.node) !== this.el) return;
      this.draw(this.item?.getAttribute("aria-expanded") !== "true");
    };

    this.onKeyDown = (event) => {
      if (event.target.closest("[role='treeitem']") !== this.item) return;
      const expanded = this.item.getAttribute("aria-expanded") === "true";
      if (["ArrowRight", "ArrowLeft", "Enter", " "].includes(event.key)) {
        event.preventDefault();
        this.draw(event.key === "ArrowRight" || (event.key !== "ArrowLeft" && !expanded));
      }
    };

    this.el.addEventListener("click", this.onClick);
    this.el.addEventListener("keydown", this.onKeyDown);
    this.serverExpanded = this.el.dataset.expanded;
    this.draw(this.item?.getAttribute("aria-expanded") === "true");
  },

  updated() {
    const requested = this.el.dataset.expanded;
    this.draw(requested === this.serverExpanded ? this.expanded : requested === "true");
    this.serverExpanded = requested;
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick);
    this.el.removeEventListener("keydown", this.onKeyDown);
  },

  draw(expanded) {
    this.expanded = expanded;
    this.item?.setAttribute("aria-expanded", String(expanded));
    this.item?.querySelectorAll(TOGGLE).forEach((trigger) => {
      if (trigger.closest(this.node) === this.el) {
        trigger.setAttribute("aria-expanded", String(expanded));
      }
    });
    this.el.toggleAttribute("open", expanded);
    if (this.content) this.content.hidden = !expanded;
    this.chevron?.classList.toggle("rotate-90", expanded);
    if (this.openIcon) this.openIcon.hidden = !expanded;
    if (this.closedIcon) this.closedIcon.hidden = expanded;
  },
};
