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

The core hooks cover work that server-declared commands cannot do:

| Hook | Purpose |
|---|---|
| `Disclosure` | measure content and hold transition attributes |
| `Overlay` | lock scroll, contain focus, and control exit timing |
| `Floating` | position a popup from available browser space |
| `Roving` | move focus with arrow keys |

A hook decides which element to use. The `JS` command on that element decides
what happens.

Specialist hooks also handle controls such as Calendar, Carousel, Scroller,
Slider, and Toast. Register the complete `live_base` hook map in applications.

## Maintainer workflow

```text
mix ui.fetch  ->  mix ui.spec  ->  mix ui.verify
 pinned source    facts + contract    snapshots, browser,
                  reviewed port       all official examples,
                                      accessibility, parity
```

`mix ui.fetch` stores fetched files in the ignored `registry/upstream/`
directory. `registry/UPSTREAM.json` commits their SHA-256 digests.
Use `mix ui.fetch --locked` to prepare an existing checkout or CI run. It
restores the recorded URLs, checks their digests, and preserves the manifest.
Use plain `mix ui.fetch` only when you intend to update upstream sources.

`mix ui.verify --source shadcn` checks every shadcn port and the data-table,
date-picker, and typography documentation families. `mix ui.verify --source
ai_elements` checks all 48 AI Elements components. `mix ui.verify` checks both
sources.

CI first checks component contracts, snapshots, and the production JavaScript
bundle. A failure stops the dependent jobs from starting. Browser checks then
run in sixteen Shadcn groups and four AI Elements groups on separate runners.
The groups use reviewed component times from
`registry/VERIFICATION_TIMINGS.json`. New components use estimates based on
example count and interactive controls. Each component belongs to one group
and keeps all required examples, visual states, and checks.

Each runner uses one browser worker and batches of up to eight examples.
Local verification keeps the default batch size of two. CI saves each group's
records and retains failed browser reports, traces, and screenshots for seven
days. The final source checks reject missing, repeated, failed, or old results
before they regenerate inventory. Deployment requires both source checks.

CI reuses complete passed results from trusted main-branch runs. The source,
contract, policy, toolchain, pinned browser image, and UTC date must match.
A group with no changed inputs skips source downloads, browser installation,
asset builds, and browser tests. A missing or stale result runs again.

A contract change affects its own component. Ports, CSS, JavaScript, renderers,
upstream references, and browser suites remain shared inputs. Changes to these
inputs can require a full run. An empty cache or a new UTC date also requires
fresh checks. The first run after this cache change fills the cache.

Browser jobs use the pinned Playwright image with browser dependencies already
installed. Reader and integration jobs also cache pinned upstream sources and
still check their recorded digests.

To force a full CI run, use **Run workflow** with `full` enabled. Local result
reuse is explicit through `--reuse PATH`; add `--force` to run that scope again.

To inspect or run a CI group locally, use:

```bash
mix ui.verify.plan --source shadcn --shards 16
mix ui.verify --source shadcn --shard 1/16 --batch-size 8 \
  --output /tmp/shadcn-1.json --artifacts /tmp/shadcn-browser-1
```

The matrix planner, verifier, and cache planner read the same committed timing
file. To refresh it, use successful full CI runs with the current browser setup.
For each component, add the milliseconds from its behavior, accessibility,
parity, and pixel batch logs. Save the mean across runs in `components_ms` and
record the run URLs and commit IDs. Review and commit the file before use.
CI does not change the timing file during a run.

`milliseconds_per_weight_unit` converts measured times to planning weights.
The current value is 2500 milliseconds, near the median time per snapshot-based
weight in the recorded runs. This keeps estimates for new components on a
similar scale. The timing file controls group assignment only. It cannot
supply verification evidence or change the required checks.

Use Phoenix component tests for server rendering and events. Use Node tests
for catalog and contract files. Keep Playwright for browser hooks, focus,
accessibility, layout, and pixels. Its [CI sharding support](https://playwright.dev/docs/test-sharding)
fits the existing assertions and reports. [Agent-browser](https://github.com/vercel-labs/agent-browser)
is useful for an agent's interactive inspection; replacing the test runner
would still require the same page rendering and comparison work. Phoenix's
[LiveView tests](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html)
can check server behavior without a browser, but cannot prove CSS or browser
hook behavior.

Local samples on 2026-10-21 measured the six-example Alert check at 46.3 seconds
with batches of two and 38.2 seconds with batches of eight. The file-only AI
catalog check took 11.4 seconds in Playwright and 0.17 seconds in Node with the
same assertions. These samples do not predict the total CI duration.

AI Elements uses agent-authored behavior and contract tests. Every component
must pass its generated contract, snapshots, example coverage, browser behavior,
and local accessibility checks. The suite runs automatically in CI. Base UI
comparison does not apply. React semantic and pixel parity are recorded as
`not_applicable`; they do not count as passing comparisons.

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
locks, and verifier changes invalidate verification evidence. `--no-browser` cannot
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
cd tools && mix deps.get && npm ci
mix ui.fetch --locked
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
port 4100). The demo uses the shadcn style sheets restored by `mix ui.fetch --locked`.
The repository's mise environment sets verification ports 14101 and 14102.
Stop existing development servers on those ports before verification.

See [CONTRIBUTING.md](CONTRIBUTING.md) for safe updates and the first-port
process. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for contract details.

## License

Apache-2.0. See [NOTICE](NOTICE) for the upstream projects.
