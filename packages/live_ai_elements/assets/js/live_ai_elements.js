// The client half of live_ai_elements.
//
// Register the hooks with your LiveSocket, alongside the live_base ones:
//
//   import { hooks as liveBase } from "live_base";
//   import { hooks as liveAiElements } from "live_ai_elements";
//
//   const liveSocket = new LiveSocket("/live", Socket, {
//     hooks: { ...liveBase, ...liveAiElements },
//   });
//
// Hook names are namespaced, so `phx-hook="LiveAiElements.Delta"` in generated
// markup cannot collide with a hook of your own.

import { Delta, DELTA_EVENT } from "./delta.js";

export const hooks = {
  "LiveAiElements.Delta": Delta,
};

export { Delta, DELTA_EVENT };
export default hooks;
