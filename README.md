# live_shadcn

shadcn/ui and AI Elements for Phoenix LiveView — generated from the upstream
registries, not hand-copied.

> Status: bootstrapping. The fetch stage works; the spec and generator stages
> are next. Nothing is published to hex yet.

## Why another component library

Every existing Phoenix port copies the styles by hand, then falls behind.
shadcn changes weekly, and a hand-copied port has no way to see what moved.

This one is a pipeline, not a copy:

| Upstream source | What it gives |
|---|---|
| `ui.shadcn.com/r/index.json` | the component list, with per-base doc links |
| `shadcn-ui/ui` → `registry/bases/base/ui/*.tsx` | `data-slot` anatomy and the class strings |
| `base-ui.com/react/components/*.md` | parts, props, data attributes, CSS variables |
| `vercel/ai-elements` → `packages/elements/src/*.tsx` | the AI component set |

Every one of those is machine-readable. So keeping up with shadcn is a
scheduled job that opens a pull request, not a person remembering to look.

## The key idea

shadcn is **class strings keyed on data attributes**. Base UI is **the behavior
that sets those attributes**.

```
data-panel-open   data-starting-style   data-ending-style
data-side         data-highlighted      data-disabled
```

If the HEEx emits the same attributes, the shadcn class strings work unchanged.
Port the behavior once, and the styling follows upstream for free.

## Packages

| Package | Install as | Contains |
|---|---|---|
| `live_base` | dependency | headless behavior: focus, dismiss, roving focus, typeahead, floating position |
| `live_shadcn` | `mix ui.add` copy-in | the components, written into your own repo |
| `live_ai_elements` | dependency | streaming message parts, reasoning, tool calls |

`live_shadcn` copies source into your project, the way shadcn does, so you own
and can edit every component. `mix ui.sync` then diffs your copy against the
registry and shows what upstream changed — your edits are never overwritten
silently.

## LiveView-native behavior

Behavior is declared on the server with `Phoenix.LiveView.JS` and runs on the
client. No round trip, no socket traffic, no assigns for opening a menu.

| Base UI needs | LiveView gives |
|---|---|
| set `data-panel-open` | `JS.set_attribute` / `JS.toggle_attribute` |
| enter and exit animation | `JS.transition` |
| focus in, focus restore | `JS.focus_first`, `JS.push_focus`, `JS.pop_focus` |
| close on outside click | `phx-click-away` |
| close on Escape | `phx-window-keydown` |

A JavaScript hook is used only for the four things a JS command cannot express:
floating position, arrow-key roving focus, typeahead, and scroll lock.

## The pipeline

```
mix ui.fetch  ->  mix ui.spec  ->  mix ui.gen  ->  mix ui.verify
   upstream        registry/spec     HEEx +          snapshots,
   sources         (our IR)          hooks           Playwright, axe
```

`registry/upstream/` is gitignored. `registry/UPSTREAM.json` records a SHA-256
per upstream file, so drift is visible without redistributing anyone's source.

63 shadcn components collapse onto about eight behavior recipes — `disclosure`,
`dialog`, `popover`, `listbox`, `menu`, `tabs`, `form-control`, and
`presentational`. Only the recipes are written by hand. Everything else is data.

## Layout

```
packages/live_base/          headless primitives
packages/live_shadcn/        components + mix ui.add / mix ui.sync
packages/live_ai_elements/   AI parts model, reducer, components
tools/                       the codegen pipeline (never published)
registry/UPSTREAM.json       pinned refs and digests
registry/spec/               generated component IR
storybook/                   demo application
```

## Status

| | |
|---|---|
| [ROADMAP.md](ROADMAP.md) | milestones and their exit criteria |
| [docs/INVENTORY.md](docs/INVENTORY.md) | 112 components, status derived from disk |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | layers, contract, pipeline stages |

Eight core recipes cover 102 of the 112 components.

## Development

```bash
cd tools && mix deps.get
mix ui.fetch --only accordion     # pin and download one component
mix ui.status                     # regenerate docs/INVENTORY.md
```

## License

Apache-2.0. See `NOTICE` for the upstream projects this work derives from.
