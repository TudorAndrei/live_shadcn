# Plan

What is left. Everything that is finished is recorded in
[ROADMAP.md](ROADMAP.md) and in the git history; this page holds only work that
has not been done. The checkbox form of this page is [TODO.md](TODO.md).

**Scope: shadcn parity, and nothing else.** AI Elements and the Ouro
integration are out of this plan. [ROADMAP.md](ROADMAP.md) holds both — M4 for
AI Elements, M5 for Ouro — and each is a plan of its own when its turn comes.

## Where this stands

**Parity is reached.** 62 of 62 shadcn components generate and verify.
`mix ui.verify` makes five checks — `generated`, `snapshot`, `browser`,
`parity`, `pixel` — and all five are green for every one of them.

The pixel census covers 66 examples. 65 are gated at zero differing pixels and
one carries a measured budget: `scroll-area.default`, 137 px of glyph
rasterisation, diagnosed and stable. Nothing is `pending`.

`mix ui.gen --check`, `mix ui.status --check` and `mix snapshot --check` are
green on a clean tree, and CI runs all three. 316 browser tests, 160 Elixir
tests.

Three jobs are left. Two came out of reaching parity and neither is a component
difference; the third needs an account rather than code.

---

## 1 — `mix ui.spec --check` is red, and no gate watches it

63 specs on disk do not match what the reader produces from the same sources —
38 shadcn and 25 AI Elements. This is not new and it was not caused by the
calendar work: the same 63 are stale at the commit before it.

It is invisible because CI runs `ui.gen --check`, `ui.status --check` and
`snapshot --check`, and none of them re-reads upstream. A spec can drift from
its own source indefinitely and every gate stays green, which is the exact shape
of the problem `mix ui.status` was built to stop one level up.

Two things to establish, in this order:

- **What the difference is.** A stale spec is not automatically a wrong one:
  `mix ui.drift` compares specs and says whether a class string moved or an
  attribute appeared. Read that before regenerating 63 files.
- **Whether `ui.spec --check` can join CI.** It cannot today, because three AI
  Elements components stop the reader (recorded in
  [ROADMAP.md](ROADMAP.md#state-is-a-prop-because-the-server-owns-state)) and a
  gate that cannot run is worse than no gate. Either those three are answered
  first, or the gate runs per registry.

This is what the calendar work found, and it is the largest remaining hole in
the record.

---

## 2 — One class string is still typed, and it is typed twice

`gen/toast.ex` hand-writes `<div class="flex min-w-0 flex-1 flex-col gap-1">` in
the heredoc that renders `sonner`. It is upstream's string, retyped, and it is
the same string the `toast` half now reads out of its spec.

The two halves take different heredocs through one recipe, which is how the
icon defect got in: `sonner` carried the type-to-icon mapping and `toast` did
not. This is the same shape.

The fix is not to retype it a third time. `sonner` renders a stack whose parts
belong to the toast anatomy, and the recipe already has that anatomy on disk in
`registry/spec/shadcn/toast.json`. Give the sonner half the same reading rather
than its own copy.

---

## 3 — Publish 0.1.0

Not code. [DEFERRED.md](DEFERRED.md) is the full guide, and every step there is
blocked on an account rather than on work:

| Step | Blocked on |
|---|---|
| Publish to hex | a `HEX_API_KEY` repository secret under a `hex` environment |
| Deploy the storybook | `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, and a `SECRET_KEY_BASE` worker secret |
| Prove the sync bot | one `Sync upstream` run by hand, and a readable pull request |

Parity is reached, so what gets published now tells the truth about its own
coverage.

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

## What this plan does not cover

**AI Elements.** M4 in [ROADMAP.md](ROADMAP.md). Item 1 above touches it only
where it blocks a shadcn gate.

**Ouro.** M5 in the roadmap. A different repository, and it needs components
worth swapping in — which this plan has now supplied.
