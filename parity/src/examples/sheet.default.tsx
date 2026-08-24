import { Checkbox } from "@upstream/shadcn/ui/checkbox";
import { Label } from "@upstream/shadcn/ui/label";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@upstream/shadcn/ui/sheet";

// Ported from `StorybookWeb.Examples.sheet_default/1`.
export default function SheetDefault() {
  return (
    <Sheet>
      <SheetTrigger>Filters</SheetTrigger>
      <SheetContent>
        <SheetHeader>
          <SheetTitle>Narrow the inventory</SheetTitle>
          <SheetDescription>By tier, by recipe, or by what the pipeline has reached.</SheetDescription>
        </SheetHeader>
        <div className="flex flex-col gap-3 text-sm">
          <div className="flex items-center gap-2">
            <Checkbox id="tier-1" defaultChecked aria-labelledby="tier-1-label" />
            <Label id="tier-1-label">Tier 1 only</Label>
          </div>
          <div className="flex items-center gap-2">
            <Checkbox id="verified" aria-labelledby="verified-label" />
            <Label id="verified-label">Verified only</Label>
          </div>
        </div>
      </SheetContent>
    </Sheet>
  );
}
