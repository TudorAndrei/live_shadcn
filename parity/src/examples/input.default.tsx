import { Input } from "@upstream/shadcn/ui/input";
import { Label } from "@upstream/shadcn/ui/label";

// Ported from `StorybookWeb.Examples.input_default/1`.
export default function InputDefault() {
  return (
    <div className="flex max-w-sm flex-col gap-2">
      <Label htmlFor="email">Email</Label>
      <Input id="email" name="email" type="email" placeholder="you@example.com" />
    </div>
  );
}
