# Plan

What is left. Everything that is finished is recorded in
[ROADMAP.md](ROADMAP.md) and in the git history; this page holds only work that
has not been done. The checkbox form of this page is [TODO.md](TODO.md).

**Scope: shadcn parity, and nothing else.** AI Elements and the Ouro
integration are out of this plan. [ROADMAP.md](ROADMAP.md) holds both — M4 for
AI Elements, M5 for Ouro — and each is a plan of its own when its turn comes.

## Where this stands

62 of 62 shadcn components generate and 61 verify on all five checks. The
exception is `chart`, which drew nothing at all until this week and is item 1
below.

The pixel census covers 66 examples. 64 are gated at zero differing pixels, one
carries a measured budget (`scroll-area.default`, 137 px of glyph
rasterisation), and one is `pending`: `chart.default`.

Four gates are green on a clean tree and CI runs all four:
`mix ui.gen --check`, `mix ui.status --check`, `mix snapshot --check`, and
`mix ui.spec --check --source shadcn` — the last being the only one that
re-reads upstream, and the only one that can tell a spec has drifted from the
source it was built from.

Two jobs are left. The first is a component; the second needs an account.

---

## 1 — The chart is a hand-written component wearing a spec

`registry/spec/shadcn/chart.json` has **no parts** and two class strings typed
by hand, because the reader refuses `chart.tsx`. Everything below follows from
that.

### What is already fixed

`chart_style/2` returned `""`, so a caller's `config` produced no
`--color-<key>` rules and every `var(--color-…)` resolved to nothing. And the
block could not have worked anyway: `<style>` is a raw-text element, so HEEx
does not interpolate `{…}` inside one and the component shipped a stylesheet
whose content was the literal characters `{@chart_style}`.

Both are fixed. The chart draws in the right colour now.

### What is not

**The reader refuses `chart.tsx`, three times over.** `ResponsiveContainer`,
`Tooltip` and `Legend` are recharts primitives, which an `@external_primitives`
entry answers — that much was tried and works. The one left is the `<style>`
block: upstream builds it as a template string through
`dangerouslySetInnerHTML`, which is a computation rather than markup, and the
reader has nothing to turn it into. Until that has an answer, `chart.json`
stays hand-written.

**So the recipe types upstream's class strings, and types some of them wrongly.**

| Where | What is missing |
|---|---|
| `classes["container"]` | twelve `[&_.recharts-*]` selectors — most of what upstream's string says |
| the tooltip's value | `text-foreground` |
| the legend's item | `[&>svg]:h-3 [&>svg]:w-3 [&>svg]:text-muted-foreground` |

These are the last upstream class strings a person maintains, and the roadmap's
non-goal says plainly that a class string typed by a person is a gap in the
pipeline.

**And the comparison cannot see any of it.** `chart.default` is `pending` at
21,169 px, and the difference is that only one side draws: `ChartContainer` puts
its children inside `<ResponsiveContainer>`, which sizes an inner wrapper to
0×0 for anything that is not a recharts element. So the reference renders the
chrome and nothing inside it.

That is not a rendering difference to budget away. It is the reference and the
component answering different questions, and it needs a decision:

- **Give the reference a recharts element to draw**, and deal with the mount
  animation that made this example the only one whose pixel count moved between
  runs (129, 134, 142). `parity/README.md` forbids two different pictures, and
  that is what took it here in the first place.
- **Or compare the chrome with an empty child**, and say in the example that the
  plot is the caller's and is not under test.

The second is smaller and true. The first is what would actually exercise the
twelve `[&_.recharts-*]` selectors, which are the whole reason they exist.

**Done when** `chart.json` is read rather than typed, or the chart is recorded
in the roadmap as a deliberately hand-written component with its reason — and
either way `chart.default` leaves `pending` and `mix ui.verify shadcn/chart`
passes all five checks.

---

## 2 — Publish 0.1.0

Not code. [DEFERRED.md](DEFERRED.md) is the full guide, and every step there is
blocked on an account rather than on work:

| Step | Blocked on |
|---|---|
| Publish to hex | a `HEX_API_KEY` repository secret under a `hex` environment |
| Deploy the storybook | `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, and a `SECRET_KEY_BASE` worker secret |
| Prove the sync bot | one `Sync upstream` run by hand, and a readable pull request |

---

## Verification

Run this at each boundary. It is the list in
[CONTRIBUTING.md](CONTRIBUTING.md):

```bash
# in each of tools/, packages/*/ and storybook/
mix format && mix compile --warnings-as-errors && mix test

cd tools && mix ui.gen --check && mix ui.status --check
cd ../storybook && mix snapshot --check
cd test/browser && npm run verify        # behaviour, axe, parity and pixels

# and, if you changed the reader — needs `mix ui.fetch` first
cd ../../../tools && mix ui.spec --check --source shadcn
```

A `--check` failure is the purpose of the gate. It means a generated file no
longer agrees with what its spec produces, because the spec moved or because
somebody edited the output.

The browser half runs locally, never in CI. CI checks the **record**:
`mix ui.status --check` refuses an inventory whose verification no longer
matches the specs on disk, so a spec that moves without a fresh
`mix ui.verify` demotes its component and turns the build red.

If a port this suite needs is held by something else, the run refuses before a
single test starts. Override it rather than guessing:

```bash
STORYBOOK_PORT=4201 PARITY_PORT=4202 mix ui.verify shadcn/calendar
```

### When a comparison fails, read the outline

`parity.spec.mjs` attaches the element tree of both renderings and puts the rows
where they stop agreeing into the failure itself. That is what to read first:
`collect` compares the vocabulary both sides share, and for a component with one
`data-slot` that vocabulary is one word.

### When a comparison passes, ask what it compared

`chart.default` was gated at zero for weeks, and both sides were drawing
nothing. A green pixel check says the two images agree, not that either one has
a component in it.

## What this plan does not cover

**AI Elements.** M4 in [ROADMAP.md](ROADMAP.md). Its specs are stale on purpose:
re-reading them deletes `question`, `snippet` and `environment-variables`, whose
`useRender` state keys have no answer yet, and shipped components do not
disappear as a side effect of a shadcn gate. That is why
`mix ui.spec --check` runs per registry.

**Ouro.** M5 in the roadmap. A different repository, and it needs components
worth swapping in — which this plan has now supplied.
