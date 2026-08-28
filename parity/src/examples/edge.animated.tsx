import { BaseEdge } from "@xyflow/react";

// Upstream does not publish a stand-alone Edge example. This fixture uses the
// same React Flow primitive and the same SVG body as Edge.Animated. The fixed
// path is the browser-independent result that React Flow normally calculates
// from two nodes.
export default function EdgeAnimated() {
  const path = "M8,16 C 114,16 114,80 220,80";

  return (
    <svg className="h-24 w-64" viewBox="0 0 240 96">
      <BaseEdge id="animated-wire" path={path} style={{ stroke: "rgb(37, 99, 235)" }} />
      <circle fill="var(--primary)" r="4">
        <animateMotion dur="2s" path={path} repeatCount="indefinite" />
      </circle>
    </svg>
  );
}
