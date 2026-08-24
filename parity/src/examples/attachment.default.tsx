import {
  Attachment,
  AttachmentContent,
  AttachmentDescription,
  AttachmentGroup,
  AttachmentMedia,
  AttachmentTitle,
} from "@upstream/shadcn/ui/attachment";

// Ported from `StorybookWeb.Examples.attachment_default/1`.
export default function AttachmentDefault() {
  return (
    <AttachmentGroup className="max-w-md">
      <Attachment>
        <AttachmentMedia />
        <AttachmentContent>
          <AttachmentTitle>accordion.json</AttachmentTitle>
          <AttachmentDescription>4 KB · spec</AttachmentDescription>
        </AttachmentContent>
      </Attachment>
    </AttachmentGroup>
  );
}
