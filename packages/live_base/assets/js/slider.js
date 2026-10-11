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
// Each input holds its value. Adjacent thumbs bound range input changes before
// the hook draws or reports the value to LiveView.

export const Slider = {
  mounted() {
    this.inputs = [...this.el.querySelectorAll("[data-lb-slider-input]")];
    this.thumbs = [...this.el.querySelectorAll("[data-lb-slider-thumb]")];
    this.range = this.el.querySelector("[data-lb-slider-range]");

    this.onInput = (event) => {
      this.clampValue(event.target);
      this.place();
      this.reportValue(event.target);
    };

    for (const input of this.inputs) {
      input.addEventListener("input", this.onInput);
      // Browsers normally emit both `input` and `change` for keyboard range
      // changes. `input` is the live update; `change` is the compatibility
      // path for a platform that only commits the final keyboard value.
      input.addEventListener("change", this.onInput);
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
    for (const input of this.inputs) {
      input.removeEventListener("input", this.onInput);
      input.removeEventListener("change", this.onInput);
    }
  },

  clampValue(input) {
    if (this.el.hasAttribute("data-lb-slider-scalar")) {
      for (const other of this.inputs) other.value = input.value;
      return;
    }

    const index = this.inputs.indexOf(input);
    const previous = this.inputs[index - 1];
    const next = this.inputs[index + 1];
    const min = Number(previous?.value ?? (input.min || 0));
    const max = Number(next?.value ?? (input.max || 100));
    input.value = String(Math.min(max, Math.max(min, Number(input.value))));
  },

  reportValue(input) {
    const change = this.el.getAttribute("data-lb-change-event");
    if (!change) return;

    // Do not send the same native value twice when a browser emits its normal
    // `input` followed by `change` pair.
    const value = input.value;
    const scalar = this.el.hasAttribute("data-lb-slider-scalar");
    if (scalar ? this.reportedScalarValue === value : input.dataset.lbReportedValue === value) return;

    if (scalar) this.reportedScalarValue = value;
    else input.dataset.lbReportedValue = value;
    this.pushEvent(change, {
      value,
      values: scalar ? [value] : this.inputs.map((nestedInput) => nestedInput.value),
    });
  },

  vertical() {
    return this.el.getAttribute("data-orientation") === "vertical";
  },

  // Where each thumb sits, and how much of the track is behind it. Both are
  // percentages of the whole, so neither needs to know how long the track is.
  place() {
    const fractions = this.inputs.map((input) => fraction(input)).sort((a, b) => a - b);
    const scalar = this.el.hasAttribute("data-lb-slider-scalar");
    const range = this.inputs.length > 1 && !scalar;
    const from = range ? Math.min(...fractions) : 0;
    const to = Math.max(...fractions, 0);
    const vertical = this.vertical();
    const length = vertical ? this.el.clientHeight : this.el.clientWidth;
    const thumb = this.thumbs[0];
    const edge = thumb ? (vertical ? thumb.offsetHeight : thumb.offsetWidth) / 2 : 0;
    const usable = Math.max(0, length - edge * 2);

    this.inputs.forEach((input, at) => {
      const thumb = this.thumbs[at];
      if (!thumb) return;

      const along = `${edge + fraction(input) * usable}px`;

      if (vertical) {
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

    const size = range ? `${(to - from) * usable}px` : `${edge + to * usable}px`;
    const start = range ? `${edge + from * usable}px` : "0px";

    if (vertical) {
      Object.assign(this.range.style, {
        position: "absolute",
        bottom: start,
        height: size,
        width: "100%",
      });
    } else {
      Object.assign(this.range.style, {
        position: "relative",
        insetInlineStart: start,
        width: size,
        height: "100%",
      });
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
