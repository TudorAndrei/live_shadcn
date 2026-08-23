# live_base

Headless behavior for Phoenix LiveView, built to Base UI's data-attribute
contract.

`live_base` owns no styling and renders no markup. It provides the two halves of
component behavior that LiveView does not: the `Phoenix.LiveView.JS` commands
that flip a component's state on the client, and the four hooks for the things
no command can express.

It is the behavior layer under
[live_shadcn](https://github.com/TudorAndrei/live_shadcn), and it has exactly
one dependency: `phoenix_live_view`.

## Installation

```elixir
def deps do
  [{:live_base, "~> 0.1"}]
end
```

Register the hooks with your `LiveSocket`:

```javascript
import { hooks as liveBase } from "live_base";

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: { ...liveBase },
});
```

Hook names are namespaced — `LiveBase.Overlay`, `LiveBase.Floating` — so they
cannot collide with hooks of your own.

Floating placement needs `@floating-ui/dom`, which is a peer dependency so you
control its version:

```bash
npm install @floating-ui/dom --prefix assets
```

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

A hook is used only where a command cannot reach:

| Hook | Because |
|---|---|
| `LiveBase.Disclosure` | `h-(--accordion-panel-height)` asks for a number only the browser can compute |
| `LiveBase.Overlay` | scroll lock, focus containment, and holding an attribute for the length of a transition |
| `LiveBase.Floating` | where a popup lands depends on how much room was left for it |
| `LiveBase.Roving` | `phx-key` filters one key per binding, and the arrow keys are four |

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
