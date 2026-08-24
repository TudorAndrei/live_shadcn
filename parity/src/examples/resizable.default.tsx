import { ResizableHandle, ResizablePanel, ResizablePanelGroup } from "@upstream/shadcn/ui/resizable";

// Ported from `StorybookWeb.Examples.resizable_default/1`.
export default function ResizableDefault() {
  return (
    <ResizablePanelGroup id="resizable-default" className="h-40 max-w-md border">
      <ResizablePanel defaultSize="50">First panel</ResizablePanel>
      <ResizableHandle withHandle />
      <ResizablePanel defaultSize="50">Second panel</ResizablePanel>
    </ResizablePanelGroup>
  );
}
