import EmblaCarousel from "embla-carousel";
import Autoplay from "embla-carousel-autoplay";

export const Carousel = {
  mounted() {
    this.viewport = this.el.querySelector("[data-lb-carousel-viewport]");
    this.previous = this.el.querySelector("[data-lb-carousel-previous]");
    this.next = this.el.querySelector("[data-lb-carousel-next]");
    this.index = this.el.querySelector("[data-lb-carousel-index]");
    this.status = this.el.ownerDocument.querySelector(
      `[data-lb-carousel-status="${CSS.escape(this.el.id)}"]`,
    );
    this.options = {
      align: this.el.dataset.carouselAlign || "center",
      axis: this.el.dataset.orientation === "vertical" ? "y" : "x",
      direction: this.el.dataset.carouselDirection || this.el.dir || "ltr",
    };

    const autoplayDelay = Number(this.el.dataset.carouselAutoplay || 0);
    this.autoplay = autoplayDelay > 0
      ? Autoplay({ delay: autoplayDelay, stopOnInteraction: true })
      : null;

    this.onSelect = () => this.measure();
    this.onPrevious = () => this.api?.scrollPrev();
    this.onNext = () => this.api?.scrollNext();
    this.onKeyDown = (event) => this.keyDown(event);
    this.onMouseEnter = () => this.autoplay?.stop();
    this.onMouseLeave = () => this.autoplay?.reset();

    this.previous?.addEventListener("click", this.onPrevious);
    this.next?.addEventListener("click", this.onNext);
    this.el.addEventListener("keydown", this.onKeyDown);

    if (this.autoplay) {
      this.el.addEventListener("mouseenter", this.onMouseEnter);
      this.el.addEventListener("mouseleave", this.onMouseLeave);
    }

    if (this.viewport) {
      this.api = EmblaCarousel(
        this.viewport,
        this.options,
        this.autoplay ? [this.autoplay] : [],
      );
      this.api.on("select", this.onSelect);
      this.api.on("reInit", this.onSelect);
      this.measure();
    }
  },

  updated() {
    this.api?.reInit(this.options, this.autoplay ? [this.autoplay] : []);
  },

  destroyed() {
    this.previous?.removeEventListener("click", this.onPrevious);
    this.next?.removeEventListener("click", this.onNext);
    this.el.removeEventListener("keydown", this.onKeyDown);
    this.el.removeEventListener("mouseenter", this.onMouseEnter);
    this.el.removeEventListener("mouseleave", this.onMouseLeave);
    this.api?.destroy();
  },

  keyDown(event) {
    if (event.key === "ArrowLeft") {
      event.preventDefault();
      this.api?.scrollPrev();
    } else if (event.key === "ArrowRight") {
      event.preventDefault();
      this.api?.scrollNext();
    }
  },

  measure() {
    if (!this.api) return;

    const count = this.api.scrollSnapList().length;
    const current = count === 0 ? 0 : this.api.selectedScrollSnap() + 1;

    this.set(this.previous, !this.api.canScrollPrev());
    this.set(this.next, !this.api.canScrollNext());
    if (this.index) this.index.textContent = `${current}/${count}`;
    if (this.status) this.status.textContent = `Slide ${current} of ${count}`;
  },

  set(button, disabled) {
    if (!button) return;
    button.disabled = disabled;
    button.toggleAttribute("data-disabled", disabled);
  },
};
