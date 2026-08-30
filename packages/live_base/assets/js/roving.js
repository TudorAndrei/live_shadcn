// The roving-focus hook.
//
// The APG asks that a set of tabs — or a menu, or a toolbar — be walked with
// the arrow keys, with Home and End at its ends. That cannot be a
// Phoenix.LiveView.JS command: `phx-key` filters one key per binding, and one
// element cannot carry four of them.
//
// So this hook does one thing: it works out which item the key means and
// clicks it. Every consequence of choosing an item — which attributes flip,
// which panel shows — stays in the `JS` command already on that item. The hook
// decides *which*, never *what*.
//
// Declared on the container:
//
//   data-lb-roving       the ARIA role of the items to walk, "tab" or "menuitem"
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
    this.el.addEventListener("keydown", (event) => this.keydown(event));
    this.el.addEventListener("pointermove", (event) => this.pointermove(event));
    this.el.addEventListener("pointerleave", () => this.cancelSubmenuOpen());
  },

  destroyed() {
    this.cancelSubmenuOpen();
  },

  items() {
    const role = this.el.getAttribute("data-lb-roving") || "tab";
    return [...this.el.querySelectorAll(`[role='${role}']`)].filter(
      (item) =>
        item.closest("[data-lb-roving]") === this.el &&
        !item.hasAttribute("data-disabled") &&
        item.offsetParent,
    );
  },

  pointermove(event) {
    const role = this.el.getAttribute("data-lb-roving") || "tab";
    const item = event.target.closest(`[role='${role}']`);

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

  keydown(event) {
    this.cancelSubmenuOpen();
    const active = document.activeElement;

    if (event.key === "ArrowRight" && active?.getAttribute("aria-haspopup") === "menu") {
      event.preventDefault();
      const popup = document.getElementById(active.getAttribute("aria-controls"));
      active.click();
      requestAnimationFrame(() => popup?.focus());
      return;
    }

    if (event.key === "ArrowLeft" && this.el.hasAttribute("data-lb-submenu")) {
      const trigger = document.getElementById(this.el.getAttribute("data-lb-parent-trigger"));

      if (trigger) {
        event.preventDefault();
        trigger.click();
        trigger.focus();
      }

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
    const highlight = this.el.getAttribute("data-lb-highlight");

    this.closeOpenSubmenus(items[to]);

    if (highlight) {
      for (const item of items) item.removeAttribute(highlight);
      items[to].setAttribute(highlight, "");
    }

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
