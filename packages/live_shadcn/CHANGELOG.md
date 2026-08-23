# Changelog

## 0.1.0

First release. 42 components, generated from the shadcn registry and verified
against a real browser.

### Components

| Recipe | Components |
|---|---|
| `presentational` | alert, aspect-ratio, attachment, avatar, badge, breadcrumb, bubble, button, button-group, card, empty, item, kbd, marker, message, pagination, progress, separator, skeleton, spinner, table |
| `form-control` | checkbox, input, label, radio-group, switch, textarea, toggle |
| `dialog` | alert-dialog, dialog, sheet |
| `menu` | context-menu, dropdown-menu, navigation-menu |
| `popover` | hover-card, popover, tooltip |
| `disclosure` | accordion, collapsible |
| `listbox` | combobox, select |
| `tabs` | tabs |

Every one of them is verified three ways before it ships: the module still
matches the spec it was generated from, its markup matches a committed snapshot,
and it behaves correctly in Chromium with axe-core clean.

### Tasks

- `mix ui.add` copies components into your application under your own namespace,
  stamped with the registry version and a digest of the file's own body
- `mix ui.sync` reports `current`, `behind` or `edited` per file, shows the
  upstream diff, and updates only the files you have not edited

### Icons

`lucide_icons` by default, configurable with `config :live_shadcn, :icon`, and a
decorative placeholder when neither is present.

### Known limits

- Contrast is upstream's. Some of shadcn's own colours fall below 4.5:1 — the
  `vega` destructive badge is 4.0:1 — and a generated component reproduces them
  faithfully. `mix ui.verify` reports these and does not fail on them.
- Not yet generated: `calendar`, `carousel`, `chart`, `command`, `input-otp` and
  `resizable`, each built on a React library rather than on Base UI; and
  `drawer`, `field`, `input-group`, `menubar`, `native-select`, `sidebar` and
  `slider`, which need reader or recipe work still to come.
- Typeahead in a select — jumping to an option by typing — is not implemented.
