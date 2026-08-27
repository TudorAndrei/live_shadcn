import { Button } from "@upstream/shadcn/ui/button";
import { Empty, EmptyContent, EmptyDescription, EmptyHeader, EmptyTitle } from "@upstream/shadcn/ui/empty";

// Ported from `StorybookWeb.Examples.empty_default/1`.
export default function EmptyDefault() {
  return (
    <Empty className="max-w-sm">
      <EmptyHeader>
        <EmptyTitle>No components yet</EmptyTitle>
        <EmptyDescription>Run `mix ui.fetch` to discover the registry.</EmptyDescription>
      </EmptyHeader>
      <EmptyContent><Button size="sm" variant="outline">Read the roadmap</Button></EmptyContent>
    </Empty>
  );
}
