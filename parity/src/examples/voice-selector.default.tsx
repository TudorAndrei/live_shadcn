import {
  VoiceSelectorAccent,
  VoiceSelectorAge,
  VoiceSelectorAttributes,
  VoiceSelectorBullet,
  VoiceSelectorDescription,
  VoiceSelectorName,
} from "@upstream/ai_elements/voice-selector";

// Ported from `StorybookWeb.Examples.voice_selector_default/1`.
//
// Eleven of this component's parts wrap a command dialog, and the generated
// package writes none of them. These are its own.
//
// The accent is given its words rather than its value: upstream turns a value
// into a flag emoji through a `switch`, which the reader records as a prop the
// caller supplies, so both sides are asked for the same thing.
export default function VoiceSelectorDefault() {
  return (
    <div className="flex max-w-sm flex-col gap-1">
      <VoiceSelectorName>Vega</VoiceSelectorName>
      <VoiceSelectorDescription>Warm, unhurried, and a little dry.</VoiceSelectorDescription>
      <VoiceSelectorAttributes>
        <VoiceSelectorAccent>British</VoiceSelectorAccent>
        <VoiceSelectorBullet />
        <VoiceSelectorAge>Adult</VoiceSelectorAge>
      </VoiceSelectorAttributes>
    </div>
  );
}
