import { Label } from "@upstream/shadcn/ui/label";
import { Switch } from "@upstream/shadcn/ui/switch";

// Ported from `StorybookWeb.Examples.switch_default/1`.
export default function SwitchDefault() {
  return (
    <div className="flex items-center gap-2 text-sm">
      <Switch id="watch" name="watch" checked aria-labelledby="watch-label" />
      <Label id="watch-label">Watch upstream weekly</Label>
    </div>
  );
}
