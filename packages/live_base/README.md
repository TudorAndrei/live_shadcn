# live_base

Headless behavior for Phoenix LiveView, built to Base UI's data-attribute
contract.

`live_base` owns no styling and renders no markup. It provides the two halves of
component behavior that LiveView does not: the `Phoenix.LiveView.JS` commands
that flip a component's state on the client, and hooks for the things
no command can express.

It is the behavior layer under
[live_shadcn](https://github.com/TudorAndrei/live_shadcn), and it has two
dependencies: `phoenix_live_view` 1.2 or later, and `phoenix` 1.8 or later.
LiveView compiles colocated hooks only with Phoenix 1.8 or later.

## Installation

```elixir
def deps do
  [{:live_base, "~> 0.1"}]
end
```

After `mix deps.get`, install the JavaScript package and its peers:

```bash
cd assets
npm install --install-links ../deps/live_base \
  @floating-ui/dom@1.8.0 embla-carousel@8.5.2 \
  embla-carousel-autoplay@8.5.2 motion@13.1.1
```

`--install-links` copies the local package into `assets/node_modules`. Its
imports can then resolve the peers in the same directory. Commit the npm lock
file. Repeat this step after upgrading the Hex package.

Add `assets/node_modules` to the esbuild `NODE_PATH` in `config/config.exs`.
Keep the existing dependency and build paths:

```elixir
env: %{
  "NODE_PATH" => [
    Path.expand("../assets/node_modules", __DIR__),
    Path.expand("../deps", __DIR__),
    Mix.Project.build_path()
  ]
}
```

The hooks are LiveView colocated hooks. When Mix compiles `live_base`, LiveView
writes them to `phoenix-colocated/live_base` in `Mix.Project.build_path()`.
The build path in `NODE_PATH` lets esbuild find that directory. The
`assets/node_modules` path lets esbuild find the npm peers that the extracted
hooks import.

Run `mix compile` before esbuild. The Phoenix `assets.build` and
`assets.deploy` aliases do this first.

Import the package for its document-level behavior, and register the hooks with
your existing `LiveSocket`. Preserve other hooks and socket options:

```javascript
import "live_base";
import { hooks as liveBase } from "phoenix-colocated/live_base";

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: { ...liveBase },
});
```

LiveView prefixes each hook name with the module that defines it, such as
`LiveBase.Dialog.Overlay` and `LiveBase.Popover.Floating`. Markup gets the name
from the module, as in `phx-hook={LiveBase.Popover.hook()}`. The names cannot
collide with hooks of your own.

The hooks manifest includes all hooks. Floating uses `@floating-ui/dom`,
Carousel uses Embla, and Message Scroller animation uses Motion. These imports
require all listed peers, even when a page uses only one component.

## The contract

Base UI publishes a stable set of data attributes per component, and shadcn's
class strings key on them:

```text
data-panel-open   data-starting-style   data-ending-style
data-side         data-highlighted      data-checked
```

Every module here sets exactly the attributes Base UI documents, under the names
Base UI documents them with. A primitive that invented a name would silently
break every class string that reads the real one.

## What is a command and what is a hook

The discrete flip is always a command. Opening a panel, choosing an option,
checking a box: each is a `Phoenix.LiveView.JS` chain declared on the server and
run on the client, so it costs no round trip, no socket traffic, and no assign.

```elixir
<button phx-click={LiveBase.Disclosure.toggle(item: "faq-1", root: "faq")}>
```

A hook is used where a command cannot complete the operation. The core hooks
include:

| Hook | Because |
|---|---|
| `LiveBase.Disclosure` | `h-(--accordion-panel-height)` asks for a number only the browser can compute |
| `LiveBase.Overlay` | scroll lock, focus containment, and holding an attribute for the length of a transition |
| `LiveBase.Floating` | where a popup lands depends on how much room was left for it |
| `LiveBase.Roving` | `phx-key` filters one key per binding, and the arrow keys are four |

The complete export also includes specialist hooks for Calendar, Carousel,
Scroller, Slider, Toast, and other controls. Use the exported hook map instead
of maintaining a separate list in the application.

**A hook decides which element, never what happens to it.** Arriving at a tab
shows its panel; arriving at a menu item does not choose it. The same roving
hook does both, told which by one attribute, because what choosing means lives
in the command already on that element.

## The recipes

| Module | Behavior | Used by |
|---|---|---|
| `LiveBase.Disclosure` | a panel that opens and closes | accordion, collapsible |
| `LiveBase.Dialog` | something over the page that takes the focus | dialog, alert dialog, sheet |
| `LiveBase.Popover` | something beside its trigger | popover, tooltip, hover card |
| `LiveBase.Menu` | a list of things to choose from | dropdown menu, context menu |
| `LiveBase.Listbox` | a list that holds a value | select, combobox |
| `LiveBase.Tabs` | panels of which one shows | tabs |
| `LiveBase.FormControl` | a control that holds a value | checkbox, switch, radio, toggle, input |

Each is a set of functions returning `Phoenix.LiveView.JS` commands, plus the
ids it derives. None of them renders anything.

## Client state and server renders

LiveView patches the DOM back to what the server last rendered. A panel the
reader opened lives only in the browser, so the elements that carry that state
opt out of patching for those attribute names, and only those:

```elixir
<div phx-mounted={LiveBase.Disclosure.owned_attributes(:panel)}>
```

Which attributes the client owns is a decision each recipe states in one place,
and it is deliberately short. `data-checked` on a checkbox is *not* client-owned:
it is the form's, and a re-render is exactly when it should be corrected.

## License

Apache-2.0. See `NOTICE` for the upstream projects this work derives from.
