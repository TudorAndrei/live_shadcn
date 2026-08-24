import { Label } from "@upstream/shadcn/ui/label";
import { Textarea } from "@upstream/shadcn/ui/textarea";

// Ported from `StorybookWeb.Examples.textarea_default/1`.
export default function TextareaDefault() {
  return (
    <div className="flex max-w-sm flex-col gap-2">
      <Label htmlFor="notes">Notes</Label>
      <Textarea id="notes" name="notes" rows={3} placeholder="What changed upstream?" />
    </div>
  );
}
