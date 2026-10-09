# Reviewed reference label rule

The rule `collapsible-settings-radius-labels` applies only to the React
reference for `collapsible/settings` in the generic interaction comparison.
It preserves the port's correct accessible names.

The pinned `collapsible-settings.tsx` uses `id="radius"` for each input.
Its authored labels target `radius-x` and `radius-y`. The reference therefore
has no associated input labels. The port uses unique IDs with correct links.

The rule checks the live reference before each observation. It requires:

- The exact `preview-collapsible-settings` root.
- Two inputs when closed and four when open.
- Text inputs with `id="radius"`, no associated labels, and no ARIA names.
- One label in each Field, in alternating X/Y order.
- The exact label text `Radius X` or `Radius Y` and its `radius-x/y` target.

Only comparison names change. The rule derives them from the authored labels.
It does not change the DOM or fetched source. Port names, field values, focus,
states, and all other comparison fields remain exact. A changed reference
pattern causes an error. A wrong port label still causes a comparison failure.

The browser report includes the rule ID and its reason as an annotation and
a JSON attachment. The Collapsible browser tests check the real closed and
open pages, a wrong port label, and a changed reference input ID.
