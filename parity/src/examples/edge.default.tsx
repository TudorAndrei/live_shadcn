import { Position } from "@xyflow/react";
import { Edge } from "@upstream/ai_elements/edge";

// Ported from `StorybookWeb.Examples.edge_default/1`.
//
// `Edge.Temporary` computes its path with React Flow's `getSimpleBezierPath`
// over where the two nodes ended up. A server has neither the nodes nor the
// arithmetic, so the port takes the path as an attribute — the same answer
// `code-block` gives about its tokens — and both sides draw the same element
// with the same class string.
export default function EdgeDefault() {
  return (
    <svg className="h-24 w-64" viewBox="0 0 240 96">
      <Edge.Temporary
        id="wire"
        source="a"
        sourcePosition={Position.Right}
        sourceX={8}
        sourceY={16}
        target="b"
        targetPosition={Position.Left}
        targetX={220}
        targetY={80}
      />
    </svg>
  );
}
