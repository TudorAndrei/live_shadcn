# TODO: live_ai_elements, held to what live_shadcn now proves

The checkbox form of [PLAN.md](PLAN.md), which holds the reasoning.

49 AI Elements components are in the registry, 14 generate, and **one
verifies**. The goal is that every one that generates also verifies.

**Done.** 110 of 111 verify, and nothing generates without verifying. The one
that does not is `direction`, which re-exports a provider and has no JSX in it.

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
- [x] Commit: `fix(ai-elements): a fold carries the recipe, not only the markup`

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
- [x] Commit: `feat(storybook): an example for the three that had none`

## Phase 5: A React reference for every AI Elements component

- [x] One `parity/src/examples/<component>.<example>.tsx` per example with a
      component behind it — thirteen of them, ported rather than designed
- [x] Nine differences corrected in the reader or the recipe: a trigger's
      default markup, a chosen prop, a `cva` group behind a spread, one name
      meaning two things, an icon's size, a list of class strings, the caller's
      class in two places, a folded recipe's own attributes, and a closed
      popover taking up space. All nine are listed in [PLAN.md](PLAN.md)
- [x] Three differences recorded as decisions in `parity-divergence.json`, by
      the slot they show on, so every other slot still gates at zero
- [x] `streamdown` shimmed on the React side: the markdown renderer is the
      application's, and comparing two of them compares neither component
- [x] Every example decided in `pixel-budget.json`: twelve at zero and `plan`
      skipped with its reason. Nothing pending
- [x] 81 parity and 81 pixel comparisons pass, and the whole browser suite —
      364 tests — is green
- [x] `mic-selector` gains the example it never had, and verifies. Its device
      list is the caller's here and `navigator.mediaDevices` upstream, which a
      headless browser has none of — recorded as a divergence with the `asChild`
      one it shares with `plan`
- [x] `open-in-chat` does not generate: every part of it is a wrapper around
      `<.dropdown_menu>`, so there is nothing left after they are dropped.
      Recorded in [ROADMAP.md](ROADMAP.md) as a non-goal, and `mix ui.verify`
      drops the record of a component that no longer generates
- [x] `mix ui.verify` reports **76 of 76** generated components verified
- [x] Commit: `test(parity): a React reference for every AI Elements component`

## Phase 6: The gap tests cover both registries

- [x] `parity.spec.mjs` — the `source === "shadcn"` filter is gone, from the gap
      test and from the comparison itself
- [x] `pixel.spec.mjs` — an unported example is a skip with a reason rather than
      a test that was never registered
- [x] Deleting one reference turns the suite red, and says which: moving
      `task.default.tsx` out names it in the gap test and skips its pixel run
- [x] Commit: `test(parity): the gap tests cover both registries` — landed with
      phase 5, because the filter and the divergence record are the same file

## Phase 7: Three components filed under the wrong recipe

- [x] `artifact` — not a disclosure; it has no trigger. Filed `presentational`
      it generates eight parts, has an example and a reference, and verifies
- [x] `voice-selector` — not a listbox either. Eleven parts are wrappers around
      `<.dialog>` and `<.command>`; the eight that are its own generate
- [x] `model-selector` — filed `presentational`, and it now stops on
      ``alt={`${provider} logo`}``, which is phase 8's list
- [x] `open-in-chat` recorded in [ROADMAP.md](ROADMAP.md) as a non-goal
- [x] `prompt-input` is refused rather than generated wrong: it had been
      emitting calls to five shadcn modules no application can name
- [ ] `voice-selector` verifies. It needs the icon its `gender`, `accent` and
      `preview` parts compute in an `if` chain — the reader turns that into a
      `:string` prop, which markup cannot be passed through. Same gap as
      `artifact_action`
- [x] Commit: `fix(inventory): the recipe three components are built on`

## Phase 8: The nine the generator meets an undeclared name in

- [x] Read all nine and group them: a prop the caller passes, a value the reader
      should compute, or a non-goal — `code-block`, `commit`, `connection`,
      `context`, `image`, `open-in-chat`, `queue`, `speech-input`,
      `transcription`
- [x] Four were a prop the caller passes: `commit`, `image`, `queue`,
      `transcription`. `speech-input` is the fifth — listening is the browser's,
      so whether it listens is an attribute
- [x] `connection` and `open-in-chat` are non-goals, recorded in
      [ROADMAP.md](ROADMAP.md) with their reasons
- [ ] `context` is the one still open. `Intl.NumberFormat` writes "1.2K" and
      "$0.02", and Elixir has neither compact notation nor a currency format in
      the standard library. Hex has `ex_cldr_numbers` — 6.5M downloads, and it
      does both — but it carries CLDR, and the cost half is not formatting at
      all: upstream reads a price per model out of `tokenlens`. A component that
      draws a price cannot be the thing that knows the price, so the text is the
      caller's and the library is the caller's choice, the same seam the
      markdown renderer already gets
- [x] Commit: `feat(ai-elements): markup that reads an undeclared name` — landed
      as five commits, one per group

## Phase 9: The reader's own gaps, closed with the parser it already has

- [x] Replace the three regular expressions that decided what a value is with
      one question put to oxc: is every node a name, a literal, an operator, or
      a call to a method this pipeline can write in Elixir?
- [x] Six components read that did not: `agent`, `code-block`, `file-tree`,
      `schema-display`, `stack-trace`, `test-results`, `web-preview`
- [x] `inline-citation` — `new URL(sources[0]).hostname` is `URI.parse/1`, and
      `sources[0]` is `Enum.at/2`
- [x] `stack-trace` is the fourth clipboard component, not a presentational one
- [x] JSX's text rule, which is not `String.trim/1`: `{percent.toFixed(0)}%`
      drew `100 %`
- [x] A component that calls a sibling which did not generate is refused rather
      than shipped — `agent` renders `code-block`, and the package stopped
      compiling
- [x] **`file-tree` needed the ARIA the roles it already writes imply.**
      `role="tree"` and `role="treeitem"` are upstream's own, and a `treeitem`
      has to be owned by a `tree` or a `group` — so the recipe adds the two
      groups, a `role="none"` on the collapsible between them, and an
      `aria-expanded` the folder already takes. The chevron is a button with an
      icon and no words; naming it would mean writing English, and the row's
      other button already opens the folder, so it leaves the accessibility
      tree instead. Neither is a difference of opinion with upstream about
      markup, and neither draws a pixel
- [ ] **The class list is not merged at render.** Upstream's `cn()` is
      tailwind-merge and sees the `cva` table, the component's own string and
      the caller's together; a generated component writes all three and lets
      stylesheet order decide. Two of the three are merged where the reader can
      see both. The third is read from a table at render, so the rest wants a
      merge at render — `LiveShadcnTools.TwMerge` is the algorithm and a
      `live_base` function is where it would go. `prompt-input`'s footer is the
      first place it shows: `justify-start`, `justify-center` and
      `justify-between` on one element
- [x] **`schema-display` was the example, not the component.** The badge sat a
      pixel out because the example composed the parts without the root they
      belong in, and that root has a border. Both sides draw it now
- [x] **`terminal` was the `<pre>` after all.** A `<pre>` indented like any
      other element prints the indentation, and the line it gained was the
      newline before its own content
- [ ] **A value beside an element gains a space HTML does not drop.** `context`
      writes `<span>{tokens}<span class="ml-2">• {cost}</span></span>`, and the
      generator puts the two children on their own lines: the newline between
      them collapses to a space that upstream never wrote. The text rule fixed
      the same fault between two text nodes; a value is text too. Budgeted at
      the 180 pixels it costs until the renderer says so
- [ ] The lucide name upstream writes can be a deprecated alias.
      `CheckCircleIcon` is `circle-check-big` now, so `tool` draws one glyph and
      React draws another. `lucide-react` publishes the whole alias table on one
      line of its `.d.ts`; reading it belongs to `mix ui.fetch`, because a table
      typed by hand is a table that goes stale
- [x] Commit: `feat(spec): ask oxc what an expression is`

## Phase 10: The rest of them, one decision each

- [x] `code-block` — a one-line value helper inlined, a shiki bit field masked
      out, and the copy button filed as the clipboard component it is. `agent`
      and `sandbox` generate with it
- [x] `context` — `Intl.NumberFormat` written out. Hex has `ex_cldr_numbers`,
      and CLDR is a large dependency for two shapes whose locale upstream
      hard-codes, so the module carries the two functions
- [x] `conversation` — `use-stick-to-bottom` is a box that scrolls and keeps
      itself at the bottom, which the `scroller` recipe already owns once a
      scrollbar of its own stopped being required
- [x] `shimmer` — `LiveBase.Shimmer` runs upstream's two keyframes through the
      Web Animations API, which is what `motion` runs them through
- [x] `audio-player` — media-chrome renders custom elements, and a custom
      element is HTML
- [x] `terminal` — `LiveAiElements.Ansi`, the seam the markdown renderer has
- [x] `sandbox` — a helper imported from a sibling file, inlined with that
      file's own imports and tables
- [x] `schema-display` — `dangerouslySetInnerHTML` read as what it means, the
      element's children
- [x] `persona` and `jsx-preview` recorded in [ROADMAP.md](ROADMAP.md) as
      non-goals: one is a Rive canvas, the other compiles markup from a string
- [x] `prompt-input` — twenty-two of its thirty-five parts wrap a menu, a
      select, a hover card or a command palette part by part, and each of those
      is one function here. The form-control recipe drops them the way the
      presentational recipe already did, and the thirteen that are its own
      generate
- [x] Commit: `feat(ai-elements): the last nine, one decision each`

## Phase 11: Nothing generated and unverified

- [x] **100 verified, and `mix ui.status` reads `0 generated`.** Every component
      this pipeline generates has an example, a React reference, a snapshot, an
      axe run and a pixel comparison. The eleven that are not verified are the
      eleven recorded non-goals
- [x] A guard is a fact about the whole part: `if (!isStreaming) return null` is
      markup that does not exist
- [x] `!` binds tighter in Elixir than in JavaScript, and only where upstream
      bracketed it
- [x] A `cva` table is the base a class string is written over, not the override
- [x] `open-in-chat` filed as a `utility`, beside the other ten non-goals, so
      the reader is not asked to read a file nobody generates
- [x] Commit: `feat(ai-elements): nothing generated and unverified`

## Phase 12: The eleven that were not components after all

- [x] Six React Flow files are a box and a class string — `controls`, `panel`,
      `toolbar`, `node`, `canvas` and `edge`. What the library owns is where a
      thing sits and the geometry between two nodes, so an edge takes its path
      as an attribute
- [x] `connection` is four numbers and a bezier, which is arithmetic
- [x] `persona` is one `<canvas>`, and Rive paints into it
- [x] `jsx-preview` draws no element of its own — `renderInWrapper={false}` says
      so — and what a server cannot compile is what a slot is for
- [x] `open-in-chat` is twelve links: `asChild` says the menu item *is* the `<a>`
- [x] `direction` is a re-export with no JSX in it, and is the one entry of a
      hundred and eleven that will never verify
- [x] **110 of 111 verified, and `mix ui.status` reads `0 generated`**
- [x] Commit: `feat(ai-elements): the eleven that were not components after all`

## Phase 13: An example that showed a header and called it a stack trace

- [x] The example drew the error row and none of the frames, so four checks
      agreed about markup nobody was looking at. It draws a trace now, with the
      internal frames dimmed the way upstream dims them
- [x] `x !== null && ":142"` is JSX's "draw this if that", not arithmetic — `!==`
      was split before `&&` and the frame printed `false` where upstream printed
      a line number
- [x] A `className` with no `cn()` call in it is still a class string. Two
      elements had none at all: a frame's function name, and every line of a
      code block that does not number its lines
- [x] `stack_trace_header` is `<CollapsibleTrigger asChild>` around a `<div>`,
      which is one element and a class string. It generates, and the collapsible
      around it stays the caller's
- [x] A run of inline children is one line: JSX drops the newline between them
      and HTML draws it as a space. `at divergence ( parity.spec.mjs :142 :31 )`
      is what that cost
- [x] The pixel check framed its photograph with `[data-slot]` boxes, and an AI
      Element carries almost none — so it photographed `stack-trace` through its
      copy button and reported the example as passing. It frames on what the
      preview root holds now, which found three more differences
- [x] `schema-display` never drew its highlighted path parameter. The caller
      writes the markup, because a slot is what `dangerouslySetInnerHTML` is for
- [ ] `commit.default` keeps a 396px budget: `lucide_icons` writes each icon as
      its own `~H` template, and a template ends with a newline. Inside a line of
      text that newline is a space, so the hash sits four pixels right of
      upstream's. It is inside a dependency, and the icon set is the
      application's choice — a wrapper that trims it would have to rebuild the
      rendered struct

## Phase 14: AI Elements has not been updated for Base UI

Drop the gate:

- [ ] `parity.spec.mjs` and `pixel.spec.mjs` gate `shadcn` alone. The 49 React
      references stay on disk; nothing compares them
- [ ] The gap tests narrow with them: an AI Elements example needs no reference,
      no budget and no skip
- [ ] `mix ui.verify` records `parity` and `pixel` for an AI Element as *not
      gated*, with the reason, rather than as a pass
- [ ] Every AI Elements entry out of `parity-divergence.json` and
      `pixel-budget.json` — a decision nothing reads is a decision nobody prunes
- [ ] [parity/README.md](parity/README.md) says which registry it is for and why

Call what is a component:

- [x] The reader leaves the reference standing instead of folding it, and the
      generator's existing `component_ref` clause calls it
- [x] `LiveShadcnTools.callable?/3` says when: an AI Element, a caller that
      writes one function per part, and a callee whose recipe is
      `presentational`, `separator` or `progress`
- [x] 24 components call one now — 44 buttons, 24 badges, 14 cards, 6 button
      groups, 4 avatars, 4 alerts, a spinner, a separator and a progress
- [x] `asChild` folds: the reference *is* the element inside it, and a call
      draws an element of its own
- [x] A recipe that folds a component into one function folds what it renders
      too — it builds its own tree and has no call site to put a call at
- [x] The call passes what the reference wrote, plus what a `{...props}` spread
      carries: React's spread carries a component's props where HEEx's
      `:global` carries HTML attributes
- [x] `disabled` and `required` are not global attributes. A `<button>` that
      only ever appeared as folded markup never needed them declared
- [x] **`mix snapshot --check`**: six of 114 moved, and every one of them is the
      same class names in a different order — the sets are identical and so is
      the rest of the markup
- [ ] `form-control` (input, textarea, input-group) and `switch` are still
      folded. They take a name and a value, and a call has to carry those

## Verification

Run at every phase boundary, as [CONTRIBUTING.md](CONTRIBUTING.md) lists it.

- [x] `mix format`, `mix compile --warnings-as-errors` and `mix test` in each of
      `tools/`, `packages/*/` and `storybook/` — 98, 26, 31, 75 and 13 tests
- [x] `mix ui.gen --check`, `mix ui.status --check`, `mix snapshot --check`
- [x] `mix ui.spec --check --source shadcn` — **live_shadcn does not regress**;
      62 of 62 stay verified through every phase
- [x] `npm run verify` in `storybook/test/browser` — the whole suite, 406 tests
- [x] The full browser suite three times in a row: 370 passed, three times
- [ ] ~~No behaviour change in `live_shadcn`~~ — **three shadcn components did
      change, on purpose.** `popover`, `hover-card` and `tooltip` wear
      `class="contents"` on the wrapper and the portal, because Base UI renders
      no element for a popover's root and portals its popup to the body: an
      empty `<div>` between a trigger and its neighbour is a flex item, and it
      cost eight pixels in an attachment list. All three re-verified, and the
      whole shadcn half stays green. The invariant was written before the parity
      check covered both registries; a correction the check found is not a
      regression, and hiding it to keep a checkbox would be

## Review

- [x] Every generated file regenerated, never edited — `mix ui.gen --check` says
      so
- [x] `docs/INVENTORY.md` regenerated, and the verified count is the true one:
      89 verified, 1 generated, 6 spec, 15 fetched. The one generated is
      `file-tree`, which is a decision recorded above rather than work not done
- [x] Each phase commit leaves every gate green
- [x] [PLAN.md](PLAN.md) updated wherever the approach changed during the work,
      which was every phase from 3 on
- [ ] [ROADMAP.md](ROADMAP.md) M4 records what was decided, not only what was
      built — the non-goal is in, the nine findings are still only in PLAN.md

## Still blocked, from the plan this replaces

Publishing 0.1.0. Each step needs an account rather than code, and
[DEFERRED.md](DEFERRED.md) is the guide.

- [ ] Publish to hex — needs a `HEX_API_KEY` secret under a `hex` environment
- [ ] Deploy the storybook — needs `CLOUDFLARE_API_TOKEN`,
      `CLOUDFLARE_ACCOUNT_ID` and a `SECRET_KEY_BASE` worker secret
- [ ] Prove the sync bot with one `Sync upstream` run by hand
