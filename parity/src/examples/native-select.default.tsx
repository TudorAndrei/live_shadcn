import { Label } from "@upstream/shadcn/ui/label";
import { NativeSelect, NativeSelectOption } from "@upstream/shadcn/ui/native-select";

// Ported from `StorybookWeb.Examples.native_select_default/1`.
export default function NativeSelectDefault() {
  return (
    <div className="flex max-w-sm flex-col gap-2">
      <Label id="recipe-label" htmlFor="recipe">Recipe</Label>
      <NativeSelect id="recipe" name="recipe" defaultValue="disclosure" aria-labelledby="recipe-label">
        <NativeSelectOption value="disclosure">Disclosure</NativeSelectOption>
        <NativeSelectOption value="dialog">Dialog</NativeSelectOption>
        <NativeSelectOption value="listbox">Listbox</NativeSelectOption>
      </NativeSelect>
    </div>
  );
}
