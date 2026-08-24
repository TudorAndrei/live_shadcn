import { Badge } from "@upstream/shadcn/ui/badge";

// Ported from `StorybookWeb.Examples.badge_variants/1`.
export default function BadgeVariants() {
  return (
    <div className="flex flex-wrap gap-2">
      {["default", "secondary", "outline", "destructive"].map((variant) => (
        <Badge key={variant} variant={variant as "default"}>
          {variant}
        </Badge>
      ))}
    </div>
  );
}
