import {
  Drawer,
  DrawerContent,
  DrawerDescription,
  DrawerHeader,
  DrawerTitle,
  DrawerTrigger,
} from "@upstream/shadcn/ui/drawer";

// Ported from `StorybookWeb.Examples.drawer_default/1`.
export default function DrawerDefault() {
  return (
    <Drawer>
      <DrawerTrigger>Stages</DrawerTrigger>
      <DrawerContent>
        <DrawerHeader>
          <DrawerTitle>What the pipeline does</DrawerTitle>
          <DrawerDescription>Four stages, each with an artefact of its own.</DrawerDescription>
        </DrawerHeader>
        <p className="text-sm">Fetch, spec, generate, verify.</p>
      </DrawerContent>
    </Drawer>
  );
}
