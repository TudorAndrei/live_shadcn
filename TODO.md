# To do

The checkbox form of [PLAN.md](PLAN.md), which holds the reasoning. Scope is
shadcn only. The phases are in order: each one makes the next one checkable.

## Phase 1 — Land the toast

- [x] Run `storybook/test/browser/toast.spec.mjs` and the axe check for
      `/preview/toast/default`
- [x] Set `data-limited`, or give the toaster a `limit` attribute
- [x] `mix ui.verify shadcn/toast` passes all four checks
- [x] Commit the toast: recipe, hook, `LiveBase.Toast`, generated module,
      example, suite, snapshot
- [x] Commit the `aria-disabled` assertion fix in `accordion_test.exs`
      separately
- [x] Commit `Examples.page_assigns/0` separately

## Phase 2 — Make "verified" mean something again

- [x] `npm run build:css` in `storybook/assets` first
- [x] `mix ui.spec` → `mix ui.gen` → `mix snapshot` → `mix ui.verify`
- [x] Commit the new `registry/VERIFY.json` and `docs/INVENTORY.md`
- [x] Add a storybook example for `toggle-group` — the one real gap
- [x] `CONTRIBUTING.md` says three checks; it makes four
- [x] `mix ui.status --check` passes on a clean tree

## Phase 3 — The parity backfill

- [x] Port the 51 shadcn examples with no reference to
      `parity/src/examples/*.tsx`, oldest-generated first
- [x] Correct every reported difference in the reader, never in the reference
- [x] Every shadcn example has a reference
- [x] Every comparison passes

## Phase 4 — Teach the reader `data-[attr=value]`

- [x] Make `classify/1` refuse an unknown variant instead of ignoring it
- [x] Give `reads/1` a place for a value, not only a name
- [x] Update the seven `["reads", "self"]` consumers and each recipe's
      `attribute!` table
- [x] No variant is dropped in silence
- [x] Read the list step one produces, then plan step three separately

## Phase 5 — The ten components that are left

### 5a — One reader change unblocks five

- [x] A primitive-to-recipe table beside `@external_roles`
- [x] `command` (`listbox`)
- [x] `sonner` (`toast`)
- [x] `input-otp` (`form-control`)
- [x] `message-scroller` (`scroller`)
- [x] `questionnaire` (`presentational`)

### 5b — One recipe, spec already written

- [x] `carousel` recipe on CSS scroll-snap

### 5c — Three that need a real decision

- [x] `resizable` — a pointer-drag hook that writes a CSS variable
- [x] `calendar` — a month grid the server computes. `locale` and
      `week_starts_on` are props, English and Sunday by default
- [x] `calendar` — `locale="browser"` opt-in: a hook reads `Intl` on mount
- [x] `chart` — port the chrome: container, style block, tooltip body, legend
      body. The plot is the caller's slot, upstream as much as here

### 5d

- [x] Record `direction` in the roadmap as a utility, not a gap

## Phase 6 — Publish 0.1.0

- [x] Push to GitHub
- [ ] Publish to hex — needs a `HEX_API_KEY`
- [ ] Deploy the storybook — needs a Cloudflare token
- [ ] Prove the sync bot with one run by hand

## Phase 7 — Close what the backfill left open

### 7a — Three gates are red at HEAD

- [x] `mix ui.gen` — regenerated seven stale components: `shadcn/input`, `input-group`,
      `questionnaire`, `sidebar`, `ai_elements/chain-of-thought`, `checkpoint`,
      `snippet`
- [x] `mix snapshot` — regenerated `chain-of-thought-default`
- [x] Delete the unused `navigation-menu` recipe. It was 141 lines, no
      component names it, and `LiveShadcnTools.GenTest` fails on it
- [x] All three gates green: `mix ui.gen --check`, `mix snapshot --check`,
      `mix test` in `tools/`

### 7b — Stop retyping upstream class strings

- [ ] Ten recipe files hold literal `cn-` strings: `pagination` 16,
      `navigation_menu` 8, `calendar` 4, `carousel` 4, `chart` 2,
      `form_control` 2, `resizable` 2, `slider` 2, `toast` 1
- [ ] `gen/toast.ex` is a hand-written `~H` template. Return it to rendering
      the spec's parts; `class="cn-toast"` drops the whole `h-(--height)` and
      `[transform:…]` stack upstream wrote
- [ ] For each retyped string, record the fact in the spec instead

### 7c — A recipe is not a patch on another recipe's output

- [ ] `String.replace` over generated source went 26 → 48. Move each patch into
      the spec, or say why it is behaviour and belongs in a recipe
- [ ] `gen/resizable.ex` has eight, two of which inject `attr` declarations
- [ ] Retire the one-component recipes that exist only to hold a patch:
      `checkbox`, `separator`, `switch`, `radio_group`, `progress`
- [ ] Correct the recipe count in `ROADMAP.md:69` and `docs/INVENTORY.md:17`.
      Both still say eight; there are 24

## Phase 8 — Finish the oxc swap

- [ ] 8a — Carry expression **nodes**, not their source text. Removes about ten
      of `spec.ex`'s nineteen regexes and most of `tsx.ex`
      (`split_args/1`, `object!/1`, `merges_class?/1`)
- [ ] 8b — Read `TSTypeAnnotation`. `boolean` → `:boolean`, `number` →
      `:integer`, a union of string literals → `values:`, `?` → optional.
      282 of 845 attributes are `:any` today
- [ ] 8c — `presentational.ex:135` decides `:any` with a regex over code. A
      `MemberExpression` is a node
- [ ] 8d — Read `ParseResult.module`. `parse.mjs` uses two of its four getters,
      and `spec.ex:651` decides exports with `~r/^[A-Z]/`
- [ ] 8e — Use `visitorKeys` / `Visitor` instead of the hand-rolled walk in
      `parse.mjs`. Evaluate `oxc-walker` for scope tracking, which is what
      `spec.ex:208` asks with a word-boundary regex
