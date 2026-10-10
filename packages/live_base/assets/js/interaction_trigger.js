// Opens controls whose browser gesture is not a normal click.
//
// Tooltip and hover-card triggers open from pointer or keyboard focus. Context
// menus open at the pointer coordinates from a right click. The hidden
// `phx-click` binding still owns the LiveView.JS state change; this hook only
// translates the browser gesture into that command.
export const InteractionTrigger = {
  mounted() {
    this.popupId = this.el.getAttribute("aria-controls");
    this.positioner = document.getElementById(this.el.dataset.lbPositioner);
    this.syncTrustedClickBlocker();

    if (this.el.hasAttribute("data-lb-open-on-hover")) this.mountHover();
    if (this.el.hasAttribute("data-lb-open-on-context")) this.mountContextMenu();
  },

  updated() {
    this.syncTrustedClickBlocker();
  },

  destroyed() {
    clearTimeout(this.openTimer);
    clearTimeout(this.closeTimer);
    if (this.blockTrustedClick) {
      this.el.removeEventListener("click", this.blockTrustedClick, true);
      this.blockTrustedClick = null;
    }
    for (const [element, event, listener, options] of this.listeners || []) {
      element.removeEventListener(event, listener, options);
    }
  },

  syncTrustedClickBlocker() {
    const callerOwnsClick = this.el.hasAttribute("data-lb-caller-click");

    if (!callerOwnsClick && !this.blockTrustedClick) {
      this.blockTrustedClick = (event) => {
        if (event.isTrusted) event.stopImmediatePropagation();
      };
      this.el.addEventListener("click", this.blockTrustedClick, true);
    }

    if (callerOwnsClick && this.blockTrustedClick) {
      this.el.removeEventListener("click", this.blockTrustedClick, true);
      this.blockTrustedClick = null;
    }
  },

  mountHover() {
    // A pointer click also creates pointer enter and focus events before the
    // browser dispatches click. Do not patch the LiveView in either event.
    // A patch at that point can replace the trigger and lose a caller-owned
    // `phx-click` command. The zero-delay task still opens a hovered or
    // focused tooltip in the same browser turn after the click can run.
    this.pointerPressed = false;
    this.on(this.el, "pointerenter", () => this.schedulePointerOpen());
    this.on(this.el, "pointerdown", () => this.markPointerPressed());
    this.on(this.el, "pointerleave", () => this.leavePointer());
    this.on(this.el, "focusin", () => this.scheduleFocusOpen());
    this.on(this.el, "focusout", () => this.scheduleClose());
    this.on(document, "pointermove", (event) => {
      const popup = this.popupElement();
      const inside = this.el.contains(event.target) || popup?.contains(event.target);

      if (inside) clearTimeout(this.closeTimer);
      else if (this.el.hasAttribute("data-popup-open")) this.scheduleClose();
    });
  },

  schedulePointerOpen() {
    if (!this.pointerPressed) this.scheduleOpen();
  },

  markPointerPressed() {
    this.pointerPressed = true;
    // Hover Card keeps the pointer entry request when the trigger is pressed.
    // Composed attachment triggers also expose the Hover Card slot.
    if (
      this.el.hasAttribute("data-lb-hover-card") ||
      this.el.getAttribute("data-slot") === "hover-card-trigger"
    ) return;
    clearTimeout(this.openTimer);
  },

  leavePointer() {
    this.pointerPressed = false;
    this.scheduleClose();
  },

  scheduleFocusOpen() {
    // Base UI opens a tooltip for keyboard focus. It does not turn the focus
    // caused by a pointer click into a tooltip open request.
    if (!this.pointerPressed) this.scheduleOpen();
  },

  mountContextMenu() {
    this.on(this.el, "contextmenu", (event) => {
      event.preventDefault();
      this.positioner?.setAttribute("data-lb-point-x", String(event.clientX));
      this.positioner?.setAttribute("data-lb-point-y", String(event.clientY));

      if (this.el.hasAttribute("data-popup-open")) {
        this.positioner?.dispatchEvent(new CustomEvent("live-base:reposition"));
      } else {
        this.openClick();
      }
    });
  },

  openHover() {
    clearTimeout(this.openTimer);
    clearTimeout(this.closeTimer);
    if (!this.el.hasAttribute("data-popup-open")) this.executeHoverCommand();
    this.clearHoverExpanded();
  },

  openClick() {
    clearTimeout(this.openTimer);
    clearTimeout(this.closeTimer);
    if (!this.el.hasAttribute("data-popup-open")) this.executeClickCommand();
    this.el.removeAttribute("aria-expanded");
  },

  scheduleClose() {
    clearTimeout(this.openTimer);
    clearTimeout(this.closeTimer);
    this.closeTimer = setTimeout(() => {
      if (
        this.el.matches(":hover, :focus-within") ||
        this.popupElement()?.matches(":hover, :focus-within")
      )
        return;
      if (this.el.hasAttribute("data-popup-open")) this.executeHoverCommand();
      this.clearHoverExpanded();
    }, this.delay("lbCloseDelay", 80));
  },

  scheduleOpen() {
    clearTimeout(this.openTimer);
    clearTimeout(this.closeTimer);
    const delay = this.delay("lbOpenDelay", 0);

    this.openTimer = setTimeout(() => this.openHover(), delay);
  },

  delay(name, fallback) {
    const value = Number(this.el.dataset[name]);
    return Number.isFinite(value) && value >= 0 ? value : fallback;
  },

  popupElement() {
    return this.popupId ? document.getElementById(this.popupId) : null;
  },

  executeClickCommand() {
    const command = this.el.getAttribute("phx-click");
    if (command) this.liveSocket.execJS(this.el, command);
  },

  executeHoverCommand() {
    const command =
      this.el.getAttribute("data-lb-hover-command") || this.el.getAttribute("phx-click");
    if (command) this.liveSocket.execJS(this.el, command);
  },

  clearHoverExpanded() {
    requestAnimationFrame(() => this.el.removeAttribute("aria-expanded"));
  },

  on(element, event, listener, options) {
    this.listeners ||= [];
    this.listeners.push([element, event, listener, options]);
    element.addEventListener(event, listener, options);
  },
};
