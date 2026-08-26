// The shimmer hook.
//
// A shimmer is a gradient that slides across a line of text while a model is
// still writing it. Upstream animates it with `motion`, which for a plain
// property like this one calls the Web Animations API — so this hook calls the
// same API with the same two keyframes, and the drawing is the browser's either
// way.
//
// It is a hook rather than a CSS animation because the keyframes are upstream's
// and this pipeline never types a style rule. What the markup declares:
//
//   data-lb-shimmer     the two background positions, `from,to`
//   data-lb-duration    how long one pass takes, in milliseconds
//
// Nothing is pushed and nothing is asked for. Whether a shimmer is moving is
// not a fact the server has any use for.

// What upstream's `duration` prop defaults to, in seconds, for markup that
// declares none.
const DURATION = 2000;

export const Shimmer = {
  mounted() {
    this.start();
  },

  updated() {
    // The text can change while the animation runs — that is the whole point of
    // a shimmer — and the element is the same one, so the animation is left
    // alone. It is restarted only when the keyframes themselves moved.
    if (this.frames !== this.el.getAttribute("data-lb-shimmer")) {
      this.start();
    }
  },

  destroyed() {
    this.animation?.cancel();
  },

  start() {
    this.animation?.cancel();
    this.frames = this.el.getAttribute("data-lb-shimmer");

    const [from, to] = (this.frames ?? "").split(",");

    if (!from || !to) {
      return;
    }

    // A reader who has asked for less motion gets the end state and no
    // movement. The gradient is still there; it stops travelling.
    if (window.matchMedia?.("(prefers-reduced-motion: reduce)").matches) {
      this.el.style.backgroundPosition = to.trim();
      return;
    }

    this.animation = this.el.animate(
      [{ backgroundPosition: from.trim() }, { backgroundPosition: to.trim() }],
      { duration: this.duration(), easing: "linear", iterations: Number.POSITIVE_INFINITY },
    );
  },

  duration() {
    return Number(this.el.getAttribute("data-lb-duration")) || DURATION;
  },
};
