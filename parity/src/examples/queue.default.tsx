import {
  Queue,
  QueueItem,
  QueueItemContent,
  QueueItemIndicator,
  QueueList,
  QueueSectionLabel,
} from "@upstream/ai_elements/queue";

// Ported from `StorybookWeb.Examples.queue_default/1`.
//
// `completed` is a prop on each part here and on each part there. Upstream
// reads it off a context in some of them; a HEEx component has no ancestor to
// ask, so the part that draws a state takes it.
export default function QueueDefault() {
  return (
    <Queue className="max-w-md">
      <QueueSectionLabel label="Waiting" />
      <QueueList>
        <QueueItem>
          <QueueItemIndicator completed />
          <QueueItemContent completed>Read every AI Elements spec again</QueueItemContent>
        </QueueItem>
        <QueueItem>
          <QueueItemIndicator />
          <QueueItemContent>Write a React reference for each one</QueueItemContent>
        </QueueItem>
      </QueueList>
    </Queue>
  );
}
