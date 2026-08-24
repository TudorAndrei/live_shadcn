import { Kbd, KbdGroup } from "@upstream/shadcn/ui/kbd";

// Ported from `StorybookWeb.Examples.kbd_default/1`.
export default function KbdDefault() {
  return <KbdGroup><Kbd>ctrl</Kbd><Kbd>k</Kbd></KbdGroup>;
}
