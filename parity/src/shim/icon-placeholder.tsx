import * as lucide from "lucide-react";
import type { ComponentProps } from "react";

// shadcn writes an icon as a set of names, one per icon library, and its
// documentation site swaps in whichever the reader picked:
//
//     <IconPlaceholder lucide="ChevronDownIcon" tabler="IconChevronDown" … />
//
// The generated components render the lucide one, because that is the set
// `LiveShadcn.Icon` ships. So this renders the lucide one too — a parity page
// that drew a different icon library would report a difference this repository
// chose on purpose.
type IconPlaceholderProps = ComponentProps<"svg"> & {
  lucide: string;
  tabler?: string;
  hugeicons?: string;
  phosphor?: string;
  remixicon?: string;
};

export function IconPlaceholder({
  lucide: name,
  tabler: _tabler,
  hugeicons: _hugeicons,
  phosphor: _phosphor,
  remixicon: _remixicon,
  ...props
}: IconPlaceholderProps) {
  const Icon = (lucide as unknown as Record<string, typeof lucide.Circle>)[name];

  if (!Icon) {
    throw new Error(`lucide-react has no ${name}`);
  }

  return <Icon aria-hidden="true" {...props} />;
}
