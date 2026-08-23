# Roadmap

Component-by-component status lives in [docs/INVENTORY.md](docs/INVENTORY.md),
which `mix ui.status` regenerates from the files on disk. This page holds the
milestones and their exit criteria.

A milestone is done when its exit criteria are met, not when the work feels
finished.

---

## M0 — Bootstrap ✅

Monorepo, three packages, and stage one of the pipeline.

- [x] `live_base`, `live_shadcn`, `live_ai_elements` build and test on their own
- [x] Path dependencies swap to version dependencies under `HEX_PUBLISH`
- [x] `mix ui.fetch` pins upstream to a commit and records SHA-256 digests
- [x] `mix ui.status` derives the inventory from disk
- [x] CI matrix, and a weekly sync workflow

**Exit:** a fresh clone runs `mix ui.fetch --only accordion` and gets a manifest. ✅

---

## M1 — The spine

One component, all the way through, with nothing done by hand.

- [ ] `mix ui.spec` parses the shadcn `.tsx` and the Base UI `.md` into
      `registry/spec/accordion.json`
- [ ] `disclosure` recipe in `live_base`: `JS` commands for open and close,
      `JS.transition` for enter and exit, correct `data-panel-open`
- [ ] `mix ui.gen` turns the spec into a HEEx module
- [ ] `storybook/` renders it
- [ ] `mix ui.verify`: markup snapshot, Playwright parity against the Base UI
      documentation example, axe-core clean

**Exit:** `<.accordion>` works and **no generated line was edited by hand**. If
the spec cannot produce correct HEEx on its own, the pipeline is wrong and we
learn it here rather than after twenty hand ports.

**Risk:** this is the milestone that decides whether the whole approach holds.
Do not start M2 before it passes.

---

## M2 — The eight core recipes

Eight recipes cover 102 of 112 components.

- [ ] `disclosure`, `dialog`, `popover`, `listbox`, `menu`, `tabs`,
      `form-control`, `presentational`
- [ ] All 34 tier-1 components generated and verified
- [ ] `mix ui.add` copies components into a host application with a version stamp
- [ ] `mix ui.sync` reports upstream drift and refuses to overwrite edited files
- [ ] Icon set is configurable — `lucide_icons` by default, since shadcn's
      `IconPlaceholder` already names five sets

**Exit:** a scratch Phoenix app runs `mix ui.add button dialog select` and the
result behaves like the shadcn documentation.

---

## M3 — Publish 0.1.0

- [ ] `live_base` and `live_shadcn` on hex
- [ ] Storybook deployed, one public URL
- [ ] Sync bot proves itself: one real upstream change lands as a pull request
      whose diff is readable
- [ ] `CONTRIBUTING.md` explains how to add a recipe

**Exit:** somebody who is not us installs it from hex and it works.

---

## M4 — AI Elements

The components are the small part. The reducer is the product.

- [ ] `LiveAiElements.Part` — the view model: `id`, `type`, `status`, `seq`
- [ ] `LiveAiElements.Stream.reduce/2` → `insert_part`, `append_delta`, `set_state`
- [ ] Open Responses adapter, the reference implementation. It carries `item_id`
      per part and `sequence_number` for ordering, which is exactly what
      `phx-update="stream"` needs
- [ ] Delta hook: a token append must never touch an assign
- [ ] Tier-1 AI components: chain-of-thought, reasoning, tool, task, sources,
      message, conversation, prompt-input, code-block, context, shimmer, suggestion
- [ ] Jido adapter, built second on purpose, to prove the adapter boundary holds

**Exit:** a golden test replays a recorded Open Responses stream and produces the
same part list every time.

---

## M5 — Ouro integration

Ouro is the first real application, and the proof the contract survives contact.

- [ ] `live_shadcn` components replace the hand-written chat and settings CSS
- [ ] `live_ai_elements` renders the `:thinking_start`, `:tool_call`, and
      `:tool_result` events Ouro already emits and currently throws away
- [ ] daisyUI token bridge, or daisyUI removed

**Exit:** Ouro's `assets/app.css` drops below 800 lines, from 1,842.

---

## M6 — Coverage

- [ ] 60 tier-2 components
- [ ] Specialist recipes: `scroller`, `toast`, `carousel`, `chart`, `calendar`,
      `resizable`
- [ ] Tier-2 AI Elements

Tier 3 is deliberately unscheduled. Canvas, sandbox, terminal, and web preview
are heavy React. They may never be worth porting.

---

## Non-goals

- **No React.** Not through `live_react`, not through web components.
- **No framework dependency in `live_base`.** One dependency:
  `phoenix_live_view`.
- **No hand-maintained styling.** If a class string is typed by a person, the
  pipeline has a gap. Fix the pipeline.
- **No model in the daily loop.** A model may draft a new recipe once. A person
  reviews it and it is then frozen.
