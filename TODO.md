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

- [x] No recipe holds a literal `cn-` string. Pagination, calendar, carousel,
      chart, form-control, resizable, slider, toast, and related recipes read
      class facts from component specifications.
- [x] `gen/toast.ex` remains a hand-written `~H` template. Represent Sonner's
      toast parts and geometry in the specification, then render that data.
- [x] For each former copied `cn-` string, record the fact in the spec instead

### 7c — A recipe is not a patch on another recipe's output

- [x] Remove generated-source `String.replace` patches. Recipe behavior now
      updates a node tree or passes structured renderer attributes.
- [x] `gen/resizable.ex` now writes its module directly; it does not inject
      declarations into generated source.
- [x] Keep one-component recipes only where they express behavior: `checkbox`,
      `separator`, `switch`, `radio_group`, and `progress` now update nodes
      before rendering.
- [x] Correct the recipe count in `ROADMAP.md` and `docs/INVENTORY.md`.
      There are 23 active recipes.

## Phase 8 — Finish the oxc swap

- [x] 8a — Carry expression **nodes**, not their source text. Removes about ten
      of `spec.ex`'s nineteen regexes and most of `tsx.ex`
      (`split_args/1`, `object!/1`, `merges_class?/1`)
- [x] 8b — Read `TSTypeAnnotation`. `boolean` → `:boolean`, `number` →
      `:integer`, a union of string literals → `values:`, `?` → optional.
      282 of 845 attributes are `:any` today
- [x] 8c — `presentational.ex:135` decides `:any` with a regex over code. A
      `MemberExpression` is a node
- [x] 8d — Read `ParseResult.module` and use its export record. Parsed JSX
      behavior now decides whether an export is a component.
- [x] 8e — Use `visitorKeys` instead of the hand-rolled parser walk.
- [x] Use `oxc-walker` scope tracking for parameter reads. This replaces the
      word-boundary check in `spec.ex`.

## Phase 9 — The storybook becomes the documentation site

### 9a — The shape

- [x] `/docs/:component` — one page per component, replacing the flat index
- [x] Sidebar navigation from `Examples.components/0`, built with `<.sidebar>`
- [x] `⌘K` search, built with `<.command>` in a `<.dialog>`. The server
      filters, as `command` was generated to expect; opening costs no round trip
- [x] A Preview / Code block per example, built with `<.tabs>`
- [x] An Installation section — `mix ui.add <name>`
- [x] Leave `/preview/:component/:example` byte-identical. The shell is a
      second layout (`docs.html.heex`) rather than a change to `app.html.heex`

### 9b — Three things generate, none is typed

- [x] The Code tab: `Code.string_to_quoted(token_metadata: true)` over
      `examples.ex`; the `~H` sigil node carries its own body. All 76 read
- [x] The API table: `Module.__components__/0` gives every attribute's name,
      type, required, doc, `default:` and `values:`, and each slot's attributes
- [x] The navigation: `Examples.components/0` and `Examples.all/1`

### 9c — Drop `phoenix_storybook`

- [x] Remove the dependency and the `live_storybook` / `storybook_assets`
      routes
- [x] Delete `storybook/storybook/*.exs` and the backend module

### 9d — The sidebar example demonstrates nothing

- [x] Replace `Examples.sidebar_default/1`: a brand, two labelled groups with
      icons, a footer, and height enough that collapsing is visible
- [x] Keep `sidebar_inset` out. It is a `<main>` and the preview page has one

### 9e — Also landed

- [x] rolldown replaces esbuild. Built on Oxc, the parser this pipeline already
      reads `.tsx` with. 347 kB against 413 kB, in 32 ms
- [x] `usage-rules.md` for `live_shadcn` and `live_base`, listed in each
      package's hex `files`. See <https://usage-rules.hexdocs.pm>

## Phase 10 — What phase 9 found

Three defects, none of them phase 9's own. The first two came from the parity
check, which is what it is for.

### 10a — The sidebar's generated component drops two contracts

- [x] `sidebar_menu_button` renders its tooltip
- [x] `is_active` emits `data-active`. `ast.ex` read only `state.slot` and
      dropped every other key
- [x] `sidebar / default` parity passes

### 10b — `navigation-menu` lost its anatomy

- [x] Restored, and not as it was: the old recipe was a hand-written template
      with eight retyped `cn-` strings. The new one assembles the parts and
      describes none of them. The inventory points at it now
- [x] Snapshot regenerated; axe clean; `mix snapshot --check` green

### 10c — The browser suite silently uses a foreign server

- [x] `test/browser/servers.mjs` probes each occupied port for a page only our
      own server serves, and refuses before a test runs
- [x] The failure names the port and the override, rather than arriving as
      sixty confusing test failures
