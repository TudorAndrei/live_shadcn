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
import { installAvatarImages } from "./avatar.js";
import { Carousel } from "./carousel.js";
import { Calendar } from "./calendar.js";
import { installCheckboxBehavior } from "./checkbox.js";
import { Clipboard } from "./clipboard.js";
import { Combobox } from "./combobox.js";
import { Command } from "./command.js";
import { Drawer } from "./drawer.js";
import { Floating } from "./floating.js";
import { InteractionTrigger } from "./interaction_trigger.js";
import { installInputGroupBehavior } from "./input_group.js";
import { InputOtp, installInputOtpBehavior } from "./input_otp.js";
import { ListboxValue } from "./listbox_value.js";
import { Menubar } from "./menubar.js";
import { Overlay } from "./overlay.js";
import { Questionnaire } from "./questionnaire.js";
import { RadioGroup } from "./radio_group.js";
import { Roving } from "./roving.js";
import { Resizable } from "./resizable.js";
import { ResponsiveDialog } from "./responsive_dialog.js";
import { Scroller } from "./scroller.js";
import { Shimmer } from "./shimmer.js";
import { Slider } from "./slider.js";
import { Toast } from "./toast.js";
import { ToggleGroup } from "./toggle_group.js";

export const hooks = {
  "LiveBase.Carousel": Carousel,
  "LiveBase.Calendar": Calendar,
  "LiveBase.Clipboard": Clipboard,
  "LiveBase.Combobox": Combobox,
  "LiveBase.Command": Command,
  "LiveBase.Disclosure": Disclosure,
  "LiveBase.Drawer": Drawer,
  "LiveBase.Floating": Floating,
  "LiveBase.InteractionTrigger": InteractionTrigger,
  "LiveBase.ListboxValue": ListboxValue,
  "LiveBase.Menubar": Menubar,
  "LiveBase.Overlay": Overlay,
  "LiveBase.Questionnaire": Questionnaire,
  "LiveBase.RadioGroup": RadioGroup,
  "LiveBase.Roving": Roving,
  "LiveBase.Resizable": Resizable,
  "LiveBase.ResponsiveDialog": ResponsiveDialog,
  "LiveBase.Scroller": Scroller,
  "LiveBase.Shimmer": Shimmer,
  "LiveBase.Slider": Slider,
  "LiveBase.Toast": Toast,
  "LiveBase.ToggleGroup": ToggleGroup,
};

installAvatarImages();
installCheckboxBehavior();
installInputGroupBehavior();
installInputOtpBehavior();

export {
  Calendar,
  Carousel,
  Clipboard,
  Combobox,
  Command,
  Disclosure,
  Drawer,
  Floating,
  InteractionTrigger,
  InputOtp,
  ListboxValue,
  Menubar,
  Overlay,
  Questionnaire,
  RadioGroup,
  Resizable,
  ResponsiveDialog,
  Roving,
  Scroller,
  Shimmer,
  Slider,
  Toast,
  ToggleGroup,
  installAvatarImages,
  installCheckboxBehavior,
  installInputGroupBehavior,
  installInputOtpBehavior,
};
export default hooks;
