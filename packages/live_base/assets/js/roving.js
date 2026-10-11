// The roving-focus hook.
//
// The APG asks that a set of tabs — or a menu, or a toolbar — be walked with
// the arrow keys, with Home and End at its ends. That cannot be a
// Phoenix.LiveView.JS command: `phx-key` filters one key per binding, and one
// element cannot carry four of them.
//
// The hook moves focus and highlight. Tabs can activate on focus; menus and
// options wait for a separate choice. Selection and its effects stay in the
// `JS` command on the item. Pointer focus in an option list does not select it.
//
// Declared on the container:
//
//   data-lb-roving       the ARIA role of the items: "tab", "menuitem", or "option"
//   data-lb-orientation  "horizontal" or "vertical"; decides which arrows apply
//   data-lb-loop         present when the end wraps round to the start
//   data-lb-activate     present when landing on an item chooses it, as in a set
//                        of tabs. Absent for a menu, where moving is moving and
//                        choosing is a separate gesture.
//   data-lb-highlight    the attribute to mark the item landed on, if any

const NEXT = { horizontal: "ArrowRight", vertical: "ArrowDown" };
const PREVIOUS = { horizontal: "ArrowLeft", vertical: "ArrowUp" };
const SUBMENU_POINTER_DELAY = 100;

export const Roving = {
  mounted() {
    this.optionNavigation = this.el.getAttribute("data-lb-roving") === "option";
    this.pointerNavigation = true;
    this.onKeydown = (event) => this.keydown(event);
    this.onPointermove = (event) => this.pointermove(event);
    this.onPointerout = (event) => this.pointerout(event);
    this.onPointerleave = () => this.cancelSubmenuOpen();
    this.el.addEventListener("keydown", this.onKeydown);
    this.el.addEventListener("pointermove", this.onPointermove);
    this.el.addEventListener("pointerout", this.onPointerout);
    this.el.addEventListener("pointerleave", this.onPointerleave);

    if (this.optionNavigation) {
      const positioner = this.el.closest("[data-lb-anchor]");
      this.anchor = document.getElementById(positioner?.getAttribute("data-lb-anchor"));
      this.markPointer = () => (this.pointerNavigation = true);
      this.markKeyboard = () => (this.pointerNavigation = false);
      this.anchor?.addEventListener("pointerdown", this.markPointer);
      this.anchor?.addEventListener("keydown", this.markKeyboard);
    }
  },

  destroyed() {
    this.cancelSubmenuOpen();
    this.el.removeEventListener("keydown", this.onKeydown);
    this.el.removeEventListener("pointermove", this.onPointermove);
    this.el.removeEventListener("pointerout", this.onPointerout);
    this.el.removeEventListener("pointerleave", this.onPointerleave);
    this.anchor?.removeEventListener("pointerdown", this.markPointer);
    this.anchor?.removeEventListener("keydown", this.markKeyboard);
  },

  items() {
    return [...this.el.querySelectorAll(this.itemSelector())].filter(
      (item) =>
        item.closest("[data-lb-roving]") === this.el &&
        !item.hasAttribute("data-disabled") &&
        item.offsetParent,
    );
  },

  itemSelector() {
    const role = this.el.getAttribute("data-lb-roving") || "tab";
    return role === "menuitem" ? "[role^='menuitem']" : `[role='${role}']`;
  },

  pointermove(event) {
    const item = event.target.closest(this.itemSelector());

    if (this.optionNavigation) {
      if (event.pointerType === "touch") return;
      this.pointerNavigation = true;
      if (!this.items().includes(item)) return;
      this.highlight(item);
      item.focus({ preventScroll: true });
      return;
    }

    if (!item || item.closest("[data-lb-roving]") !== this.el) return;

    this.closeOpenSubmenus(item);

    if (item.getAttribute("aria-haspopup") !== "menu") return;
    if (item.getAttribute("aria-expanded") === "true") return;

    this.cancelSubmenuOpen();
    this.submenuTimer = setTimeout(() => {
      if (
        item.matches(":hover") &&
        item.offsetParent &&
        item.getAttribute("aria-expanded") !== "true"
      )
        item.click();
    }, SUBMENU_POINTER_DELAY);
  },

  pointerout(event) {
    if (!this.optionNavigation || !this.pointerNavigation || event.pointerType === "touch") return;

    const items = this.items();
    const item = event.target.closest(this.itemSelector());
    const next = event.relatedTarget?.closest?.(this.itemSelector());
    if (!items.includes(item) || items.includes(next)) return;

    this.highlight(null);
    if (this.el.contains(document.activeElement)) this.el.focus({ preventScroll: true });
  },

  highlight(item) {
    const attribute = this.el.getAttribute("data-lb-highlight");
    if (!attribute) return;
    for (const sibling of this.items()) sibling.removeAttribute(attribute);
    item?.setAttribute(attribute, "");
  },

  cancelSubmenuOpen() {
    clearTimeout(this.submenuTimer);
    this.submenuTimer = null;
  },

  closeOpenSubmenus(except) {
    for (const trigger of this.items().filter(
      (item) =>
        item !== except &&
        item.getAttribute("aria-haspopup") === "menu" &&
        item.getAttribute("aria-expanded") === "true",
    ))
      trigger.click();
  },

  deepestOpenSubmenuTrigger() {
    let menu = this.el;
    let trigger = null;

    while (menu) {
      const child = [...menu.querySelectorAll("[aria-haspopup='menu'][aria-expanded='true']")].find(
        (item) => item.closest("[data-lb-roving]") === menu,
      );

      if (!child) break;
      trigger = child;
      menu = document.getElementById(child.getAttribute("aria-controls"));
    }

    return trigger;
  },

  keydown(event) {
    this.pointerNavigation = false;
    this.cancelSubmenuOpen();
    const active = document.activeElement;

    if ((event.key === "Enter" || event.key === " ") && this.items().includes(active)) {
      event.preventDefault();
      active.click();
      return;
    }

    if (event.key === "ArrowRight" && active?.getAttribute("aria-haspopup") === "menu") {
      event.preventDefault();
      const popup = document.getElementById(active.getAttribute("aria-controls"));
      active.click();
      requestAnimationFrame(() => {
        if (active.getAttribute("aria-expanded") === "true") popup?.focus();
      });
      return;
    }

    let closingTrigger = event.key === "Escape" ? this.deepestOpenSubmenuTrigger() : null;

    if (
      !closingTrigger &&
      ["ArrowLeft", "Escape"].includes(event.key) &&
      this.el.hasAttribute("data-lb-submenu")
    )
      closingTrigger = document.getElementById(this.el.getAttribute("data-lb-parent-trigger"));

    if (closingTrigger) {
      event.preventDefault();
      event.stopPropagation();
      closingTrigger.click();
      closingTrigger.focus();
      return;
    }

    const orientation = this.el.getAttribute("data-lb-orientation") || "horizontal";
    const items = this.items();
    const from = items.indexOf(document.activeElement);
    if (items.length === 0) return;

    const to = this.target(event.key, orientation, from, items.length);
    if (to === null) return;

    event.preventDefault();
    this.move(items, to);
  },

  // Landing on an item is not the same as choosing it. A set of tabs shows the
  // panel you arrive at; a menu waits to be told. The hook decides *which* item
  // either way, and never what happens to it: for tabs it clicks, and the
  // command already on the tab does the rest.
  move(items, to) {
    this.closeOpenSubmenus(items[to]);
    this.highlight(items[to]);

    if (this.el.hasAttribute("data-lb-activate")) items[to].click();
    items[to].focus();
  },

  target(key, orientation, from, count) {
    const loop = this.el.hasAttribute("data-lb-loop");
    const step = (by) => {
      const next = from + by;
      if (next >= 0 && next < count) return next;
      return loop ? (next + count) % count : null;
    };

    switch (key) {
      case NEXT[orientation]:
        return from === -1 ? 0 : step(1);
      case PREVIOUS[orientation]:
        return from === -1 ? count - 1 : step(-1);
      case "Home":
        return 0;
      case "End":
        return count - 1;
      default:
        return null;
    }
  },
};
