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
//
// This entry imports every hook, and `Persona` imports `@rive-app/webgl2`. An
// application that does not render a Persona imports the hooks it uses from
// their own subpaths instead, so its bundler never has to resolve Rive:
//
//   import { Delta } from "live_ai_elements/delta";
//
//   hooks: { ...liveBase, "LiveAiElements.Delta": Delta }

import { Delta, DELTA_EVENT } from "./delta.js";
import { installAttachmentRemove } from "./attachment_remove.js";
import { FileTree } from "./file_tree.js";
import { MicSelector } from "./mic_selector.js";
import { Persona } from "./persona.js";
import { PromptInput } from "./prompt_input.js";
import { Question } from "./question.js";
import { SpeechInput } from "./speech_input.js";
import { Terminal } from "./terminal.js";
import { Transcription } from "./transcription.js";
import { WebPreview } from "./web_preview.js";

installAttachmentRemove();

export const hooks = {
  "LiveAiElements.Delta": Delta,
  "LiveAiElements.FileTree": FileTree,
  "LiveAiElements.MicSelector": MicSelector,
  "LiveAiElements.Persona": Persona,
  "LiveAiElements.PromptInput": PromptInput,
  "LiveAiElements.Question": Question,
  "LiveAiElements.SpeechInput": SpeechInput,
  "LiveAiElements.Terminal": Terminal,
  "LiveAiElements.Transcription": Transcription,
  "LiveAiElements.WebPreview": WebPreview,
};

export { Delta, DELTA_EVENT, FileTree, MicSelector, Persona, PromptInput, Question, SpeechInput, Terminal, Transcription, WebPreview };
export default hooks;
