// The disclosure hook.
//
// Everything discrete about opening a panel — aria-expanded, data-panel-open,
// data-open — is a Phoenix.LiveView.JS command declared on the server. This
// hook exists for the two things a JS command cannot express, and for nothing
// else:
//
//   1. a measurement. `h-(--accordion-panel-height)` asks for a height that
//      only the browser can compute.
//   2. a timed attribute. `data-starting-style` has to be present for one
//      frame and `data-ending-style` for the length of a transition, and a JS
//      command has no notion of "until the transition ends".
//
// The hook is declared on the panel and reads its own configuration from the
// markup the generator emitted:
//
//   data-lb-height-var    the CSS variable that carries the measured height
//   data-lb-width-var     the CSS variable that carries the measured width
//   data-lb-measure       on the descendant whose natural size is measured
//   data-lb-style-target  on every descendant whose class string reads
//                         data-starting-style or data-ending-style
//
// Those four are plumbing between the generator and this file. None of them is
// read by a shadcn class string, which is why they carry a prefix that cannot
// collide with a documented Base UI attribute name.

const OPEN = "data-open";
const CLOSED = "data-closed";
const STARTING = "data-starting-style";
const ENDING = "data-ending-style";

export const Disclosure = {
  mounted() {
    this.heightVar = this.el.getAttribute("data-lb-height-var");
    this.widthVar = this.el.getAttribute("data-lb-width-var");
    this.open = this.el.hasAttribute(OPEN);

    // The server already rendered the right hidden state; only the measurement
    // is missing, and an animation on mount would be a flash, not a transition.
    if (this.open) this.measure();

    this.observer = new MutationObserver(() => this.stateChanged());
    this.observer.observe(this.el, { attributes: true, attributeFilter: [OPEN] });
  },

  destroyed() {
    this.observer?.disconnect();
    clearTimeout(this.timer);
  },

  stateChanged() {
    const open = this.el.hasAttribute(OPEN);
    if (open === this.open) return;
    this.open = open;

    // data-closed is exactly the other half of data-open, and the shadcn style
    // sheets read it. Deriving it here keeps the server command to one flip.
    this.el.toggleAttribute(CLOSED, !open);

    open ? this.enter() : this.leave();
  },

  // Remove `hidden` first, because a hidden box measures zero. Then flush the
  // collapsed state so the browser has something to animate away from.
  enter() {
    clearTimeout(this.timer);
    this.el.removeAttribute(ENDING);
    this.el.hidden = false;
    this.measure();

    this.mark(STARTING);
    this.el.offsetHeight;
    this.unmark(STARTING);
  },

  // Measure while the panel still has its natural size, then collapse and wait
  // for the transition the class strings declared. If nothing is transitioning,
  // `duration` is zero and the panel hides on the next tick.
  leave() {
    clearTimeout(this.timer);
    this.measure();
    this.mark(ENDING);

    this.timer = setTimeout(() => {
      this.unmark(ENDING);
      this.el.hidden = true;
    }, this.duration());
  },

  measure() {
    const target = this.el.querySelector("[data-lb-measure]") || this.el;
    const style = this.el.style;

    // `auto` lets the box take its content size for the length of one read.
    if (this.heightVar) style.setProperty(this.heightVar, "auto");
    if (this.widthVar) style.setProperty(this.widthVar, "auto");

    const height = target.scrollHeight;
    const width = target.scrollWidth;

    if (this.heightVar) style.setProperty(this.heightVar, `${height}px`);
    if (this.widthVar) style.setProperty(this.widthVar, `${width}px`);
  },

  // Base UI documents these attributes on the panel. A descendant gets them
  // too when its own class string reads them, which the generator recorded.
  targets() {
    return [this.el, ...this.el.querySelectorAll("[data-lb-style-target]")];
  },

  mark(attribute) {
    for (const el of this.targets()) el.setAttribute(attribute, "");
  },

  unmark(attribute) {
    for (const el of this.targets()) el.removeAttribute(attribute);
  },

  // How long the class strings say the collapse takes. Reading it beats a
  // transitionend listener, which never fires when nothing is transitioning.
  duration() {
    const style = getComputedStyle(this.el.querySelector("[data-lb-measure]") || this.el);
    return (seconds(style.transitionDuration) + seconds(style.transitionDelay)) * 1000;
  },
};

// "0.15s, 0s" -> 0.15
function seconds(list) {
  return Math.max(0, ...list.split(",").map((value) => parseFloat(value) || 0));
}
