import type { ReactNode } from "react";

// The markdown renderer, neutralised on this side of the comparison.
//
// Upstream renders assistant prose with Streamdown. The generated components do
// not render markdown at all: `LiveAiElements.Markdown` is a **seam**, and which
// renderer sits behind it is the application's decision — the argument being
// that everybody who renders LLM output already has one, and a component library
// that drags a second one behind it cannot be adopted by them.
//
// So a comparison that rendered Streamdown here and `phoenix_streamdown` there
// would be comparing two markdown renderers, and neither of them is the
// component. With no renderer configured the seam renders the text as text, in a
// `<div>` carrying the class it was given, and that is what this draws.
//
// It is the one shim in this directory that stands in for a package upstream
// really does depend on. The others are files shadcn does not publish.
export function Streamdown({
  children,
  className,
}: {
  children?: ReactNode;
  className?: string;
  plugins?: unknown;
}) {
  return <div className={className}>{children}</div>;
}

export default Streamdown;
