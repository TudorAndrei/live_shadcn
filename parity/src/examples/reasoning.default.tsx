import { Reasoning, ReasoningContent, ReasoningTrigger } from "@upstream/ai_elements/reasoning";

// Ported from `StorybookWeb.Examples.reasoning_default/1`.
//
// `content` is an attribute on the reviewed port and children here, for
// the same reason `title` is: a folded disclosure has one slot and it belongs to
// the panel. The markdown renderer is shimmed away on this side — see
// `src/shim/streamdown.tsx` — because it is the application's and not the
// component's.
export default function ReasoningDefault() {
  return (
    <Reasoning className="max-w-80" defaultOpen={false}>
      <ReasoningTrigger>Thought for 4 seconds</ReasoningTrigger>
      <ReasoningContent keepMounted>
        The reader wants **today&apos;s** weather, so call the tool.
      </ReasoningContent>
    </Reasoning>
  );
}
