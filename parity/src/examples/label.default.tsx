import { Input } from "@upstream/shadcn/ui/input";
import { Label } from "@upstream/shadcn/ui/label";

// Ported from `StorybookWeb.Examples.label_default/1`.
export default function LabelDefault() {
  return (
    <div className="flex max-w-sm flex-col gap-2">
      <Label htmlFor="ref">Upstream ref</Label>
      <Input id="ref" name="ref" value="ac60ef5" readOnly />
    </div>
  );
}
