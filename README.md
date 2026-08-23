# live_shadcn

shadcn/ui and AI Elements for Phoenix LiveView — generated from the upstream
registries, not hand-copied.

> Status: all eight recipes are written, and every shadcn tier-1 component is
> generated and verified — markup snapshot, behaviour in a real browser, and
> axe-core clean — with no line edited by hand. `mix ui.add` and `mix ui.sync`
> work against a real application. Nothing is published to hex yet.
>
> The AI Elements reducer is done and its two adapters agree on five recorded
> streams. The reader now reads both registries, and the first AI Elements
> component is generated and verified. [docs/INVENTORY.md](docs/INVENTORY.md)
> has the count, derived from disk rather than typed here.

## Why another component library

Every existing Phoenix port copies the styles by hand, then falls behind.
shadcn changes weekly, and a hand-copied port has no way to see what moved.

This one is a pipeline, not a copy:

| Upstream source | What it gives |
|---|---|
| `ui.shadcn.com/r/index.json` | the component list, with per-base doc links |
| `shadcn-ui/ui` → `registry/bases/base/ui/*.tsx` | `data-slot` anatomy and the class strings |
| `base-ui.com/react/components/*.md` | parts, props, data attributes, CSS variables |
| `shadcn-ui/ui` → `registry/styles/style-*.css` | the `cn-` rules, one sheet per style |
| `shadcn-ui/ui` → `app/globals.css` | the design tokens the rules resolve against |
| `vercel/ai-elements` → `packages/elements/src/*.tsx` | the AI component set |

Every one of those is machine-readable. So keeping up with shadcn is a
scheduled job that opens a pull request, not a person remembering to look.

## The key idea

shadcn is **class strings keyed on data attributes**. Base UI is **the behavior
that sets those attributes**.

```text
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
and can edit every component:

```bash
mix ui.add button card accordion   # into lib/my_app_web/components/ui/
mix ui.sync                        # current, behind, or edited — per file
mix ui.sync --apply                # update the ones you have not edited
```

Every copy is stamped with the registry version it came from and a digest of its
own body. An edited file no longer matches that digest, and **an edited file is
never overwritten** — not by `--apply`, not silently. That is what a component
library owes you when it writes into your repository: a dependency can be
upgraded behind your back; a file in your `lib/` cannot.

## LiveView-native behavior

Behavior is declared on the server with `Phoenix.LiveView.JS` and runs on the
client. No round trip, no socket traffic, no assigns for opening a menu.

| Base UI needs | LiveView gives |
|---|---|
| set `data-panel-open` | `JS.set_attribute` / `JS.toggle_attribute` |
| keep client state across a render | `JS.ignore_attributes` |
| focus in, focus restore | `JS.focus_first`, `JS.push_focus`, `JS.pop_focus` |
| close on outside click | `phx-click-away` |
| close on Escape | `phx-window-keydown` |

Four hooks in the whole library, and each one is there because no `JS` command
reaches it:

| Hook | Because |
|---|---|
| `Disclosure` | `h-(--accordion-panel-height)` asks for a number only the browser can compute |
| `Overlay` | scroll lock, focus containment, and holding an attribute for the length of a transition |
| `Floating` | where a popup lands depends on how much room was left |
| `Roving` | `phx-key` filters one key per binding, and the arrow keys are four |

The line they are held to: a hook decides *which* element, never *what happens
to it*. What happens is the `JS` command already on that element.

## The pipeline

```text
mix ui.fetch  ->  mix ui.spec  ->  mix ui.gen  ->  mix ui.verify
   upstream        registry/spec     HEEx +          snapshots,
   sources         (our IR)          hooks           Playwright, axe
```

`registry/upstream/` is gitignored. `registry/UPSTREAM.json` records a SHA-256
per upstream file, so drift is visible without redistributing anyone's source.

63 shadcn components collapse onto eight behavior recipes — `disclosure`,
`dialog`, `popover`, `listbox`, `menu`, `tabs`, `form-control`, and
`presentational`. All eight are written. Only the recipes are written by hand;
everything else is data.

## Layout

```text
packages/live_base/          headless primitives and the client hooks
packages/live_shadcn/        priv/registry holds the generated components
packages/live_ai_elements/   AI parts model, reducer, components
tools/                       the codegen pipeline (never published)
registry/UPSTREAM.json       pinned refs and digests
registry/spec/<source>/      generated component IR, one directory per registry
registry/snapshot/           the markup each example renders to
registry/VERIFY.json         what `mix ui.verify` last proved
storybook/                   demo application, and the browser suite
```

## Status

| | |
|---|---|
| [ROADMAP.md](ROADMAP.md) | milestones and their exit criteria |
| [DEFERRED.md](DEFERRED.md) | publishing and deployment, and what each needs |
| [docs/INVENTORY.md](docs/INVENTORY.md) | 112 components, status derived from disk |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | layers, contract, pipeline stages |

Eight core recipes cover 102 of the 112 components.

## Development

```bash
cd tools && mix deps.get
mix ui.fetch --only accordion     # pin and download one component, and the styles
mix ui.spec                       # upstream -> registry/spec
mix ui.gen                        # spec -> HEEx modules
mix ui.status                     # regenerate docs/INVENTORY.md
```

Verifying needs a browser once:

```bash
cd storybook && mix setup
cd test/browser && npm install && npm run verify:install

cd tools && mix ui.verify         # generated, snapshot, browser
```

To look at the components, run `mix phx.server` in `storybook/` and open
<http://localhost:4100>. The demo builds shadcn's own styling from the sheets
`mix ui.fetch` downloaded, so run the fetch first.

## License

Apache-2.0. See `NOTICE` for the upstream projects this work derives from.
