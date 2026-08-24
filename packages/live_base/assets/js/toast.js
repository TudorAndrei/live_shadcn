// The toast hook.
//
// A toast is a message the server decided to show and the reader did not ask
// for. So the list of them is the server's — an assign, a stream, whatever the
// application already has — and this hook never adds one and never invents one.
//
// What it does is everything about the stack that only a browser knows:
//
//   --toast-index              how far back this toast is, 0 at the front
//   --toast-height             how tall it is, measured
//   --toast-frontmost-height   how tall the front one is, so the rest can align
//   --toast-offset-y           how far down the stack this one starts
//   --toast-swipe-movement-x   how far a finger has pushed it, while pushing
//   --toast-swipe-movement-y
//
//   data-expanded        the stack is fanned out, because a reader is looking
//   data-swiping         a finger is on this one
//   data-swipe-direction which way it left, while it is leaving
//
// Declared on the viewport:
//
//   data-lb-toasts     the marker this hook is placed on
//   data-lb-dismiss    the event pushed when a toast should go, with its id
//   data-lb-duration   how long a toast stays, in milliseconds. 0 to stay
//   data-lb-limit      how many newest toasts stay visible
//
// Dismissal is a server event, not a removal. The server owns the list, so a
// toast the client deleted would come back on the next patch — and the reader
// would watch it return.

// How far a finger has to push before letting go dismisses rather than springs
// back.
const THRESHOLD = 48;

export const Toast = {
  mounted() {
    this.timers = new Map();

    this.el.addEventListener("pointerenter", () => this.expand(true));
    this.el.addEventListener("pointerleave", () => this.expand(false));
    this.el.addEventListener("focusin", () => this.expand(true));
    this.el.addEventListener("focusout", () => this.expand(false));

    this.arrange();
  },

  updated() {
    this.arrange();
  },

  destroyed() {
    for (const timer of this.timers.values()) clearTimeout(timer);
  },

  toasts() {
    return [...this.el.querySelectorAll("[data-slot='toast']")];
  },

  // Newest at the front. The server writes them in the order it holds them, so
  // the last one in the list is the one that just arrived.
  arrange() {
    const toasts = this.toasts();
    const front = toasts[0];

    if (front) {
      this.el.style.setProperty("--toast-frontmost-height", `${front.offsetHeight}px`);
    }

    let offset = 0;
    const limit = Number(this.el.getAttribute("data-lb-limit") || 0);

    toasts.forEach((toast, index) => {
      if (!toast.style.getPropertyValue("--toast-swipe-movement-x")) {
        toast.style.setProperty("--toast-swipe-movement-x", "0px");
      }

      if (!toast.style.getPropertyValue("--toast-swipe-movement-y")) {
        toast.style.setProperty("--toast-swipe-movement-y", "0px");
      }

      toast.style.setProperty("--toast-index", index);
      toast.style.setProperty("--toast-height", `${toast.offsetHeight}px`);
      toast.style.setProperty("--toast-offset-y", `${offset}px`);
      offset += toast.offsetHeight;

      // Only the front one is read. The ones under it are a stack of edges, so
      // their content fades out until the reader fans them apart.
      this.mark(toast, "data-behind", index > 0);
      this.mark(toast, "data-limited", limit > 0 && index >= limit);

      this.arm(toast);
      this.grabbable(toast);
    });
  },

  // One toast's own elements that read state: itself, and whatever the
  // generator marked inside it.
  mark(toast, attribute, on) {
    toast.toggleAttribute(attribute, on);

    for (const target of toast.querySelectorAll("[data-lb-style-target]")) {
      target.toggleAttribute(attribute, on);
    }
  },

  // One timer per toast, and only ever one: `arrange` runs on every patch, and
  // a toast that started again on each would never leave.
  arm(toast) {
    const id = toast.id;
    const duration = Number(this.el.getAttribute("data-lb-duration") || 0);

    if (!id || duration <= 0 || this.timers.has(id)) return;

    this.timers.set(
      id,
      setTimeout(() => {
        this.timers.delete(id);
        this.dismiss(toast);
      }, duration),
    );
  },

  dismiss(toast, direction) {
    const event = this.el.getAttribute("data-lb-dismiss");
    if (!event || !toast.id) return;

    if (direction) toast.setAttribute("data-swipe-direction", direction);

    this.pushEvent(event, { id: toast.id });
  },

  // A toast is two elements that read the state, not one: the frame reads
  // `data-expanded` to stop overlapping its neighbours, and the content inside
  // it reads the same attribute to come back to full opacity. The generator
  // marks both with `data-lb-style-target`, so the hook writes to the marks
  // rather than to a shape it assumed.
  targets() {
    return [this.el, ...this.el.querySelectorAll("[data-lb-style-target]")];
  },

  expand(on) {
    for (const target of this.targets()) target.toggleAttribute("data-expanded", on);
  },

  grabbable(toast) {
    if (toast.dataset.lbGrabbable) return;
    toast.dataset.lbGrabbable = "true";

    toast.addEventListener("pointerdown", (event) => this.grab(event, toast));
  },

  // A push that goes far enough dismisses; one that does not springs back. The
  // movement is written as a variable rather than a transform, because the
  // transform is shadcn's and reads the variable among six other things.
  grab(event, toast) {
    if (event.target.closest("button, a, [role='button']")) return;

    toast.setPointerCapture(event.pointerId);
    toast.toggleAttribute("data-swiping", true);

    const from = { x: event.clientX, y: event.clientY };

    const move = (moved) => {
      const x = moved.clientX - from.x;
      const y = Math.max(0, moved.clientY - from.y);

      toast.style.setProperty("--toast-swipe-movement-x", `${x}px`);
      toast.style.setProperty("--toast-swipe-movement-y", `${y}px`);
    };

    const release = (released) => {
      toast.removeEventListener("pointermove", move);
      toast.removeEventListener("pointerup", release);
      toast.removeEventListener("pointercancel", release);
      toast.removeAttribute("data-swiping");

      const x = released.clientX - from.x;
      const y = released.clientY - from.y;

      if (Math.abs(x) > THRESHOLD) return this.dismiss(toast, x > 0 ? "right" : "left");
      if (y > THRESHOLD) return this.dismiss(toast, "down");

      toast.style.removeProperty("--toast-swipe-movement-x");
      toast.style.removeProperty("--toast-swipe-movement-y");
    };

    toast.addEventListener("pointermove", move);
    toast.addEventListener("pointerup", release);
    toast.addEventListener("pointercancel", release);
  },
};
