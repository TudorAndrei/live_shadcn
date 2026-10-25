defmodule LiveBase.RadioGroup do
  @moduledoc """
  Keeps the visible radio controls of a group in step with their native inputs,
  and walks them with the arrow keys.
  """

  use Phoenix.Component

  @doc "The client hook name the group declares in `phx-hook`."
  def hook, do: "LiveBase.RadioGroup.RadioGroup"

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook radio_group.js#RadioGroup --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".RadioGroup">
      const RadioGroup = {
        mounted() {
          this.serverStates = new WeakMap();
          this.syncServerState();
          this.updateTabStops();
          this.onRadioFocus = (event) => this.radioFocus(event);
          this.el.addEventListener("focusin", this.onRadioFocus);
          this.onRadioChange = (event) => this.radioChange(event);
          this.el.addEventListener("change", this.onRadioChange);
          this.onRadioKeydown = (event) => this.radioKeydown(event);
          this.el.addEventListener("keydown", this.onRadioKeydown);
          this.onRadioSelect = (event) => {
            const control = event.target;
            if (event.detail?.group !== this.el.id || !this.controls().includes(control)) return;
            if (control.hasAttribute("data-disabled") || control.hasAttribute("data-readonly")) return;
            this.selectControl(control);
            this.inputFor(control)?.dispatchEvent(new Event("change", { bubbles: true }));
          };
          this.el.addEventListener("live-base:select-radio", this.onRadioSelect);
          this.onRadioLabel = (event) => {
            if (event.defaultPrevented || !(event.target instanceof Element)) return;
            const label = event.target.closest("label");
            const control = this.controlFor(label?.control);
            if (!control || event.target.closest("a[href], button, input, select, textarea")) return;
            event.preventDefault();
            if (control.hasAttribute("data-disabled") || control.hasAttribute("data-readonly")) return;
            control.focus({ preventScroll: true });
            if (!control.contains(event.target) && control.getAttribute("aria-checked") !== "true") control.click();
          };
          this.el.ownerDocument.addEventListener("click", this.onRadioLabel, true);
        },
        updated() {
          this.syncServerState();
          this.updateTabStops(document.activeElement);
        },
        destroyed() {
          this.el.ownerDocument.removeEventListener("click", this.onRadioLabel, true);
          this.el.removeEventListener("live-base:select-radio", this.onRadioSelect);
          this.el.removeEventListener("keydown", this.onRadioKeydown);
          this.el.removeEventListener("change", this.onRadioChange);
          this.el.removeEventListener("focusin", this.onRadioFocus);
        },
        radioFocus(event) {
          const target = event.target;
          if (!(target instanceof Element) || target.closest("[role='radiogroup']") !== this.el) return;
          if (target instanceof HTMLInputElement && target.type === "radio") this.controlFor(target)?.focus();
          else if (target.matches("[role='radio']")) this.updateTabStops(target);
        },
        controls() {
          return [...this.el.querySelectorAll("[role='radio']")].filter((control) => control.closest("[role='radiogroup']") === this.el);
        },
        controlFor(input) {
          if (!(input instanceof HTMLInputElement) || input.type !== "radio") return null;
          const control = input.previousElementSibling;
          return control?.matches("[role='radio']") && control.closest("[role='radiogroup']") === this.el ? control : null;
        },
        inputFor(control) {
          const input = control.nextElementSibling;
          return this.controlFor(input) === control ? input : null;
        },
        syncServerState() {
          for (const control of this.controls()) {
            const server = control.getAttribute("data-lb-radio-state");
            const previous = this.serverStates.get(control);
            const declaration = previous?.server === server ? previous : {
              server,
              override: previous ? server === "true" : null
            };
            this.serverStates.set(control, declaration);
            this.applyState(control, declaration.override ?? control.getAttribute("aria-checked") === "true");
          }
        },
        enabledControls() {
          return this.controls().filter((control) => !control.hasAttribute("data-disabled") && control.getAttribute("aria-disabled") !== "true");
        },
        updateTabStops(preferred) {
          const enabled = this.enabledControls();
          const entry = enabled.includes(preferred) ? preferred : enabled.find((control) => control.getAttribute("aria-checked") === "true") || enabled[0];
          for (const control of this.controls()) control.tabIndex = control === entry ? 0 : -1;
        },
        radioKeydown(event) {
          const control = event.target;
          const enabled = this.enabledControls();
          const index = enabled.indexOf(control);
          if (index < 0) return;
          if (event.key === " " && (control.getAttribute("aria-checked") === "true" || control.hasAttribute("data-readonly"))) {
            event.preventDefault();
            event.stopPropagation();
            return;
          }
          if (event.altKey || event.ctrlKey || event.metaKey) return;
          const step = {
            ArrowDown: 1,
            ArrowRight: 1,
            ArrowUp: -1,
            ArrowLeft: -1
          }[event.key];
          if (!step) return;
          event.preventDefault();
          event.stopPropagation();
          const next = enabled[(index + step + enabled.length) % enabled.length];
          if (next !== control && !next.hasAttribute("data-readonly")) next.click();
          next.focus();
          this.updateTabStops(next);
        },
        radioChange(event) {
          const input = event.target;
          if (!(input instanceof HTMLInputElement) || input.type !== "radio" || input.closest("[role='radiogroup']") !== this.el) return;
          const selectedControl = this.controlFor(input);
          if (!input.checked && selectedControl?.getAttribute("aria-checked") !== "true") return;
          for (const control of this.controls()) this.serverStates.set(control, {
            server: control.getAttribute("data-lb-radio-state"),
            override: control === selectedControl
          });
          this.selectControl(selectedControl);
        },
        selectControl(selectedControl) {
          if (!selectedControl) return;
          for (const control of this.controls()) {
            const selected = control === selectedControl;
            this.applyState(control, selected);
          }
          this.updateTabStops(selectedControl);
        },
        applyState(control, selected) {
          const radio = this.inputFor(control);
          if (!radio) return;
          if (radio.checked !== selected) radio.checked = selected;
          radio.toggleAttribute("checked", selected);
          control.setAttribute("aria-checked", String(selected));
          control.toggleAttribute("data-checked", selected);
          control.toggleAttribute("data-unchecked", !selected);
          control.toggleAttribute("data-filled", selected);
          control.querySelector("[data-slot='radio-group-indicator']")?.toggleAttribute("hidden", !selected);
        }
      };
      export default RadioGroup;
    </script>
    <%!-- /colocated-hook --%>
    """
  end
end
