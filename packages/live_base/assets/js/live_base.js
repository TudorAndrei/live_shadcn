// The client half of live_base.
//
// The hooks are colocated hooks. Compiling live_base extracts them into
// `phoenix-colocated/live_base`, and `phx-hook={LiveBase.Popover.hook()}` in
// generated markup names one of them. Register them with your LiveSocket:
//
//   import "live_base";
//   import { hooks as liveBase } from "phoenix-colocated/live_base";
//
//   const liveSocket = new LiveSocket("/live", Socket, {
//     hooks: { ...liveBase },
//   });
//
// The bundler resolves `phoenix-colocated` from `Mix.Project.build_path()`, so
// esbuild needs it in `NODE_PATH`. This entry installs the document-level
// behavior that is not a hook.

import { installAvatarImages } from "./avatar.js";
import { installCheckboxBehavior } from "./checkbox.js";
import { installInputGroupBehavior } from "./input_group.js";
import { InputOtp, installInputOtpBehavior } from "./input_otp.js";

installAvatarImages();
installCheckboxBehavior();
installInputGroupBehavior();
installInputOtpBehavior();

export {
  InputOtp,
  installAvatarImages,
  installCheckboxBehavior,
  installInputGroupBehavior,
  installInputOtpBehavior,
};
