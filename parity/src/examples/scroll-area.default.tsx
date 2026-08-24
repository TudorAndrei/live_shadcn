import { ScrollArea } from "@upstream/shadcn/ui/scroll-area";

// Ported from `StorybookWeb.Examples.scroll_area_default/1`.
export default function ScrollAreaDefault() {
  return (
    <ScrollArea className="h-40 w-full max-w-sm rounded-md border p-4">
      {Array.from({ length: 12 }, (_, index) => (
        <p className="pb-2 text-sm" key={index}>
          Pass {index + 1}: the reader settles when no file moves.
        </p>
      ))}
    </ScrollArea>
  );
}
