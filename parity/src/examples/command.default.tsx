import {
  Command,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
  CommandSeparator,
  CommandShortcut,
} from "@upstream/shadcn/ui/command";

// Ported from `StorybookWeb.Examples.command_default/1`.
export default function CommandDefault() {
  return (
    <Command className="max-w-md border">
      <CommandInput aria-label="Search commands" placeholder="Search commands" />
      <CommandList>
        <CommandGroup>
          <CommandItem>New file</CommandItem>
          <CommandItem>Open project</CommandItem>
        </CommandGroup>
        <CommandSeparator />
        <CommandGroup>
          <CommandItem>
            Settings
            <CommandShortcut>⌘,</CommandShortcut>
          </CommandItem>
        </CommandGroup>
      </CommandList>
    </Command>
  );
}
