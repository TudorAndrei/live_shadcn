import {
  InputGroup,
  InputGroupAddon,
  InputGroupInput,
  InputGroupText,
} from "@upstream/shadcn/ui/input-group";

// Ported from `StorybookWeb.Examples.input_group_default/1`.
export default function InputGroupDefault() {
  return (
    <InputGroup className="max-w-sm">
      <InputGroupAddon align="inline-start">
        <InputGroupText>https://</InputGroupText>
      </InputGroupAddon>
      <InputGroupInput id="site" name="site" value="hex.pm" aria-label="Site" />
      <InputGroupAddon align="inline-end">
        <InputGroupText>/packages</InputGroupText>
      </InputGroupAddon>
    </InputGroup>
  );
}
