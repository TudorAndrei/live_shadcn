# Plan

The shadcn half of [ROADMAP.md](ROADMAP.md), in the order it has to be done.
The checkbox form of this page is [TODO.md](TODO.md).

A milestone says what is finished. This says what to do next, and why in that
order.

**Scope: shadcn only.** AI Elements and the Ouro integration are out of this
plan. [What this plan does not cover](#what-this-plan-does-not-cover) says where
they went.

## Context

52 of the 62 shadcn components generate. The four specialist recipes that the
eight core ones could not cover — `sidebar`, `scroller`, `slider`, `toast` — are
written.

What is left is five jobs. Each one makes the next one checkable:

1. A toast that is generated but has never run in a browser.
2. **`registry/VERIFY.json` is fully stale.** All 57 entries do not match the
   specs on disk. So `mix ui.status` reports **0 verified**, where the committed
   `docs/INVENTORY.md` says 52. Until this is corrected, no statement about
   coverage can be checked, and the CI gate that already exists will fail.
3. `parity.spec.mjs` compares a generated component with the React it came from.
   It is the only check that reads upstream instead of the spec. 4 of 55 shadcn
   examples have a reference, so it covers 7% of the work.
4. The reader drops Tailwind's `data-[attr=value]:` variants in silence. There
   are about 3,300 of them in shadcn's sources. Class strings will move when
   this is corrected, so it must be done while the parity check can judge it.
5. Ten components are not built. Each one has a stated reason, and the reasons
   collapse into fewer decisions than the count suggests.

The order below is that dependency chain.

---

## Phase 1 — Land the toast

The work is in the tree and not committed. Four defects were found and
corrected. It now generates correctly. What it has never had is a browser.

- Run `storybook/test/browser/toast.spec.mjs` and the axe check for
  `/preview/toast/default`.
- Set `data-limited` in the hook, or give the toaster a `limit` attribute.
  shadcn styles the attribute (`data-limited:opacity-0`) and the hook does not
  write it. Upstream limits the visible stack to a count.
- Commit as one scoped change: the recipe
  (`tools/lib/live_shadcn_tools/gen/toast.ex`), the behaviour
  (`packages/live_base/lib/live_base/toast.ex`,
  `packages/live_base/assets/js/toast.js`), the generated module, the example,
  the suite, and the snapshot.
- Two unrelated corrections share the tree and need their own commits: the
  `aria-disabled` assertion in `packages/live_shadcn/test/ui/accordion_test.exs`
  (it asserted `:present`, and an ARIA state is a word), and
  `Examples.page_assigns/0` in `storybook/lib/storybook_web/examples.ex`, which
  the three renderers of an example now share.

**Done when** `mix ui.verify shadcn/toast` passes all four checks.

---

## Phase 2 — Make "verified" mean something again

`verified?/2` (`tools/lib/mix/tasks/ui.status.ex:147`) counts a pass only while
the recorded spec digest is equal to the spec on disk. All 57 entries are stale.

The cause is known and harmless. `VERIFY.json` was last written at `f7a712c`,
where all 57 agreed. Commit `98ccb89` ("an element can wear two cva tables")
then replaced `"variant_class"` with a `"variant_calls"` array in almost every
spec. That one format change made every digest wrong. **No component
regressed.** The correction is one fresh run.

- Build the Tailwind sheet first — `npm run build:css` in `storybook/assets`.
  `parity/src/main.tsx` imports `storybook/priv/static/assets/app.css`. Without
  the build, every parity comparison reports differences between the two builds
  instead of differences between the components.
- Then `mix ui.spec` → `mix ui.gen` → `mix snapshot` → `mix ui.verify`.
  Playwright starts both servers itself
  (`storybook/test/browser/playwright.config.mjs:33-53`), one at a time.
- Commit the new `registry/VERIFY.json` and `docs/INVENTORY.md`.
- Close the one real example gap: **`toggle-group` has no storybook example.**
  It generates on the `tabs` recipe and nothing exercises it.
- `CONTRIBUTING.md` says `mix ui.verify` makes three checks. It makes four.
  Correct that line and its table.

The gate already exists. `.github/workflows/ci.yml:76` runs
`mix ui.status --check`. **It will fail today.** Nobody has seen it, because the
repository is not pushed ([DEFERRED.md](DEFERRED.md), step 1).

**Done when** `mix ui.status --check` passes on a clean tree.

---

## Phase 3 — The parity backfill

`parity.spec.mjs` found two things that no other check could see —
`aria-disabled=""` that styled nothing, and a missing `cn-input-group-button`
base — with only 5 examples ported. There are 55 shadcn examples.

To add one reference, write one file. There is no manifest to edit:

```tsx
// parity/src/examples/<component>.<example>.tsx
import { Badge } from "@upstream/shadcn/ui/badge";

// Ported from `StorybookWeb.Examples.badge_variants/1`.
export default function BadgeVariants() {
  // the same markup the example writes
}
```

`parity/src/main.tsx` globs the directory. `parity.spec.mjs` reads the same
directory and compares it with `registry/snapshot/index.json`. So a component
that nobody ported is named, not skipped.

`storybook/test/browser/measure.mjs` loads both pages. It waits until the height
of each root stops changing — not until the root is *visible*, because a
LiveView hook sets `--accordion-panel-height` after it connects. It then walks
every `data-slot` descendant by its ancestor path, and asserts three things: the
box `{x, y, width, height}` relative to the root is within 0.5 px, no slot is
present on only one side, and **37 computed properties are string-equal**. Ids,
`phx-*` and all other attributes are never examined.

- Port the 51 shadcn examples that have no reference. Take them
  oldest-generated first, so the oldest readings are checked first.
- A reference is a **port, not a second design** (`parity/README.md`). Where a
  Base UI default is different from the recipe's behaviour, pass the prop that
  makes both sides ask the same question. `keepMounted` on `AccordionContent` is
  the example: the disclosure recipe hides the panel instead of unmounting it.
- Every difference that the check reports is a finding about the **reader**.
  Correct it in `tools/lib/live_shadcn_tools/`, never in the reference.

**Done when** every shadcn example has a reference and every comparison passes.

---

## Phase 4 — Teach the reader `data-[attr=value]`

The larger of the two gaps the roadmap names, and the one it calls "read by
nobody".

Tailwind writes a state variant in two forms. `data-open:` names an attribute,
and `state_attr?/1` (`tools/lib/live_shadcn_tools/spec.ex:1560`) matches it with
`~r/^(data|aria)-[a-z][a-z0-9-]*$/`. `data-[state=open]:` names an attribute
**and a value**. `prefixes/1` already counts bracket depth, so the token arrives
complete, and the `$`-anchored regular expression then rejects it. It falls to
`classify/1`'s `:ignore` (`spec.ex:1555`) with no message and no error.

**Step one: refuse instead of ignore.** A variant that the reader does not know
must name itself, as every other stage of this pipeline already does. That turns
about 3,300 silent drops into a list to work through. It is a small change at
`spec.ex:1555`.

**Step two: the structural change.** `reads/1` returns
`%{"self" => [attr_name], "group" => [%{"group" => …, "attr" => …}]}`
(`spec.ex:1544`) — a flat list of names with **no place for a value**. It must
carry `{name, value}`. Seven consumers read `["reads", "self"]`: `heex.ex:1003`,
`dialog.ex:283`, `disclosure.ex:311`, `listbox.ex:279`, `popover.ex:243`,
`menu.ex:233`, `tabs.ex:177`. Each recipe's `attribute!` table
(`disclosure.ex:77`, `dialog.ex:63`, and the others) also changes. That table
maps a name to an expression and raises on anything it does not know.

**Then stop and read the list.** About 3,300 uses across some 30 names.
`data-[side=]` 753, `data-[slot=]` 712, `data-[size=]` 427, `data-[variant=]`
361, `data-[placement=]` 224, and the rest. Most of them name something that a
recipe already emits for another reason, which is why nothing has looked broken.

**Do not promise step three now.** Steps one and two are bounded. Working all 30
names is not, and the list itself is what says how large it is: for each name
there are three possible answers — a recipe already emits it, a recipe must emit
it, or the caller passes it. Plan step three after step one has produced the
list.

**Done when** no variant is dropped in silence, and phase 3's parity check
agrees with the class strings that changed.

---

## Phase 5 — The ten components that are left

Not ten jobs. Eight of the nine stop in the same place — `base_node/3` at
`spec.ex:1101`, which raises `not_base_ui/2` because there is no data-attribute
contract to generate against.

### 5a — One reader change unblocks five

`spec.ex` already holds the shape of the answer. `@external_roles`
(`spec.ex:1114`) maps a **package** to a **job** — `streamdown` → `markdown` —
so the spec records the job and the generated component names a seam.

Five components need the same idea, aimed at a recipe instead of a renderer: a
table that maps a third-party primitive to the recipe that already owns its
behaviour, so the *recipe* supplies the contract that Base UI would have given.

| Component | Primitive | Recipe that already owns it |
|---|---|---|
| `sonner` | `<Sonner>` from `sonner` | `toast` — written in phase 1 |
| `command` | `<CommandPrimitive.*>` from `cmdk` | `listbox`. See the decision below. |
| `input-otp` | `<OTPInput>` from `input-otp` | `form-control` — one `<input>` per character under one name, the shape `slider` already uses for one range input per value |
| `message-scroller` | `<MessageScrollerPrimitive.*>` | `scroller` |
| `questionnaire` | `<QuestionnairePrimitive.*>` | `presentational` |

`mix ui.fetch` did not store a Base UI page for any of these
(`tools/lib/mix/tasks/ui.fetch.ex:130-149`), because the index's `base.api` link
points at the React library's own site. There is no contract to read even if the
reader agreed to read one. That is exactly why the recipe must supply it.

**Decision: `command` filters on the server.** cmdk filters the list in the
client, with fuzzy matching. Here the caller filters and the component draws.
The server already owns the list, which is the same reason the toast list is a
slot: a client that held its own filtered copy would disagree with the server
after the next patch.

The cost is stated rather than hidden. It is one round trip for each keystroke,
and fuzzy matching becomes the application's to write. This is a deliberate
difference from upstream, and the parity check cannot catch it, because that
check compares computed styles and not behaviour.

### 5b — One recipe, and the spec is already written

`carousel` is the only one of the nine that **already has a spec**
(`registry/spec/shadcn/carousel.json`). It reads correctly, because
embla-carousel is a *hook* and every piece of JSX in shadcn's `carousel.tsx` is
a plain `<div>`. It stops in the generator (`ui.gen.ex:42`, "no `carousel`
recipe yet") only because `Gen.@recipes` (`gen.ex:27-40`) has no entry.

Write a `carousel` recipe on CSS scroll-snap. Use a hook only for the disabled
state of the arrows — a measurement, as `scroller` does.

### 5c — Three that need a real decision

| Component | Upstream | Decision |
|---|---|---|
| `resizable` | react-resizable-panels | **A `resizable` recipe**: a pointer-drag hook that writes a CSS variable, which is what `slider` already does. Small. |
| `calendar` | react-day-picker | **A `calendar` recipe.** A month grid is data that the server computes, and Elixir's `Date` and `Calendar` are sufficient. See the locale decision below. |
| `chart` | recharts | **Port the chrome. There is nothing to put behind a seam.** See below. |

**`chart` draws no chart.** The 370 lines of `chart.tsx` are a container, a
`<style>` block, a tooltip body and a legend body. `ChartTooltip` and
`ChartLegend` are re-exports of recharts and nothing else. The plot is the
caller's children, upstream as much as here — so the seam this component needs
is a slot, and it already has one.

What ports, on the `presentational` recipe:

- `chart_container` — a `<div data-slot="chart">` that carries a `data-chart` id
- the `<style>` block, which emits one `--color-<key>` variable for each entry
  in a config, per theme. This is data, and Elixir writes it the same way
- `chart_tooltip_content` and `chart_legend_content` — ordinary markup

Two things to state plainly rather than hide. `ResponsiveContainer` is a
measurement wrapper; `aspect-video` is already on the container, so try CSS
before a hook. And most of the container's class string is selectors against
recharts' own DOM — `[&_.recharts-cartesian-axis-tick_text]` and fifteen more.
Keep them, because the rule is that no class string is retyped, and record in
the moduledoc that they apply only to a renderer that emits those class names.

**No dependency is added.** For the record, if an application wants a renderer
for the slot: `tucan` (0.6.0, 2026-04) and `live_charts` (0.5.0, 2026-07) are
current. `contex` (0.5.0, 2023-05) and `chartkick` (1.0.0, 2023-03) are not.

**`calendar` takes the locale as a prop, and can ask the browser.** shadcn takes
`locale` as an optional prop and gives it to react-day-picker. When the caller
passes nothing, `date.toLocaleString(undefined, …)` uses the browser default —
but only for the **month label**. The weekday names and the first day of the
week come from react-day-picker's own `en-US`.

That difference matters here, because the server renders the grid and the first
day of the week changes the shape of the grid. So:

- `attr :locale, :string, default: nil` and
  `attr :week_starts_on, :integer, default: 0`. English and Sunday, which is
  what upstream does. No new dependency, and the first render is correct.
- `locale="browser"` is opt-in. A hook then reads
  `Intl.DateTimeFormat().resolvedOptions().locale` and
  `Intl.Locale.prototype.getWeekInfo()` on mount and pushes both.

The cost of the opt-in is stated rather than hidden: one round trip on mount,
and a visible reflow if the browser's first day of the week is not the default.
An application that cannot accept the reflow reads `accept-language` in its own
endpoint and passes `locale` itself, which the first form already supports.

### 5d — `direction`

Not a component. It has no markup and nothing to draw. It is already named a
utility. Keep it out of the count instead of counting it as a gap.

**Done when** every shadcn component either generates and verifies, or is named
in the roadmap as a deliberate non-goal, with its reason.

---

## Phase 6 — Publish 0.1.0

Not code. [DEFERRED.md](DEFERRED.md) is the full list: a push, a hex API key, a
Cloudflare token, then one sync-bot run by hand to show that the pull request is
readable. Do it after phase 2 has made the inventory honest, so that the first
CI run is green and what is published tells the truth about itself.

---

## Phase 7 — Close what the backfill left open

Phases 1 to 5 are done: 62 of 62 shadcn components generate, every example has
a React reference, and the reader reads `data-[attr=value]`. A review of that
work found four things, and the last one is the one that matters.

### 7a — Three gates are red at HEAD

None of them is large, and all three are one command away.

- **`mix ui.gen --check` fails.** Seven components no longer match their spec:
  `shadcn/input`, `input-group`, `questionnaire`, `sidebar`, and
  `ai_elements/chain-of-thought`, `checkpoint`, `snippet`. The generator gained
  `minlength` and `maxlength` in its global list, a `class` on a `<details>`
  root and a `{@rest}` on an icon, and nothing re-ran `mix ui.gen`. The diff is
  12 lines.
- **`mix snapshot --check` then fails** on `chain-of-thought-default`, for the
  `class` above.
- **`mix test` in `tools/` fails.** `LiveShadcnTools.GenTest` reports that the
  `navigation-menu` recipe is written and no component names it. It is 141
  lines and dead: the inventory gives `navigation-menu` to the `menu` recipe.

`.github/workflows/ci.yml` runs the first and the third. Phase 2 existed to
make that gate honest, so leaving it red undoes phase 2.

### 7b — The recipes retype upstream class strings

This is the finding. [ROADMAP.md](ROADMAP.md) states a non-goal:

> **No hand-maintained styling.** If a class string is typed by a person, the
> pipeline has a gap. Fix the pipeline.

Ten recipe files now hold literal `cn-` class strings — `pagination` 16,
`navigation_menu` 8, `calendar` 4, `carousel` 4, and six more. Some are whole
upstream button strings, retyped:

```elixir
"cn-button group/button inline-flex shrink-0 items-center justify-center
 whitespace-nowrap transition-all outline-none select-none …"
```

`gen/toast.ex` goes further. It was a recipe that rendered the spec's parts; it
is now a hand-written `~H` template with `class="cn-toast"` and
`class="flex min-w-0 flex-1 flex-col gap-1"` — a Tailwind string that appears
nowhere upstream, and a `cn-toast` that drops the whole
`[--gap:…] h-(--height) [transform:…]` stack the class string carried.

A retyped class string is invisible to `mix ui.drift`, so the sync bot will not
notice when upstream moves it. That is the cost, and it arrives silently.

### 7c — A recipe is becoming a patch on another recipe's output

`String.replace` over generated source went from 26 uses to 48. Eight new
one-component recipes exist only to hold one:

```elixir
# gen/separator.ex — the whole module
spec
|> Presentational.module(opts)
|> String.replace(" orientation={@orientation}", " data-orientation={@orientation}",
     global: false)
```

`gen/resizable.ex` has eight, and two of them inject `attr` declarations into
the source by text substitution.

Every one of these patches is a **fact that belongs in the spec** — Base UI
writes `data-orientation`; a checkbox indicator mounts only when checked —
applied to the output because the reader did not record it. And a
`String.replace` on generated source cannot know where anything ends, which is
the same reason the reader stopped using regular expressions in M4.
`global: false` means "the first one", which is a decision about position.

The recipe count went 12 → 24, eight of them serving one component. A
one-component recipe is the recipe absorbing what the reader could not say.
`ROADMAP.md:69` and `docs/INVENTORY.md:17` both still claim eight.

### The work

For each patch and each retyped class string, ask which of the three it is: a
fact the reader should record in the spec, a `cva` table the fold read wrongly,
or a genuine behaviour that belongs in a recipe. Move the first two. Then the
one-component recipes disappear, and the count returns to something the roadmap
can state truthfully.

Do this before phase 8. Phase 8 is what makes it cheap.

---

## Phase 8 — Finish the oxc swap

M4 replaced the reader's regular expressions with `oxc-parser` and listed four
bugs the swap fixed. That swap stopped at the file level. **Expressions are
still text**, and every argument M4 made applies unchanged one level down.

`parse.mjs` prints the tree; `Ast` reads it and slices the source back out with
the offsets; then `Spec` and `Tsx` parse those slices again with regular
expressions. The pipeline parses each file twice, and the second parser is the
one M4 threw away.

### 8a — Read expressions as nodes, not as source

`spec.ex:925-1027` classifies an expression with five patterns:

```elixir
@value      ~r/^[a-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$/
@arithmetic ~r/^[a-z_][A-Za-z0-9_.]*(\s*(\+|-|\*|\/|\?\?)\s*…)+$/
@ternary    ~r/^[^?<]+\?[^:<]+:[^<]+$/s
```

`@ternary` cannot tell `a ?. b` from `a ? b : c`, and cannot see a `:` inside a
string. `tsx.ex` counts bracket depth by hand in `split_args/1`, splits an
object literal on commas in `object!/1`, and asks `~r/\bclassName\b/` whether a
`cn()` call merges a class — a regex that matches the word in a comment.

The nodes for all of this already exist. `ConditionalExpression`,
`CallExpression`, `ObjectExpression`, `MemberExpression`. Carry them instead of
their source text. This removes about ten of `spec.ex`'s nineteen regular
expressions and most of `tsx.ex`, and it is what makes phase 7's patches
movable: a patch exists because the reader could not say something, and this is
the reader learning to say it.

### 8b — Read the TypeScript

`ast.ex:722` reads a type's *name* and drops the rest. oxc parses every
`TSTypeAnnotation` in the file already.

Upstream types every prop. The generator guesses instead: `:boolean` only when
the default is literally `true` or `false` (`presentational.ex:129`), `:any`
when a regular expression spots `foo.bar`, `:string` otherwise. Across the
shadcn output that gives 282 `:any` and 224 `:string` out of 845 attributes.

A `boolean` is `:boolean`. A `number` is `:integer`. A union of string literals
is a `values:` list. A `?` is optional. That is upstream stating the contract,
in a file this pipeline already parses, and it is the same argument that made
`cva` tables data rather than something retyped.

### 8c — A regular expression decides `:any`

`presentational.ex:135`:

```elixir
Regex.scan(~r/\b([a-z_][A-Za-z0-9_]*)\.[a-z_]/, code, capture: :all_but_first)
```

It matches inside a string literal and inside a comment, and it misses `a?.b`
and `a["b"]`. A `MemberExpression` is a node with an object and a property.

### 8d — The module record is unread

`ParseResult` has four getters — `program`, `module`, `comments`, `errors` —
and `parse.mjs` uses two. `module` is the ECMAScript module record:
`staticImports`, `staticExports`, `dynamicImports`, each exact.

`spec.ex:651` and `:664` currently decide what a file exports with
`Regex.match?(~r/^[A-Z]/, export)`. Reading exports wrongly is what once gave
all 49 AI Elements components a spec with no parts, which
[ROADMAP.md](ROADMAP.md) records under M4 — and on disk a spec with no parts
looks exactly like one the reader understood.

### 8e — The walk is hand-rolled

`parse.mjs` recurses `Object.keys(node)` on every node, which descends into
fields that are not nodes. oxc ships `visitorKeys` and a generated `Visitor`
for this. `oxc-walker` builds on both and adds scope tracking, which is what
`spec.ex:208` currently asks with `Regex.match?(~r/\b#{name}\b/, code)` —
"does this expression mention this name", a scope question answered by a word
boundary.

Semantic analysis proper (`oxc_semantic`: scopes and symbol resolution) is
Rust-side and is **not** exposed by the npm parser, so `oxc-walker` is the
reachable version of it.

---

## Phase 9 — The storybook becomes the documentation site

Two things are called "the storybook" today, and neither is the thing a reader
wants.

`phoenix_storybook` is mounted at `/storybook` with **one** story out of 63,
and that story's three variations are a retyped copy of
`Examples.accordion_default/1` and its siblings — the same markup in two
places, which is what this repository refuses everywhere else.
`StorybookWeb.IndexLive` at `/` is a flat page that renders every example at
once, which is why a fixed-position toaster sits over the whole listing.

The target is the shadcn website's structure, built out of `live_shadcn`'s own
components. It looks like shadcn because it **is** shadcn, and the site becomes
the honest test of the components it documents: if the sidebar is awkward to
navigate with, the sidebar is awkward.

### 9a — The shape

```text
┌─ sidebar ─┐┌─ main ───────────────────────┐
│ search ⌘K ││ Badge                        │
│           ││ A label for a status.        │
│ Getting.. ││                              │
│  Install  ││ ┌ Preview ┐ Code             │
│           ││ │  [new] [beta] [old]      │ │
│ Components││ └──────────────────────────┘ │
│  Accordion││                              │
│  Badge  ● ││ Installation                 │
│  Button   ││  mix ui.add badge            │
│  ...      ││                              │
│           ││ API   (generated from attr)  │
│           ││  variant  :string  "default" │
└───────────┘└──────────────────────────────┘
```

- `/` — getting started and installation
- `/docs/:component` — one page per component, replacing the flat index
- `/preview/:component/:example` — **unchanged.** It is the fixture that
  `mix snapshot`, axe-core and `parity.spec.mjs` drive, and
  `PreviewLive`'s moduledoc says why it carries no chrome: a violation has to
  belong to the component rather than to the navigation around it. This phase
  is additive.

The sidebar is `<.sidebar>`, the search is `<.command>` on `⌘K`, the
Preview/Code block is `<.tabs>`, the API table is `<.table>`.

### 9b — Three things generate rather than being typed

This is what makes the site worth building here rather than copying. All three
were checked against the code before being written down.

**The Code tab.** `Code.string_to_quoted(token_metadata: true)` over
`storybook/lib/storybook_web/examples.ex` finds all 75 example functions, and
the `~H` sigil node carries its own body — no file slicing and no regular
expression:

```elixir
{:defp, _, [{name, _, [_]}, [do: {:sigil_H, _, [{:<<>>, _, [heex]}, _]}]]}
```

That yields exactly the markup a person would write, which is what shadcn's own
site shows.

**The API reference.** Every generated module answers `__components__/0` with
each function's attributes and slots — `name`, `type`, `required`, `doc`, and
the `opts` holding `default:` and `values:`, plus each slot's own attributes and
their docs. shadcn hand-writes that table on its site. Here it is data:

```elixir
%{name: :variant, type: :string, required: false,
  opts: [default: "default", values: ["default", "destructive", …]],
  doc: "…"}
```

**The navigation.** `Examples.components/0` and `Examples.all/1` already exist.

Nothing on the page is retyped. If a component gains an attribute, its
documentation gains a row.

### 9c — Drop `phoenix_storybook`

Remove the dependency, the `live_storybook` and `storybook_assets` routes, the
backend module, and `storybook/storybook/*.exs`. It documents one component of
63, and the way it documents that one is by holding a second copy of the
example markup.

### 9d — The sidebar example demonstrates nothing

`Examples.sidebar_default/1` draws Pipeline → Fetch, Spec, Generate, Verify
inside `min-h-64`, so collapsing it changes nothing a reader can see. Give it a
real shell: a header with a brand, two labelled groups with icons, a footer
holding a user item, and enough height that collapsing is visible.

One constraint stays. `sidebar_inset` is left out on purpose — it is a `<main>`,
the preview page already has one, and axe is right to object to the second.

**Done when** `/docs/badge` shows the badge, the HEEx that drew it, and its
attribute table, with none of the three typed by hand; `/preview/*` is
byte-identical to what it renders today; and `mix ui.verify` still passes.

---

## Phase 12 — Pixel parity, and where verification runs

### 12a — CI checks the record; the browser runs locally

The browser suite ran in CI and **could not have been working**. The job fetched
`--only accordion`, `registry/upstream/**` is gitignored, and `parity/` was
never installed at all — so the reference server could not build 65 of its 66
pages. A check that cannot tell "did not run" from "passed" is worse than no
check, and this was one.

The fix is not to make CI fetch everything. It is to put the browser where the
things it needs are already true.

- **CI** runs what is hermetic and cheap: format, compile, test, credo,
  `deps.audit`, dialyzer, `mix ui.gen --check`, `mix ui.status --check`,
  `mix snapshot --check`. No browser, no fetch. Verified on a clean clone with
  no `registry/upstream/` and no asset build: all three pipeline gates pass.
- **A developer's machine** runs `mix ui.verify`, which writes
  `registry/VERIFY.json` — and that file is committed.
- **CI enforces the record.** `mix ui.status --check` refuses an inventory whose
  verification no longer matches the specs on disk. Change a spec without
  re-verifying and the component demotes, the inventory diff shows it, and the
  build goes red.

So CI enforces that somebody verified without pretending to verify. That is the
repository's existing mechanism, used for what it was already for.

### 12b — A fifth check: pixel parity

The geometric check compares numbers and strings, never rendered output. It is
blind to painted shadows and gradients, `::before`/`::after` content, z-order,
transforms, SVG glyphs, background images, text rendering, anti-aliasing of
borders and radii — and to any element without a `data-slot` at all.

**The one decision the rest follows from: no committed golden images.**
Photograph both sides in the same run, in the same browser, on the same machine,
and diff the two buffers in memory. The React render is the baseline,
recomputed every run — the same shape the geometric check already uses.

That single choice removes the whole class of screenshot-test misery:
platform-suffixed baselines, `--update-snapshots` churn, goldens that go stale
the moment `registry/UPSTREAM.json` moves, and macOS-against-Linux font
differences. Both images come from one Chromium, so every environmental
variable cancels and only the components can differ. It also keeps the rule
this repository holds itself to: a difference is a finding about the reader or
the recipe, because the reference is rebuilt from unmodified upstream at the
pinned commit on every run.

**Mechanism.** `pixelmatch` + `pngjs`, in new files:

```text
storybook/test/browser/pixel.spec.mjs      # the check
storybook/test/browser/shoot.mjs           # settle, freeze, shoot, diff, localise
storybook/test/browser/pixel-budget.json   # budgets, pending, skips
```

Viewport screenshots — not element screenshots — at a viewport sized to the
taller of the two documents. A preview root can have a zero-height box, which
`measure.mjs` already documents, and portals paint outside it. A viewport shot
is also what makes fixed toasts and portals comparable, because
`position: fixed` is viewport-relative however the DOM is arranged.

Rejected: `toHaveScreenshot` (a golden mechanism, and the baselines would be our
own output — the wrong source of truth); SSIM (one opaque score a reviewer
cannot act on); `odiff` (a native binary per platform, for milliseconds saved).

**Determinism**, in a second Playwright project so the knobs never leak into the
behaviour specs: forced headless, `deviceScaleFactor: 2`, `colorScheme: "light"`,
`reducedMotion`, and `--disable-gpu --disable-lcd-text
--disable-font-subpixel-positioning --force-color-profile=srgb`. Before every
shot, reuse the existing settle discipline, then `document.getAnimations({subtree:
true})` finished — a CSS override cannot stop a Web Animations API animation,
and Sonner and Recharts use one.

**Threshold:** differing pixels ≤ a committed per-example budget, default zero,
hard-capped at 0.5% of image area. The anti-absorption rule is the part that
matters: a budget more than 10× its observed diff **fails**, so a slack budget
is a stale budget rather than a quiet blanket. A global percentage tolerance was
rejected because 0.3% of a large image is a whole missing border on every
element.

**Reporting** hit-tests diff regions against the slot boxes `collect()` already
returns, so a failure reads
`4,812 px differ, budget 0 — hottest: card > card-footer (3,904), outside any
slot (298)`. That last bucket is what the geometric check is structurally blind
to, and naming it is the point.

**A fifth check, not a replacement.** Geometry names the fix in the vocabulary a
recipe is written in — `padding-left: React 0.5rem, Phoenix 8px`. Pixels catch
what geometry cannot see but name only a region. Each is the other's triage
tool.

**Migration** reuses the pattern this repository already owns — "one test for
the whole gap". Land the harness with every example in `pending`; pending
examples still run and print their observed diff, so day one is green *and*
produces a complete noise census that replaces every estimated number with a
measured one. Burn down in batches; done when `pending` is empty.

**Order:** 12a first. Adding a fifth check on top of a fourth that has never run
would be building on a foundation nobody has seen work.

---

## Verification

Run this at each phase boundary. It is the list in
[CONTRIBUTING.md](CONTRIBUTING.md):

```bash
# in each of tools/, packages/*/ and storybook/
mix format && mix compile --warnings-as-errors && mix test

cd tools && mix ui.gen --check && mix ui.status --check
cd ../storybook && mix snapshot --check
cd test/browser && npm run verify        # behaviour, axe, and parity
```

A `--check` failure is the purpose of the gate. It means a generated file no
longer agrees with what its spec produces, because the spec moved or because
somebody edited the output.

## Files that will move

| Path | Which phase |
|---|---|
| `tools/lib/live_shadcn_tools/spec.ex` | 4 (`state_attr?/1`, `reads/1`, `classify/1`) and 5a (a primitive-to-recipe table beside `@external_roles`) |
| `tools/lib/live_shadcn_tools/gen/*.ex` | 4's `attribute!` tables, 5b's new recipe |
| `parity/src/examples/*.tsx` | 3 — 51 new files |
| `storybook/lib/storybook_web/examples.ex`, `storybook/test/browser/*.spec.mjs` | one example and one suite for each new component |
| `registry/spec/`, `registry/snapshot/`, `registry/VERIFY.json`, `docs/INVENTORY.md` | generated. Regenerated, never edited |
| `ROADMAP.md`, `DEFERRED.md`, `CONTRIBUTING.md` | the record |

## What this plan does not cover

**AI Elements.** 14 components generate, 13 have a spec and no module, and 22
are only fetched. Two things block most of them, and both are recorded in
[ROADMAP.md](ROADMAP.md) under M4: a fold copies markup but not the recipe that
made the part work (six components), and eight components need JavaScript that a
template cannot run. Phase 5a's reader change and phase 5's `command` will
unblock some of them as a side effect. That is a plan of its own.

**Ouro.** M5 in the roadmap. It is a different repository, and it needs
components that are worth swapping in, which this plan supplies.
