import {
  ContextMenu,
  ContextMenuContent,
  ContextMenuItem,
  ContextMenuTrigger,
} from "@upstream/shadcn/ui/context-menu";

// Ported from `StorybookWeb.Examples.context_menu_default/1`.
export default function ContextMenuDefault() {
  return (
    <ContextMenu>
      <ContextMenuTrigger>accordion.json</ContextMenuTrigger>
      <ContextMenuContent>
        <ContextMenuItem>Regenerate</ContextMenuItem>
        <ContextMenuItem>Verify</ContextMenuItem>
      </ContextMenuContent>
    </ContextMenu>
  );
}
