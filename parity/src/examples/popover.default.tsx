import {
  Popover,
  PopoverContent,
  PopoverTitle,
  PopoverTrigger,
} from "@upstream/shadcn/ui/popover";

// Ported from `StorybookWeb.Examples.popover_default/1`.
export default function PopoverDefault() {
  return (
    <Popover>
      <PopoverTrigger>What is a recipe?</PopoverTrigger>
      <PopoverContent>
        <PopoverTitle>Recipes</PopoverTitle>
        The one hand-written part of the pipeline. It says which Base UI part plays which role,
        and what expression computes each attribute.
      </PopoverContent>
    </Popover>
  );
}
