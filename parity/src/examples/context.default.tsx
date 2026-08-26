import { Context, ContextInputUsage } from "@upstream/ai_elements/context";

// Ported from `StorybookWeb.Examples.context_default/1`.
//
// Upstream puts the usage in a context and each row reads it back; here each
// row is given the count it draws, which is the answer every React context in
// this registry gets. `<Context>` is a hover card, so the rows are what both
// sides draw without one being opened — and the wrapper is here only to fill
// the context those rows read.
//
// The cost is a prop on both sides for a reason of its own: upstream reads a
// price per model out of `tokenlens`, and a component that draws a price cannot
// be the thing that knows the price.
export default function ContextDefault() {
  return (
    <div className="max-w-xs space-y-1">
      <Context maxTokens={200_000} usage={{ inputTokens: 12_400 }} usedTokens={14_500}>
        <ContextInputUsage />
      </Context>
    </div>
  );
}
