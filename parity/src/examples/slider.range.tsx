import { Slider } from "@upstream/shadcn/ui/slider";

// Ported from `StorybookWeb.Examples.slider_range/1`.
export default function SliderRange() {
  return <Slider defaultValue={[20, 80]} aria-label="Tier range" className="max-w-sm" />;
}
