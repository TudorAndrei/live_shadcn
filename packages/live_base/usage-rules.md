# live_base usage rules

The headless half of `live_shadcn`: the client hooks and the `Phoenix.LiveView.JS`
commands the generated components are built on. One dependency,
`phoenix_live_view`, and no framework of its own.

Most applications never call this directly — they use `live_shadcn` and register
the hooks. Read this if you are writing a component against the same contract.

## Register the hooks under their own names

```javascript
import { hooks as liveBase } from "live_base";

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { ...liveBase },
});
```

Hook names are namespaced — `LiveBase.Disclosure`, `LiveBase.Floating` — so they
cannot collide with a hook of your own. Do not rename them; the generated markup
writes those exact strings into `phx-hook`.

## A hook decides *which* element, never *what happens to it*

That is the boundary every hook here is held to. What happens is the `JS` command
already on the element. A hook that started changing state would be a second
source of truth for something the server or a `JS` command already owns.

## Reach for a hook only when the browser is the only place the answer exists

The hooks that exist are the measurements a template cannot make:

| Hook | Because |
|---|---|
| `Disclosure` | a panel's height |
| `Overlay` | scroll lock, focus containment, transition timing |
| `Floating` | where a popup lands |
| `Roving` | which element the arrow keys move to |
| `Scroller` | a scrollbar's size and position |
| `Slider` | where a thumb sits over a native range input |
| `Toast` | how tall each toast is and where it sits in the stack |

Anything discrete — open, close, choose, toggle — is a `JS` command and costs no
round trip. If you are writing a hook to toggle an attribute, write
`JS.toggle_attribute/2` instead.

## The server owns application state; the client owns ephemeral UI state

A hook never adds to a list, never removes from one, and never invents data. The
toast hook measures and stacks; the server decides which toasts exist. A client
that held its own copy would disagree with the server on the next patch.

## Data attributes are the contract

Base UI's attribute names are what the class strings read — `data-open`,
`data-closed`, `data-checked`, `data-disabled`, `data-orientation`. An ARIA
state is a **word**, not a presence: write `aria-disabled="true"`, because a
Tailwind `aria-disabled:` variant matches the value.

## Markers the generator writes, which hooks read

| Marker | Meaning |
|---|---|
| `data-lb-measure` | this element's class string interpolates a CSS variable, so measure it |
| `data-lb-style-target` | write the client-owned state attributes here |

Write to the markers rather than to a shape you assumed. An element can be
marked more than once, and a component can mark several.
