import {
  HoverCard,
  HoverCardContent,
  HoverCardTrigger,
} from "@upstream/shadcn/ui/hover-card";

// Ported from `StorybookWeb.Examples.hover_card_default/1`.
export default function HoverCardDefault() {
  return (
    <HoverCard>
      <HoverCardTrigger>shadcn-ui/ui</HoverCardTrigger>
      <HoverCardContent>
        Where the class strings come from. Pinned to a commit, and every file&apos;s digest recorded,
        so drift shows up as a diff.
      </HoverCardContent>
    </HoverCard>
  );
}
