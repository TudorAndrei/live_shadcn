import {
  Conversation,
  ConversationContent,
} from "@upstream/ai_elements/conversation";

// Ported from `StorybookWeb.Examples.conversation_default/1`.
//
// Two components upstream and one here. `<Conversation>` and
// `<ConversationContent>` have to agree about one scroll position, and a
// caller who puts the wrong thing between them has a log that does not scroll —
// so the scroller recipe folds them, the way it folds shadcn's scroll area, and
// what the caller writes is what scrolls.
export default function ConversationDefault() {
  return (
    <Conversation className="h-40 max-w-md border">
      <ConversationContent>
        {[1, 2, 3, 4, 5, 6].map((line) => (
          <p className="text-sm" key={line}>
            Message {line}
          </p>
        ))}
      </ConversationContent>
    </Conversation>
  );
}
