import { Checkbox } from "@upstream/shadcn/ui/checkbox";
import { Label } from "@upstream/shadcn/ui/label";

// Ported from `StorybookWeb.Examples.checkbox_default/1`.
export default function CheckboxDefault() {
  return (
    <div className="flex flex-col gap-3 text-sm">
      <div className="flex items-center gap-2">
        <Checkbox id="subscribe" name="subscribe" checked aria-labelledby="subscribe-label" />
        <Label id="subscribe-label">Send me the sync pull requests</Label>
      </div>
      <div className="flex items-center gap-2">
        <Checkbox id="beta" name="beta" aria-labelledby="beta-label" />
        <Label id="beta-label">Try new recipes first</Label>
      </div>
      <div className="flex items-center gap-2">
        <Checkbox id="locked" name="locked" checked disabled aria-labelledby="locked-label" />
        <Label id="locked-label">Verified components stay verified</Label>
      </div>
    </div>
  );
}
