import { Message, MessageContent, MessageResponse } from "@upstream/ai_elements/message";

// Ported from `StorybookWeb.Examples.ai_message_default/1`.
//
// Named `ai_elements-message` because upstream has a `message` in each registry
// and a name is not an identity. The markdown renderer is shimmed away on this
// side — see `src/shim/streamdown.tsx` — because it is the application's and not
// the component's.
export default function AiElementsMessageDefault() {
  return (
    <Message className="max-w-md" from="assistant">
      <MessageContent>
        <MessageResponse>It is **18 degrees** and clear in Cluj.</MessageResponse>
      </MessageContent>
    </Message>
  );
}
