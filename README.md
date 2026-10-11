# live_shadcn

Reviewed shadcn/ui and AI Elements ports for Phoenix LiveView.

The repository keeps upstream class and CVA facts current without translating
React into Elixir. Oxc extracts safe facts and structural fingerprints. A
maintainer owns the HEEx API and behavior of each port.

See [docs/INVENTORY.md](docs/INVENTORY.md) for the component status derived from disk.

## Why another component library

shadcn changes often. A copied port needs a clear way to identify safe upstream
changes without replacing reviewed LiveView behavior.

The synchronization inputs are machine-readable:

| Upstream source | What it gives |
|---|---|
| `ui.shadcn.com/r/index.json` | component names and source references |
| shadcn `.tsx` files | class strings, CVA tables, and structure |
| Base UI Markdown | parts, data attributes, and CSS variables |
| shadcn style sheets | `cn-` rules and their state variants |
| AI Elements `.tsx` files | AI component facts and structure |

A scheduled workflow fetches these sources and opens a pull request when safe
facts change. Structural or behavior drift stops the workflow for review.

## The key idea

shadcn class strings use data and ARIA attributes. `live_base` supplies the
LiveView behavior that sets those attributes.

```text
data-panel-open   data-starting-style   data-ending-style
data-side         data-highlighted      aria-disabled
```

The port keeps the upstream class strings. Its reviewed HEEx body decides how
LiveView provides the required state and behavior.

## Packages

| Package | Install as | Contains |
|---|---|---|
| `live_base` | dependency | focus, dismiss, roving focus, typeahead, and floating position |
| `live_shadcn` | `mix ui.add` copy | reviewed shadcn component ports |
| `live_ai_elements` | dependency | streaming message parts, reasoning, and tool calls |

`live_shadcn` copies source into your application, as the shadcn CLI does:

```bash
mix ui.add button card accordion
mix ui.sync
mix ui.sync --apply
```

You own and can edit each copied file. `mix ui.sync` does not overwrite an
edited file. Use `mix ui.add <name> --force` only when you want to discard local
changes.

## LiveView-native behavior

Behavior is declared with `Phoenix.LiveView.JS` and runs on the client. It does
not need a server round trip for actions such as opening a menu.

| Base UI needs | LiveView provides |
|---|---|
| set state attributes | `JS.set_attribute` and `JS.toggle_attribute` |
| keep client state across a render | `JS.ignore_attributes` |
| manage focus | `JS.focus_first`, `JS.push_focus`, and `JS.pop_focus` |
| close on an outside click | `phx-click-away` |
| close on Escape | `phx-window-keydown` |

Four hooks cover work that server-declared commands cannot do:

| Hook | Purpose |
|---|---|
| `Disclosure` | measure content and hold transition attributes |
| `Overlay` | lock scroll, contain focus, and control exit timing |
| `Floating` | position a popup from available browser space |
| `Roving` | move focus with arrow keys |

A hook decides which element to use. The `JS` command on that element decides
what happens.

## Maintainer workflow

```text
mix ui.fetch  ->  mix ui.spec  ->  mix ui.verify
 pinned source    facts + contract    snapshots, browser,
                  reviewed port       all official examples,
                                      accessibility, parity
```

`mix ui.fetch` stores fetched files in the ignored `registry/upstream/`
directory. `registry/UPSTREAM.json` commits their SHA-256 digests.

`mix ui.verify --source shadcn` checks every shadcn port and the data-table,
date-picker, and typography documentation families. AI Elements is outside this
verification pipeline. Its normal package tests still run in CI.

After verification, refresh inventory and enforce complete current evidence:

```bash
mix ui.status
mix ui.status --check --source shadcn --require-verified
```

Storybook uses the same evaluation for its index and component-page badges:

| Badge | Meaning |
|---|---|
| Verified | All required checks and official examples passed for the current inputs. |
| Failed | A required check or preparation failed for the current inputs. |
| Stale | Recorded evidence describes older inputs. Rerun verification. |
| Not verified | Evidence is missing, incomplete, skipped, or diagnostic. |
| No DOM | Policy explicitly identifies a component that renders no DOM. |

Component pages expand the per-check results. Hooks, CSS, references, dependency
locks, and verifier changes invalidate shadcn evidence. `--no-browser` cannot
produce Verified. Release badges describe the sources compiled into the image;
recompile Storybook after writing evidence and rebuild to update a release.

`mix ui.spec` uses Oxc to extract class literals, CVA values, state reads, and
a structural fingerprint. It can update only safe facts in the marked block of
a reviewed port. It does not translate expressions, component structure, React
state, or behavior.

```elixir
# live-shadcn: upstream facts start
@upstream_facts %{
  "jsx/Button/class/0" => "cn-button inline-flex"
}
# live-shadcn: upstream facts end
```

Each `registry/spec/<source>/<name>.json` file records those facts, their
bindings, source digests, fingerprints, and the digest of the reviewed port
body. A class or CVA literal can update automatically. A structure, state-read,
or Base UI contract change requires manual review. One manual change stops all
writes in a full registry run.

The offline check needs no fetched source and no JavaScript parser:

```bash
cd tools
mix ui.spec --check --offline
```

## Layout

```text
packages/live_base/          headless primitives and client hooks
packages/live_shadcn/        reviewed shadcn ports in priv/registry
packages/live_ai_elements/   reducer and reviewed AI component ports
tools/                       Oxc fact extraction and synchronization
registry/UPSTREAM.json       pinned references and source digests
registry/spec/<source>/      version-2 port contracts
registry/snapshot/           rendered example markup
registry/VERIFY.json         results from mix ui.verify
storybook/                   demo application and browser tests
```

## Development

```bash
cd tools && mix deps.get && npm install
mix ui.fetch
mix ui.spec
mix ui.spec --check --offline
mix ui.status
```

To verify and view the components:

```bash
cd storybook && mix setup
cd test/browser && npm ci && npm run verify:install
cd ../../../parity && npm ci
cd ../tools && mix ui.verify --source shadcn

cd ../storybook && mix phx.server
```

Open <http://localhost:14101> with the repository's mise environment (otherwise
port 4100). The demo uses the shadcn style sheets fetched by `mix ui.fetch`.
The repository's mise environment sets verification ports 14101 and 14102.
Stop existing development servers on those ports before verification.

See [CONTRIBUTING.md](CONTRIBUTING.md) for safe updates and the first-port
process. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for contract details.

## License

Apache-2.0. See [NOTICE](NOTICE) for the upstream projects.
