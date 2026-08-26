import {
  Node,
  NodeContent,
  NodeHeader,
  NodeTitle,
} from "@upstream/ai_elements/node";

// Ported from `StorybookWeb.Examples.node_default/1`.
//
// shadcn's card with the class strings AI Elements writes over it. The two
// handles are React Flow's connection dots and are drawn only when the graph
// asks for them, so neither side draws one here.
export default function NodeDefault() {
  return (
    <Node handles={{ source: false, target: false }}>
      <NodeHeader>
        <NodeTitle>Reader</NodeTitle>
      </NodeHeader>
      <NodeContent>Reads a registry source and writes a spec.</NodeContent>
    </Node>
  );
}
