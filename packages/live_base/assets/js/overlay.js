// The overlay hook.
//
// Opening a dialog is a Phoenix.LiveView.JS command: it sets the attributes the
// class strings read, moves the focus, and remembers where the focus came from.
// This hook is for the four consequences a JS command cannot express.
//
//   1. a timed attribute. `data-starting-style` has to be present for one frame
//      and `data-ending-style` for the length of a transition, and a command has
//      no notion of "until the transition ends".
//   2. scroll lock. The page behind a modal must not scroll, and how much
//      padding replaces the scrollbar is a measurement.
//   3. focus containment. Tab order is decided by the browser as the key is
//      pressed; there is no attribute that says "and no further".
//   4. background accessibility. Only the front modal and live regions remain
//      available, and caller attributes are restored after the modal closes.
//
// The hook is declared on the popup and finds the rest from its own markup:
//
//   data-lb-backdrop  the id of the layer behind it
//   data-lb-modal     present when the page behind must not scroll or receive
//                     focus, absent for a non-modal overlay
//
// Both are plumbing between the port and this file, and neither is read by
// a shadcn class string.

import { hide, show } from "./transition.js";
import { accessibilityInside, holdAccessibility, releaseAccessibility } from "./modal_accessibility.js";

const OPEN = "data-open";

const FOCUSABLE = [
  "a[href]",
  "button:not([disabled])",
  "input:not([disabled]):not([type='hidden'])",
  "select:not([disabled])",
  "textarea:not([disabled])",
  "[tabindex]:not([tabindex='-1'])",
].join(",");

// Each document has one modal stack. An earlier overlay can close or be
// destroyed while a later one is still open, so scroll locking and focus
// belong to the stack rather than to an individual hook. Overlay and Drawer
// are bundled separately, so the stack lives on `globalThis` to be one stack.
const modalDocuments = (globalThis[Symbol.for("live_base.modal_stack")] ??= new WeakMap());

function frontModal(state) {
  return state.owners.findLast((owner) => owner.el.isConnected && owner.el.hasAttribute(OPEN));
}

function refreshModal(state) {
  state.observer.disconnect();
  const front = frontModal(state);
  state.inside = front ? accessibilityInside(front.el) : new Set();
  if (state.owners.length) {
    state.observer.observe(state.document.body, {
      subtree: true,
      childList: true,
      attributes: true,
      attributeFilter: ["aria-live", "data-open", "hidden", "class", "style"],
    });
  }
}

function holdModal(owner) {
  const document = owner.el.ownerDocument;
  let state = modalDocuments.get(document);
  if (!state) {
    state = {
      document, owners: [], inside: new Set(),
      overflow: document.body.style.overflow,
      padding: document.body.style.paddingRight,
    };
    state.observer = new document.defaultView.MutationObserver(() => refreshModal(state));
    modalDocuments.set(document, state);
    const scrollbar = document.defaultView.innerWidth - document.documentElement.clientWidth;
    document.body.style.overflow = "hidden";
    if (scrollbar > 0) document.body.style.paddingRight = `${scrollbar}px`;
  }
  state.owners.push(owner);
  owner.accessibilityLease = holdAccessibility(owner.el);
  refreshModal(state);
  return state;
}

function releaseModal(owner, state) {
  releaseAccessibility(owner.accessibilityLease);
  owner.accessibilityLease = null;
  state.owners = state.owners.filter((candidate) => candidate !== owner);
  refreshModal(state);
  if (state.owners.length) return;
  state.document.body.style.overflow = state.overflow;
  state.document.body.style.paddingRight = state.padding;
  modalDocuments.delete(state.document);
}

export const Overlay = {
  mounted() {
    this.modal = this.el.hasAttribute("data-lb-modal");
    this.open = this.el.hasAttribute(OPEN);
    this.onKeydown = (event) => this.keydown(event);
    this.onFocusIn = (event) => this.focusin(event);
    this.el.addEventListener("focusin", this.onFocusIn);

    if (this.open) this.enter(false);

    this.observer = new MutationObserver(() => this.stateChanged());
    this.observer.observe(this.el, { attributes: true, attributeFilter: [OPEN] });
  },

  destroyed() {
    this.observer?.disconnect();
    clearTimeout(this.timer);
    this.release();
    this.el.removeEventListener("focusin", this.onFocusIn);
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
    this.held = holdModal(this);
    this.el.ownerDocument.addEventListener("keydown", this.onKeydown, true);
  },

  release() {
    if (!this.held) return;
    releaseModal(this, this.held);
    this.held = null;
    this.el.ownerDocument.removeEventListener("keydown", this.onKeydown, true);
  },

  // LiveView repeats focus commands after two frames. A popup can close in
  // that interval and remain mounted for its exit transition. Keep the
  // current outside focus when that delayed command reaches a closing popup.
  focusin(event) {
    if (this.el.hasAttribute(OPEN)) return;
    const outside = event.relatedTarget;
    if (
      outside?.isConnected && !this.el.contains(outside) &&
      !outside.closest("[hidden], [inert], [aria-hidden='true'], [role='dialog'][data-closed], [role='alertdialog'][data-closed]")
    ) {
      outside.focus({ preventScroll: true });
    }
    if (this.el.contains(this.el.ownerDocument.activeElement)) event.target.blur();
  },

  // Tab from the last focusable element goes to the first, and Shift+Tab from
  // the first goes to the last. Nothing else is intercepted: Escape and every
  // other key belong to the server's own bindings.
  keydown(event) {
    if (event.key !== "Tab" || event.defaultPrevented || frontModal(this.held) !== this) return;

    const focusable = [...new Set([...this.held.inside].flatMap((target) =>
      [...target.querySelectorAll(FOCUSABLE)],
    ))].filter((el) => el.tabIndex >= 0 && el.offsetParent && !el.closest("[aria-hidden='true'], [inert]"));
    if (focusable.length === 0) return event.preventDefault();

    const first = focusable[0];
    const last = focusable[focusable.length - 1];
    const active = this.el.ownerDocument.activeElement;

    if (![...this.held.inside].some((target) => target.contains(active))) {
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
