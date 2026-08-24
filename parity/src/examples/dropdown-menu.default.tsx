import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@upstream/shadcn/ui/dropdown-menu";

// Ported from `StorybookWeb.Examples.dropdown_menu_default/1`.
export default function DropdownMenuDefault() {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger>Actions</DropdownMenuTrigger>
      <DropdownMenuContent>
        <DropdownMenuItem>Fetch upstream</DropdownMenuItem>
        <DropdownMenuItem>Regenerate</DropdownMenuItem>
        <DropdownMenuItem>Verify</DropdownMenuItem>
        <DropdownMenuItem disabled>Publish</DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
