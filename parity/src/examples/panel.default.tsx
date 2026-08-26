import { ReactFlowProvider } from "@xyflow/react";
import { Panel } from "@upstream/ai_elements/panel";

// Ported from `StorybookWeb.Examples.panel_default/1`.
//
// Where it floats is React Flow's, and the provider is what has an opinion
// about that. The box is the component.
export default function PanelDefault() {
  return (
    <ReactFlowProvider>
      <Panel className="w-fit" position="top-left">
        <span className="text-xs">62 components</span>
      </Panel>
    </ReactFlowProvider>
  );
}
