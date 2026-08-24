import { Slider } from "@upstream/shadcn/ui/slider";

// Ported from `StorybookWeb.Examples.slider_default/1`.
export default function SliderDefault() {
  return <Slider defaultValue={[3]} min={1} max={5} aria-label="Passes" className="max-w-sm" />;
}
