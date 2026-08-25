# TODO: live_ai_elements, held to what live_shadcn now proves

The checkbox form of [PLAN.md](PLAN.md), which holds the reasoning.

49 AI Elements components are in the registry, 14 generate, and **one
verifies**. The goal is that every one that generates also verifies.

## Phase 1a: Two props the reader made and then filtered back out

Neither `text` nor `showValues` needed a decision. `props_read/2` keeps only the
params something in the markup reads, and neither reaches the tree as a name.

- [x] A field read off a React context is recorded as `context_fields` and
      counts as a read — `{question.text}` mentions `question`, never `text`
- [x] A conditional class records the identifiers of its condition, as every
      other expression in the spec already does
- [x] `question` generates
- [x] `carousel` and `sidebar` gain an `orientation` param for the same reason.
      **Neither component changes** — `ui.gen --check` green, snapshots
      unmoved — and both are re-verified
- [x] A test for each gap, in `spec_test.exs` and `ast_test.exs`
- [x] Commit: `fix(spec): a prop read through a context or a condition`

## Phase 1b: `isCopied`, and a choice the client owns

`snippet` and `environment-variables` stop on the same name and the same shape:
`const Icon = isCopied ? CheckIcon : CopyIcon`. The reader reads it; the
generator can only render a choice the **server** decides.

- [x] A choice whose condition a recipe declares client-owned renders both
      branches, each marked with the state it belongs to, the inactive one
      `hidden` — which `measure.mjs` already skips, so parity reads the two
      pages as the same page
- [x] `LiveBase.Clipboard` and its hook, beside `LiveBase.Toast`. Built, not
      depended on: the clipboard is a browser API, and `live_base` takes one
      dependency by a non-goal
- [x] `JS.ignore_attributes`, so a patch does not put the server's guess back
- [x] Not an assign: that costs a round trip and a server-side timer per copy,
      and makes the caller write `handle_event` for a 2-second icon swap
- [x] The `clipboard` recipe, for the two components that are presentational
      everywhere except one button. What it copies is a prop, because React
      reads it off a context in a callback and HEEx has no context
- [x] `snippet` and `environment-variables` generate, and `snippet` is
      re-verified against a re-ported React reference
- [x] `snippet.spec.mjs`, which found both bugs a snapshot cannot: `hidden` is
      `HTMLElement`'s and both branches are an `<svg>`, and a connected socket
      is not a mounted hook (`data-lb-ready`)
- [x] Commit: `feat(ai-elements): a choice the client owns, and the clipboard`

## Phase 2: Re-read every AI Elements spec, and gate the reading

- [x] `mix ui.spec --source ai_elements`, then `mix ui.drift` — 22 specs moved:
      18 attributes, 46 class strings, 34 parts, 12 variants, over nine
      components
- [x] `mix ui.gen` and `mix snapshot` — one snapshot moves, and it is a
      correction: `package-info`'s badge writes shadcn's `data-variant`
- [x] `mic-selector` generates, with no work of its own
- [x] `confirmation` loses three parts that always rendered their children and
      upstream renders only in one state. Phase 3's question, asked about a
      context
- [x] `mix ui.verify` for every component whose spec digest moved
- [x] `mix ui.spec --check --source ai_elements` in the `reader` job of
      `.github/workflows/ci.yml`, as a second gate beside the shadcn one — one
      per library, so neither hides behind the other
- [x] Commit: `fix(spec): re-read every AI Elements spec, and gate it in CI`

## Phase 3: A fold that carries behaviour, not only markup

- [x] `attachments` — the three hover-card wrappers are dropped rather than
      folded, and the moduledoc says to compose `<.hover_card>`. A wrapper
      around a component whose recipe folds has nothing to wrap, which is what
      `menubar` already says; `LiveShadcnTools.carries?/2` decides it
- [x] `plan` — no `<button>` inside a `<button>`. `asChild` is one element, and
      the reader knew the fact under Base UI's name for it. `checkpoint` and
      `mic-selector` had the same nesting from the same cause
- [x] `environment-variables` — the toggle has `role="switch"`, `tabindex` and
      `aria-checked`, and pushes `on_toggle`, because the value it reveals is a
      secret and the server owns it
- [x] `show_values` is a `:boolean`: a context field's type is in the context's
      interface, and the reader read type aliases but not interfaces
- [x] axe is clean on all three preview pages, once phase 4 gave them one
- [ ] Commit: `fix(ai-elements): a fold carries the recipe, not only the markup`

## Phase 4: An example for the three that have none

- [x] `Examples.attachments_default/1`, `environment_variables_default/1`,
      `plan_default/1`, each listed in `components/0` and `all/1`
- [x] The attachments example composes the application's own `<.hover_card>`,
      which is what phase 3 said a caller would do. Aliased, not imported:
      `LiveShadcn.UI.Attachment` exports an `attachment/1` too
- [x] `show_values` is an assign and the switch pushes an event, so the preview
      LiveView answers `toggle_values` — one round trip per reveal
- [x] A browser suite for the two that behave, in the shape of `task.spec.mjs`
- [x] `mix snapshot` and the axe run green for all three
- [x] Their record shows two failures rather than four — `parity` and `pixel`
      only, which phase 5 closes
- [ ] Commit: `feat(storybook): an example for the three that had none`

## Phase 5: A React reference for every AI Elements component

- [ ] One `parity/src/examples/<component>.<example>.tsx` per generated
      component, ported from its `Examples` function — a port, not a second
      design
- [ ] Every reported difference corrected in the reader or the recipe, never in
      the reference
- [ ] Every example decided in `pixel-budget.json`: gated at zero, a measured
      budget, or a skip with its reason. Nothing left pending
- [ ] `mix ui.verify` reports every generated AI Elements component verified
- [ ] Commit: `test(parity): a React reference for every AI Elements component`

## Phase 6: The gap tests cover both registries

- [ ] `parity.spec.mjs` — drop the `source === "shadcn"` filter on *every
      example has a React reference*
- [ ] `pixel.spec.mjs` — an unported example is named, not skipped
- [ ] Deleting one reference turns the suite red, and says which
- [ ] Commit: `test(parity): the gap tests cover both registries`

## Phase 7: Three components filed under the wrong recipe

- [ ] `model-selector` and `voice-selector` — a command dialog, not a listbox
- [ ] `artifact` — not a disclosure; it has no trigger
- [ ] Each re-filed in `registry/INVENTORY.json` or recorded in
      [ROADMAP.md](ROADMAP.md) as a non-goal with its reason
- [ ] Commit: `fix(inventory): the recipe three components are built on`

## Phase 8: The nine the generator meets an undeclared name in

- [ ] Read all nine and group them: a prop the caller passes, a value the reader
      should compute, or a non-goal — `code-block`, `commit`, `connection`,
      `context`, `image`, `open-in-chat`, `queue`, `speech-input`,
      `transcription`
- [ ] Where one wants work a library would really do — syntax highlighting for
      `code-block`, an audio meter for `speech-input` — search hex first and
      record what was found, either way. A bare browser API is not that question
- [ ] Land the groups, splitting this phase per group and updating
      [PLAN.md](PLAN.md) when it splits
- [ ] Commit: `feat(ai-elements): markup that reads an undeclared name`

## Verification

Run at every phase boundary, as [CONTRIBUTING.md](CONTRIBUTING.md) lists it.

- [ ] `mix format`, `mix compile --warnings-as-errors` and `mix test` in each of
      `tools/`, `packages/*/` and `storybook/`
- [ ] `mix ui.gen --check`, `mix ui.status --check`, `mix snapshot --check`
- [ ] `mix ui.spec --check --source shadcn` — **live_shadcn does not regress**;
      62 of 62 stay verified through every phase
- [ ] `npm run verify` in `storybook/test/browser` — the whole suite, not the
      one component in hand
- [ ] The full browser suite three times in a row after any phase that touches a
      spec file. Two of this repository's timing bugs only opened under load
- [ ] No behaviour change in `live_shadcn`: `registry/snapshot/*.html` shows no
      diff for any shadcn component in phases 1 to 8

## Review

- [ ] Every generated file regenerated, never edited — `mix ui.gen --check` says
      so
- [ ] `docs/INVENTORY.md` regenerated, and the verified count is the true one
- [ ] Each phase commit leaves every gate green
- [ ] [PLAN.md](PLAN.md) updated wherever the approach changed during the work
- [ ] [ROADMAP.md](ROADMAP.md) M4 records what was decided, not only what was
      built

## Still blocked, from the plan this replaces

Publishing 0.1.0. Each step needs an account rather than code, and
[DEFERRED.md](DEFERRED.md) is the guide.

- [ ] Publish to hex — needs a `HEX_API_KEY` secret under a `hex` environment
- [ ] Deploy the storybook — needs `CLOUDFLARE_API_TOKEN`,
      `CLOUDFLARE_ACCOUNT_ID` and a `SECRET_KEY_BASE` worker secret
- [ ] Prove the sync bot with one `Sync upstream` run by hand
