import { Button } from "@upstream/shadcn/ui/button";

// Ported from `StorybookWeb.Examples.button_sizes/1`.
export default function ButtonSizes() {
  return (
    <div className="flex flex-wrap items-center gap-2">
      {(["xs", "sm", "default", "lg"] as const).map((size) => <Button key={size} size={size}>{size}</Button>)}
    </div>
  );
}
