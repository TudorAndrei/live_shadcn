import { ToggleGroup, ToggleGroupItem } from "@upstream/shadcn/ui/toggle-group";

// Ported from `StorybookWeb.Examples.toggle_group_default/1`.
export default function ToggleGroupDefault() {
  return (
    <ToggleGroup spacing={0} variant="outline" defaultValue={["bold"]} aria-label="Text formatting">
      <ToggleGroupItem id="bold" name="bold" value="bold" aria-label="Bold">B</ToggleGroupItem>
      <ToggleGroupItem id="italic" name="italic" value="italic" aria-label="Italic">I</ToggleGroupItem>
      <ToggleGroupItem id="underline" name="underline" value="underline" aria-label="Underline">U</ToggleGroupItem>
    </ToggleGroup>
  );
}
