# Plan

What is left. Everything that is finished is recorded in
[ROADMAP.md](ROADMAP.md) and in the git history; this page holds only work that
has not been done. The checkbox form of this page is [TODO.md](TODO.md).

**Scope: shadcn parity, and nothing else.** AI Elements and the Ouro
integration are out of this plan. [ROADMAP.md](ROADMAP.md) holds both — M4 for
AI Elements, M5 for Ouro — and each is a plan of its own when its turn comes.

## Where this stands

**62 of 62 shadcn components generate and verify** on all five checks.

The pixel census covers 66 examples. 64 are gated at zero differing pixels, one
carries a measured budget (`scroll-area.default`, 137 px of glyph
rasterisation), and one is a recorded skip (`chart.default`, which only one side
can draw). Nothing is pending.

Four gates are green on a clean tree and CI runs all four:

| Gate | What it compares |
|---|---|
| `mix ui.gen --check` | a component with its spec |
| `mix ui.status --check` | the inventory with the verification record |
| `mix snapshot --check` | the markup a reader gets with its snapshot |
| `mix ui.spec --check --source shadcn` | **a spec with the source it was built from** |

The fourth is the one added last and the only one that re-reads upstream. The
first three compare two committed things, so before it existed a spec could
drift from its own source indefinitely and every gate stayed green — which is
what 38 shadcn specs had done.

One job is left, and it needs an account rather than code.

---

## 1 — Publish 0.1.0

Not code. [DEFERRED.md](DEFERRED.md) is the full guide, and every step there is
blocked on an account:

| Step | Blocked on |
|---|---|
| Publish to hex | a `HEX_API_KEY` repository secret under a `hex` environment |
| Deploy the storybook | `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, and a `SECRET_KEY_BASE` worker secret |
| Prove the sync bot | one `Sync upstream` run by hand, and a readable pull request |

Parity is reached, so what gets published tells the truth about its own
coverage.

---

## Two decisions that are recorded rather than open

Neither is work. Each is a decision whose cost is stated where somebody meeting
it will find it, and each names the one thing that would reopen it.

**`chart` is hand-written.** `chart.tsx` stops the reader in four places, and
teaching it the last three means teaching it recharts' payload model — a large
amount of reader for one component whose plot is the caller's anyway. So its
spec is two class strings and no parts, and its example is a recorded skip
because `<ResponsiveContainer>` sizes anything that is not a recharts element to
nothing. Both costs, and the two defects the skip was hiding, are in
[ROADMAP.md](ROADMAP.md#chart-is-hand-written-and-this-is-the-reason).

Reopen it if `mix ui.drift` ever needs to report a chart change: it cannot
today, because the class strings do not follow upstream.

**AI Elements specs are stale on purpose.** Re-reading them deletes `question`,
`snippet` and `environment-variables`, whose `useRender` state keys have no
answer yet, and shipped components do not disappear as a side effect of a shadcn
gate. That is why `mix ui.spec --check` takes `--source`. Reopen it with M4.

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

`chart.default` was gated at zero for weeks and both sides were drawing nothing.
A green pixel check says the two images agree, not that either one has a
component in it.
