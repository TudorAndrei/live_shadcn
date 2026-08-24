// The scroll-area hook.
//
// Base UI's scroll area replaces the platform scrollbar with one the style
// sheet can reach. Everything that takes — how much there is to scroll, how far
// down the reader is, how tall the thumb should be — is a measurement, and a
// measurement is the one thing a `Phoenix.LiveView.JS` command cannot make.
//
// So the hook measures and writes, and decides nothing else. Every rule that
// reads what it writes is shadcn's, unchanged:
//
//   data-has-overflow-x     there is more content than fits, across
//   data-has-overflow-y     the same, down
//   data-overflow-x-start   there is content hidden off the start edge
//   data-overflow-x-end     …off the end edge
//   data-overflow-y-start   the same, up
//   data-overflow-y-end     the same, down
//   data-scrolling          present while the reader is scrolling, briefly after
//
//   --scroll-area-thumb-height   how tall the thumb is, in pixels
//   --scroll-area-thumb-width    how wide
//   --scroll-area-overflow-y-start  how far down the reader has scrolled, 0 to 1
//   --scroll-area-overflow-y-end    how far is left
//   --scroll-area-overflow-x-start  the same, across
//   --scroll-area-overflow-x-end
//
// Declared on the root:
//
//   data-lb-scroller   on the viewport, the element that actually scrolls
//   data-lb-thumb      on each thumb, so dragging one scrolls the viewport
//
// The thumb's *position* is a style, not a variable: `translate3d` on the thumb
// itself. Base UI does the same, because a transform is the one property a
// browser moves without laying the page out again.

// How long `data-scrolling` outlives the last scroll event. Long enough that a
// scrollbar which fades in does not flicker between two flicks of a wheel.
const SETTLE = 500;

// A thumb smaller than this is one nobody can grab.
const MINIMUM_THUMB = 20;

export const Scroller = {
  mounted() {
    this.viewport = this.el.querySelector("[data-lb-scroller]") || this.el;

    this.onScroll = () => this.scrolled();
    this.viewport.addEventListener("scroll", this.onScroll, { passive: true });

    // Content arrives after the first paint as often as with it — a stream
    // appends, an image loads — and either changes what there is to scroll.
    this.observer = new ResizeObserver(() => this.measure());
    this.observer.observe(this.viewport);
    for (const child of this.viewport.children) this.observer.observe(child);

    for (const thumb of this.el.querySelectorAll("[data-lb-thumb]")) {
      thumb.addEventListener("pointerdown", (event) => this.grab(event, thumb));
    }

    this.measure();
  },

  updated() {
    this.measure();
  },

  destroyed() {
    this.viewport.removeEventListener("scroll", this.onScroll);
    this.observer?.disconnect();
    clearTimeout(this.timer);
  },

  // Everything the style sheet reads, from one read of the layout.
  measure() {
    const { scrollHeight, clientHeight, scrollWidth, clientWidth } = this.viewport;

    this.axis("y", scrollHeight, clientHeight, this.viewport.scrollTop);
    this.axis("x", scrollWidth, clientWidth, this.viewport.scrollLeft);
  },

  axis(name, total, visible, offset) {
    const overflowing = total > visible + 1;
    const targets = [this.el, ...this.el.querySelectorAll("[data-slot]")];

    for (const target of targets) {
      target.toggleAttribute(`data-has-overflow-${name}`, overflowing);
      target.toggleAttribute(`data-overflow-${name}-start`, overflowing && offset > 0);
      target.toggleAttribute(
        `data-overflow-${name}-end`,
        overflowing && offset + visible < total - 1,
      );
    }

    // The thumb is as much of the track as the viewport is of the content, and
    // it sits that far along. Both are ratios, so neither needs to know how
    // long the track is — the style sheet does, and it is where they are read.
    const track = name === "y" ? this.el.clientHeight : this.el.clientWidth;
    const size = overflowing ? Math.max(MINIMUM_THUMB, (visible / total) * track) : 0;
    const travel = Math.max(0, total - visible);
    const at = travel === 0 ? 0 : (offset / travel) * (track - size);

    const style = this.el.style;
    style.setProperty(`--scroll-area-thumb-${name === "y" ? "height" : "width"}`, `${size}px`);
    style.setProperty(`--scroll-area-overflow-${name}-start`, travel === 0 ? "0" : offset / travel);
    style.setProperty(
      `--scroll-area-overflow-${name}-end`,
      travel === 0 ? "0" : 1 - offset / travel,
    );

    for (const thumb of this.el.querySelectorAll(`[data-lb-thumb][data-orientation='${axis(name)}']`)) {
      thumb.style.transform =
        name === "y" ? `translate3d(0, ${at}px, 0)` : `translate3d(${at}px, 0, 0)`;
    }
  },

  scrolled() {
    this.mark();
    this.measure();
  },

  // `data-scrolling` for the length of the scroll and a moment after. A class
  // string that fades a scrollbar in reads it, and a scrollbar that vanished
  // between two flicks of a wheel would flicker.
  mark() {
    clearTimeout(this.timer);

    for (const target of this.scrollables()) target.toggleAttribute("data-scrolling", true);

    this.timer = setTimeout(() => {
      for (const target of this.scrollables()) target.removeAttribute("data-scrolling");
    }, SETTLE);
  },

  scrollables() {
    return [this.el, ...this.el.querySelectorAll("[data-slot]")];
  },

  // Dragging the thumb scrolls the viewport, which scrolls this hook, which
  // moves the thumb. The thumb is never moved directly: one direction of
  // travel means the two can never disagree.
  grab(event, thumb) {
    event.preventDefault();
    thumb.setPointerCapture(event.pointerId);

    const vertical = thumb.getAttribute("data-orientation") !== "horizontal";
    const start = vertical ? event.clientY : event.clientX;
    const from = vertical ? this.viewport.scrollTop : this.viewport.scrollLeft;

    const total = vertical ? this.viewport.scrollHeight : this.viewport.scrollWidth;
    const visible = vertical ? this.viewport.clientHeight : this.viewport.clientWidth;
    const track = vertical ? this.el.clientHeight : this.el.clientWidth;
    const size = Math.max(MINIMUM_THUMB, (visible / total) * track);

    const move = (moved) => {
      const travelled = (vertical ? moved.clientY : moved.clientX) - start;
      const room = track - size;
      const scrolled = room === 0 ? 0 : (travelled / room) * (total - visible);

      if (vertical) this.viewport.scrollTop = from + scrolled;
      else this.viewport.scrollLeft = from + scrolled;
    };

    const release = () => {
      thumb.removeEventListener("pointermove", move);
      thumb.removeEventListener("pointerup", release);
      thumb.removeEventListener("pointercancel", release);
    };

    thumb.addEventListener("pointermove", move);
    thumb.addEventListener("pointerup", release);
    thumb.addEventListener("pointercancel", release);
  },
};

function axis(name) {
  return name === "y" ? "vertical" : "horizontal";
}
