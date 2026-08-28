import { Rive } from "@rive-app/webgl2";

const STATE_MACHINE = "default";
const INPUTS = ["listening", "thinking", "speaking", "asleep"];

export const Persona = {
  mounted() {
    this.canvas = this.el.querySelector("[data-persona-canvas]");
    this.frame = requestAnimationFrame(() => {
      this.rive = new Rive({
        autoplay: true,
        canvas: this.canvas,
        src: this.el.dataset.riveSource,
        stateMachines: STATE_MACHINE,
        onLoad: () => {
          this.rive.resizeDrawingSurfaceToCanvas();
          this.inputs = new Map(
            this.rive.stateMachineInputs(STATE_MACHINE).map((input) => [input.name, input]),
          );
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
    this.rive?.cleanup();
  },

  draw(state) {
    if (!this.inputs) return;
    for (const name of INPUTS) {
      const input = this.inputs.get(name);
      if (input) input.value = name === state;
    }
  },
};
