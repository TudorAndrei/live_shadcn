# Architecture

## Three layers

```text
live_ai_elements   parts model, stream reducer, AI components
        |
   live_shadcn     63 components, copy-in through mix ui.add
        |
    live_base      headless behavior, Base UI data-attribute contract
        |
 phoenix_live_view
```

`live_base` has exactly one dependency: `phoenix_live_view`. No AI framework,
no Ash, no Ecto. This is deliberate. A component library that drags an agent
framework behind it cannot be adopted by people using a different one.

## The data-attribute contract

Base UI publishes a stable set of data attributes per component. shadcn's class
strings key on them. `live_base` emits them from HEEx and from its hooks.

Nothing in `live_shadcn` may invent an attribute name. If a class string reads
`data-panel-open`, the primitive sets `data-panel-open`. This rule is what lets
class strings be copied verbatim and stay correct after an upstream change.

## Behavior placement

Server owns application state. Client owns ephemeral UI state. The client
behavior is declared on the server with `Phoenix.LiveView.JS`.

Use a hook only for these four:

1. floating position (`@floating-ui/dom`)
2. arrow-key roving focus
3. typeahead (select, combobox, command)
4. scroll lock

Everything else is a `JS` command, `phx-click-away`, or `phx-window-keydown`.

## Recipes

63 components map onto about eight behavior recipes:

| Recipe | Components |
|---|---|
| `disclosure` | accordion, collapsible, sidebar |
| `dialog` | dialog, alert-dialog, sheet, drawer |
| `popover` | popover, hover-card, tooltip |
| `listbox` | select, combobox, command, native-select |
| `menu` | dropdown-menu, context-menu, menubar, navigation-menu |
| `tabs` | tabs, toggle-group |
| `form-control` | input, textarea, checkbox, radio-group, switch, slider, field |
| `presentational` | badge, card, alert, separator, skeleton, table, and the rest |

Recipes are hand-written and reviewed once. A component's spec names its recipe,
and the generator does the rest.

## Pipeline stages

### `mix ui.fetch`

Resolves each upstream repository to a commit SHA, downloads sources into
`registry/upstream/` (gitignored), and writes `registry/UPSTREAM.json` with a
SHA-256 per file.

Tracking digests rather than the sources keeps upstream code out of this
repository while still making drift visible as a diff.

### `mix ui.spec`

Parses the shadcn `.tsx` and the Base UI `.md` into `registry/spec/<name>.json`:

```jsonc
{
  "name": "accordion",
  "recipe": "disclosure",
  "parts": [
    {
      "slot": "accordion-trigger",   // from data-slot
      "element": "button",
      "classes": "cn-accordion-trigger group/accordion-trigger relative flex …",
      "aria": {"expanded": "state.open"},
      "data": ["data-panel-open", "data-disabled"]
    }
  ],
  "css_vars": ["--accordion-panel-height"]
}
```

The spec is the only thing the generator reads. It is committed, so a change in
generated output always traces back to a change in the spec.

### `mix ui.gen`

Spec to HEEx module plus hook wiring, from a deterministic template. No model
involved. Rerunning on an unchanged spec must produce identical bytes.

### `mix ui.verify`

Golden snapshots of rendered markup, Playwright behavior tests transcribed from
the Base UI documentation examples, and axe-core accessibility checks in the
storybook.

## Where a model is allowed

Only when a new recipe is needed, which happens once per behavior pattern. A
person reviews it and it is then frozen. The daily sync loop is pure parsing
and templating.

## Sync

A scheduled workflow runs fetch, spec, gen, and verify, then opens a pull
request:

```text
sync shadcn @ ac60ef5 — 4 class strings changed, 1 new component, 0 behavior changes
```

In a user's application, `mix ui.sync` compares the installed component version
against the registry, shows the upstream diff, and skips any file the user has
edited.
