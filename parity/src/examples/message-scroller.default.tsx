import {
  MessageScroller,
  MessageScrollerContent,
  MessageScrollerItem,
  MessageScrollerProvider,
  MessageScrollerViewport,
} from "@upstream/shadcn/ui/message-scroller";

// Ported from `StorybookWeb.Examples.message_scroller_default/1`.
export default function MessageScrollerDefault() {
  return (
    <MessageScrollerProvider>
      <MessageScroller className="h-48 max-w-md border">
        <MessageScrollerViewport>
          <MessageScrollerContent>
            {Array.from({ length: 8 }, (_, index) => (
              <MessageScrollerItem className="p-3" key={index}>
                Message {index + 1}
              </MessageScrollerItem>
            ))}
          </MessageScrollerContent>
        </MessageScrollerViewport>
      </MessageScroller>
    </MessageScrollerProvider>
  );
}
