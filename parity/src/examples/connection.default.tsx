import { Connection } from "@upstream/ai_elements/connection";

// Ported from `StorybookWeb.Examples.connection_default/1`.
//
// Four numbers and a bezier between them. Upstream builds the path in a
// template literal and so does the port — this one is arithmetic all the way
// down, and nothing about it is React Flow's.
export default function ConnectionDefault() {
  return (
    <svg className="h-24 w-64" viewBox="0 0 240 96">
      <Connection
        connectionLineStyle={undefined}
        connectionLineType={undefined}
        connectionStatus={null}
        fromHandle={null}
        fromNode={null}
        fromPosition={undefined}
        fromX={8}
        fromY={16}
        toPosition={undefined}
        toX={220}
        toY={80}
      />
    </svg>
  );
}
