import type { ComponentProps } from "react";

import { Icon } from "./lucide";

// shadcn writes an icon as a set of names, one per icon library, and its
// documentation site swaps in whichever the reader picked:
//
//     <IconPlaceholder lucide="ChevronDownIcon" tabler="IconChevronDown" … />
//
// The reviewed ports render the lucide one, because that is the set
// `LiveShadcn.Icon` ships. So this renders the lucide one too — a parity page
// that drew a different icon library would report a difference this repository
// chose on purpose.
//
// From `lucide-static` at the version `lucide_icons` vendors, not from
// `lucide-react`. See `./lucide.tsx`: the two packages were different snapshots
// of the icon set, and three icons had been redrawn between them.
type IconPlaceholderProps = ComponentProps<"svg"> & {
  lucide: string;
  tabler?: string;
  hugeicons?: string;
  phosphor?: string;
  remixicon?: string;
};

// `ChevronDownIcon` in shadcn's source is `chevron-down` on disk, which is also
// the name `LiveShadcn.Icon` is given.
function kebab(name: string): string {
  return name
    .replace(/Icon$/, "")
    .replace(/([a-z0-9])([A-Z])/g, "$1-$2")
    .replace(/([A-Z])([A-Z][a-z])/g, "$1-$2")
    .toLowerCase();
}

export function IconPlaceholder({
  lucide: name,
  tabler: _tabler,
  hugeicons: _hugeicons,
  phosphor: _phosphor,
  remixicon: _remixicon,
  ...props
}: IconPlaceholderProps) {
  return <Icon name={kebab(name)} {...props} />;
}
