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

### The contract has two sources, not one

The `.tsx` is half of it. The other half is the style sheet, where every `cn-`
class is defined:

```css
.cn-accordion-content {
  @apply data-open:animate-accordion-down data-closed:animate-accordion-up;
}
```

`data-closed` appears in no `.tsx` and on no Base UI page. A component generated
from the component source alone would never set it, and the collapse animation
would silently not run. So `mix ui.spec` reads the sheets too, and an attribute
a sheet reads is as binding as one Base UI documents.

## Behavior placement

Server owns application state. Client owns ephemeral UI state. The client
behavior is declared on the server with `Phoenix.LiveView.JS`.

Four hooks exist, and each is there because no `JS` command reaches what it
does:

| Hook | Used by | Because |
|---|---|---|
| `Disclosure` | accordion, collapsible | a height only the browser can compute, and an attribute held for one frame |
| `Overlay` | dialog, alert dialog, sheet | scroll lock, focus containment, exit timing |
| `Floating` | popover, tooltip, menu, select | where a popup lands depends on the room left for it |
| `Roving` | tabs, menu, select | `phx-key` filters one key per binding, and the arrow keys are four |

Everything else is a `JS` command, `phx-click-away`, or `phx-window-keydown`.

### The line a hook is held to

**A hook decides which element, never what happens to it.** Arriving at a tab
shows its panel; arriving at a menu item does not choose it. The same roving
hook does both, told which by one attribute, because what choosing means is the
`JS` command already on that element.

That line is why the split survives: the discrete flip — `aria-expanded`,
`data-open`, `data-selected` — is a `JS` command in every recipe, so no click
reaches the server unless the caller asked for one. The hooks own measurements,
timing, and which element a key means.

### What a hook is told

A hook reads its configuration from the markup the generator emitted, under a
`data-lb-` prefix that no shadcn class string reads:

```text
data-lb-anchor  data-lb-side  data-lb-align  data-lb-offset   floating position
data-lb-roving  data-lb-orientation  data-lb-loop            which items to walk
data-lb-activate  data-lb-highlight                          what arriving does
data-lb-measure  data-lb-style-target  data-lb-height-var     what to measure
data-lb-modal  data-lb-autofocus  data-lb-popup  data-lb-backdrop
```

Every one of them follows from a fact the spec already records. None is a
decision a person makes per component.

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

A recipe says three things and nothing else:

1. which Base UI part plays which role
2. what expression computes each documented attribute
3. how the parts nest into one component

`presentational` is the degenerate case — no roles, no attributes to compute,
one function per exported part. `disclosure` is the other end: five roles, two
shapes (a list of items, or one panel), and a client hook.

## Variants

shadcn writes a component's variants as a `class-variance-authority` table:

```ts
const buttonVariants = cva("cn-button inline-flex …", {
  variants: { variant: { default: "cn-button-variant-default", … } },
  defaultVariants: { variant: "default" },
})
```

Four decisions live there — which variants exist, what each is called, which is
the default, and what class string each carries — and a HEEx component needs all
four. The spec records the table, so `attr :variant, :string, values: …` is
generated from it rather than retyped, and a variant nobody defined is a compile
error instead of a class that does not exist.

## Pipeline stages

### `mix ui.fetch`

Resolves each upstream repository to a commit SHA, downloads sources into
`registry/upstream/` (gitignored), and writes `registry/UPSTREAM.json` with a
SHA-256 per file. Four kinds of source:

| Path | What it holds |
|---|---|
| `shadcn/ui/<name>.tsx` | the anatomy and the class strings |
| `base_ui/<name>.md` | the parts, the data attributes, the CSS variables |
| `shadcn/styles/<style>.css` | the `cn-` rules, one sheet per shadcn style |
| `shadcn/theme/globals.css` | the design tokens every rule resolves against |

Tracking digests rather than the sources keeps upstream code out of this
repository while still making drift visible as a diff.

### `mix ui.spec`

Reads all four into `registry/spec/<source>/<name>.json`:

```jsonc
{
  "name": "accordion",
  "recipe": "disclosure",
  "primitives": {
    "accordion.Trigger": {                          // module and part
      "element": "button",                          // "Renders a <button> element."
      "data": ["data-panel-open", "data-disabled"], // the documented contract
      "props": [ /* name, type, default, doc */ ]
    }
  },
  "parts": [
    {
      "name": "accordion_trigger",
      "primitive": "Trigger",
      "tree": {
        "type": "primitive", "module": "accordion", "part": "Header", "tag": "h3",
        "children": [
          {
            "type": "primitive", "module": "accordion", "part": "Trigger",
            "tag": "button",
            "slot": "accordion-trigger",            // from data-slot
            "class": "cn-accordion-trigger group/accordion-trigger …",
            "merges_class": true,                 // the caller's class goes here
            "reads": {"self": ["aria-disabled"], "group": []},
            "vars": []
          }
        ]
      }
    }
  ],
  "styles": {"vega": {"cn-accordion-content": "data-open:animate-… …"}},
  "css_vars": ["--accordion-panel-height", "--accordion-panel-width"]
}
```

`reads` and `vars` are the two facts that make generation possible without a
person placing attributes. A class string containing `data-ending-style:h-0`
declares that this element must carry `data-ending-style` while it animates out;
one containing `h-(--accordion-panel-height)` declares that something has to
measure it.

The spec is the only thing the generator reads. It is committed, so a change in
generated output always traces back to a change in the spec.

### `mix ui.gen`

Spec to HEEx module plus hook wiring, from a deterministic template. No model
involved. Rerunning on an unchanged spec must produce identical bytes, which is
what makes `mix ui.gen --check` a usable gate against a hand edit.

The recipe folds a component's parts into one function. shadcn exports four
components for the accordion and threads the item's identity between them with
React context; HEEx has no implicit context, so four functions would mean the
caller repeating an id on each of them. One `<.accordion>` with an `:item` slot
names each item once, and `LiveBase.Disclosure` derives every id the ARIA
contract needs from it.

### `mix ui.verify`

Three checks, written to `registry/VERIFY.json` so `mix ui.status` can mark a
component verified without anybody typing a status:

| Check | Question |
|---|---|
| generated | does the module on disk still match its spec? |
| snapshot | has the markup a reader gets changed? |
| browser | does it behave like Base UI, and is it clean under axe-core? |

The snapshots live in `registry/snapshot/`, pretty-printed, so an upstream class
change arrives in a pull request as a diff of what a reader sees. The browser
check starts the demo application and drives it with Playwright, because opening
a panel is a client behavior: no amount of server-side rendering can tell you
whether it works.

A component with behavior has a suite of its own. One without still has an
accessibility contract, and the generic axe-core run over its preview pages is
what checks it.

### Contrast is upstream's

axe-core reports colour contrast, and some of shadcn's own colours fall below
4.5:1 — the `vega` destructive badge is 4.0:1, its `kbd` is 4.34:1. A generated
component reproduces upstream's colours faithfully, which is the point, so it
cannot be held to a ratio its own style sheet does not meet. Contrast findings
are reported and do not fail the run. Everything else axe reports is markup,
which is ours, and does.

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
