import { Label } from "@upstream/shadcn/ui/label";
import { RadioGroup, RadioGroupItem } from "@upstream/shadcn/ui/radio-group";

const styles = ["vega", "nova", "maia"];

// Ported from `StorybookWeb.Examples.radio_group_default/1`.
export default function RadioGroupDefault() {
  return (
    <RadioGroup
      role="radiogroup"
      aria-labelledby="style-label"
      className="max-w-sm"
      defaultValue="vega"
    >
      <Label id="style-label">Style</Label>
      {styles.map((style) => (
        <div key={style} className="flex items-center gap-2 text-sm">
          <RadioGroupItem
            id={`style-${style}`}
            name="style"
            value={style}
            aria-labelledby={`style-${style}-label`}
          />
          <Label id={`style-${style}-label`}>{style}</Label>
        </div>
      ))}
    </RadioGroup>
  );
}
