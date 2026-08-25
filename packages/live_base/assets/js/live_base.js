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
import { Carousel } from "./carousel.js";
import { Calendar } from "./calendar.js";
import { Clipboard } from "./clipboard.js";
import { Floating } from "./floating.js";
import { Overlay } from "./overlay.js";
import { Roving } from "./roving.js";
import { Resizable } from "./resizable.js";
import { Scroller } from "./scroller.js";
import { Slider } from "./slider.js";
import { Toast } from "./toast.js";

export const hooks = {
  "LiveBase.Carousel": Carousel,
  "LiveBase.Calendar": Calendar,
  "LiveBase.Clipboard": Clipboard,
  "LiveBase.Disclosure": Disclosure,
  "LiveBase.Floating": Floating,
  "LiveBase.Overlay": Overlay,
  "LiveBase.Roving": Roving,
  "LiveBase.Resizable": Resizable,
  "LiveBase.Scroller": Scroller,
  "LiveBase.Slider": Slider,
  "LiveBase.Toast": Toast,
};

export {
  Calendar,
  Carousel,
  Clipboard,
  Disclosure,
  Floating,
  Overlay,
  Resizable,
  Roving,
  Scroller,
  Slider,
  Toast,
};
export default hooks;
