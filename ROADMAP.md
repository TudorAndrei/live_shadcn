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

**Exit:** a fresh clone runs `mix ui.fetch --only accordion` and gets a
manifest. ✅

---

## M1 — The spine ✅

One component, all the way through, with nothing done by hand.

- [x] `mix ui.spec` parses the shadcn `.tsx`, the Base UI `.md`, **and the
      shadcn style sheets** into `registry/spec/shadcn/accordion.json`
- [x] `disclosure` recipe in `live_base`: `JS` commands for open and close, a
      hook for measurement and enter and exit, correct `data-panel-open`
- [x] `mix ui.gen` turns the spec into a HEEx module
- [x] `storybook/` renders it, with shadcn's own styling
- [x] `mix ui.verify`: markup snapshot, Playwright parity against the Base UI
      documentation example, axe-core clean

**Exit:** `<.accordion>` works and **no generated line was edited by hand**. ✅

### What M1 changed

M1 existed to find out whether the approach holds. Three things it corrected:

**The `.tsx` is not the whole contract.** `.cn-accordion-content` is styled with
`data-closed:animate-accordion-up`, and `data-closed` appears in no `.tsx` and on
no Base UI page. The spec now reads the style sheets too, and the styling layer
is fetched with the rest.

**Enter and exit cannot be `JS.transition`.** `JS.transition` toggles classes;
shadcn styles these states with data attributes, and `h-(--accordion-panel-height)`
asks for a number no static class string can compute. So the hooks grow two jobs
they were not designed for — measurement, and holding a state for the length of
a transition — and the four steps that takes are shared code rather than a fifth
hook. The discrete flip is still a `JS` command, so a click still costs no round
trip.

**Four exports become one function.** React threads the item's identity through
context. HEEx cannot, so `<.accordion>` takes an `:item` slot and derives every
id from the item's own.

**Risk:** this is the milestone that decided whether the whole approach holds. It
held.

---

## M2 — The eight core recipes ✅

Eight recipes cover 102 of 112 components.

- [x] `disclosure`, `dialog`, `popover`, `listbox`, `menu`, `tabs`,
      `form-control`, `presentational`
- [x] Every shadcn tier-1 component generated and verified — 22 of 22. The
      other twelve tier-1 components are AI Elements, which is M4.
- [x] `mix ui.add` copies components into a host application with a version stamp
- [x] `mix ui.sync` reports upstream drift and refuses to overwrite edited files
- [x] Icon set is configurable — `lucide_icons` by default, since shadcn's
      `IconPlaceholder` already names five sets

**Exit:** a scratch Phoenix app runs `mix ui.add button dialog select`, the
three components compile under its own namespace, and each renders with the
contract it was generated with. ✅

42 components verified in all, by 118 browser tests.

### Where the reader got to

53 of the 62 shadcn components read into a spec. The nine that do not are not
gaps in the reader:

| Component | Built on |
|---|---|
| `calendar` | react-day-picker |
| `carousel` | embla-carousel |
| `chart` | recharts |
| `command` | cmdk |
| `input-otp` | input-otp |
| `resizable` | react-resizable-panels |
| `message-scroller`, `questionnaire` | `@shadcn/react` |
| `sidebar` | its own state machine, several returns deep |

None of them is a Base UI component, so none has a data-attribute contract to
generate against. They are the specialist recipes M6 already schedules, and the
reader says so by name rather than failing obscurely.

### What the reader had to learn

Two things the accordion never showed:

**Variants are data.** shadcn writes them as a `cva` table — which variants
exist, what each is called, which is the default, what class string each
carries. The spec records all four, so `<.button variant="destructive">` gets
its `values:` list from upstream rather than from somebody retyping it.

**A `.tsx` says more than markup.** `render={<a />}`, `useRender`, ternaries,
`??`, conditional children, `.map` over a list, style objects, and references to
other components in the same registry all appear. Each is a decision the
generated component has to make too, so each became a node in the spec rather
than something dropped.

**Four hooks, and no more.** That is what the architecture reserved, and every
recipe since has fitted in them. M1 added measurement and transition timing, and
both went inside the hooks that already existed rather than beside them:

| Hook | Used by | Because |
|---|---|---|
| `Disclosure` | accordion, collapsible | a height only the browser can compute |
| `Overlay` | dialog, alert dialog, sheet | scroll lock, focus containment, timing |
| `Floating` | popover, tooltip, menu, select | where a popup lands is a measurement |
| `Roving` | tabs, menu, select | `phx-key` filters one key, and there are four |

`Disclosure`, `Floating` and `Overlay` all show and hide something that
animates, so the four steps that takes live in one shared module rather than in
three hooks, each getting them slightly wrong.

Everything else — every attribute a class string reads, every open and close,
every choice — is a `Phoenix.LiveView.JS` command. No click reaches the server
unless the caller asked for one.

**One hook, two behaviours, one attribute.** Arriving at a tab shows its panel;
arriving at a menu item does not choose it. The same roving hook does both, told
which by `data-lb-activate`. That is the boundary the hooks are held to: they
decide *which* element, never *what happens to it* — what happens is the `JS`
command already on that element.

**A form control is a form field.** Base UI publishes one attribute contract for
every control it has — `data-checked`, `data-invalid`, `data-required`,
`data-filled` — and `Phoenix.HTML.FormField` already carries every fact it
needs. So `<.checkbox field={@form[:subscribe]} />` is the whole API, and the
recipe's job is only to join the two.

Three things that took a browser to get right, and each one is now a test:

- a `<label for>` cannot name a `<span role="checkbox">`, because a label names
  a *labelable* element and that is not one
- a radio is not a round checkbox: choosing one is choosing instead of the
  others, and its hidden input is `type="radio"` so the browser enforces that too
- `role` comes from the Base UI module, not from the shape. A radio announced as
  a checkbox is worse than one not announced at all.

---

## M3 — Publish 0.1.0

- [ ] `live_base` and `live_shadcn` on hex — both build and pass `hex.publish
      --dry-run`; a `v*` tag runs the checks again and publishes them in
      dependency order. Nothing is tagged yet.
- [ ] Storybook deployed, one public URL — the image builds, serves, and
      carries the styling layer. Nothing is deployed yet.
- [ ] Sync bot proves itself: one real upstream change lands as a pull request
      whose diff is readable — the run itself works and has been done by hand.
      What it has not done is open a pull request, because nothing is pushed.
- [x] `CONTRIBUTING.md` explains how to add a recipe

**Exit:** somebody who is not us installs it from hex and it works.

Every remaining box needs an account rather than more code: a hex API key, a
Cloudflare token, and a push. `storybook/deploy/README.md` says what to set.

### What preparing to publish found

Publishing is the first time the work is looked at from outside, and four things
did not survive that look. Each was in a part nobody had run.

**A name is not an identity.** Upstream has a `message` in the shadcn registry
and a different `message` in AI Elements. Every stage keyed its files on the
name alone, so they shared one spec and one verification entry, and the
inventory reported the AI Elements one as verified on the strength of a browser
run against shadcn's. A derived status that is wrong is worse than a typed one.
A component is now `{source, name}` everywhere, which is also what M4 needs to
land 49 AI Elements components in their own package.

**The pre-commit hook was editing generated files.** It stripped a trailing
space from a generated `@moduledoc` and normalised the end of every snapshot.
Both are files `mix ui.gen --check` compares byte for byte, so the next run
failed with no visible cause. The fixers now exclude everything a pipeline
stage writes — and the generator no longer emits the trailing space that
invited the edit.

**The image had never been built.** The Dockerfile pinned
`hexpm/elixir:1.20.3-erlang-29.0.1-debian-bookworm-20250630-slim`, which Docker
Hub does not publish, and an empty `GITHUB_TOKEN` sent `Bearer` with nothing
after it, which is a 401 rather than a lower rate limit. Both are fixed, and the
image now builds, serves, and carries the styling layer.

**The sync bot would have cried wolf every week.** Running it by hand found two
files whose digests changed on every fetch. shadcn's index points a component
at whatever documents it, and for one built on a React library that is the
library's own site — so the fetcher was storing GitHub repository pages as Base
UI contracts, and GitHub embeds a fresh token in every page it serves. A weekly
pull request that says nothing changed is a pull request nobody reads, and then
the one that matters is not read either.

That one has a second lesson. The secret scanner had been reporting those
tokens all along, and the scan was widened to ignore the directory rather than
asked why source files had tokens in them. The directory is scanned again now,
and it is clean: a finding there means the fetcher brought back a web page, and
the fix is in `mix ui.fetch`.

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
  pipeline has a gap. Fix the pipeline. This covers the style sheets as well as
  the class strings: both are fetched, and neither is retyped.
- **No model in the daily loop.** A model may draft a new recipe once. A person
  reviews it and it is then frozen.
