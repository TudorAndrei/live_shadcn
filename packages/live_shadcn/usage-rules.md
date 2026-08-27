# live_shadcn usage rules

Reviewed shadcn/ui ports for Phoenix LiveView. The class strings, `data-slot`
names, and data-attribute contract come from upstream.

## The components are copied into your application, not called from the dependency

`mix ui.add button dialog select` copies the modules into your own namespace and
rewrites them. So the module you import is **yours**, not `LiveShadcn.UI.*`:

```elixir
# in my_app_web.ex
import MyAppWeb.Components.UI.Button
import MyAppWeb.Components.UI.Dialog
```

Never write `import LiveShadcn.UI.Button` in an application. That module exists
in the dependency, but `mix ui.add` renamed the copy, and the two will drift.

## Local edits are allowed

`mix ui.sync` reports upstream drift and **refuses to overwrite a file you have
edited**. An edited component stays at its installed version until you merge an
update or replace it explicitly.

For a style change, prefer the `class` attribute because every component appends
it to the upstream class string. Edit the copied module when the application
needs a different API, markup, or behavior.

## Register the JavaScript hooks, or nothing behaves

Opening a dialog, positioning a popover, measuring a scrollbar and stacking
toasts are client behaviour. Without the hooks the markup renders and does
nothing.

```javascript
import { hooks as liveBase } from "live_base";

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { ...liveBase },
});
```

## The style sheet is upstream's, and it is nested

shadcn publishes every rule inside `.style-<name>`. Put that class on the
document or nothing is styled:

```heex
<html lang="en" class="style-vega">
```

## `id` is required wherever ARIA needs one

Ids are not optional decoration. `aria-controls`, `aria-labelledby` and every
`phx-click` target are derived from the `id` you pass, and an id must be unique
on the page.

```heex
<.accordion id="faq">
```

## A list of things is a slot, and the slot entry carries its own id

React threads an item's identity through context. HEEx cannot, so a component
that repeats takes a slot and derives every id from the entry's own `id`:

```heex
<.accordion id="faq">
  <:item id="what" title="What is this?">A reviewed shadcn/ui port.</:item>
  <:item id="how" title="How do I install it?">mix ui.add</:item>
</.accordion>

<.tabs id="stages" value="spec">
  <:tab value="fetch" label="Fetch">registry/UPSTREAM.json</:tab>
  <:tab value="spec" label="Spec">registry/spec/*.json</:tab>
</.tabs>
```

## A form control takes a `field`, not a name and a value

`Phoenix.HTML.FormField` already carries the name, the value, the errors and
whether the field is required. Pass it whole:

```heex
<.checkbox field={@form[:subscribe]} label="Email me" />
<.input field={@form[:email]} type="email" />
```

Do not pass `name=` and `value=` separately, and do not compute
`data-invalid` yourself — the component reads the field.

## The server owns a toast list

There is no client-side toast manager. Keep the list in an assign or a stream,
draw it, and dismiss with an event. A client that held its own copy would
disagree with the server on the next patch, and the reader would watch a
dismissed message come back.

```heex
<.toaster id="toasts" dismiss="dismiss_toast">
  <:toast :for={t <- @toasts} id={t.id} type={t.type} title={t.title}>
    {t.description}
  </:toast>
</.toaster>
```

```elixir
def handle_event("dismiss_toast", %{"id" => id}, socket) do
  {:noreply, update(socket, :toasts, &Enum.reject(&1, fn t -> t.id == id end))}
end
```

Timing out is the same event on a timer, so it costs one round trip per toast.

## Opening and closing costs no round trip

Disclosure, dialogs, popovers, menus, tabs and the sidebar all flip a data
attribute with a `Phoenix.LiveView.JS` command. Do not add a `phx-click` that
pushes an event just to open something — you would be paying for a round trip
the component already avoided.

## Variants come from upstream, so use the declared values

`variant` and `size` are read off shadcn's own `cva` tables. The accepted values
are declared on the attribute, so a wrong one raises at compile time rather than
rendering unstyled:

```heex
<.button variant="destructive" size="sm">Delete</.button>
```

Check the component's own `attr` declarations for what a given component
accepts, rather than guessing from another library's API.

## Icons are configuration

Components name an icon; they do not depend on an icon library.
`lucide_icons` is the default. Configure the set rather than editing a
component to change an icon.

## Commands

| Command | What it does |
|---|---|
| `mix ui.add <name>` | copy components into your application |
| `mix ui.sync` | report upstream drift; refuses to overwrite edited files |
