import {
  MicSelector,
  MicSelectorContent,
  MicSelectorTrigger,
} from "@upstream/ai_elements/mic-selector";
import { Label } from "@upstream/shadcn/ui/label";

// Ported from `StorybookWeb.Examples.mic_selector_default/1`.
//
// The device list is the browser's here and the caller's there: upstream reads
// `navigator.mediaDevices`, which reports nothing without a permission prompt,
// and a server has no such list at all. Closed — which is how both sides start
// — the list is not drawn either way, so what is compared is the trigger.
export default function MicSelectorDefault() {
  return (
    <div className="flex max-w-sm flex-col gap-2">
      <Label id="mic-label">Microphone</Label>
      <MicSelector>
        <MicSelectorTrigger aria-labelledby="mic-label">Select a microphone</MicSelectorTrigger>
        <MicSelectorContent />
      </MicSelector>
    </div>
  );
}
