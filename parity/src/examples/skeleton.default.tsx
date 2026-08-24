import { Skeleton } from "@upstream/shadcn/ui/skeleton";

// Ported from `StorybookWeb.Examples.skeleton_default/1`.
export default function SkeletonDefault() {
  return (
    <div className="flex max-w-sm flex-col gap-2">
      <Skeleton className="h-4 w-3/4" />
      <Skeleton className="h-4 w-1/2" />
      <Skeleton className="h-4 w-2/3" />
    </div>
  );
}
