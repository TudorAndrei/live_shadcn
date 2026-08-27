import { SpeechInput } from "@upstream/ai_elements/speech-input";

// Ported from `StorybookWeb.Examples.speech_input_default/1`.
//
// Neither side is listening, which is the state a page opens in. Upstream keeps
// that in React and reaches for `SpeechRecognition`; the reviewed port
// takes it as an attribute, because a server cannot hear anything and the
// browser API belongs to the page.
export default function SpeechInputDefault() {
  return <SpeechInput aria-label="Start dictation" />;
}
