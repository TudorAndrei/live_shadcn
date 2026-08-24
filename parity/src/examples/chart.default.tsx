import { Line, LineChart } from "recharts";

import { ChartContainer } from "@upstream/shadcn/ui/chart";

// Ported from `StorybookWeb.Examples.chart_default/1`.
export default function ChartDefault() {
  return (
    <ChartContainer config={{ visits: { color: "var(--chart-1)" } }} className="max-w-md">
      <LineChart data={[{ visits: 10 }, { visits: 20 }]}>
        <Line dataKey="visits" stroke="var(--color-visits)" />
      </LineChart>
    </ChartContainer>
  );
}
