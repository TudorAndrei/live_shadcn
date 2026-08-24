import {
  Menubar,
  MenubarContent,
  MenubarItem,
  MenubarMenu,
  MenubarTrigger,
} from "@upstream/shadcn/ui/menubar";

// Ported from `StorybookWeb.Examples.menubar_default/1`.
export default function MenubarDefault() {
  return (
    <Menubar>
      <MenubarMenu>
        <MenubarTrigger>File</MenubarTrigger>
        <MenubarContent>
          <MenubarItem>Fetch upstream</MenubarItem>
          <MenubarItem>Rebuild specs</MenubarItem>
        </MenubarContent>
      </MenubarMenu>
      <MenubarMenu>
        <MenubarTrigger>View</MenubarTrigger>
        <MenubarContent>
          <MenubarItem>Verified only</MenubarItem>
          <MenubarItem>Everything</MenubarItem>
        </MenubarContent>
      </MenubarMenu>
    </Menubar>
  );
}
