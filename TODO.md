# TODO: live_ai_elements, held to what live_shadcn now proves

The checkbox form of [PLAN.md](PLAN.md), which holds the reasoning.

49 AI Elements components are in the registry, 14 generate, and **one
verifies**. The goal is that every one that generates also verifies.

## Phase 1: The three state keys the generator cannot bind

Each stops the generator the moment its spec is re-read, and every later phase
is behind them.

- [ ] `LiveBase.Clipboard` and its hook, beside `LiveBase.Toast`. Built, not
      depended on: the clipboard is a browser API, and `live_base` takes one
      dependency by a non-goal
- [ ] `snippet` — `isCopied` is the hook's, not a prop. The copy button gets the
      attribute contract the hook writes
- [ ] `question` — `text` is an attribute the caller passes
- [ ] `environment-variables` — `show_values` is an attribute and the switch
      pushes an event. **The real value is only sent once it is asked for**: it
      masks by changing text, and a server that rendered it and hid it with CSS
      would put every secret in the page source
- [ ] `environment-variables` keeps a real switch, not a bare toggle — which
      makes this and phase 3 one change for that component
- [ ] `mix ui.spec ai_elements/{question,snippet,environment-variables}` then
      `mix ui.gen` generates all three, rather than removing them
- [ ] Commit: `feat(ai-elements): the three state keys the generator refused`

## Phase 2: Re-read every AI Elements spec, and gate the reading

- [ ] `mix ui.spec --source ai_elements`, then `mix ui.drift` — say what moved
      before regenerating anything
- [ ] `mix ui.gen` and `mix snapshot`
- [ ] `mic-selector` generates, with no work of its own
- [ ] `mix ui.verify` for every component whose spec digest moved
- [ ] `mix ui.spec --check --source ai_elements` in the `reader` job of
      `.github/workflows/ci.yml`, as a second gate beside the shadcn one — one
      per library, so neither hides behind the other
- [ ] Commit: `fix(spec): re-read every AI Elements spec, and gate it in CI`

## Phase 3: A fold that carries behaviour, not only markup

- [ ] `attachments` — `align` and `side` reach the popover recipe instead of
      landing on an element as attributes (`attachments.ex:186`)
- [ ] `plan` — no `<button>` inside a `<button>`
- [ ] `environment-variables` — the toggle has `role="switch"`, `tabindex` and
      `aria-checked`, and is the switch phase 1 kept rather than a bare toggle
- [ ] axe is clean on all three preview pages
- [ ] Commit: `fix(ai-elements): a fold carries the recipe, not only the markup`

## Phase 4: An example for the three that have none

- [ ] `Examples.attachments_default/1`, `environment_variables_default/1`,
      `plan_default/1`, each listed in `components/0` and `all/1`
- [ ] A browser suite for the two that behave, in the shape of `task.spec.mjs`
- [ ] `mix snapshot` and the axe run green for all three
- [ ] Their record shows two failures rather than four — `parity` and `pixel`
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
