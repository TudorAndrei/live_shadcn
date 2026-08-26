import { ReactFlowProvider } from "@xyflow/react";
import { Toolbar } from "@upstream/ai_elements/toolbar";

// Ported from `StorybookWeb.Examples.toolbar_default/1`.
//
// React Flow puts the row under the node it belongs to, which is why the
// provider is here. The row is the component.
export default function ToolbarDefault() {
  return (
    <ReactFlowProvider>
      <Toolbar className="w-fit" isVisible nodeId="reader">
        <button className="text-xs" type="button" aria-label="Run">
          Run
        </button>
      </Toolbar>
    </ReactFlowProvider>
  );
}
