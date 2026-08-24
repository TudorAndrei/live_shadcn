import { AspectRatio } from "@upstream/shadcn/ui/aspect-ratio";

// Ported from `StorybookWeb.Examples.aspect_ratio_default/1`.
export default function AspectRatioDefault() {
  return (
    <AspectRatio ratio={1.7778} className="bg-muted max-w-sm rounded-md">
      <div className="text-muted-foreground flex h-full items-center justify-center text-sm">
        16 / 9
      </div>
    </AspectRatio>
  );
}
