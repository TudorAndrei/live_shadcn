import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@upstream/shadcn/ui/collapsible";

// Ported from `StorybookWeb.Examples.collapsible_default/1`.
export default function CollapsibleDefault() {
  return (
    <Collapsible className="max-w-80">
      <CollapsibleTrigger>What the pipeline does</CollapsibleTrigger>
      <CollapsibleContent keepMounted>
        Fetch, spec, generate, verify. Four stages, each one deterministic.
      </CollapsibleContent>
    </Collapsible>
  );
}
