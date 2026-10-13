import { Rive } from "@rive-app/webgl2";

const STATE_MACHINE = "default";
const INPUTS = ["listening", "thinking", "speaking", "asleep"];
const DYNAMIC_COLOR_VARIANTS = new Set(["command", "glint", "halo", "obsidian"]);

export const Persona = {
  mounted() {
    this.canvas = this.el.querySelector("[data-persona-canvas]");
    this.frame = requestAnimationFrame(() => {
      this.rive = new Rive({
        autoplay: true,
        autoBind: true,
        canvas: this.canvas,
        src: this.el.dataset.riveSource,
        stateMachines: STATE_MACHINE,
        onLoad: () => {
          this.rive.resizeDrawingSurfaceToCanvas();
          this.inputs = new Map(
            this.rive.stateMachineInputs(STATE_MACHINE).map((input) => [input.name, input]),
          );
          if (DYNAMIC_COLOR_VARIANTS.has(this.el.dataset.personaVariant)) {
            this.color = this.rive.viewModelInstance?.color("color");
            this.themeChanged = () => this.updateColor();
            this.themeObserver = new MutationObserver(this.themeChanged);
            this.themeObserver.observe(document.documentElement, {
              attributes: true,
              attributeFilter: ["class"],
            });
            this.updateColor();
          }
          this.draw(this.el.dataset.personaState);
          this.el.dataset.riveReady = "true";
        },
        onLoadError: () => {
          this.el.dataset.riveReady = "false";
        },
      });
    });
  },

  updated() {
    this.draw(this.el.dataset.personaState);
  },

  destroyed() {
    cancelAnimationFrame(this.frame);
    this.themeObserver?.disconnect();
    this.rive?.cleanup();
  },

  updateColor() {
    const dark = document.documentElement.classList.contains("dark");
    const channel = dark ? 255 : 0;
    this.color?.rgb(channel, channel, channel);
  },

  draw(state) {
    if (!this.inputs) return;
    for (const name of INPUTS) {
      const input = this.inputs.get(name);
      if (input) input.value = name === state;
    }
  },
};
