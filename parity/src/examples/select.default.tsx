import { Label } from "@upstream/shadcn/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@upstream/shadcn/ui/select";

// Ported from `StorybookWeb.Examples.select_default/1`.
export default function SelectDefault() {
  return (
    <div className="flex max-w-sm flex-col gap-2">
      <Label id="style-select-label">Style</Label>
      <Select>
        <SelectTrigger aria-labelledby="style-select-label">
          <SelectValue placeholder="Select…" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="vega">Vega</SelectItem>
          <SelectItem value="nova">Nova</SelectItem>
          <SelectItem value="maia">Maia</SelectItem>
        </SelectContent>
      </Select>
    </div>
  );
}
