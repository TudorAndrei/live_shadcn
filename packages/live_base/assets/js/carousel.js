// CSS scroll-snap supplies the movement. This hook only measures which way can
// still move, then gives the existing button styles `data-disabled` to read.
export const Carousel = {
  mounted() {
    this.viewport = this.el.querySelector("[data-lb-carousel-viewport]");
    this.previous = this.el.querySelector("[data-lb-carousel-previous]");
    this.next = this.el.querySelector("[data-lb-carousel-next]");
    this.index = this.el.querySelector("[data-lb-carousel-index]");
    this.horizontal = this.el.dataset.orientation !== "vertical";

    this.onScroll = () => this.measure();
    this.onPrevious = () => this.move(-1);
    this.onNext = () => this.move(1);
    this.onKeyDown = (event) => this.keyDown(event);

    this.viewport?.addEventListener("scroll", this.onScroll, { passive: true });
    this.previous?.addEventListener("click", this.onPrevious);
    this.next?.addEventListener("click", this.onNext);
    this.el.addEventListener("keydown", this.onKeyDown);
    this.observer = new ResizeObserver(() => this.measure());
    if (this.viewport) this.observer.observe(this.viewport);
    this.measure();
  },

  updated() {
    this.measure();
  },

  destroyed() {
    this.viewport?.removeEventListener("scroll", this.onScroll);
    this.previous?.removeEventListener("click", this.onPrevious);
    this.next?.removeEventListener("click", this.onNext);
    this.el.removeEventListener("keydown", this.onKeyDown);
    this.observer?.disconnect();
  },

  move(direction) {
    if (!this.viewport) return;
    const distance = this.horizontal ? this.viewport.clientWidth : this.viewport.clientHeight;
    this.viewport.scrollBy({ [this.horizontal ? "left" : "top"]: direction * distance, behavior: "smooth" });
  },

  keyDown(event) {
    const previousKey = this.horizontal ? "ArrowLeft" : "ArrowUp";
    const nextKey = this.horizontal ? "ArrowRight" : "ArrowDown";
    if (event.key === previousKey) {
      event.preventDefault();
      this.move(-1);
    } else if (event.key === nextKey) {
      event.preventDefault();
      this.move(1);
    }
  },

  measure() {
    if (!this.viewport) return;
    const offset = this.horizontal ? this.viewport.scrollLeft : this.viewport.scrollTop;
    const visible = this.horizontal ? this.viewport.clientWidth : this.viewport.clientHeight;
    const count = this.viewport.querySelectorAll("[data-slot='carousel-item']").length;
    const current = count === 0 || visible === 0
      ? 0
      : Math.min(count, Math.max(1, Math.round(offset / visible) + 1));

    this.set(this.previous, current <= 1);
    this.set(this.next, current >= count);
    if (this.index) this.index.textContent = `${current}/${count}`;
  },

  set(button, disabled) {
    if (!button) return;
    button.disabled = disabled;
    button.toggleAttribute("data-disabled", disabled);
  },
};
