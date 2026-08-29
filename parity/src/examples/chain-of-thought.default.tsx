import {
  ChainOfThought,
  ChainOfThoughtContent,
  ChainOfThoughtHeader,
} from "@upstream/ai_elements/chain-of-thought";

// Ported from `StorybookWeb.Examples.chain_of_thought_default/1`.
//
// `title` is what the disclosure recipe calls the trigger's children, because a
// folded component has one slot and it belongs to the panel. So the header's
// children here are that title.
export default function ChainOfThoughtDefault() {
  return (
    <ChainOfThought className="max-w-80">
      <ChainOfThoughtHeader>Thought for 4 seconds</ChainOfThoughtHeader>
      <ChainOfThoughtContent keepMounted>
        Read the registry index, then the accordion source, then the Base UI page.
      </ChainOfThoughtContent>
    </ChainOfThought>
  );
}
