// A separator changes only its adjacent panels. The browser owns their pixel
// sizes while the pointer is down; no server round trip can measure this.
export const Resizable = {
  mounted() {
    this.onPointerDown = (event) => this.drag(event);
    this.el.addEventListener("pointerdown", this.onPointerDown);
  },

  destroyed() {
    this.el.removeEventListener("pointerdown", this.onPointerDown);
  },

  drag(event) {
    const handle = event.target.closest("[data-lb-resizable-handle]");
    if (!handle) return;
    const previous = handle.previousElementSibling;
    const next = handle.nextElementSibling;
    if (!previous || !next) return;

    event.preventDefault();
    handle.setPointerCapture(event.pointerId);
    const horizontal = this.el.getAttribute("aria-orientation") !== "vertical";
    const start = horizontal ? event.clientX : event.clientY;
    const previousSize = horizontal ? previous.getBoundingClientRect().width : previous.getBoundingClientRect().height;
    const nextSize = horizontal ? next.getBoundingClientRect().width : next.getBoundingClientRect().height;

    const move = (pointer) => {
      const delta = (horizontal ? pointer.clientX : pointer.clientY) - start;
      const before = Math.max(0, previousSize + delta);
      const after = Math.max(0, nextSize - delta);
      previous.style.flexBasis = `${before}px`;
      next.style.flexBasis = `${after}px`;
    };
    const release = () => {
      handle.removeEventListener("pointermove", move);
      handle.removeEventListener("pointerup", release);
      handle.removeEventListener("pointercancel", release);
    };

    handle.addEventListener("pointermove", move);
    handle.addEventListener("pointerup", release);
    handle.addEventListener("pointercancel", release);
  },
};
