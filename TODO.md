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
- [ ] `command` (`listbox`)
- [ ] `sonner` (`toast`)
- [x] `input-otp` (`form-control`)
- [ ] `message-scroller` (`scroller`)
- [x] `questionnaire` (`presentational`)

### 5b — One recipe, spec already written

- [x] `carousel` recipe on CSS scroll-snap

### 5c — Three that need a real decision

- [ ] `resizable` — a pointer-drag hook that writes a CSS variable
- [ ] `calendar` — a month grid the server computes. `locale` and
      `week_starts_on` are props, English and Sunday by default
- [ ] `calendar` — `locale="browser"` opt-in: a hook reads `Intl` on mount
- [ ] `chart` — port the chrome: container, style block, tooltip body, legend
      body. The plot is the caller's slot, upstream as much as here

### 5d

- [x] Record `direction` in the roadmap as a utility, not a gap

## Phase 6 — Publish 0.1.0

- [ ] Push to GitHub
- [ ] Publish to hex — needs a `HEX_API_KEY`
- [ ] Deploy the storybook — needs a Cloudflare token
- [ ] Prove the sync bot with one run by hand
