import { Button } from "@upstream/shadcn/ui/button";

// Ported from `StorybookWeb.Examples.button_variants/1`.
export default function ButtonVariants() {
  return (
    <div className="flex flex-wrap items-center gap-2">
      {(["default", "secondary", "outline", "ghost", "destructive", "link"] as const).map((variant) => (
        <Button key={variant} variant={variant}>{variant}</Button>
      ))}
    </div>
  );
}
