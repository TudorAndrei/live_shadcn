// The slider hook.
//
// A slider is a native `<input type="range">` per thumb, and a set of `<div>`s
// drawn where those inputs say. The input is what a reader drags, what a
// keyboard moves, what a screen reader announces and what a form submits — all
// of it the platform's, none of it worth reimplementing.
//
// What the platform will not do is style it. So each input is invisible over
// its own thumb, and this hook does one thing: it puts the thumb and the filled
// part of the track where the input's value says they are.
//
// Declared on the root:
//
//   data-lb-slider-input   on each nested input, the one a reader operates
//   data-lb-slider-thumb   on each thumb, the one a reader sees
//   data-lb-slider-range   on the filled part of the track
//
// Nothing here decides a value. The input holds it, `phx-change` on the form
// around it carries it, and the server never has to be asked what it is.

export const Slider = {
  mounted() {
    this.inputs = [...this.el.querySelectorAll("[data-lb-slider-input]")];
    this.thumbs = [...this.el.querySelectorAll("[data-lb-slider-thumb]")];
    this.range = this.el.querySelector("[data-lb-slider-range]");

    this.onInput = () => this.place();

    for (const input of this.inputs) {
      input.addEventListener("input", this.onInput);
      // `data-dragging` is what the style sheet fades a ring in on, and the
      // platform has no event for "the reader is holding the thumb".
      input.addEventListener("pointerdown", () => this.dragging(true));
      input.addEventListener("pointerup", () => this.dragging(false));
      input.addEventListener("pointercancel", () => this.dragging(false));
      input.addEventListener("focus", () => this.focused(true));
      input.addEventListener("blur", () => this.focused(false));
    }

    this.place();
  },

  updated() {
    this.place();
  },

  destroyed() {
    for (const input of this.inputs) input.removeEventListener("input", this.onInput);
  },

  vertical() {
    return this.el.getAttribute("data-orientation") === "vertical";
  },

  // Where each thumb sits, and how much of the track is behind it. Both are
  // percentages of the whole, so neither needs to know how long the track is.
  place() {
    const fractions = this.inputs.map((input) => fraction(input)).sort((a, b) => a - b);
    const from = this.inputs.length > 1 ? Math.min(...fractions) : 0;
    const to = Math.max(...fractions, 0);

    this.inputs.forEach((input, at) => {
      const thumb = this.thumbs[at];
      if (!thumb) return;

      const along = `${fraction(input) * 100}%`;

      if (this.vertical()) {
        thumb.style.bottom = along;
        thumb.style.insetInlineStart = "50%";
        thumb.style.transform = "translate(-50%, 50%)";
      } else {
        thumb.style.insetInlineStart = along;
        thumb.style.top = "50%";
        thumb.style.transform = "translate(-50%, -50%)";
      }
    });

    if (!this.range) return;

    const size = `${(to - from) * 100}%`;
    const start = `${from * 100}%`;

    if (this.vertical()) {
      Object.assign(this.range.style, { bottom: start, height: size, width: "100%" });
    } else {
      Object.assign(this.range.style, { insetInlineStart: start, width: size, height: "100%" });
    }
  },

  dragging(on) {
    this.mark("data-dragging", on);
  },

  focused(on) {
    this.mark("data-focused", on);
    // A slider a reader has touched is one the styling may treat differently,
    // and it stays touched.
    if (on) this.mark("data-touched", true);
  },

  mark(attribute, on) {
    for (const el of [this.el, ...this.el.querySelectorAll("[data-slot]")]) {
      el.toggleAttribute(attribute, on);
    }
  },
};

function fraction(input) {
  const min = Number(input.min || 0);
  const max = Number(input.max || 100);
  const value = Number(input.value ?? min);

  return max === min ? 0 : (value - min) / (max - min);
}
