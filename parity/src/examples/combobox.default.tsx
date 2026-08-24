import { Label } from "@upstream/shadcn/ui/label";
import {
  Combobox,
  ComboboxContent,
  ComboboxItem,
  ComboboxTrigger,
} from "@upstream/shadcn/ui/combobox";

// Ported from `StorybookWeb.Examples.combobox_default/1`.
export default function ComboboxDefault() {
  return (
    <div className="flex max-w-sm flex-col gap-2">
      <Label id="recipe-label">Recipe</Label>
      <Combobox>
        <ComboboxTrigger aria-labelledby="recipe-label">Select…</ComboboxTrigger>
        <ComboboxContent>
          <ComboboxItem value="disclosure">Disclosure</ComboboxItem>
          <ComboboxItem value="dialog">Dialog</ComboboxItem>
          <ComboboxItem value="listbox">Listbox</ComboboxItem>
        </ComboboxContent>
      </Combobox>
    </div>
  );
}
