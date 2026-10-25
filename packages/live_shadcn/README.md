# live_shadcn

Reviewed shadcn/ui ports for Phoenix LiveView, synchronized with the upstream
registry.

Every class string, every `data-slot`, and every data attribute in these
components came from upstream. Maintainers review the HEEx API and behavior;
Oxc keeps the marked class and CVA facts current.

## Installation

```elixir
def deps do
  [
    {:live_shadcn, "~> 0.1"},
    {:live_base, "~> 0.1"},
    # The default icon set. Swap it for your own if you prefer.
    {:lucide_icons, "~> 2.3"}
  ]
end
```

## Adding components

`mix ui.add` copies each requested component into your application. Use that
copy as the application's entry point. You can edit the copied file:

```bash
mix ui.add button card accordion
#=> lib/my_app_web/components/ui/button.ex
#=> lib/my_app_web/components/ui/card.ex
#=> lib/my_app_web/components/ui/accordion.ex

mix ui.add --list          # what the registry holds
mix ui.add button --into lib/ui
```

The module is rewritten to match where it landed: `LiveShadcn.UI.Button` becomes
`MyAppWeb.Components.UI.Button`.

Alias the copied modules in your LiveView:

```elixir
alias MyAppWeb.Components.UI.Button
```

```heex
<Button.button phx-click="save">Save</Button.button>
```

The alias avoids a conflict with the default Phoenix `CoreComponents.button/1`.

Only the requested modules are copied. References inside a component retain
their package namespace. For example, a copied Carousel still uses the package
Button. Editing the application's Button does not change that nested Button.
Keep the package dependency. To own a nested component too, copy it and change
the parent reference to the application module. `mix ui.sync` will preserve
that edited parent. Package upgrades can change nested package components.

## Keeping up

Every copy is stamped with the registry version it came from and a digest of its
own body:

```elixir
# live_shadcn: button @ 0.1.0 (037da9a280f9)
# Copied from the live_shadcn registry. Local edits are allowed.
```

`mix ui.sync` compares each installed file against the registry and gives one of
three answers:

```bash
mix ui.sync
#   current  button  lib/my_app_web/components/ui/button.ex
#   behind   card    lib/my_app_web/components/ui/card.ex
#   edited   dialog  lib/my_app_web/components/ui/dialog.ex

mix ui.sync --diff card    # what upstream changed
mix ui.sync --apply        # update the ones you have not edited
```

**An edited file is never overwritten.** Not by `--apply`, not silently, not at
all: the whole point of copying source into your repository is that it becomes
yours. `mix ui.add card --force` is the explicit way to discard your changes.

This protection applies to the copied file. Shared behavior and nested package
components still follow the installed dependency version.

## Behavior

The components' behavior lives in `live_base`. Follow its
[JavaScript installation instructions](../live_base/README.md#installation)
and register the complete hook map. Preserve existing socket options and hooks:

```javascript
import "live_base";
import { hooks as liveBase } from "phoenix-colocated/live_base";

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: { ...liveBase },
});
```

Opening a panel, choosing an option, checking a box: each runs entirely on the
client through `Phoenix.LiveView.JS`. No round trip, no socket traffic, and no
assign for a menu that is open.

## Styling

The ports require Tailwind 4 and the pinned shadcn theme and style sheets.
The following setup uses the Vega style tested in Storybook. From the
application's `assets` directory, install the CSS dependencies:

```bash
npm install tailwindcss@4.3.0 shadcn@4.19.0 tw-animate-css@1.4.0
```

Copy these files from the pinned shadcn commit. Run this command from `assets`:

```bash
shadcn_source=https://raw.githubusercontent.com/shadcn-ui/ui/503a3a57aec9a3817e37f90aa0817b1fabd284d0/apps/v4
mkdir -p css/upstream/theme css/upstream/styles
curl -fL "$shadcn_source/app/globals.css" -o css/upstream/theme/globals.css
curl -fL "$shadcn_source/app/legacy-themes.css" -o css/upstream/theme/legacy-themes.css
curl -fL "$shadcn_source/registry/styles/style-vega.css" -o css/upstream/styles/vega.css
```

Commit these files and the npm lock file. Keep them at the package's upstream
pin. Replace the generated Tailwind and theme imports in `assets/css/app.css`
with these imports. Keep any application-specific CSS and colocated CSS import:

```css
@import "./upstream/theme/globals.css";
@import "./upstream/styles/vega.css";

@source "../js";
@source "../../lib/my_app_web";
@source "../../deps/live_shadcn/priv/registry";

:root {
  --font-sans: ui-sans-serif, system-ui, sans-serif;
  --font-heading: var(--font-sans);
  --font-mono: ui-monospace, monospace;
}
```

Replace `my_app_web` with the application directory. Put the style class on
the root layout:

```heex
<html lang="en" class="style-vega">
```

Run `mix assets.build`. The globals file imports Tailwind, animation classes,
shadcn variants, and legacy theme tokens. The Vega file supplies the `cn-`
classes used by these ports. Importing only `shadcn/tailwind.css` is insufficient.

## Icons

shadcn names an icon per set — lucide, tabler, phosphor, hugeicons, remixicon —
and the spec records all five. Which one draws it is yours:

```elixir
config :live_shadcn, :icon, {MyAppWeb.Icons, :render}
```

With `lucide_icons` installed and nothing configured, icons draw themselves.
With neither, they render as decorative empty spans that still carry their class
string, so layout and state variants keep working — only the glyph is missing.

## License

Apache-2.0. See `NOTICE` for the upstream projects this work derives from.
