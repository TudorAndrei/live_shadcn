import { ChartContainer } from "@upstream/shadcn/ui/chart";

// Ported from `StorybookWeb.Examples.chart_default/1`.
//
// The same `<svg>` the Elixir example passes, and that is the point rather than
// a shortcut. shadcn's `chart.tsx` draws no chart: it is a container, a style
// block, a tooltip body and a legend body, and the plot is whatever the caller
// puts inside it. So the component under test here is the chrome, and a
// faithful port passes it the same children.
//
// This used to render `recharts` `<LineChart>` against two data points while
// the Elixir side rendered a hand-written path — two different pictures, which
// `parity/README.md` forbids: a reference is a port, not a second design.
//
// It was also the only example whose pixel difference moved between runs — 129,
// 134, 142. recharts animates its line on mount through `requestAnimationFrame`
// and React state, and the harness freezes CSS animations and the Web
// Animations API, neither of which that is. Comparing the chrome rather than
// somebody else's animation removes the question instead of suppressing it.
export default function ChartDefault() {
  return (
    <ChartContainer
      config={{ visits: { color: "var(--chart-1)" } }}
      className="max-w-md"
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      children={
        (
          <svg viewBox="0 0 320 160" role="img" aria-label="Visits increased">
            <path
              d="M0 140 L80 110 L160 120 L240 60 L320 20"
              fill="none"
              stroke="var(--color-visits)"
              strokeWidth="8"
            />
          </svg>
        ) as never
      }
    />
  );
}
