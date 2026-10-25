defmodule LiveBase.Slider do
  @moduledoc """
  The behavior behind a slider: one `<input type="range">` per thumb, drawn.

  ## Why the input is still there

  Base UI's slider page documents "a ref to access the nested input element",
  and that input is the whole of the control. It is what a reader drags, what a
  keyboard moves by arrow and by page, what a screen reader announces as a
  value between a minimum and a maximum, and what a form submits. Every one of
  those is the platform's, and none is worth writing again.

  What the platform will not do is let a style sheet reach the track and the
  thumb. So each input is invisible over its own thumb, and the hook puts the
  thumb and the filled part of the track where the input's value says.

  ## What the server knows

  Whatever the form tells it. The input carries a `name`, so a `phx-change` on
  the form around it reports the value the same way a text field does — there
  is no event of this component's own, and nothing to ask for.

  ## The attribute contract

  | Attribute | When |
  |---|---|
  | `data-dragging` | while a reader is holding a thumb |
  | `data-focused` | while a thumb has focus |
  | `data-touched` | once a reader has focused one, and after |
  | `data-orientation` | always, `horizontal` or `vertical` |
  | `data-disabled` | when the slider refuses interaction |
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @hook "LiveBase.Slider.Slider"

  @doc "The client hook name the root declares in `phx-hook`."
  def hook, do: @hook

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook slider.js#Slider --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Slider">
      const Slider = {
        mounted() {
          this.inputs = [];
          this.onInput = (event) => {
            this.clampValue(event.target);
            this.place();
            this.reportValue(event.target);
          };
          this.inputListeners = {
            input: this.onInput,
            change: this.onInput,
            pointerdown: () => this.dragging(true),
            pointerup: () => this.dragging(false),
            pointercancel: () => this.dragging(false),
            focus: () => this.focused(true),
            blur: () => this.focused(false)
          };
          this.refreshControls();
          this.place();
        },
        updated() {
          this.refreshControls();
          if (this.el.hasAttribute("data-lb-slider-scalar")) this.reportedScalarValue = this.inputs[0]?.value;
          this.place();
        },
        destroyed() {
          for (const input of this.inputs) for (const [event, listener] of Object.entries(this.inputListeners)) input.removeEventListener(event, listener);
        },
        refreshControls() {
          const inputs = [...this.el.querySelectorAll("[data-lb-slider-input]")];
          for (const input of this.inputs) {
            if (inputs.includes(input)) continue;
            for (const [event, listener] of Object.entries(this.inputListeners)) input.removeEventListener(event, listener);
          }
          for (const input of inputs) {
            if (this.inputs.includes(input)) continue;
            for (const [event, listener] of Object.entries(this.inputListeners)) input.addEventListener(event, listener);
          }
          this.inputs = inputs;
          this.thumbs = [...this.el.querySelectorAll("[data-lb-slider-thumb]")];
          this.range = this.el.querySelector("[data-lb-slider-range]");
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
          const value = input.value;
          const scalar = this.el.hasAttribute("data-lb-slider-scalar");
          if (scalar ? this.reportedScalarValue === value : input.dataset.lbReportedValue === value) return;
          if (scalar) this.reportedScalarValue = value;
          else input.dataset.lbReportedValue = value;
          this.pushEvent(change, {
            value,
            values: scalar ? [value] : this.inputs.map((nestedInput) => nestedInput.value)
          });
        },
        vertical() {
          return this.el.getAttribute("data-orientation") === "vertical";
        },
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
          if (vertical) Object.assign(this.range.style, {
            position: "absolute",
            bottom: start,
            height: size,
            width: "100%"
          });
          else Object.assign(this.range.style, {
            position: "relative",
            insetInlineStart: start,
            width: size,
            height: "100%"
          });
        },
        dragging(on) {
          this.mark("data-dragging", on);
        },
        focused(on) {
          this.mark("data-focused", on);
          if (on) this.mark("data-touched", true);
        },
        mark(attribute, on) {
          for (const el of [this.el, ...this.el.querySelectorAll("[data-slot]")]) el.toggleAttribute(attribute, on);
        }
      };
      function fraction(input) {
        const min = Number(input.min || 0);
        const max = Number(input.max || 100);
        const value = Number(input.value ?? min);
        return max === min ? 0 : (value - min) / (max - min);
      }
      export default Slider;
    </script>
    <%!-- /colocated-hook --%>
    """
  end

  @doc "The id of one thumb's input, given the slider and the thumb's position."
  def input_id(slider, index), do: "#{slider}-#{index}"

  @doc """
  The attributes the client owns once the page is live.

  All three are facts about a reader's hand and a reader's focus, which the
  server never sees and would otherwise erase on the next patch.
  """
  def owned_attributes(js \\ %JS{}),
    do: JS.ignore_attributes(js, ~w(data-dragging data-focused data-touched), [])
end
