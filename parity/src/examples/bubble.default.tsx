import {
  Bubble,
  BubbleContent,
  BubbleGroup,
} from "@upstream/shadcn/ui/bubble";

// Ported from `StorybookWeb.Examples.bubble_default/1`.
export default function BubbleDefault() {
  return (
    <BubbleGroup className="max-w-md">
      <Bubble align="start">
        <BubbleContent>Which stage writes the snapshot?</BubbleContent>
      </Bubble>
      <Bubble align="end">
        <BubbleContent>`mix ui.verify`, from the examples.</BubbleContent>
      </Bubble>
    </BubbleGroup>
  );
}
