import {
  Attachment,
  AttachmentHoverCard,
  AttachmentHoverCardContent,
  AttachmentHoverCardTrigger,
  AttachmentInfo,
  AttachmentPreview,
  AttachmentRemove,
  Attachments,
} from "@upstream/ai_elements/attachments";

// Ported from `StorybookWeb.Examples.attachments_default/1`.
//
// The three hover-card parts are wrappers around one shadcn component, and the
// generated package does not write them: a dependency cannot name a module
// `mix ui.add` renames on the way into an application, and those parts have to
// agree about one id. So the storybook example composes the application's own
// `<.hover_card>` there, and this side composes upstream's wrappers — which is
// the same hover card either way.
//
// `variant`, `data` and `onRemove` are context fields upstream and attributes in
// the reviewed port, for the reason every context is one: a HEEx component
// has no ancestor to ask, so the part that draws a field takes it. `onRemove` is
// what makes upstream draw the remove button at all, and only the second
// attachment has one on either side.
const remove = () => {};

export default function AttachmentsDefault() {
  return (
    <Attachments className="max-w-md" variant="list">
      <AttachmentHoverCard>
        <AttachmentHoverCardTrigger>
          <Attachment
            data={{ filename: "accordion.json", mediaType: "application/json", type: "file" }}
          >
            <AttachmentPreview />
            <AttachmentInfo showMediaType />
          </Attachment>
        </AttachmentHoverCardTrigger>
        <AttachmentHoverCardContent>
          The contract the accordion port uses.
        </AttachmentHoverCardContent>
      </AttachmentHoverCard>
      <Attachment
        data={{ filename: "upstream.png", mediaType: "image/png", type: "file" }}
        onRemove={remove}
      >
        <AttachmentPreview />
        <AttachmentInfo showMediaType />
        <AttachmentRemove label="Remove upstream.png" />
      </Attachment>
    </Attachments>
  );
}
