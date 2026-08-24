// The client half of live_base.
//
// Register the hooks with your LiveSocket:
//
//   import { hooks as liveBase } from "live_base";
//
//   const liveSocket = new LiveSocket("/live", Socket, {
//     hooks: { ...liveBase },
//   });
//
// Hook names are namespaced, so `phx-hook="LiveBase.Disclosure"` in generated
// markup cannot collide with a hook of your own.

import { Disclosure } from "./disclosure.js";
import { Floating } from "./floating.js";
import { Overlay } from "./overlay.js";
import { Roving } from "./roving.js";
import { Scroller } from "./scroller.js";
import { Slider } from "./slider.js";
import { Toast } from "./toast.js";

export const hooks = {
  "LiveBase.Disclosure": Disclosure,
  "LiveBase.Floating": Floating,
  "LiveBase.Overlay": Overlay,
  "LiveBase.Roving": Roving,
  "LiveBase.Scroller": Scroller,
  "LiveBase.Slider": Slider,
  "LiveBase.Toast": Toast,
};

export { Disclosure, Floating, Overlay, Roving, Scroller, Slider, Toast };
export default hooks;
