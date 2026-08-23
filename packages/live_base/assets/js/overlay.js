// The overlay hook.
//
// Opening a dialog is a Phoenix.LiveView.JS command: it sets the attributes the
// class strings read, moves the focus, and remembers where the focus came from.
// This hook is for the three consequences a JS command cannot express.
//
//   1. a timed attribute. `data-starting-style` has to be present for one frame
//      and `data-ending-style` for the length of a transition, and a command has
//      no notion of "until the transition ends".
//   2. scroll lock. The page behind a modal must not scroll, and how much
//      padding replaces the scrollbar is a measurement.
//   3. focus containment. Tab order is decided by the browser as the key is
//      pressed; there is no attribute that says "and no further".
//
// The hook is declared on the popup and finds the rest from its own markup:
//
//   data-lb-backdrop  the id of the layer behind it
//   data-lb-modal     present when the page behind must not scroll or receive
//                     focus, absent for a non-modal overlay
//
// Both are plumbing between the generator and this file, and neither is read by
// a shadcn class string.

import { hide, show } from "./transition.js";

const OPEN = "data-open";

const FOCUSABLE = [
  "a[href]",
  "button:not([disabled])",
  "input:not([disabled]):not([type='hidden'])",
  "select:not([disabled])",
  "textarea:not([disabled])",
  "[tabindex]:not([tabindex='-1'])",
].join(",");

export const Overlay = {
  mounted() {
    this.modal = this.el.hasAttribute("data-lb-modal");
    this.open = this.el.hasAttribute(OPEN);
    this.onKeydown = (event) => this.keydown(event);

    if (this.open) this.enter(false);

    this.observer = new MutationObserver(() => this.stateChanged());
    this.observer.observe(this.el, { attributes: true, attributeFilter: [OPEN] });
  },

  destroyed() {
    this.observer?.disconnect();
    clearTimeout(this.timer);
    this.release();
  },

  layers() {
    const backdrop = this.el.getAttribute("data-lb-backdrop");
    const behind = backdrop && document.getElementById(backdrop);
    return behind ? [this.el, behind] : [this.el];
  },

  stateChanged() {
    const open = this.el.hasAttribute(OPEN);
    if (open === this.open) return;
    this.open = open;
    open ? this.enter(true) : this.leave();
  },

  enter(animate) {
    clearTimeout(this.timer);
    show(this.layers(), animate);
    this.hold();
  },

  leave() {
    clearTimeout(this.timer);
    this.release();
    this.timer = hide(this.layers());
  },

  // While the dialog is open the page behind it does not scroll and does not
  // take the focus. Replacing the scrollbar's width keeps the page from
  // shifting under the dialog as it opens.
  hold() {
    if (!this.modal || this.held) return;
    this.held = { overflow: document.body.style.overflow, padding: document.body.style.paddingRight };

    const scrollbar = window.innerWidth - document.documentElement.clientWidth;
    document.body.style.overflow = "hidden";
    if (scrollbar > 0) document.body.style.paddingRight = `${scrollbar}px`;

    document.addEventListener("keydown", this.onKeydown, true);
  },

  release() {
    if (!this.held) return;
    document.body.style.overflow = this.held.overflow;
    document.body.style.paddingRight = this.held.padding;
    this.held = null;
    document.removeEventListener("keydown", this.onKeydown, true);
  },

  // Tab from the last focusable element goes to the first, and Shift+Tab from
  // the first goes to the last. Nothing else is intercepted: Escape and every
  // other key belong to the server's own bindings.
  keydown(event) {
    if (event.key !== "Tab") return;

    const focusable = [...this.el.querySelectorAll(FOCUSABLE)].filter((el) => el.offsetParent);
    if (focusable.length === 0) return event.preventDefault();

    const first = focusable[0];
    const last = focusable[focusable.length - 1];
    const active = document.activeElement;

    if (!this.el.contains(active)) {
      event.preventDefault();
      first.focus();
    } else if (event.shiftKey && active === first) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && active === last) {
      event.preventDefault();
      first.focus();
    }
  },
};
