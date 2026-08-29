import {
  CommitActions,
  CommitAuthor,
  CommitAuthorAvatar,
  CommitCopyButton,
  CommitHash,
  CommitInfo,
  CommitMessage,
  CommitMetadata,
  CommitSeparator,
  CommitTimestamp,
} from "@upstream/ai_elements/commit";

// Ported from `StorybookWeb.Examples.commit_default/1`.
//
// Upstream wraps all of this in a collapsible whose parts are wrappers around
// shadcn's, and the generated package writes none of them: those parts have to
// agree about one id, so the application composes `<.collapsible>` itself. The
// row is what both sides draw here.
//
// The timestamp is given the words rather than a `Date`. Upstream formats one
// with `Intl.RelativeTimeFormat` in an effect; a server has already decided what
// "2 hours ago" says by the time the page is rendered.
export default function CommitDefault() {
  return (
    <CommitInfo className="max-w-md">
      <CommitHash>a99f1b7</CommitHash>
      <CommitMessage>the recipe three components are built on</CommitMessage>
      <CommitMetadata>
        <CommitAuthor>
          <CommitAuthorAvatar className="size-8" initials="TA" />
        </CommitAuthor>
        <CommitSeparator />
        <CommitTimestamp date={new Date("2026-08-26T00:50:00Z")}>2 hours ago</CommitTimestamp>
      </CommitMetadata>
      <CommitActions>
        <CommitCopyButton aria-label="Copy the hash" hash="a99f1b7" />
      </CommitActions>
    </CommitInfo>
  );
}
