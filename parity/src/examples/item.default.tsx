import { Button } from "@upstream/shadcn/ui/button";
import {
  Item,
  ItemActions,
  ItemContent,
  ItemDescription,
  ItemGroup,
  ItemTitle,
} from "@upstream/shadcn/ui/item";

// Ported from `StorybookWeb.Examples.item_default/1`.
export default function ItemDefault() {
  return (
    <ItemGroup className="max-w-md">
      <Item role="listitem">
        <ItemContent>
          <ItemTitle>accordion</ItemTitle>
          <ItemDescription>disclosure · tier 1 · verified</ItemDescription>
        </ItemContent>
        <ItemActions>
          <Button size="sm" variant="ghost">Open</Button>
        </ItemActions>
      </Item>
    </ItemGroup>
  );
}
