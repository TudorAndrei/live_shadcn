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

Components are not called from this dependency. `mix ui.add` copies their source
into your application, the way the shadcn CLI does, so you own and can edit every
file:

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

That is what a component library owes you when it writes into your `lib/`. A
dependency can be upgraded behind your back; a file you own cannot.

## Behavior

The components' behavior lives in `live_base`. Register its hooks:

```javascript
import { hooks as liveBase } from "live_base";

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: { ...liveBase },
});
```

Opening a panel, choosing an option, checking a box: each runs entirely on the
client through `Phoenix.LiveView.JS`. No round trip, no socket traffic, and no
assign for a menu that is open.

## Styling

The class strings are shadcn's, and they read shadcn's own `cn-` classes, which
are defined in its style sheets. Point Tailwind at the components and import the
sheet for the style you want:

```css
@import "tailwindcss";
@import "shadcn/tailwind.css";

@source "../../deps/live_shadcn/priv/registry";
@source "../../lib/my_app_web/components/ui";
```

Every `cn-` rule upstream publishes is nested inside `.style-<name>`, so which
style you get is a class on the document.

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
