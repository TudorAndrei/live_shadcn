import { Marker, MarkerContent } from "@upstream/shadcn/ui/marker";

// Ported from `StorybookWeb.Examples.marker_default/1`.
export default function MarkerDefault() {
  return <Marker className="max-w-md"><MarkerContent>The spec is committed; the sources are not.</MarkerContent></Marker>;
}
