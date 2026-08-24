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
