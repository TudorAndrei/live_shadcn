import { SandboxTabsBar } from "@upstream/ai_elements/sandbox";

// Ported from `StorybookWeb.Examples.sandbox_default/1`.
//
// One part, because it is the only one that is its own. Every other part of
// `sandbox` wraps a collapsible or a set of tabs, and both of those are one
// function here — their parts have to agree about one id — so the moduledoc
// says which component to compose and there is nothing for the wrappers to
// wrap.
export default function SandboxDefault() {
  return (
    <SandboxTabsBar className="max-w-md">
      <span className="text-muted-foreground text-xs">Files</span>
    </SandboxTabsBar>
  );
}
