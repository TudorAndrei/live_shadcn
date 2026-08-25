import * as lucide from "lucide-react";
import type { ComponentProps } from "react";

// One icon set, at the release both sides ship.
//
// `lucide-react` is pinned to **1.32.0**, which is the release `lucide_icons`
// vendors as `lucide-static` 1.32.0 — the two packages share a version number
// and a publish date, so pinning one pins the glyphs.
//
// It was `^0.545.0`, and the pixel check found what that costs. Three of the
// nine icons in the sidebar example — `file-json`, `book-open`, `git-branch` —
// had been redrawn between the two releases, which reported as 68 differing
// pixels on `sidebar`. That is not a finding about the component; it is the
// comparison measuring the icon library. Left alone it would return on every
// lucide release, on every component using an icon that moved, and the
// temptation each time would be to grant a budget — which is how a check stops
// meaning anything.
//
// The icon set is configuration in this design rather than part of any
// component, so both sides now configure it identically.
//
// (An earlier version of this shim read `lucide-static`'s SVG files through
// `import.meta.glob`. It was correct and far too slow: eagerly transforming
// fifteen hundred modules took the pixel run from 1.2 to 5.6 minutes and timed
// three tests out. Pinning the package the references already import does the
// same job for nothing.)

type IconProps = ComponentProps<"svg"> & { name: string };

/** `chevron-down` — the name `LiveShadcn.Icon` is given — as a component. */
function componentFor(name: string) {
  const pascal = name
    .split("-")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join("");

  const icon = (lucide as unknown as Record<string, typeof lucide.Circle>)[pascal];

  if (!icon) {
    throw new Error(`lucide-react has no ${pascal} (from "${name}")`);
  }

  return icon;
}

/** One lucide icon by its kebab-case name, hidden from assistive technology. */
export function Icon({ name, ...props }: IconProps) {
  const Component = componentFor(name);
  return <Component aria-hidden="true" {...props} />;
}
