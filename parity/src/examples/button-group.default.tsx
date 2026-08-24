import { Button } from "@upstream/shadcn/ui/button";
import { ButtonGroup, ButtonGroupSeparator } from "@upstream/shadcn/ui/button-group";

// Ported from `StorybookWeb.Examples.button_group_default/1`.
export default function ButtonGroupDefault() {
  return (
    <ButtonGroup>
      <Button variant="outline">Fetch</Button>
      <ButtonGroupSeparator />
      <Button variant="outline">Generate</Button>
      <ButtonGroupSeparator />
      <Button variant="outline">Verify</Button>
    </ButtonGroup>
  );
}
