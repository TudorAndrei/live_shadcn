// The client half of live_ai_elements.
//
// The hooks are colocated hooks. Compiling live_ai_elements extracts them into
// `phoenix-colocated/live_ai_elements`. Register them with your LiveSocket,
// alongside the live_base ones:
//
//   import "live_base";
//   import "live_ai_elements";
//   import { hooks as liveBase } from "phoenix-colocated/live_base";
//   import { hooks as liveAiElements } from "phoenix-colocated/live_ai_elements";
//
//   const liveSocket = new LiveSocket("/live", Socket, {
//     hooks: { ...liveBase, ...liveAiElements },
//   });
//
// The Persona hook imports `@rive-app/webgl2`, so the application's bundler
// must resolve it. This entry installs the document-level behavior that is not
// a hook.

import { DELTA_EVENT } from "./delta.js";
import { installAttachmentRemove } from "./attachment_remove.js";

installAttachmentRemove();

export { DELTA_EVENT };
