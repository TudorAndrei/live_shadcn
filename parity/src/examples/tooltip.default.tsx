import { Tooltip, TooltipContent, TooltipTrigger } from "@upstream/shadcn/ui/tooltip";

// Ported from `StorybookWeb.Examples.tooltip_default/1`.
export default function TooltipDefault() {
  return (
    <Tooltip>
      <TooltipTrigger>ac60ef5</TooltipTrigger>
      <TooltipContent side="top">
        The upstream commit every digest in the manifest was taken at.
      </TooltipContent>
    </Tooltip>
  );
}
