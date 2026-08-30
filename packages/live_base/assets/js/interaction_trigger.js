// Opens controls whose browser gesture is not a normal click.
//
// Tooltip and hover-card triggers open from pointer or keyboard focus. Context
// menus open at the pointer coordinates from a right click. The hidden
// `phx-click` binding still owns the LiveView.JS state change; this hook only
// translates the browser gesture into that command.
export const InteractionTrigger = {
  mounted() {
    this.popup = document.getElementById(this.el.getAttribute("aria-controls"));
    this.positioner = document.getElementById(this.el.dataset.lbPositioner);

    this.blockTrustedClick = (event) => {
      if (event.isTrusted) event.stopImmediatePropagation();
    };
    this.el.addEventListener("click", this.blockTrustedClick, true);

    if (this.el.hasAttribute("data-lb-open-on-hover")) this.mountHover();
    if (this.el.hasAttribute("data-lb-open-on-context")) this.mountContextMenu();
  },

  destroyed() {
    clearTimeout(this.closeTimer);
    for (const [element, event, listener, options] of this.listeners || []) {
      element.removeEventListener(event, listener, options);
    }
  },

  mountHover() {
    this.on(this.el, "pointerenter", () => this.open());
    this.on(this.el, "pointerleave", () => this.scheduleClose());
    this.on(this.el, "focusin", () => this.open());
    this.on(this.el, "focusout", () => this.scheduleClose());
    if (this.popup) {
      this.on(this.popup, "pointerenter", () => clearTimeout(this.closeTimer));
      this.on(this.popup, "pointerleave", () => this.scheduleClose());
    }
  },

  mountContextMenu() {
    this.on(this.el, "contextmenu", (event) => {
      event.preventDefault();
      this.positioner?.setAttribute("data-lb-point-x", String(event.clientX));
      this.positioner?.setAttribute("data-lb-point-y", String(event.clientY));

      if (this.el.hasAttribute("data-popup-open")) {
        this.positioner?.dispatchEvent(new CustomEvent("live-base:reposition"));
      } else {
        this.open();
      }
    });
  },

  open() {
    clearTimeout(this.closeTimer);
    if (!this.el.hasAttribute("data-popup-open")) this.el.click();
    this.el.removeAttribute("aria-expanded");
  },

  scheduleClose() {
    clearTimeout(this.closeTimer);
    this.closeTimer = setTimeout(() => {
      if (this.el.matches(":hover, :focus-within") || this.popup?.matches(":hover")) return;
      if (this.el.hasAttribute("data-popup-open")) this.el.click();
      this.el.removeAttribute("aria-expanded");
    }, 80);
  },

  on(element, event, listener, options) {
    this.listeners ||= [];
    this.listeners.push([element, event, listener, options]);
    element.addEventListener(event, listener, options);
  },
};
