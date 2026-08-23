// The storybook mounts its own LiveSocket and reads the hooks from here, so a
// component rendered inside the sandbox behaves exactly as it does on a page.
import { hooks as liveBase } from "live_base";

(function () {
  window.storybook = { Hooks: liveBase };
})();
