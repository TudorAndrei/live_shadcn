import { Message, MessageContent, MessageGroup, MessageHeader } from "@upstream/shadcn/ui/message";

// Ported from `StorybookWeb.Examples.message_default/1`.
export default function ShadcnMessageDefault() {
  return (
    <MessageGroup className="max-w-md">
      <Message>
        <MessageContent>
          <MessageHeader>live_shadcn</MessageHeader>
          Twenty-three components generated, none edited by hand.
        </MessageContent>
      </Message>
    </MessageGroup>
  );
}
