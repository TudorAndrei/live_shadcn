import { Separator } from "@upstream/shadcn/ui/separator";

// Ported from `StorybookWeb.Examples.separator_default/1`.
export default function SeparatorDefault() {
  return (
    <div className="max-w-sm text-sm">
      <p>The spec is committed.</p>
      <Separator className="my-4" />
      <p>The upstream sources are not.</p>
    </div>
  );
}
