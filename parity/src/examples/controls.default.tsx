import { ReactFlowProvider } from "@xyflow/react";
import { Controls } from "@upstream/ai_elements/controls";

// Ported from `StorybookWeb.Examples.controls_default/1`.
//
// The provider carries no markup of its own — React Flow's controls read a
// store, and outside one they throw. What is compared is the box and the class
// string, which is all AI Elements adds.
export default function ControlsDefault() {
  return (
    <ReactFlowProvider>
      <Controls className="w-fit" showFitView={false} showInteractive={false} showZoom />
    </ReactFlowProvider>
  );
}
