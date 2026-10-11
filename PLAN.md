# Plan: shadcn parity and verification badges

Active execution: [release completion](docs/plans/release-completion/PLAN.md).
Use its task board for parallel work. The phase details below remain the
technical reference. A code commit does not establish current verification.

Status: the latest full run at `c6ba115` passed 62 of 64 component groups.
The proved component repairs in phase 6e.83 pass. Drawer and Sidebar need the
entry repairs in phases 6e.84 and 6e.85 before phase 6f can complete. Use the
current checklist for acceptance. The detailed phases below retain their
original diagnosis and measurement history.
Base commit: `f34f1f0`.
Checklist: [TODO.md](TODO.md).
Previous completed plan: [port synchronization](docs/plans/port-synchronization/PLAN.md).

## Goal

Make shadcn verification prove that each reviewed LiveView component matches
its pinned React reference. Make component badges show the same current
pipeline result. Verified requires all checks to pass for the current inputs
and all current official examples. Include the documentation families
data-table, date-picker, and typography.

## Scope

Cover the shadcn review findings and the user's badge requirement. AI Elements
reference selection and AI evidence portability are outside this plan. Shared
infrastructure can change where shadcn needs it. Preserve AI policy, examples,
and verification records.

Keep pinned upstream sources, the shared CSS build, local browser verification,
CI checks of committed evidence, and current comparison thresholds. Component
API redesign, upstream updates, dependency upgrades, and deployment are outside
this plan. Add specific repair phases if corrected checks expose port bugs.

## Original review findings

Phases 1–5 resolved these findings. This table records the original baseline.

| ID | Original code and problem | Required result |
|---|---|---|
| S1 | `LiveShadcnTools.verification_evidence_digest/3` in `tools/lib/live_shadcn_tools.ex` omits hooks, CSS, reference-page code, and shims. | Runtime changes invalidate affected shadcn evidence. |
| S2 | `Mix.Tasks.Ui.Verify.record_incremental!/3` calculates identity at import time. `PlaywrightReport` omits top-level errors. | Imports prove their test-time identity and complete execution. |
| S3 | `storybook/test/browser/parity.spec.mjs` applies `PARITY_DEBUG_STATE` but retains a normal passing result. | Partial state checks cannot produce complete evidence. |
| S4 | `paintedBoxInDocument` in `storybook/test/browser/shoot.mjs` omits overflowing descendants without slots. | Screenshots include all visible component output. |
| S5 | `.github/workflows/sync-upstream.yml` omits the parity dependency install. Its browser command does not write `VERIFY.json`. | A clean shadcn sync starts its reference server and records verification. |
| S6 | `StorybookWeb.Docs` duplicates digest and status logic. Its file list omits `incremental_verification.ex` and `playwright_report.ex`, which the tools digest includes. | Badges and pipeline use one shadcn identity and status calculation. |

Also fix pixel failure diagnostics with S4. In `shoot.mjs`, `localise` reads
`box.x` when a lazy off-screen item can have `box: null`.

Review baseline: 60 selected tools tests, 85 browser helper tests, and 28 parity
tests passed. `mix ui.status --check` failed for data-table, date-picker, and
typography. The full component browser suite was not run. Do not copy the old
Verified count into acceptance criteria or replace evidence digests by hand.

## Approach

### Share the shadcn calculation

Add a small private Mix project under `tools/verification/`, with the proposed
module `LiveShadcnVerification` under `tools/verification/lib/`. These paths and
this module are new. It will own shadcn input discovery, identity calculation,
required-check evaluation, and status with a reason. Separate file collection
from pure record evaluation so tests can use temporary fixtures.

Add path dependencies in `tools/mix.exs` and `storybook/mix.exs`. Reuse Jason and
SHA-256. The private project must not depend on Phoenix or the fetch tools and
must not become a dependency of published component packages.

Use it from `LiveShadcnTools.verification_evidence_digest/3`,
`Mix.Tasks.Ui.Status`, and the shadcn branch of `StorybookWeb.Docs`. Preserve the
AI branch. Tools still own execution and writes. Storybook calculates release
badge data during compilation, with no repository reads on HTTP requests.

Use `registry/VERIFICATION_POLICY.json` as the policy source. Standard shadcn
components require generated, snapshot, examples, browser, behavior,
accessibility, parity, and pixel. Documentation families require the same set
without generated. Keep `shadcn/direction` as No DOM.

### Badge meaning

| Badge | Pipeline result |
|---|---|
| Verified | Current identity, complete review, and all required gated checks and examples passed. |
| Failed | Current identity and an actual required-check or preparation failure. |
| Stale | A prior record exists but its inputs, contract, policy, or evidence schema changed. Includes historical failures. |
| Not verified | No record, or current evidence is incomplete, diagnostic, skipped, or missing required checks. |
| No DOM | Explicit policy says that the component renders no DOM. This is not a parity pass. |

Check freshness before classifying an old failure. Add explicit outcomes to new
check records where `pass` and `gated` cannot distinguish failure from a check
that did not run. Preserve those fields for existing readers. Treat ambiguous
older records as incomplete or stale.

Use the same result on `/` and `/docs/:component`. Keep `data-component-status`
as the test contract. Add a small expandable check list on component pages with
check names, results, and short reasons. Use text such as "Pixel check failed"
or "Source changed since verification". Keep hashes, paths, and command logs
out of badge copy. Color must not be the only status indicator.

Inventory can retain fetched and generated stages when no verification exists.
Its Verified, Failed, and Stale decisions must agree with the shared evaluator.
A deployed badge describes the source compiled into that release. Local record
changes update development badges through code reload. Release changes require
a new build.

### Evidence identity

Version the new shadcn identity. Use sorted relative paths and content digests.
Include the selected contract, port, snapshot list and bytes, official example
mapping, and committed upstream source/style digests. Include shared live_base
behavior, shadcn support code, Storybook renderers, asset sources and build
settings, dependency manifests and locks, React loaders and shims, browser
suites, budgets, and verification rules. Follow actual imports and build inputs
when completing this list.

Start with conservative invalidation for shared shadcn inputs. Do not build a
component dependency graph in this change. Exclude generated assets, caches,
absolute paths, timestamps, and `VERIFY.json`. Use committed digests for fetched
inputs. Check fetched bytes against those digests during preparation.

Return the same input list to Storybook for compile dependencies. Detect added
and deleted files as well as changed files. `@external_resource` alone does not
detect a newly added hook. Include required inputs in the Docker builder. The
release must work without repository files in the runtime image.

Capture identity before preparation and tests. Check it again before publishing
evidence. Reject results if inputs changed during the run. Imported reports
must carry a versioned record with test-time identity, source/component/example
scope, layer, state coverage, completion status, and the Playwright report.
Use this format for managed and direct batch runs. Do not use import time or
report mtime as proof of source identity.

## Implementation phases

### Phase 1: share shadcn evidence evaluation

- Add the private project and define `LiveShadcnVerification` before moving logic.
- Add path dependencies and route shadcn tools/status/Docs calls through it.
  Preserve the AI branch and the existing source/name mapping.
- Initially preserve the tools' current shadcn digest bytes. Prove that the
  extraction preserves pipeline decisions and corrects the separate badge hash.
- Add fixtures for a primitive, a documentation family, No DOM, missing checks,
  and a stale record. Compare both adapters with independent expected results.
- Add the private project to CI and build checks.
- Run `mix test` and `mix format --check-formatted` in the new project. In tools,
  run `mix test test/identity_test.exs test/verification_policy_test.exs`. In
  Storybook, run `mix test test/storybook_web/examples_test.exs`.

**Commit:** `refactor(verification): share shadcn evidence evaluation`

### Phase 2: bind current inputs to badges

- Implement versioned input coverage. Test changes to hooks, CSS, reference
  code, shims, locks, port dependencies, and the input file set. Test equal
  identities in prepared and clean-checkout fixtures.
- Update `Mix.Tasks.Ui.Verify` to capture and recheck identity around execution.
- Implement the badge truth table and explicit check outcomes. Update
  `Mix.Tasks.Ui.Status` and `StorybookWeb.Docs` compile dependencies.
- Update `storybook/lib/storybook_web/live/index_live.ex` and
  `storybook/lib/storybook_web/live/docs_live.ex` with labels and check reasons.
  Share status presentation where practical.
- Test current pass, current failure, stale pass, stale failure, missing record,
  incomplete record, and No DOM on both routes. Do not compare badge text only
  with `Docs.status/1`, since both can contain the same error.
- Test code reload after record changes and added/deleted inputs. Update
  `storybook/Dockerfile` if needed. Extend
  `storybook/test/storybook_web/production_image_test.exs` to check compiled
  evidence, not only a COPY-line match.
- Run shared-project, tools identity/policy, and Storybook status tests. Compile
  a temporary clean Storybook build and compare its shadcn results with tools.

**Commit:** `fix(verification): bind shadcn badges to current pipeline evidence`

### Phase 3: validate reports and reject partial verification

- Update `storybook/test/browser/verify.mjs`,
  `storybook/test/browser/playwright.config.mjs`, and the managed runner in
  `tools/lib/mix/tasks/ui.verify.ex` to produce versioned reports. Use the shared
  identity through a small proposed Mix export task; do not write another digest
  implementation in JavaScript.
- Update `record_incremental!/3`, `import_report!/4`,
  `LiveShadcnTools.IncrementalVerification`, and
  `LiveShadcnTools.PlaywrightReport` to validate identity, layer, ownership,
  examples, states, global errors, and successful completion before merge.
- A report for another component cannot count merely because the caller named
  one example. Reject old raw reports with a clear rerun reason.
- Reject `PARITY_DEBUG_STATE` in evidence runs. Diagnostic commands can retain
  state filters, but their output must be partial and unavailable for normal
  import. Keep complete-example batching and require every required batch.
- Validate, merge, and publish atomically under the existing verifier lock.
  Recheck identity before publication.
- Extend `tools/test/playwright_report_test.exs`,
  `tools/test/incremental_verification_test.exs`, `tools/test/ui_verify_test.exs`,
  and `storybook/test/browser/verify.test.mjs`. Test source edits before import,
  wrong component/layer, top-level errors, missing states, and valid multi-batch
  completion. Rejected imports must never create a current pass.
- Run these tools tests and `node --test ./*.test.mjs` in the browser directory.
  Run one complete shadcn batch through both direct and managed paths.

**Commit:** `fix(verification): reject stale and partial browser reports`

### Phase 4: capture overflow and preserve pixel diagnostics

- Update `paintedBoxInDocument` in `storybook/test/browser/shoot.mjs` to include
  visible unslotted overflow. Respect hidden content and clipping ancestors.
  Keep page chrome excluded and preserve lazy layout rules.
- Add an isolated browser case in the pixel test setup: change an unslotted
  child outside its parent's bounds and require a nonzero pixel difference.
  Cover nested overflow, portals, clipped content, and hidden descendants.
- Extend `storybook/test/browser/shoot.test.mjs` for bounds. Make `localise`
  accept null boxes and keep unmatched pixels in the outside-slot count.
- Run browser helper tests. Run scoped parity and pixel checks for dialog,
  popover, tooltip, toast, and message-scroller. Use
  `PREVIEW_SOURCE=shadcn PREVIEW_COMPONENTS=dialog,popover,tooltip,toast,message-scroller
  npm run verify -- --project pixel`
  in `storybook/test/browser`. Repeat for semantic parity with the chromium
  project and `parity.spec.mjs`. Require complete coverage and useful failures.

**Commit:** `fix(parity): capture visible shadcn overflow`

### Phase 5: make shadcn workflow scope explicit

- Add `--source shadcn` to `Mix.Tasks.Ui.Verify` and `Mix.Tasks.Ui.Status`.
  These options do not exist at the baseline. Select all shadcn ports and
  documentation families; apply No DOM policy. Reject unknown options and
  invalid source/name combinations. Keep default all-source commands.
- Add the proposed `--require-verified` status option. With `--check`, require
  current passing evidence for every selected comparison target. No DOM is an
  explicit accepted result. Matching inventory text alone is not sufficient.
- Install parity dependencies with `npm ci` in upstream sync. Use
  `mix ui.verify --source shadcn` for the shadcn step so it writes evidence.
  Refresh inventory and include it and evidence in the update diff. Keep
  unrelated AI workflow behavior separate.
- Add `mix ui.status --check --source shadcn --require-verified` as a shadcn CI
  gate. Preserve existing all-source checks. Report unrelated baseline failures
  without expanding this implementation into AI repairs.
- Test source selection and strict checking, including all three documentation
  families and incomplete evidence with a matching inventory file.
- Run tools tests, browser helper tests, parity tests, and
  `actionlint .github/workflows/ci.yml .github/workflows/sync-upstream.yml`.
  Exercise installs and scoped verification from a clean temporary checkout.

**Commit:** `fix(ci): record and gate shadcn verification results`

### Phase 6a: restore pinned shadcn source facts

- Restore the `calendar`, `carousel`, and `sidebar` contracts and ports to the
  shadcn ref in `registry/UPSTREAM.json`. A prior local source tree supplied
  facts from another ref without changing the committed pin.
- Restore snapshots and focused tests that changed only because of those wrong
  facts. Keep later behavior fixes that do not depend on the wrong ref.
- Give grouped dropdown-menu labels an ID and connect their menu group with
  `aria-labelledby`, as the pinned Base UI primitive does. This keeps rich label
  content out of the menu ownership tree.
- Record current port-body hashes after the reviewed code changes already on
  the branch.
- Run the offline shadcn contract check, the three focused component tests,
  and their snapshot checks. Run focused browser checks and record the static
  reference asset gap for the next phase.

**Commit:** `fix(registry): restore pinned shadcn source facts`

### Phase 6b: serve shared example assets to the reference

- Serve the tracked Storybook static files from the parity Vite server so both
  renderers use the same example images. Do not read an unrecorded file from an
  upstream checkout.
- Add tracked static example assets to the shadcn evidence identity. Test that
  an asset-byte change invalidates evidence.
- Run the focused sidebar accessibility, semantic, and pixel checks.
- Record any component defect that the corrected reference exposes. Keep the
  asset change separate from the component repair.

**Commit:** `fix(parity): serve shared example assets`

### Phase 6c: align the sidebar with pinned browser contracts

- Preserve the pinned collapsible root and sidebar menu-item structure. Both
  renderers have the same inherited list violations. Normalize axe targets by
  stable DOM structure so LiveView-only selector attributes cannot turn an
  upstream violation into a false local regression.
- Normalize example team IDs without trailing punctuation so the current team
  selection check targets the rendered second team.
- Match the pinned closed-menu relation, grouped menu-label ownership, sidebar
  classes, and toggle attributes. Add regression tests before each repair.
- Refresh affected port-body hashes and the sidebar snapshot. Run the focused
  package, snapshot, behavior, accessibility, semantic, and pixel checks.

**Commit:** `fix(sidebar): align pinned browser contracts`

### Phase 6d: pin the Base UI documentation source

- Fetch Base UI contracts from its immutable official release deployment
  instead of mutable website pages. Pin release 1.7.0, its commit, and its
  Netlify deployment ID.
- Translate Base UI component and utility links to immutable deployment paths.
  Record the release and immutable file origins in the upstream manifest.
- Preserve all reviewed page digests, extracted source facts, ports, and
  snapshots.
- Add manifest regression tests and fetch the already pinned shadcn and AI refs.
  Pass the full offline check and focused fetched-source checks for the restored
  Base UI contracts. Record separate shadcn structure differences for repair.

**Commit:** `fix(fetch): pin Base UI documentation source`

### Phase 6e: align pinned shadcn structure facts

- Add focused regression tests for the structure facts that differ from the
  pinned shadcn source.
- Review menubar, navigation-menu, popover, slider, and toast against their
  pinned source files. Update only the stale facts, ports, snapshots, and tests
  that the review requires.
- Refresh the five contracts' Base UI page identities against the immutable
  1.7.0 documentation deployment introduced in phase 6d. Review the documented
  primitive parts and defaults against the ports; retain current APIs.
- Pass the focused component checks and the full offline and fetched-source
  shadcn contract checks.

Review: all five shadcn source diffs replace the synthetic `cn` import with
`@/registry/bases/base/lib/utils`; no JSX or class facts change. Verbatim pinned
fixtures verify source bytes, structure fingerprints, copied facts, and joined
facts. Base UI 1.7.0 npm documentation matches the deployment for navigation-menu,
slider, toast, and menubar; menu and popover differ only in a generated example
CSS import/comment (`home` versus `opt`). No port or snapshot repair is implied
by these source-location differences. Focused component and full fetched-source
checks remain required before accepting the refreshed identities.

Phase 6e checks: 35 focused tools tests and 6 package tests passed; all 61
contracts passed both offline and fetched-source checks. The 23 focused snapshots
passed after refreshing 13 files whose only difference was JSON object-key order
inside Phoenix JS attributes under the configured OTP 29 runtime. Parsed JS
payloads, markup, ports, and class facts are unchanged. Five regression tests
failed against the original contracts and passed against the reviewed contracts.

**Commit:** `fix(registry): align pinned shadcn structure facts`

### Phase 6e.1: preserve out-of-scope verification records

- A full shadcn run exposed that `ui.verify` prunes all AI records while merging
  results. Add a regression test for preserving out-of-scope records, including
  records whose component no longer has a generated port.
- Limit stale-target pruning to shadcn. Preserve AI records unchanged through
  full and scoped publication; do not alter AI evaluation or examples.
- Restore the 48 AI records from the pre-run file, run focused and full tools
  tests, and verify persistence with a real scoped no-browser run.
- Align the existing combobox ownership test with the already reviewed
  `aria-controls` ownership; run the Base package and hook tests.
- Keep the snapshot refresh in phase 6f. Stop the interrupted run and rerun
  against the repaired verifier identity before accepting browser evidence.

Verification: the regression failed before the merge repair; all 160 tools
tests and 42 Base tests pass afterward, as do 93 hook tests. A real scoped
`--no-browser shadcn/direction` publication preserved all 48 AI record values
byte-for-byte. That diagnostic command exits nonzero and is not parity evidence.
Tools Credo and tools/Base formatting pass. The pre-run records were restored
after this persistence check; final evidence still requires a complete run.

**Commit:** `fix(verification): preserve out-of-scope evidence records`

### Phase 6e.2: enforce badge gating and input-set reload

- A compiled temporary-copy route test exposed that explicit `outcome: passed`
  overrides `gated: false`. Reject ungated and contradictory passing records;
  test standard and documentation-family policies against independent results.
- A second route test exposed that an added hook does not recompile Docs.
  Implement Mix's documented `__mix_recompile__?/0` input-path-set check beside
  existing `@external_resource` byte tracking. Do not read repository files in
  HTTP handlers or require them in a runtime release.
- Add regression tests before repair, then repeat both-route temporary-copy
  checks for Verified, Failed, Stale, missing, incomplete, ungated, no-browser,
  added/deleted hooks, and recovery.
- Run private-project, tools, and Storybook tests and configured static checks.
  Restart full evidence verification only after the repaired identity is stable.

Verification: private-project regressions failed for ungated, contradictory,
and unknown passing outcomes before their repairs; all 28 tests now pass.
The input-set regression failed before the Mix hook and now passes for both
added and deleted hooks. Tools pass 160 tests; Storybook passes 75. Formatting,
Tools/Storybook Credo, and Storybook Dialyzer pass. A separately compiled temporary
copy passed both index and component-page assertions for Verified, Failed,
Stale, missing, incomplete, ungated, no-browser, added/deleted inputs, and
recovery. Only the temporary copy used synthetic records; repository evidence
was not replaced with fixture passes.

**Commit:** `fix(verification): enforce badge gating and input-set reload`

### Phase 6e.3: complete browser report provenance

- Test and fix incremental publication's independent AI-pruning path; reuse the
  source-safe merge and put identity capture and report validation inside the lock.
- Replace empty state metadata with test-time expected/completed state coverage
  from the actual parity, pixel, and accessibility loops. Reject missing or partial
  coverage on the real managed/import paths, not only in validator unit tests.
- Capture a scoped direct run's identity through the existing Mix exporter before
  testing. Always write its JSON report; derive completion from actual execution,
  not a caller-provided constant. Direct mixed-scope diagnostic runs remain
  non-importable; complete single-component/layer batches support direct import.
- Test report failure, skipped/interrupted execution, diagnostic filters, identity
  changes, ownership, layer, and state coverage. Preserve complete-example batching.
- Pass private/tools/browser-helper tests, then exercise a complete direct batch
  and import plus a managed component run. Preserve AI bytes on both writes.

Verification: private tests (29), tools tests (161), browser helpers (108),
parity helpers (32), formatting, Tools Credo, and Tools Dialyzer pass. The real
button/default direct parity batch passes four tests with three completed states;
its import records only that batch and correctly remains incomplete. A complete
managed aspect-ratio run passes all required layers. Both paths preserve all 48
AI record values byte-for-byte. Real malformed imports (missing/partial states,
wrong owner/layer, incomplete execution, and global error) leave evidence bytes
unchanged. An identical temporary checkout first matches the direct identity;
editing its hook afterward causes import rejection without an evidence write.
The full button run exposed separately recorded failures for phase 6e.6; no
thresholds or example scope were relaxed to complete this report repair.

**Commit:** `fix(verification): complete browser report provenance`

### Phase 6e.4: prepare reproducible release badge inputs

- The clean Docker build fails resolving `motion` from the Base hooks. Install
  the Base package's locked npm dependencies in the builder, before asset bundling.
- Add a packaging regression test, build the clean image, and test compiled badge
  routes without runtime repository files. Keep dependency versions unchanged.
- The first successful build exposed one extra identity input: Phoenix's generated
  digest-named avatar copy. Exclude only a digest-named copy whose MD5 suffix and
  bytes match its logical source. Keep source-byte changes and unexpected derivative
  changes visible; cover nested asset directories without treating directories as
  file inputs. Verify builder/checkout input equality and rendered badge equality.

Verification: the clean build first failed on missing `motion`, then exposed
one generated avatar copy in its identity. Both regressions now pass; all 31
private tests, 161 tools tests, and 76 Storybook tests pass. The rebuilt image
`c8b88451cdf5` and clean checkout have 600 identical shared input paths/hashes.
With no `/build`, `/registry`, `/app/registry`, or `/app/tools` tree in the runtime,
its index and six component pages match pipeline results: aspect-ratio is Verified;
button, dialog, data-table, date-picker, and typography are Stale. The aspect-ratio
record comes from a complete passing managed browser run, not a fixture. The
explicit direction route returns 404 and is absent from the index; that existing
presentation gap is recorded in phase 6e.7 and remains a final acceptance blocker.

**Commit:** `fix(release): prepare reproducible badge inputs`

### Phase 6e.4a: restore inventory and static checks

- The status command fails when the shared evaluator returns `excluded` for
  AI Elements. Add an inventory command regression test with an AI component.
  Render this status and preserve the stored AI evidence.
- Extract state annotation collection from the report validator to meet the
  configured nesting limit. Preserve report validation behavior.
- Pass the status regression, private verification tests, and tools tests.
  Pass the configured static checks for both changed projects.
- Rerun the strict shadcn status command. It must report verification gaps,
  rather than fail in the inventory renderer.

Result: the regression test reproduced the missing `excluded` renderer before
the repair. All 33 private verification tests and 162 tools tests pass. Both
projects pass `mix check`. The real strict status command now reports 64
shadcn targets that need current verification. It does not crash. All 48 AI
verification records still match the previous commit.

**Commit:** `fix(verification): restore inventory and static checks`

### Phase 6e.5: bind shared build manifests to evidence

- The input audit found that Mix manifests, Storybook configuration, and the
  Base hook npm manifest/lock are not included in the identity. Add mutation
  tests for these current build inputs before including them.
- Follow the shared Tailwind source list: include committed AI component and
  reference source files that contribute classes to the shared stylesheet.
  This is conservative shadcn invalidation, not a change to AI policy or records.
- Cover the same path set in Docs compilation and test prepared/clean identity
  equality. Recheck fetched files used by the shared stylesheet against their
  committed digests, without advancing upstream refs.
- Pass private/tools/Storybook tests and the offline/fetched shadcn checks before
  restarting the final verification run.

Result: both new tests fail against the previous code and pass with the input
coverage change. Mix manifests, Storybook configuration, Base npm inputs, and
AI source files used by the shared stylesheet now invalidate shadcn evidence
and participate in compilation input tracking. Prepared and clean fixture
identities agree. Fetched shared stylesheet source bytes match their committed
digests.

All 33 private verification tests, 162 tools tests, and 76 Storybook tests pass.
All three projects pass `mix check`. Offline and fetched-source checks pass for
all 61 shadcn ports. The 463 snapshot checks, 108 browser helper tests, and 32
reference tests pass. Package tests pass for Base, shadcn, and AI Elements with
42, 147, and 99 results. The strict shadcn gate still reports 64 targets that
need current verification. No full browser verification or release build ran
in this phase. Phase 6e.6 and phase 6e.7 remain open.

**Commit:** `fix(verification): bind shared build manifests to evidence`

### Phase 6e.6: align complete button comparison states

- The full managed button run exposed destructive/RTL accessibility regressions
  and incomplete group-demo/render comparisons. A direct group-demo run reproduces
  a 140-second timeout in nested interactive-state discovery while closing a root.
- Minimize and regression-test each cause before repairing it. Check stable axe
  target ownership, settled state, and actual pinned styles for the contrast
  mismatch; do not normalize away a real contrast regression.
- Preserve every official example and discovered state and all current thresholds.
  Pass complete button behavior, accessibility, semantic, and pixel checks before
  the final full-source run.
- Browser diagnosis confirms that Escape closes both LiveView menu levels.
  The pinned React menu closes only its submenu and restores focus to its
  trigger. Extend the existing button group browser test before repairing the
  Base roving keyboard handler. This is a shared menu behavior repair.
- The accessibility scan captures React during a finite CSS transition. It
  records temporary passing colors, while both settled pages have the same
  contrast violation. Add a browser regression for default-state settling and
  wait for finite transitions before comparing accessibility. Keep contrast
  rules and target matching unchanged.
- The first repair passes Escape from inside a submenu. The complete rerun
  exposes the same defect when focus remains on the parent trigger or parent
  popup. Compare this pointer path with pinned React behavior. Extend the button
  and nested dropdown browser tests, then close the deepest open submenu before
  closing the current menu.
- The shared menu run passes the two new regressions and 58 of 59 checks.
  The remaining check fails on pinned React: moving to the RTL Profiles trigger
  opens it by hover, then clicking closes it before the radio assertion. Switch
  the already-open menubar by hover and require the Profiles trigger to expand.
  Preserve all checkbox and radio assertions and rerun all four menu suites.
- The broader state-helper browser run passes all 59 menu checks but exposes
  seven old fixture failures. LiveView previews must use the existing connected
  visit helper before discovery and replay. Update the tooltip expectation to
  include its current click state, and use the pinned context-menu trigger name.
  Preserve the existing state and popup assertions. Pass all state-helper browser
  tests before recording the complete button run.
- Connected fixtures expose five previously missed editable states: four fields
  in the popover and one editable combobox. Add them to the expected state lists
  and replay the intended expanded state. Do not remove any discovered state.
- The complete rerun reaches nested radio replay, then waits indefinitely on
  the React submenu. The trace shows that replay moves the pointer to (0, 0)
  after opening each menu level; pinned React closes the child on pointer leave.
  Add a two-sided nested-radio replay regression. Clear hover after the root or
  a listbox opens, but keep the pointer inside the nested menu path.
- The final shared run exposes focus loss after rapid ArrowRight/Escape input.
  Extend the existing menu regression to close after open observers run but
  before the next frame. Diagnose delayed focus, floating focus return, and
  LiveView updates. The controlled frame regression reproduces focus loss.
  Require the trigger to remain expanded before delayed ArrowRight focus runs,
  so a pending frame cannot override the Escape focus destination. Repeat the
  complete checks after this shared hook change.
- Complete group comparison now exposes conflicting display and submenu width
  classes. Test caller display/width precedence and both submenu renderer levels.
  Use the shared class merger for these ports. Preserve repeated unknown classes
  as the pinned Tailwind merger does, and test that dependency contract. Refresh
  the two reviewed port hashes and affected snapshots after review.

Verification: all three class regressions failed before repair and pass after
repair. All 149 shadcn package tests and 108 browser helper tests pass. Offline
and fetched-source checks pass for all 61 ports. All 463 shadcn snapshots are
current. Shadcn static checks pass after refreshing stale local dependency data.
The complete managed button run passes every required check for all 15 official
examples. Stored AI record blocks preserve their committed bytes. The final
shared run exposed an intermittent submenu focus return failure. A controlled
frame regression fails before the delayed focus repair and passes in all ten
runs after it. All 93 Base hook tests pass. All 72 shared menu and state-helper
browser tests pass after the final hook change. The final complete button run
passes every required check for all 15 official examples. All 48 AI record
blocks still match their committed bytes.

**Commit:** `fix(button): align complete official comparison states`

### Phase 6e.7: complete badge status semantics

- The real partial import exposes another badge precedence issue: producers set
  top-level `pass: false` for incomplete evidence, and the evaluator treats that
  alone as an actual failure. Regression-test real incomplete/no-browser records,
  not only synthetic records with `pass: true`.
- Require an actual failed required check for Failed. Record preparation failures
  explicitly and include their readable reason, so a genuine preparation failure
  remains Failed while skipped/incomplete checks remain Not verified.
- The release check also exposes that direction is omitted from the index and
  `/docs/direction` returns 404 because it has no examples. Include explicit
  No DOM policy components in documentation navigation and routing without
  inventing a DOM preview or counting them as parity passes.
- The compiled badge HTTP fixture exposes duplicate `username-1` ids in the
  existing connected Dialog documentation examples. Record this separate
  documentation defect for the full review. Keep LiveView duplicate-id checks
  enabled; use HTTP for the compiled status contract.
- Test both rendered badge locations against producer-shaped fixtures and preserve
  stale precedence, No DOM policy, and AI records. Pass private/tools/Storybook
  tests and rerun current verification after this shared identity change.

Validation: the actual CLI regression tests fail before the repair and pass
after it. The compiled HTTP fixture checks both badge locations for incomplete,
failed, stale, verified, docs-only, No DOM, and excluded AI records. It also
checks recovery after a new record and compilation. Direction passes its
connected LiveView route and index checks. Private verification has 33 passing
tests, tools has 164, and Storybook has 78. All three static checks pass.
Run the large suites in sequence because they scan or change shared inputs.
AI record bytes remain unchanged.

**Commit:** `fix(verification): complete badge status semantics`

### Phase 6e.8: isolate Dialog documentation inputs

- The default and RTL Dialog examples both use `name-1` and `username-1`.
  They share one documentation page, so LiveView rejects duplicate IDs and
  labels can select the wrong input.
- Test the connected documentation route and each dialog's label association.
  Give the RTL inputs distinct IDs and update their labels. Keep the official
  text, values, names, and interaction checks.
- Refresh only the RTL Dialog snapshot. Check the focused route, preview
  coverage, formatting, and the shadcn snapshots before the full browser run.

**Commit:** `fix(storybook): isolate dialog example inputs`

Validation: the connected route fails before the repair on duplicate
`username-1` IDs. After the repair, all 64 example tests pass, including
connected Dialog documentation and independent label associations. All 463
shadcn snapshots are current. Formatting and diff checks pass.

### Phase 6e.9: preserve initially open disclosure states

- The full run exposes an Accordion replay timeout. The reference trace shows
  an initially expanded trigger, a click that closes it, and a wait for true.
  The affected examples include borders, card, and RTL.
- Test replay against both real renderers. Keep every discovered state and
  require its controlled panel to be visible. Skip the opening click when the
  path trigger is already expanded, including nested action paths.
- Pass the shared state suite and verify all Accordion states. Record any
  separate rendering failure before the full source run restarts.

**Commit:** `fix(verification): preserve initially open disclosure states`

Validation: the retained reference trace and the new LiveView regression both
fail before the repair because a click closes the initial panel. The repaired
test checks both real renderers. All 14 shared state tests and 108 helper tests
pass. Complete Accordion behavior, accessibility, and pixel checks pass. Its
only semantic failure is the duplicate root width recorded in phase 6e.11.

### Phase 6e.10: stop tracking the generated reference link

- Git tracks `parity/src/upstream`, although the reference loader regenerates
  it. Restoring unstaged changes after a commit has produced a regular pointer
  file at its old target and left the prepared reference link unusable.
- Remove the generated link from the index. Ignore both the link and generated
  release paths regardless of file type. Preserve the pinned registry source
  files and the running prepared tree.
- Check that source preparation still creates a valid reference directory,
  the generated link is ignored, and pinned refs remain unchanged. No new
  absence test is needed for this generated-file cleanup.

**Commit:** `chore(parity): untrack generated upstream link`

Validation: preparation creates a valid reference directory. Git ignores both
the generated symlink and the old regular pointer file. The pinned source
manifest is unchanged, and the recorded verification identity still matches.

### Phase 6e.11: honor Accordion caller width and disabled state

- State replay now reaches every Accordion state. The semantic check finds
  duplicate `w-full` classes in the disabled example. The root appends caller
  utilities instead of applying the pinned `cn` merge contract.
- Extend the existing caller-class test with explicit default and replacement
  widths. Use the shared class merger for the root. Review its port-body hash
  and refreshed root classes without changing pinned facts or comparison rules.
- The same root review finds that `disabled=true` only marks the root. Child
  flags and commands read the item value, so root-disabled items can still open.
  Test the documented root contract and propagate root disablement to each part
  and its client command. Keep independently disabled items disabled.
- Pass package tests and complete Accordion verification before the full run.

**Commit:** `fix(accordion): honor caller width and disabled state`

Validation: both extended package tests fail before their repairs and pass
after them. All 149 shadcn tests and its static check pass. Offline and fetched
contract checks pass for all 61 ports. Only the Accordion port-body hash changes.
All 463 shadcn snapshots are current. Complete Accordion verification passes all
nine required checks over its seven official examples. Comparison rules and
pinned refs remain unchanged.

### Phase 6e.12: document native and composed examples

- The new No DOM route inherits a generic installation command and a nonexistent
  component spec path. Direction uses the native HTML `dir` attribute. The three
  documentation families also have no copied component or version-2 spec.
- Extend the connected route test to require a usable HTML direction example.
  Show native usage and the real policy source for Direction. Point the composed
  documentation families to their pinned source manifest and explain example
  adaptation. Keep ordinary component installation instructions and the badge
  contract.
- Pass the route test, Storybook tests, and static checks before the full run.

**Commit:** `fix(storybook): document native and composed examples`

Validation: both route tests fail before the repair for the intended native
usage and source-label errors. All 80 Storybook tests pass after the repair,
including connected documentation families, the native Direction route, and
the compiled badge fixture. Storybook static checks pass. Pinned refs,
comparison rules, and AI record bytes remain unchanged.

### Phase 6e.13: restore Alert Dialog Escape dismissal

- The full browser check finds all seven Alert Dialog examples stay open after
  Escape. The pinned React implementation closes them. It disables pointer
  dismissal independently of its Escape handler.
- Correct the existing browser test. Click the backdrop while open, then press
  Escape and require a closed popup, a closed trigger, and returned focus.
  Prove the test fails on the current LiveView port and passes on pinned React.
- Keep backdrop dismissal disabled by default. Bind Escape to the shared close
  command. Do not add a new public option or change comparison rules.
- Review the port hash, refresh affected snapshots, pass package static checks,
  and pass complete Alert Dialog verification before the scoped commit.

**Commit:** `fix(alert-dialog): restore Escape dismissal`

Validation: the corrected browser test passes on pinned React and fails on the
old LiveView port because the trigger stays open after Escape. Both sides pass
after the repair. All 149 package tests and package static checks pass. All 61
offline and fetched-source contracts and all 463 shadcn snapshots are current.
Complete Alert Dialog verification passes all nine required checks over all
seven official examples. The snapshot commit changes only the eight popup
Escape bindings. Pinned refs, comparison limits, and all 48 AI record byte
blocks remain unchanged.

### Phase 6e.14: settle Avatar images before behavior comparison

- The restarted full run finds one Avatar dropdown behavior mismatch. React
  still renders its fallback text when the probe reads the trigger. The
  LiveView page has already loaded the same public image. Both requests succeed.
- Review the shared image fixture and page readiness helpers. Use the same
  controlled image input on both sides and wait for the final rendered image
  state before discovery and interaction. Keep trigger names in the comparison.
- Prove the current race with the captured trace and a deterministic delayed
  image regression. Keep the existing Avatar menu interaction test.
- Pass browser helper tests and complete Avatar verification before the scoped
  commit. Let the current full run finish to collect other failures first.

**Commit:** `fix(verification): settle avatar image behavior probes`

Temporary proof: the new delayed-image browser test fails with the current
helper because it reads `CN` before the held response completes. The temporary
repair passes the same test and the existing menu test. Six existing helper
tests pass with the draft imports. A real-page check compares discovery and
interaction on both renderers and checks native image failure. Both pass. The
draft patch is in `/tmp/shadcn-avatar-readiness-draft/phase-6e14.patch`.
The project files remain frozen during full run 3. Applying the repair, running
all helper checks and complete Avatar verification, and committing are pending.

### Phase 6e.14a: settle disclosure render transitions

- The Bubble Popover contrast trace starts its scan about 46 ms after the
  LiveView click. The saved frame is still fading in. Its final frame has dark,
  readable text. The generic disclosure state path returns without waiting for
  finite transitions, although the default and hover paths already wait.
- Add a real Popover regression that lengthens its opening transition and
  requires the final opacity after expanded-state entry. Test both renderers.
  Prove it fails before the repair and passes after it.
- Wait for finite transitions after the generic disclosure path. Keep infinite
  animation handling, actual interaction, and all contrast and pixel limits.
- Pass the shared state browser suite and the affected Bubble accessibility
  example before this prerequisite commit.

**Commit:** `fix(verification): settle disclosure render transitions`

Temporary proof: the existing Popover state test now checks both renderers with
a 600 ms opening transition. Both current helpers return during the fade, with
opacity below 0.01. Both temporary repaired cases pass at opacity 1. A focused
axe scan of Bubble Popover content also reports no contrast violation on either
page after the draft wait. The full-page scan still has the pinned destructive
Bubble text violation. It is outside this popup repair. The draft patch is in
`/tmp/shadcn-disclosure-readiness-draft/phase-6e14a.patch`. Project application,
complete state checks, affected accessibility verification, and commit remain
pending until full run 3 ends.

### Phase 6e.14b: align Sonner notice layout and fonts

- The complete Bubble link-button image check reports 1978 different pixels.
  Saved reference and port images show differences in the notice text and frame.
  Native styles confirm a system font stack and title weight 500 in React.
  The port inherits a different stack and weight 400.
- React uses 24 px viewport offsets. The port uses 32 px. The port also adds
  the Base Toast cn-toast class, whose theme rule changes the corner radius
  from 10 px to 18 px. An empty description creates an extra 2 px content gap.
- Match the pinned Sonner stack, title weight, viewport offsets, and radius.
  Remove the unrelated Base Toast theme class. Omit a blank description while
  preserving real description content, notice types, dismissal, and API inputs.
- Review the Sonner port hash and affected snapshots. Pass package checks,
  complete Sonner verification, and the complete Bubble notice image check.
  Keep all image limits.

**Commit:** `fix(sonner): align reference notice layout and fonts`

### Phase 6e.15: align Bubble official example behavior and states

- The full run finds a read-receipt trigger name difference, stale notice test
  selectors, collapsed-answer class differences, Popover text class and contrast
  differences, and a notice-action pixel difference.
- Review each difference against the pinned examples and the rendered trace.
  Use the Sonner notice contract in the existing behavior tests. Keep notice
  content and success assertions. Review the optional trigger label separately
  from the public Tooltip API.
- Match the caller-owned Bubble and Popover text classes and collapsed-answer
  composition. Keep expansion, collapse, tooltip, and outside-click behavior.
- Match the controlled long-answer state with one server state value. Use
  existing public Collapsible props and JS commands. Render one current answer
  and button label. Add the event to both Preview and Docs pages. Preserve
  native interaction and the public component API.
- The repaired long-answer state still exposes template line breaks through
  inherited pre-line whitespace. Its default image differs by 14,051 pixels.
  Keep paragraph breaks in the answer. Remove generated line breaks at the
  Bubble Content slot and composed Collapsible slot boundaries. Keep caller
  whitespace. Render one current answer. Review both changed port hashes.
- Run the prerequisite disclosure-readiness and Sonner font phases first.
  Check Popover contrast and notice pixels with focused complete-example runs.
  Keep accessibility and pixel limits.
- Prove repairs with existing failing checks, review affected snapshots and any
  changed port hash, and pass complete Bubble verification before the commit.

**Commit:** `fix(bubble): align official example behavior and states`

### Phase 6e.16: merge Separator caller widths in Button Groups

- The complete split and separator examples keep both `data-horizontal:w-full`
  and `data-horizontal:w-auto` in the port. The pinned React component keeps
  the caller's auto width. Its Button Group separator delegates to Separator;
  the port copies the base classes and appends both class sets.
- Extend the existing public separator contract test with the effective width
  classes. Prove the current conflict before the repair. Check direct caller
  overrides at the Separator boundary as a separate public API contract.
- Apply the shared class merger to Separator and compose it in Button Group
  separator, as the pinned implementation does. Preserve orientation, roles,
  caller attributes, and content. Add no option solely for tests.
- Review both port hashes and affected snapshots. Pass package checks and
  complete Button Group and Separator verification before the scoped commit.

**Commit:** `fix(separator): merge caller widths in button groups`

### Phase 6e.17: preserve DayPicker day button classes

- All 11 Calendar examples fail semantic comparison. The only reported class
  difference is a missing `rdp-day` on day buttons. The pinned
  `CalendarDayButton` combines its literal classes with `defaultClassNames.day`
  and the incoming DayPicker button class. The derived binding includes only
  `rdp-day_button`. The Persian button already includes both classes.
- Use the existing exact Calendar button class test to check both DayPicker
  classes. The test fails on the old component because `rdp-day` is missing.
- Add `rdp-day` to the reviewed derived binding and synchronize the contract
  and port facts. Preserve selection, modifiers, focus, and day-cell classes.
- All eight Date Picker semantic examples also report this missing class.
  Their captured failures contain 476 day button class differences. Check
  Calendar composition in Date Picker after the repair.
- Review the generated fact change and affected snapshots. Pass package
  checks, offline and fetched contract checks, and complete Calendar verification.
- Completed checks: 150 package tests, package static checks, fetched and
  offline contracts, and all nine Calendar verification checks pass. Only
  the Calendar verification record changed. All 48 AI record byte blocks
  remain unchanged. The 19 affected Calendar and Date Picker snapshots
  change only the class on 742 day buttons.

**Commit:** `c481326 fix(calendar): preserve DayPicker day button classes`

### Phase 6e.18: align Card spacing button values

- The Card spacing example uses values `4`, `5`, `6`, and `8` on native
  buttons. The pinned React buttons have empty native values. The port already
  has a `native_value` slot option. Its controlled click command carries the
  selected spacing separately.
- Set empty native values in the example. Keep the selection key and click
  command. Preserve the public Toggle Group API and generic value comparison.
- Verify empty native values, the initial selection, and a user change to
  another spacing on both pages. Test the connected state change and Card
  spacing style, rather than only an attribute in a static render.
- Review the affected snapshot and pass complete Card verification.
- Completed checks: the existing generic interaction regression fails for
  native values on the old fixture and passes after the repair. All four
  connected spacing choices match the reference selection, class, and computed
  style. Agent-browser also confirms a connected 32px choice. All 80 Storybook
  tests, static checks, and all nine Card verification checks pass. Only four
  native values change in the owned snapshot. All 48 AI record byte blocks
  remain unchanged.

**Commit:** `6af2220 fix(card): align spacing example button values`

### Phase 6e.19: wait for Carousel movement before measurement

- The named spacing test fails on both React and Phoenix. It waits only for
  movement to start, then checks the final distance. Semantic and pixel checks
  also compare different intermediate slide positions after Next slide.
- Inspect captured transforms and the shared Embla movement mechanism before
  choosing a readiness condition. CSS animation readiness does not cover
  transforms written by requestAnimationFrame.
- Wait for movement to stop at the browser helper boundary. Use observed
  transform stability or a public event available on both pages. Do not add a
  component option or expose an internal API solely for tests. Keep autoplay,
  partial-width, vertical, spacing, and RTL behavior in the checks.
- Correct the named spacing test to poll for its expected final distance.
  Add a real-page regression for visual-state readiness if it checks a distinct
  helper contract. Preserve exact semantic and pixel thresholds.
- Pass the browser helper checks and complete Carousel verification before
  the scoped commit. Make a separate port repair phase if settled movement
  still differs from the pinned reference.
- Observed motion: the original visual helper returns at about -67px on
  React and -77px on Phoenix. Both finish at -129.5px. Embla rounds transforms
  to two decimals and has a 17-frame plateau before its final position. The
  draft waits for 400ms of unchanged transforms with a 10-second limit.
- Regression proof: the existing named spacing test fails on both pages at
  3.53px because it measures after movement starts. A distinct real-page visual
  action test fails on both pages before the repair and passes with the draft.
  It checks the final spacing distance and 32 later frames without movement.
- Completed checks: all 108 browser helper tests, 93 Base hook tests, 14
  named Carousel browser cases, and both actual visual readiness cases pass.
  Complete Carousel verification passes all nine checks across seven examples
  after the separate caption repair. Only its evidence record changed, and
  all 48 AI record byte blocks remain unchanged.

**Commit:** `8a223de fix(verification): wait for carousel movement before capture`

### Phase 6e.19b: preserve Carousel status text boundaries

- Complete Carousel verification passes every check except the API example
  pixel check. The settled action differs by one counted pixel in the caption
  digit 2. A direct exact-settings replay reproduces the same difference.
  Its 93 raw color differences are confined to that digit. Slide images,
  controls, and the rest of the caption match.
- Compare native caption text nodes and glyph position on the actual pages.
  Check text boundaries first, then box position and capture paint timing.
  The pinned React caption renders current and count as separate text nodes.
  The port controller replaces the entire caption with one text node.
- If separate numeric text nodes remove the measured difference, keep the
  native text composition at the existing status update boundary. Preserve
  the caption, selection count, API notifications, and autoplay behavior.
  Add no public option or test-only component API.
- Use the existing exact API pixel check as the primary regression owner.
  Pass it before and after a real Next action without changing its zero
  budget. Pass the named API behavior check and the complete Carousel run.
- Commit the status repair separately from the capture readiness repair.
- Real-page draft result: both caption boxes and fonts are identical. The
  digit begins at x=639.046875px on React and x=639.0625px on the port. Four
  separate text nodes move the port digit to the exact reference position.
  The existing comparator changes from one different pixel to zero. Keep
  this source repair separate from the motion wait.
- The built source passes the existing API pixel check at zero in every state
  and both extended API behavior cases. The complete Carousel run passes all
  nine checks with the motion wait.

**Commit:** `0e2e778 fix(carousel): preserve status text boundaries`

### Phase 6e.19a: stabilize responsive Chart state discovery

- The legend example passes state coverage in accessibility and semantic
  checks. Its pixel check finds no hover state on React, while Phoenix exposes
  one. The pinned example contains a tooltip and bars. Inspect responsive
  rendering readiness before changing the example or discovery rules.
- If initial chart rendering causes the gap, wait for the actual rendered
  chart parts before discovery. Cover the wait with a delayed responsive render
  on a real reference page. Do not wait for bars in tooltip anatomy examples,
  which contain no plot. Do not remove a state to make the lists agree.
- Pass the shared state checks and the complete legend example on both pages.

**Commit:** `fix(verification): wait for responsive chart state discovery`

### Phase 6e.20: complete the Chart demo hover state

- The Chart demo fails state coverage in accessibility and semantic checks.
  React exposes a chart hover state. The Phoenix demo has bars but no tooltip
  wrapper or controller. Its connected series selection test passes. The
  existing ChartTooltip hook assumes six categories and two series, so the
  30-day single-series demo cannot use it without a reviewed change.
- Add a user-facing tooltip and cursor to the demo. Reuse the public Chart
  tooltip composition. Make the browser controller read the demo date and
  active series value. Preserve the current monthly examples and their RTL
  geometry. Use a separate controller if it keeps these data contracts clear.
- Test hover date, Page Views label, active series value, pointer leave, and
  hover after a connected series change. Keep the existing connected selection
  test. Test behavior through real pages and public controls.
- Run all demo states through exact semantic and pixel comparison. Review
  responsive plot geometry, grid, axis, and caller classes against the pinned
  example if completed state coverage exposes further differences. Do not
  remove the hover state or add comparison tolerances.
- The demo has no named pixel budget. After exact comparison passes, add an
  explicit zero budget. This keeps the current effective zero threshold and
  satisfies the example inventory check.
- Review affected snapshots and any changed port hash. Pass Storybook and
  browser checks and complete Chart verification before the scoped commit.

**Commit:** `fix(chart): complete interactive demo hover behavior`

### Phase 6e.20a: align Checkbox table selection

- The table example changes its header to mixed when the user selects some
  rows. The pinned React example sets its header to true only when all four
  rows are selected. Its header is false for a partial selection. Generic
  behavior and semantic checks report this difference.
- Correct the example-owned CheckboxTable controller to use the pinned header
  state. Preserve row selection, native input values, and the public Checkbox
  indeterminate option. Do not change the Data Table mixed-selection contract.
- Extend the existing table browser checks for partial selection, all rows,
  clearing a row, and clearing all rows on both pages. Require the header state,
  row state, and native submitted state at each step.
- Pass the complete table example and focused browser checks before the scoped
  commit. Complete component verification follows the focus repair.
- The extended existing table browser checks pass the reference's complete
  selection flow. They fail on the port after a partial selection because the
  header reports `mixed` instead of `false`. Native selected names and values
  are checked at every step, with each renderer's current form value default.
- Test audit: `CheckboxTable makes the header mixed when one row is selected`
  in `storybook/assets/js/checkbox_table.test.mjs` came from `c5f40ce`. It calls
  the private setter with mocked attributes and does not select a real row.
  The two real browser cases now own this contract. Remove that mock test and
  the example-only indeterminate setter branch. The public Checkbox and
  separate Data Table indeterminate contracts keep their existing owners.
- The same full selection flow exposes a second example defect after the
  header repair. Assigning the native `checked` property makes it stop following
  later attribute toggles. After a partial selection, the header has a checked
  attribute and true visible state but a false native property, so it clears
  rows. Keep the controller's updates at the existing checked-attribute
  boundary. The new compound browser flow owns this lifecycle regression.

**Commit:** `fix(checkbox): align table selection example`

The repair is on main in `8c862ae`. Both complete selection browser flows
pass. All nine table comparison checks pass. The 12 client tests, 80
Storybook tests, static checks, and eight Checkbox snapshots pass.

### Phase 6e.21: keep Checkbox focus on the visible control

- The Checkbox default example loses focus to its hidden input after a click
  inside a containing label. React keeps focus on its visible checkbox. The
  generic behavior check compares this focus contract. The port has a visible
  span and a hidden native input but no input focus redirection.
- Confirm label activation and focus order in both pages. Extend the existing
  Checkbox browser checks for a containing label, a separate label, and Space
  after a pointer click. Require one state change and the correct submitted
  value. Preserve disabled, readonly, and native form behavior.
- Return hidden input focus to the visible control at the component or shared
  form-control boundary. Keep labels and native submission. Do not suppress
  focus comparison or change the example solely to avoid label activation.
- Review the affected port hash and snapshots. Pass package and browser checks
  and complete Checkbox verification before the scoped commit.

**Commit:** `fix(checkbox): preserve label state and focus`

The real browser tests show a state fault as well as a focus fault. On both
label forms, the native input changes but the visible checkbox stays false.
Both React cases pass. Both old port cases fail for that state difference.

The repair handles label activation at the Checkbox boundary. A private marker
identifies its native input. Label clicks use the visible control's existing
command once and keep focus there. Clicks inside the control keep that command
path. Hidden input focus returns to the visible control. Interactive label
children keep their own behavior. No new hook or callback command is needed.

All 18 checkable-control browser tests and all 37 Checkbox comparison checks
pass. The 150 package tests, 93 Base client tests, package static checks, and
online and offline contract checks pass. The real form proof also confirms
readonly values, disabled state, hidden input focus, a caller event that selects
one server-owned Data Table row, and the public mixed header state.

All 80 Storybook tests and Storybook static checks pass. Thirty affected
snapshots are current. Seventeen changed snapshots add only the private native
input marker. The Checkbox contract changes only its reviewed port body hash.

The full managed Checkbox run passes all nine checks for all eight examples.
Only the Checkbox verification record changes. All 48 AI record byte blocks
stay unchanged. Repeated behavior registration sends one real control click
because the existing event guard stops the second listener from acting.

The source and evidence repair is on main in `bdcdd96`. Commit hooks pass.

### Phase 6e.22: size accessibility time limits for complete state coverage

- The Collapsible file-tree accessibility test reaches its 30-second limit
  while scanning states. Its trace shows 41 navigations and 39 started axe
  scans. It continues normal work until the test closes the page. The semantic
  and pixel suites already set bounded time limits from the discovered state
  count. The accessibility suite uses the fixed default.
- Apply a bounded allowance after state discovery for official comparison and
  local-only accessibility paths. Reuse the existing state-count time policy
  if it covers the measured work. Keep action waits and the overall upper bound.
- Use the captured file-tree failure as the before result. Pass its complete
  accessibility example after the repair. Check a small state set and the
  existing time-policy tests. Add no test that only repeats a formula.
- Pass browser helper checks and complete file-tree accessibility coverage.
- The nested Drawer trace also reaches the 30-second overall deadline. It
  contains 15 scan navigations after discovery. Its last animated trigger
  action starts near the deadline. A separate geometry sample confirms the
  outer popup becomes stable. Treat this case as state-count budget work;
  do not infer a persistent motion defect from the last timeout message.
- The complete nested Drawer accessibility example passes in 46.3 seconds
  with a temporary 120-second limit. The temporary run uses the tested popup
  target and replay drafts. The source time policy is still unchanged.

**Commit:** `fix(verification): size accessibility time limits by state count`

### Phase 6e.23a: observe only visible interaction controls

- The real settings pages show a second comparison fault. The reference has
  two inputs when closed and four when open. The port keeps two hidden inputs
  in its closed panel. The observer counts them as current visible controls.
- Apply the observer's existing visibility rule to its control list. Keep the
  port's hidden DOM and the input values. Do not change native form submission.
- Check both real pages through opening and closing. Require four visible
  input values when open and two when closed. This is a separate comparison
  contract from the reviewed reference label rule.
- Pass browser helper checks and the Collapsible browser cases. Complete
  Collapsible verification after the label comparison repair.

**Commit:** `fix(verification): observe visible interaction controls`

The real reference case passes on the old observer. The port case fails
because its closed observation has four controls instead of two. The repair
passes both real cases. All nine Collapsible browser tests and all 108 browser
helper tests pass. Only the observer filter and its real browser owner change.

The observer repair is on main in `e541ead`. Commit hooks pass.

### Phase 6e.23: preserve Collapsible settings label links

- Generic behavior comparison finds empty reference input names but correct
  port names in the settings example. The pinned source has four inputs with
  ID `radius`. Its labels point to `radius-x` and `radius-y`. The port has
  unique IDs and correct label links. Reproducing the broken reference links
  would remove current accessibility behavior.
- Keep the pinned source and the port label links. Add one reviewed, named
  comparison normalization for this example's known reference label defect.
  Check the exact raw reference pattern before applying the normalization.
  Derive its intended X/Y names from the authored labels and control order.
  Normalize only reference input names for this example. Keep every other
  probe, control value, focus field, state, and comparison exact.
- Test the actual reference defect and the port's current label links on real
  pages, with the panel closed and open. A wrong port label or a changed
  reference pattern must fail. Do not use a blanket empty-name rule or rewrite
  fetched source. Attach the normalization reason to the browser report and
  document the precise accepted difference in the parity documentation.
- Pass helper and browser checks and complete Collapsible verification before
  the scoped commit. Review snapshots if source composition changes are needed.

**Commit:** `fix(verification): preserve corrected settings label semantics`

The current settings comparison fails before the rule because the two reference
input names are empty. It passes after the rule. All ten Collapsible browser
cases and all 108 helper tests pass. The real safety case compares closed and
open observations, keeps a wrong port label different, and rejects a changed
reference input ID. The rule and reason are attached to the generic report.

The full managed run passes all nine checks for all five Collapsible examples.
Only its verification record changes. All 48 AI record byte blocks stay
unchanged. No component body, source pin, snapshot, or pixel budget changes.

The rule and evidence are on main in `0970c3c`. Commit hooks pass.

### Phase 6e.24: hide outside Combobox add-ons while open

- The Combobox input-group example has one semantic difference. React hides
  its decorative globe add-on from assistive technology while the popup is
  open. The port hides only add-ons containing a button. The existing hook
  discovers both add-ons, but the button-only condition skips the globe.
- Use popup containment to distinguish outside add-ons from parts inside a
  popup input. Hide outside add-ons during opening and restore them on close.
  Keep inside popup add-ons exposed. Preserve selection, focus, filtering,
  caller composition, and the existing attribute ownership contract.
- Extend the existing input-group browser test to check both add-ons through
  opening and closing on both pages. Extend the popup-input accessibility check
  to prove its inside add-on stays exposed. Review the old mocked empty-addon
  test against this stronger browser proof before keeping duplicate coverage.
- Pass Base hook and package checks and complete Combobox verification. Review
  any necessary port ownership change and its hash and snapshots.

**Commit:** `fix(combobox): hide outside add-ons while the popup is open`

The real browser check confirms the outside globe fault. Both Popup cases and
the reference Input Group case pass the expanded owners. The old port Input
Group case fails because the globe add-on has no `aria-hidden="true"` while
open. The owners also check closing, reopening, filtering, selection, and focus.
The group assertions use authored names because the reference unmounts empty
groups while the port hides them.

Test audit: `Combobox keeps an empty Popup input addon exposed when it opens`
in `combobox.test.mjs` came from `c5f40ce`. It calls the private open method with
mocked attributes. Its add-on has no DOM parent, so the test cannot distinguish
an inside add-on from an outside add-on without a button. The four real browser
cases now protect that distinction. Remove the mock case and the button-only
classification. The production open path has native pointer and keyboard
callers. The risk is hiding inside Popup parts. The real inside and outside
cases and the complete Combobox run own that risk. No test seam is needed.

All four expanded add-on cases pass with the built repair. The full browser
suite exposes an existing reference readiness fault in its trigger-name case.
On the real groups page, the first ARIA snapshot says `combobox`; after the
existing React readiness signal it says `button`. Base UI sets its initial
input-inside-popup state before the outside input registers. Add the existing
readiness wait before the ARIA snapshot. Keep the exact role and name check.
The 92 Base client tests, 42 Base package tests, and Base static checks pass.

The final canonical browser suite passes all 17 cases. The 12 Combobox
snapshots are current. The complete managed run passes all nine checks for
all 12 official examples. Only the Combobox verification record changes. All
48 AI record byte blocks stay unchanged. No port body, contract, source pin,
attribute ownership, snapshot, or pixel budget changes are needed.
The scoped commit is `47436b0`.

### Phase 6e.25: compare portalled accessibility targets by logical ownership

- Command groups and scrollable dialogs report a new port listbox violation.
  Actual axe scans show the same separator-child violation in both renderers.
  React portals its dialog outside the preview root. The current target key
  includes a preview prefix only when it is a physical DOM ancestor. The
  equivalent port dialog is inside that ancestor, so the keys differ.
- Preserve the rule-and-target comparison. Assign the same logical preview
  ownership to corresponding portalled parts. Pass the current preview context
  to target normalization or reuse an existing ownership resolver. Do not
  merge unrelated targets, count only violations, or hide the separator.
- Prove the current mismatch on the real grouped Command pages. Check that an
  additional port violation on a different slot or occurrence still fails.
  Keep occurrence identity and cover a component whose popup is physically
  inside the preview. Use existing accessibility regression tests where they
  already own the rule-and-target contract.
- Pass helper checks and the complete grouped and scrollable accessibility
  examples. Document the logical ownership rule without changing thresholds.
- A temporary draft now passes the real grouped Command regression. The same
  test fails on the current code at the expected target comparison. The draft
  keeps popup slot identity and uses the page's sole preview as the logical
  owner of external popup parts. A physical preview owner takes precedence.
  Different slots, repeated controls, and another preview still report new
  violations. The six helper tests and complete grouped and scrollable scans
  pass in temporary files. The original full run has ended. The canonical
  repair is now ready for its scoped commit.
- The same target draft, with the disclosure transition draft, also passes
  complete sticky-footer and scrollable-content Dialog accessibility scans.
  Their scrollable-region warnings match the reference at the logical target.

The canonical owner test failed before the repair on the expected Command
listbox target mismatch. It now passes and detects an extra listbox, repeated
listbox slots, and an unrelated preview. All 108 browser helper tests pass.
The complete accessibility states pass for Command groups and scrollable
examples, and Dialog sticky-footer and scrollable-content examples.
The agent-browser scan confirms the same separator-child violation on both
Command pages. No markup, source pin, threshold, or example changes are needed.
All 48 AI record byte blocks stay unchanged. Shared browser inputs changed,
so final verification must refresh all 64 shadcn records.

**Commit:** `fix(verification): compare logical accessibility portal targets`

The scoped commit is `c006aac`. All commit checks pass.

### Phase 6e.26a: merge translation utility conflicts

The existing basic Command browser comparison first fails on both default top
and translation classes. Routing Dialog through Cn removes the top conflict,
but the comparison still fails on the vertical translation conflict.
Cn recognizes negative prefixes but has no translation utility groups.
Add the axis groups and the directional composite conflicts from the installed
pinned tailwind-merge implementation. Keep variants and independent axes.
The Cn public API test must cover variant conflicts, independent axes, the
combined XY utility, and translate-none across XYZ. The real Command comparison
owns the Dialog integration. No new test export or component test seam is needed.
Run the public Cn test before and after the repair, then package tests and static
checks. Review rendered class changes and verify the basic Command example.

The public merger case fails before the repair on the expected missing
translation groups. All 151 package tests and static checks pass after it.
The installed tailwind-merge source confirms the directional XY and XYZ rules.
All 463 shadcn snapshots were rendered. The only changes are the nine reviewed
Dialog class attributes from the paired caller repair. The complete basic
Command semantic, accessibility, and pixel checks pass, as do its two focus
and Escape cases. All 15 existing Dialog browser cases pass. The connected
agent-browser check also opens, focuses, and closes the basic dialog.
All 48 AI record byte blocks remain unchanged.

**Commit:** `fix(cn): merge translation utility conflicts`

The scoped commit is `8b7ccd0`. All commit checks pass.

### Phase 6e.26: merge Dialog caller popup position classes

- The basic Command dialog retains `top-1/2` and `-translate-y-1/2` along with
  caller overrides `top-1/3` and `translate-y-0`. React's shared class merger
  keeps only the caller position. The Dialog popup port appends class sets.
- Apply the shared class merger at the public Dialog popup boundary. Use the
  existing complete basic Command semantic comparison as the primary test.
  It fails on both expanded states because the port retains conflicting default
  and caller position classes. No Dialog package render test currently exists.
  Keep the stronger browser proof and preserve focus, dismissal, titles,
  descriptions, and caller content.
- Review the Dialog port hash and affected snapshots. Pass package checks and
  the complete basic Command comparisons before the scoped position commit.
  Full Dialog verification still requires the planned popup observation, focus,
  submit, and modal accessibility repairs. Keep that full requirement pending
  until those dependent phases finish. Do not claim the component is verified
  from a position-only test.

The existing basic Command semantic case fails before the repair on both
expanded popup states. The intermediate caller repair removes the top conflict
but leaves the missing Cn translation-group fault. The paired repairs now pass
all three complete basic Command comparisons, two native and port focus cases,
and all 15 Dialog browser cases. Both Dialog contract checks pass and only its
port-body digest changes. The 39 affected family snapshots and all 463 shadcn
snapshots were rendered. Nine snapshot files change only Dialog class values.
Four remove the overridden default top and vertical translation utilities;
five remove extra class spaces. No other DOM changes occur.
Package and static checks pass. Full Dialog verification remains pending until
its other planned repairs finish. No source pin or comparison limit changes.

**Commit:** `fix(dialog): merge caller popup position classes`

The scoped commit is `8a5c659`. All commit checks pass.

### Phase 6e.26b: merge Dialog caller footer alignment classes

The complete Share Dialog semantic check fails because its footer keeps both
`sm:justify-end` and the caller's `sm:justify-start`. The pinned React footer
uses `cn` and keeps the caller alignment. Apply the existing public class
merger at the footer boundary. The actual semantic comparison owns this
regression. No additional render test or test export is needed.

The before result is `/tmp/shadcn-readonly-canonical-close-button-checks.log`.
All 151 package tests and static checks pass after the repair. Both Dialog
contract checks pass. Only the port body digest changes. All 463 shadcn
snapshots were rendered. Only one footer class in `dialog-close-button.html`
changed. The reviewed result is `/tmp/shadcn-dialog-footer-snapshot-review.json`.

The complete Share interaction, accessibility, semantic, and pixel checks pass
after the repair. The nine-test command completed with exit code 0. Its log is
`/tmp/shadcn-readonly-footer-final-close-button-checks.log`. The owned servers
are stopped. Source pins, comparison rules, and all 48 AI records are unchanged.
Full Dialog verification remains pending until the other planned repairs pass.

**Commit:** `fix(dialog): merge caller footer alignment classes`

The scoped commit is `2505204`. All commit checks pass.

### Phase 6e.27: align Command example tests and composition

- Shortcut and group tests use an exact text selector for Settings. It matches
  both the group heading and the item on both pages. Select the intended group
  or item at its semantic boundary. Keep shortcut text, item counts, group
  boundaries, and keyboard focus assertions.
- The local default example adds an explicit input label absent from the
  pinned example. Align the caller composition. Keep the public input's label
  support and placeholder. Do not add a global empty-name normalization.
- Complete the logical accessibility target and shared Dialog position repairs
  first. Keep the inherited separator warning visible in the reference results.
- Review affected snapshots and any port change. Pass Storybook and browser
  checks and complete Command verification before the scoped commit.

All four existing shortcut and grouped cases fail before the selector repair
because Settings matches both the group heading and an item. The real default
interaction case also fails on the extra local input label. Select the named
groups and keep shortcut text, item counts, separator counts, and focus checks.
The fixture repair removes only the default caller's explicit label. The public
Command input still accepts caller labels. No port or contract change is needed.
All 80 Storybook tests and static checks pass. Six Command snapshots were
rendered; only the default input label changes. The complete managed run passes
all nine checks for all six official examples. Only the Command verification
record changes. All 48 AI record byte blocks remain unchanged. The managed
servers stop after the run. The raw before-result logs and final managed result
are saved in `/tmp/shadcn-command-selectors-red.log`,
`/tmp/shadcn-command-composition-red.log`, and
`/tmp/shadcn-command-composition-full-verification.log`.

**Commit:** `fix(command): align official example composition and tests`

The scoped commit is `0f3b1c4`. All commit checks pass.

### Phase 6e.28: align Calendar month navigation labels

- Six Date Picker interaction examples fail on the focused month navigation
  button name. The English port uses `Go to the previous month`. DayPicker
  uses `Go to the Previous Month`. The Arabic port also uses the English name,
  while the reference has `اذهب إلى الشهر السابق`.
- A current scan also shows missing navigation landmark names on the port.
  React names the default, Arabic, and Persian landmarks `Navigation bar`,
  `شريط التنقل`, and `نوار ناوبری`. The port omits all three names.
  The actual page result is `/tmp/shadcn-calendar-navigation-discovery.json`.
  Match these names through the same existing locale value.
- Calendar renders both button names as fixed English strings. Use the existing
  locale input to select the pinned previous and next month names. Check the
  declared English, Arabic, and Persian locales. Preserve the browser locale
  fallback and the current keyboard and month navigation behavior.
- Extend the existing Calendar public rendering tests for these accessible
  names. Use the captured interaction failures as the browser before result.
  Check the repaired names on the Date Picker pages and after month changes.
- Complete the day class repair first. Review snapshots and the port hash.
  Pass package checks, complete Calendar verification, and complete Date
  Picker verification. Keep all example states and comparison thresholds.

**Commit:** `fix(calendar): align localized month navigation labels`

The Calendar repair passes all nine checks for its twelve official examples.
Date Picker passes its eight required checks for its eight official examples.
Date Picker is a documentation family and has no generated component check.
The full verification command completed with exit code 0. The log is
`/tmp/shadcn-calendar-nav-full-verification.log`.

All 151 package tests and the package static checks pass. The offline and
online Calendar contract checks pass. All twenty snapshot changes contain
only the three navigation accessible names. Only the Calendar and Date
Picker verification records changed. All 48 AI record byte blocks remain
unchanged.

The scoped commit is `4bfae45`. All commit checks pass.

### Phase 6e.29: observe visible popup controls in interaction checks

- Generic Dialog interaction checks fail for default, close-button, and RTL.
  React popup fields are outside the preview. The check sees no controls.
  Phoenix fields are inside the preview. The check includes these controls
  both when the popup is open and when it is hidden.
- Observe the preview and its visible controlled popup as one logical scope.
  Keep each node only once. Exclude controls hidden by the popup or an
  ancestor. Preserve field names, values, states, and focus comparison. Do not
  remove visible fields from the comparison to make the pages agree.
- Test actual Dialog fields while open and after Escape on both pages. Use
  the captured mismatch as the before result. Keep a control difference
  detectable in the open popup. Extend an existing browser owner test and
  preserve the six interaction helper contracts.
- Review the Avatar readiness draft before applying this repair. Both changes
  affect the shared interaction helper. Pass helper checks and complete
  Dialog interaction verification.
- The temporary regression fails on both current pages for the expected
  reason. React omits open fields; Phoenix reports hidden fields after close.
  The draft passes both cases and reports a changed Username value. Its six
  helper tests pass. Complete generic default, close-button, and RTL Dialog
  examples also pass. The responsive Drawer Dialog has the same scope defect.
  Canonical application and the scoped commit remain pending.

**Commit:** `fix(verification): observe visible controls in popup scope`

The current-source regression fails on React because the open popup controls
are absent from its result. Phoenix passes with the earlier visibility repair.
The log is `/tmp/shadcn-popup-observation-current-red.log`. The scoped repair
adds the visible controlled popup to the preview scope and removes duplicate
physical controls. Controls below an accessibility-hidden or inert ancestor
are excluded. Field names, values, states, and focus remain in the comparison.

All 27 tests selected by the Dialog file filter pass, including Alert Dialog.
The actual popup regression runs
on both renderers. It checks two open fields, no closed fields, and a changed
Username value. All three affected Dialog interaction examples and the Drawer
Dialog interaction example pass. All 108 verification helper tests pass.
The green logs are `/tmp/shadcn-popup-observation-dialog-green.log`,
`/tmp/shadcn-popup-observation-dialog-interaction-green.log`,
`/tmp/shadcn-popup-observation-drawer-interaction-green.log`, and
`/tmp/shadcn-popup-observation-all-node-green.log`.

An isolated agent-browser session confirms the Dialog field values and focus
return after Escape. The browser and owned servers are closed. This repair
does not change component code, snapshots, source pins, comparison thresholds,
or verification records. Full component verification follows the remaining
Dialog repairs and the final common helper changes.

The scoped commit is `ea7a8d1`. All commit checks pass.

### Phase 6e.30: preserve read-only fields during state replay

- Dialog close-button accessibility times out because discovery declares the
  read-only Link field editable. Replay calls `fill`, which cannot complete.
  A longer timeout cannot correct this failure.
- Keep read-only controls in observations and accessibility scans. Exclude
  them from text mutation probes and from editable visual state discovery.
  Use the same eligible-control rule in discovery and replay locators so that
  control indices remain correct. Preserve editable fields and native
  selection and checkable states.
- Test the real Share dialog on both pages. Replay all declared states and
  confirm that the Link value stays unchanged. Include an editable dialog
  field to prove that normal text entry remains in the state model.
- Pass helper checks and complete close-button behavior, accessibility,
  semantic, and pixel verification. Keep the existing reference field
  read-only and keep all valid official states.
- The temporary replay regression fails on both current renderers at the
  read-only fill. The draft passes both cases with the normal 30-second test
  limit. It keeps the Link value and also replays an editable Name state.
  All 30 interaction and visual state helper tests pass. The complete Share
  accessibility scan passes with the target and transition drafts. The main
  source, remaining complete checks, and commit are still pending.

**Commit:** `fix(verification): preserve read-only controls during replay`

Both current-source replay tests fail at the read-only Link fill operation.
The actual before log is `/tmp/shadcn-readonly-canonical-red.log`. The repair
excludes read-only text fields from both mutation selectors. Discovery and
replay use the same selectors. Observations and accessibility scans still
include these fields. Native select, checkable, and range controls are unchanged.

The actual Share replay tests pass on both renderers. They replay every declared
state, preserve the Link value, check that Link has no text mutation probe, and
enter text in the normal editable Name field. The log is
`/tmp/shadcn-readonly-canonical-green.log`. All 108 verification helper tests
pass in `/tmp/shadcn-readonly-canonical-node-green.log`.

The complete Share interaction, accessibility, semantic, and pixel checks pass
with the footer alignment prerequisite. The final nine-test command completed
with exit code 0 in `/tmp/shadcn-readonly-footer-final-close-button-checks.log`.
No component verification record changed. The final full run must refresh
evidence after all common helper repairs.

The scoped commit is `36e1236`. All commit checks pass.

### Phase 6e.31: focus a Dialog that has no focusable child

- The no-close-button example has no input or button inside its popup.
  React focuses the dialog. Phoenix leaves focus on the trigger. The popup
  already has `tabindex="-1"`. The opening command calls `focus_first`, which
  searches descendants and has no popup fallback.
- At the shared Dialog or Overlay boundary, focus the popup when no child
  accepts focus. Preserve normal first-child focus, Escape, focus return,
  modal containment, and explicit host focus choices.
- Extend the existing browser focus test with the no-close-button example.
  Prove the current focus failure. Test focus inside the popup, Tab containment,
  Escape, and focus return after the repair. Review related overlay owners
  before changing a shared hook.
- Pass the affected Base and package checks and complete empty Dialog example
  checks before the scoped commit. Review snapshots and input identity changes.
  Full Dialog verification remains required after the pending Save, nested
  entry, and modal ownership repairs. Keep that full requirement pending.

**Commit:** `fix(dialog): focus the popup when no child accepts focus`

The existing focus owner fails on the actual empty popup before the repair.
Its normal Name field case passes. The before log is
`/tmp/shadcn-dialog-empty-focus-browser-red.log`. The installed LiveView
`focus_first` executor searches descendants and never focuses the root.
The pinned React empty popup keeps focus on its dialog container during Tab.
An isolated agent-browser session confirms that reference behavior.

The shared opening command now focuses the popup after it stores return focus
and before it searches for the first child. No hook, new API, or asset build
is needed. The existing browser focus owner now covers normal Name focus,
empty popup focus with Tab and Shift+Tab, and an appended caller Username
focus command. Escape and focus return pass in each case.

All 42 Base and 151 shadcn package tests and both static checks pass. All 27
Dialog browser tests and eight related Alert Dialog, Command, Drawer, and
Sheet focus checks pass. All nine empty Dialog interaction, accessibility,
semantic, and pixel tests pass in
`/tmp/shadcn-dialog-empty-focus-complete-example.log`. The command completed
with exit code 0. The repaired agent-browser focus and dismissal checks pass.

All 463 shadcn snapshots were rendered. The thirty changed snapshots contain
only 38 added popup focus commands. The exact review is
`/tmp/shadcn-dialog-empty-focus-snapshot-review.json`. Port specs and
verification records are unchanged. All 48 AI record byte blocks are unchanged.

The scoped commit is `5df749a`. All commit checks pass.

### Phase 6e.32: keep sample Dialog Save actions on the current page

- Default and RTL semantic checks fail after Save. A real browser check shows
  that the React Save button has no native form owner because the popup is
  portalled. It stays on the current page with the dialog open. The Phoenix
  button belongs to the outer form. Its native GET submits the field values,
  reloads the preview, and closes the dialog.
- Align this behavior in the official example composition. Keep the Submit
  button type, field names, values, and the form. Prevent the sample's native
  navigation through an existing LiveView form command. Do not change public
  application form submission or add a new component API for this fixture.
- Extend the real Dialog browser tests for Save on both default and RTL pages.
  Require an unchanged URL, an open popup, and retained edited values. Keep
  Cancel and Escape dismissal checks.
- Pass Storybook checks and complete affected semantic and pixel examples.
  Review snapshots before the scoped example commit.
- Canonical repair passes all four Save cases and all 31 Dialog and Alert Dialog
  browser tests.
  Storybook passes 80 tests and its static checks. Only the two outer form
  attributes change in reviewed snapshots. The complete default and RTL
  interaction, accessibility, semantic, and pixel run passes all 13 tests
  after phase 6e.33. All 48 AI record byte blocks remain unchanged.

**Commit:** `fix(dialog): preserve sample state after Save actions` (`c7dd40b`)

### Phase 6e.33: finish popup focus entry before a nested action

- Default and RTL semantic and pixel checks show the first field focused
  after replay edits the second field. The nested interaction path waits for
  a visible popup but does not settle opening focus before it calls `fill`.
  LiveView runs its first-child focus command immediately and again after
  two animation frames.
- Confirm the ordering on both real pages. Test replay of the Username state
  and require that field to have focus when capture starts. Use the captured
  semantic and pixel failures as the before result.
- If the opening focus command runs after text entry, wait for actual popup
  entry at the nested path boundary before the next action. Reuse the existing
  frame and finite transition wait. Keep focus in the comparison and keep all
  pixel thresholds. Do not force focus after capture to hide a product defect.
- Pass shared state checks and complete affected Dialog checks. Review nested
  menu and combobox paths because they use the same replay function.
- The small unthrottled regression passes on current code, so it is not a
  sufficient before result. Delivering callbacks every eight real browser
  frames reproduces the Phoenix focus failure. The reference still passes.
  The draft waits for entry before the action and passes both throttled cases.
  It also passes all 24 visual state helper tests. The responsive Drawer
  Dialog reports the same Username focus and pixel failure. Complete affected
  verification was pending at the draft stage.
- Canonical repair passes both throttled Username cases, the nested radio
  menu and editable combobox owners, all four Popover and read-only Share
  cases, and all 108 Node helper tests. Default and RTL Dialog pass all
  13 interaction, accessibility, semantic, and pixel tests. Full responsive
  Drawer/Dialog verification still needs the phase 6e.39 width repair.
  The scoped commit changes no thresholds, states, pins, or verification
  records. Its commit hooks pass.

**Commit:** `fix(verification): finish popup entry before nested actions` (`a17b728`)

### Phase 6e.34: keep a modal trigger target stable during replay

- The reference default Drawer hides its trigger from the accessibility tree
  while the modal is open. The interaction probe locator excludes
  `aria-hidden="true"`. After its click, the same locator cannot find that
  trigger to read the expanded attribute. This causes the captured timeout.
- Retain the actual disclosure target before opening. Read its state while
  the modal is open and after it closes. Keep discovery limited to visible,
  accessible controls. Do not make hidden controls eligible for new probes.
- Add a real default Drawer replay regression. It must open and close through
  the shared probe on both pages. Prove the current reference timeout, then
  require the expected expanded state and focus return after the repair.
- Preserve the Avatar image, read-only field, and visible popup scope repairs
  when changing the shared helper. Pass helper checks and complete Drawer
  interaction verification after the product focus repair.
- The actual default Drawer regression times out on the current reference
  target lookup. The port case passes. The temporary retained-target draft
  passes both cases, including popup state and focus return. Its six helper
  tests pass. The draft preceded the canonical repair.
- The canonical React case reproduces the 30-second trigger lookup timeout.
  Phoenix passes before the repair. The retained disclosure target passes
  both cases after the repair. The four existing Dialog and Collapsible
  observation owners and all 108 Node tests also pass. The shared helper
  retains its fixture image wait, observation rules, and discovery rules.
- Complete default, nested, and non-modal Drawer interaction replay now
  finishes. Each comparison fails only on the known opening focus difference
  in phase 6e.35. Keep those failures visible until the product repair.
  No component source, snapshot, spec, or verification record changes.

**Commit:** `fix(verification): retain disclosure targets during modal replay` (`c03e126`)

### Phase 6e.35: use the pinned Drawer opening focus

- The pinned Drawer popup defaults its initial focus to the popup itself.
  The port opens through the shared Dialog first-child focus command. Real
  default, non-modal, and nested pages confirm the different focus targets.
- Give Drawer its own opening focus choice while retaining the shared open
  state, focus stack, dismissal, and return behavior. Keep the responsive
  desktop Dialog first-child focus. Do not change Dialog's normal focus rule.
- Extend the existing Drawer browser focus checks for modal, non-modal,
  nested, and responsive desktop and mobile cases. Use the captured generic
  focus failures as the before results. Require popup focus and focus return.
- Pass affected Base and package checks and complete Drawer verification.
  Review snapshots and the changed port hash before the scoped commit.
- Canonical before tests fail in six Drawer cases because the popup lacks
  focus. The desktop Dialog case passes. `LiveBase.Dialog.open/3` now accepts
  `:first` or `:popup`. Existing opening calls keep their first-child rule.
  Drawer chooses popup focus without adding another client controller.
- All 42 Base and 151 shadcn tests and their static checks pass. The new Base
  API required a forced refresh of the shadcn type checker dependency data.
  The repeated full static check passes. Both Drawer contract checks pass.
  Only the reviewed port body digest changes in the contract.
- Rendering all 463 snapshots changes seven Drawer files. Exact comparison
  shows only ten removed first-child focus commands. Desktop Dialog remains
  unchanged. The complete browser run passes 45 tests, consisting of 14
  Drawer, 21 Dialog, and 10 Alert Dialog cases. The previously failing
  default, nested, and non-modal Drawer interaction comparisons all pass.
- The complete non-modal example passes all nine interaction, accessibility,
  semantic, and pixel tests. The agent-browser check confirms actual popup
  focus and Escape focus return on React and Phoenix. The browser session
  and owned servers are closed. Commit hooks pass. All 48 AI record byte
  blocks remain unchanged. Full Drawer verification still needs phases
  6e.36 through 6e.39 and the final fresh source run.

**Commit:** `fix(drawer): focus the popup when it opens` (`97ca5bd`)

### Phase 6e.36: align delivery Drawer title classes

- The default Drawer titles lack the pinned `gap-2` on four rows. The first
  row adds caller `flex items-center` to the same base classes and therefore
  has duplicate class tokens. Both differences appear in captured semantic
  failures. The pinned example gives every FieldTitle the same caller class.
- Add the missing caller class to all delivery rows. Merge caller classes
  in the public FieldTitle part through the existing class merger. Preserve
  labels, field composition, radio state, and delivery confirmation.
- Add the public FieldTitle class override owner. No such test exists in the
  current package. Check all rows through the real delivery comparison. Keep
  the existing connected selection tests.
- Pass package and Storybook checks, complete Field verification, and the
  affected Drawer checks. Review snapshots and the port hash.
- The new public render test fails before repair. It keeps conflicting
  display, width, and alignment classes. The complete package now passes
  152 tests and its static checks. Storybook passes 80 tests and its static
  checks. The test run restores the fixture exactly. Both Field contract
  checks pass. Only the reviewed Field port digest changes.
- All 463 snapshots render. Exact review finds only 15 FieldTitle class
  attribute changes in seven files. Five delivery titles gain the correct
  merged classes. The other ten attributes only lose trailing spaces.
  The existing Field slider, select, and delivery selection tests all pass.
- The complete default Drawer run passes seven tests and fails two. All 30
  title class differences are resolved. Six trigger `aria-hidden` differences
  remain for phase 6e.37. Confirm Delivery Time still differs by 1,602 pixels.
  The stored before record has the same image failure. The reference shows
  a confirmation notice with the selected label. The port only closes the
  Drawer. Phase 6e.59 must complete that independent caller behavior.
- Full Field verification still needs the radio focus and validation image
  repairs in phases 6e.41 and 6e.45. Full Drawer verification needs phase
  6e.37 and the other Drawer repairs. No verification record, state, pin, or
  threshold changes. All 48 AI record byte blocks remain unchanged.
  The scoped commit hooks pass.

**Commit:** `fix(field): merge title classes in delivery drawer rows` (`8a6b74f`)

### Phase 6e.37: preserve modal Drawer background accessibility

- The default reference Drawer marks its trigger `aria-hidden="true"` while
  open. The port leaves it exposed. On the nested page, the reference hides
  the containing main region instead. The port exposes that region. The
  shared Overlay currently locks scroll and traps Tab but does not hide the
  background from the accessibility tree.
- Review the reference's outside-node marking before implementing the shared
  modal behavior. Keep the popup, live regions, nested front drawer, and any
  required portal transport accessible. Restore previous attributes on close,
  destruction, and server patches. Preserve non-modal access and nesting.
- Test the public background accessibility contract through real browser
  pages. Require outside content to be unavailable only while a modal is open.
  Test restoration and successive nested close operations. Preserve authored
  hidden state and unrelated overlays.
- Pass affected Base and browser checks and complete affected component
  verification. Keep current accessibility rules and semantic thresholds.

The shared repair is committed as `8262f70`. One modal stack now controls
background access and page scroll. Only the front modal receives Tab input.
The hook restores caller attributes after close, view removal, and document
changes. Live regions and non-modal content keep their required access.

All 68 affected browser tests passed with no retries or skipped tests. These
include four nested levels on both pages, changed background attributes,
independent modal locks, fast dismissal, and the complete default Dialog and
Drawer comparisons. The manual browser check confirmed front drawer access,
nested keyboard focus, retained scroll lock, and Notifications access.

Base passed 42 Elixir tests, 92 JavaScript tests, and all static checks.
Storybook passed 80 tests and all static checks. All 463 shadcn snapshots are
current. All 108 browser-tool tests passed. All 48 AI record byte blocks are
unchanged. No source pin, state, comparison limit, component contract, or
verification record changed. Commit checks passed. Complete Drawer verification
still requires the compact, responsive, and nested-size repairs.

**Commit:** `fix(overlay): preserve modal access and focus` (`8262f70`)

### Phase 6e.38: replay actions in a compact Drawer

- Snap-points accessibility, semantic, and pixel checks time out while clicking
  Close. The reference button is outside the viewport at the compact snap
  point. Discovery treats it as visible. A normal pointer click cannot reach
  it in this state.
- Inspect the real compact geometry after entry completes. Apply
  the tested entry readiness repair first. Keep all valid
  actions. Use a real supported user action to expose the compact drawer's
  controls before pointer activation, or a keyboard activation when the
  control is reachable through the keyboard. Do not force pointer clicks
  through the viewport or use a synthetic DOM click to hide this failure.
- Test replay through the actual shared state path on both pages. Require
  dismissal and correct focus return. Keep named pointer, drag, and snap
  checks. Do not remove the Close state or increase the timeout to mask an
  unreachable control.
- Pass shared state checks and complete snap-points verification.
  Review the resulting modality, focus styles, and pixel state on both pages.
- Both pages settle at popup height 624 px and top 224 px in the 720 px
  viewport. Close is at top 796 px. A real Tab/Enter check reaches it, closes
  the popup, and returns focus on both pages. With the entry prerequisite,
  current shared replay fails both cases at the offscreen pointer click. The
  temporary draft uses Enter only for an offscreen action in a snap-point
  Drawer. Both replay cases and all 24 visual state helper tests pass. The
  complete snap-points accessibility example also passes with the temporary
  target and entry corrections. Canonical application, complete semantic and
  pixel checks, and the scoped commit remain pending.

The repair is committed as `36fec6c`. Both real browser owners failed before
the repair because the pointer could not reach Close. At 1280 by 720 pixels,
both settled popups start at 224 pixels and have a height of 624 pixels. Close
starts at 796 pixels. The manual check used Tab and Enter and confirmed close
and trigger focus return on both pages.

Shared replay now follows real Tab input to the target and then sends Enter
when an action in a snap-point Drawer is outside the viewport. The Tab limit
comes from the current controls. Replay fails if the target is not reachable.
Other actions retain their pointer input. No forced click or direct focus
command is used.

All nine complete snap-points comparison checks passed. All 24 shared browser
state tests and all 108 browser-tool tests passed. All 48 AI record byte blocks
are unchanged. No component source, snapshot, contract, state, pin, image limit,
or verification record changed. Commit checks passed. The before and complete
logs are `/tmp/shadcn-compact-current-browser-red.log` and
`/tmp/shadcn-compact-current-complete.log`.

**Commit:**
`fix(verification): replay compact drawer actions through user controls`
(`36fec6c`)

### Phase 6e.39: align the responsive Drawer desktop Dialog class

- The responsive example's desktop Dialog lacks the pinned caller class
  `sm:max-w-[425px]`. Captured semantic failures show this class difference
  in three open states. Its Username state also has the entry focus failure
  already covered by phase 6e.33.
- Add the pinned caller class through the existing Dialog class input.
  Complete the Dialog class merge prerequisite first. Keep the mobile Drawer
  composition, breakpoint, field values, and responsive switch behavior.
- Extend the existing responsive browser check only where it adds a current
  public contract. Use complete semantic comparison to prove the caller class.
  Pass Storybook and browser checks and complete responsive example verification.
  Review affected snapshots before the scoped commit.

The repair is committed as `e8197da`. The current before comparison failed
with three missing desktop popup class values. The existing Dialog class
input now receives `sm:max-w-[425px]`, as specified by the pinned caller.
The mobile composition is unchanged.

All 11 affected browser checks passed. These include the existing desktop
and mobile owners and all nine complete responsive example comparison checks.
The manual browser check confirmed matching desktop geometry, initial Email
focus, Escape focus return, and both mobile forms. The active Vega stylesheet
produces a width of 448 pixels on both desktop pages, with the caller class
present on both.

Storybook passed all 80 tests and static checks. All 463 shadcn snapshots are
current. Exact review shows only the added class on the desktop popup in
`drawer-dialog.html`. All 48 AI record byte blocks are unchanged. No component
body, contract, pin, state, comparison limit, or verification record changed.
Commit checks passed. The before and complete logs are
`/tmp/shadcn-responsive-current-semantic-red.log` and
`/tmp/shadcn-responsive-current-complete.log`.

**Commit:** `fix(drawer): align responsive desktop dialog composition` (`e8197da`)

### Phase 6e.40: preserve labelled control names in observations

- The generic Field checks discover Month correctly, but observations read MM.
  Discovery follows `aria-labelledby`; observation does not. The actual browser
  accessible names are correct on both pages in English and Arabic.
- Read referenced label text before falling back to native labels or content.
  Keep this change separate from popup scope and read-only replay repairs.
- Extend the existing Select browser suite with real Field select observations.
  Current helpers pass React and fail Phoenix in both languages. The temporary
  draft passes all four cases and the six interaction helper tests.
- Apply the scoped patch after the active run. Pass complete Field default and
  RTL generic checks, helper checks, and source verification before the commit.

The current regression runs on `11f3005`. React passes both language cases.
Phoenix passes the actual browser label checks, then returns `MM` in the
opened observation instead of `Month` or `الشهر`. The four cases finish in
8.2 seconds. The result is `/tmp/shadcn-label-names-red-review.json` with
the original report and saved failure traces. The source change adds the
same referenced-label lookup that discovery already uses. Include the Drawer
modal disclosure probe when checking shared observation callers.

Current success proof includes all four English and Arabic cases, six helper
tests, all 24 Select and Field behavior cases, and six shared Dialog, Drawer,
and Collapsible observation cases. All 13 Field examples pass accessibility,
interaction, structure, and pixel checks with the phase 6e.45 capture repair.
The complete Field run has 57 passes in 7.0 minutes, with no skips or unstable
results. Current reports use `/tmp/shadcn-label-names` and
`/tmp/shadcn-native-validation` . Storybook passes 80 tests. All 463 Shadcn
snapshots are current. Static checks pass with zero errors. No snapshot bytes
changed.

**Commit:** `fix(verification): preserve labelled control names in observations`
(`20369b0`)

### Phase 6e.41: keep radio label focus on the visible control

- Field choice-card label clicks select the correct native value, but leave
  focus on the hidden form input. The pinned reference focuses the visible radio.
- Redirect native radio focus from the group hook to its visible control.
  Remove the added listener when the hook is destroyed. Keep selection and form
  change events. Handle a second click on an already selected label too.
- The real browser regression in the existing Field suite passes React and
  fails Phoenix on current focus. A temporary asset draft passes both pages,
  including the second label click, and preserves the native value vm.
- Apply the source patch after the active run. Pass radio and Field browser
  coverage, package checks, and complete affected example verification.

The current regression confirms the failure on commit `77b85ec`. React passes;
Phoenix selects `vm` but leaves focus on the hidden `vm-z4k` input. The separate
browser event log records native input focus before its change event, with no
page update. The saved failure is `/tmp/shadcn-radio-current-red-review.json`
and `/tmp/shadcn-radio-current-red-trace.zip`.

The current examples use this group hook in all seven Radio Group examples,
Field radio and choice-card, and the default Drawer delivery form. Run all
comparison layers for those complete examples. Keep the existing direct Field,
radio selection, and Drawer delivery checks. Field default and RTL do not use
this hook; their name and validation repairs remain in phases 40 and 45.

Phase 41 is complete in commit `f79a404`. All six focused browser checks pass.
They include both label clicks on the reference and port, plus the existing
Field and radio selection checks. Complete comparisons pass for all seven
Radio Group examples, both affected Field examples, and the default Drawer.
The batches pass 33, 13, and 9 checks. The six default Drawer opening and
delivery confirmation checks also pass. None of these runs has skipped tests,
failures, or flaky results. The reports use the prefix
`/tmp/shadcn-radio-current-` with `radio-full`, `field-full`, `drawer-full`,
and `drawer-behavior` followed by `-review.json`.

The manual check after LiveView connection puts focus on `vm-z4k-control`,
checks that control, and keeps the native value `vm`. The result is
`/tmp/shadcn-radio-current-manual-proof.json`. The first manual attempt clicked
before connection and is not evidence for the hook. Both browser sessions are
closed. The group removes the added focus listener when the hook is destroyed.

Base passes 42 Elixir tests, 92 JavaScript tests, and its static checks.
Storybook passes all 80 tests and static checks. The saved test input hashes
match after the suite. All 463 shadcn snapshots match. No port, snapshot, source
contract, upstream pin, verification record, comparison state, or threshold
changed. All 48 AI record byte blocks are unchanged. The commit hooks pass and
restore the five pending documentation files. All owned test servers are
stopped. The separate arrow-key failure remains open in phase 64.

**Commit:** `fix(radio-group): keep focus on the visible control`

### Phase 6e.42: preserve the Input form Country name

- The reference Country trigger uses its native associated label. The port
  instead names it from its generated selected-value node, United States.
  Both buttons have the native Country label; the port's `aria-labelledby`
  overrides that label. This differs from the Field observation defect.
- Connect the example Select to its existing form-country-label id through
  the public labelledby input. Keep the selected value and option changes.
- Extend the existing Input browser check to verify Country before and after
  selection, with the native value. Prove the current failure and
  repaired behavior on both pages. Keep the public Select naming choices.
- Pass Storybook and browser checks and complete Input form verification.

The current regression on `20369b0` passes React and fails Phoenix at the
initial accessible name. React reports `Country`. Phoenix reports `United States`
through its selected-value label reference. The two cases finish in 10.4 seconds.
The fresh report, saved trace, and error are `/tmp/shadcn-country-red.json`
and `/tmp/shadcn-country-red-review.json`. Apply the label id and public
`labelledby` caller input, then prove the names before and after Canada.
Both native Country inputs remain unnamed. The test checks values, not submission.

Both current Country name cases pass before and after Canada. The native
values remain `us` and `ca`, and all entered text remains in place. All eight
Input owner cases pass. All 15 Input examples pass the complete accessibility,
interaction, structure, and pixel layers, with 65 passes in 5.4 minutes.
No skips, unstable results, state exclusions, or comparison limit changes occur.
Fresh reports use `/tmp/shadcn-country`, with summary
`/tmp/shadcn-country-browser-review.json`.

The source uses only the public label id and Select `labelledby` input. The
snapshot review confirms that only `input-form.html` changes. Its one changed
attribute replaces `form-country-value` with `form-country-label`; all other
bytes match. The snapshot index, port bodies, facts, and pins remain unchanged.
Storybook passes 80 tests in 62.0 seconds. All 463 Shadcn snapshots are current.
Static checks pass with zero errors. All three test input files have their
original bytes. All 48 AI record byte blocks remain unchanged.

**Commit:** `fix(input): preserve the country field name` (`bd2ae35`)

### Phase 6e.43: preserve nested choices and menu labels

- A Push Notifications checkbox click updates its state, then closes all three
  port menus. React keeps the complete branch open. Removing the native
  phx-click-away binding in an isolated page preserves the three port menus.
  The floating hook already follows logical submenu ownership, but the native
  outside-click handler also runs and ignores that relationship.
- Let the Dropdown Menu root give its dismissal command to the floating hook
  through an internal data attribute. Preserve other existing dismissal owners.
  The hook must keep child popup choices inside and dismiss genuine outside
  clicks. Keep item actions, keyboard dismissal, and selection behavior.
- Extend the existing Dropdown Menu suite with two nested checkbox choices
  and outside dismissal. Current React passes; Phoenix loses the menu branch.
  The temporary command-attribute and asset draft passes both pages.
- Temporary markup is applied after LiveView connects; it is not a compiled
  component proof. Apply the canonical template and hook after the active run,
  pass hook and package checks, all menu browser suites, and complete complex
  semantic and pixel comparison before the scoped commit.

The pre-fix regression on `bd2ae35` passes React and fails Phoenix after the
first nested checkbox choice. Both pages open three menu levels. Phoenix changes
the checkbox to false, then exposes zero visible menus instead of three.
The two cases finish in 11.3 seconds. The report, trace, and exact failure are
saved under `/tmp/shadcn-nested-menu-red`, with
`/tmp/shadcn-nested-menu-red-review.json`. Apply the reviewed hook command and
root attribute repair before rebuilding the asset and repeating the same test.

The fresh compiled menu repair passes both browser cases in 6.1 seconds.
The canonical render changes 49 snapshots with 79 command attributes. Moving
the command to a data attribute also exposes an artifact stability gap.
The snapshot serializer sorts JSON keys only in `phx-` attributes. The new
command therefore retains VM map key order. Extend the existing serializer
owner with this command attribute, prove its pre-fix failure, then apply the
same ordering rule. This is a deterministic snapshot contract, separate from
browser dismissal. It requires no new export or test-only production input.
Regenerate the affected snapshots and review unchanged command values and markup.

The serializer regression fails before the new attribute rule, then all four
serializer cases pass. The final snapshot review explains all 49 changed files,
79 transport moves, and three JSON key normalizations in Open in Chat. Command
values, array order, other markup, the snapshot index, and upstream fact bytes
are unchanged. Proof is `/tmp/shadcn-nested-menu-snapshot-review.json`.

The first wider direct menu run passes 55 of 57 cases. The React RTL Menubar
case sends its key before React readiness. The Phoenix submenu case sends
ArrowLeft about 5.3 milliseconds after ArrowRight, before the scheduled entry
frame can move focus. A four-case rerun also loses the React opening click.
Its traces and exact failures are preserved. Using the existing React readiness
helper makes all four cases pass in 6.5 seconds. Extend the existing submenu
owner to assert real focus inside the submenu before its close key. This adds
no test case, focus operation, fixed sleep, or production seam. It protects the
keyboard-entry contract and prevents a visibility-only driver race. Immediate
key reversal before the entry frame remains outside this proof.

The complete Dropdown run passes 43 of 57 checks. Twelve interaction checks
report missing menu labels. The accurate label observation exposes a production
gap. The pinned Menu links each popup to its active trigger. Add that link to
the root and both submenu paths. Preserve a Context root's empty name and all
caller overrides of the same attribute. Extend the existing browser cases with
real accessible-name checks. No new case or production test input is needed.

The fresh label regression passes React and fails Phoenix at the root menu
name. All three menu levels open first. Phoenix has an empty name instead of
Complex Menu. The saved report is `/tmp/shadcn-menu-label-red-review.json`.
Apply the reviewed label source and repeat the owner and complete comparisons.

The linked-state regression passes React and fails Phoenix at Show Sidebar
after the Email click. Phoenix keeps true where false is required. The result
is saved in `/tmp/shadcn-menu-label-linked-state-red-failures.json`. The reviewed
caller repair uses existing JS command composition to update the other view.
Both controls keep their own local selection command. Push remains independent.

The same full run finds a complex example state difference and a six-pixel
submenu position difference. The pinned caller binds Show Sidebar and Email
Notifications to the same email value. The port currently toggles them
independently. Preserve the reference's linked caller state through real
selection commands. Prove both controls change together and that Push
Notifications remains independent. Inspect actual collision state and the
pinned positioning source before changing shared geometry. Keep all official
states, source pins, and comparison limits.

**Commit:** `fix(dropdown-menu): preserve nested choices and menu labels` (`321ce90`)

The canonical dismissal, menu naming, linked caller state, serializer and
snapshot repairs are committed in `321ce90`. The label overrides and nested
choices remain supported. The collision repair is committed separately in
phase 67. Complete Dropdown Menu semantic and pixel checks pass. The saved
five-family comparison still has separate Menubar, Context Menu and Tooltip
failures. It is not complete shared caller proof or final release proof.

### Phase 6e.44: preserve Hover Card entry during pointer clicks

The actual pinned reference uses Base UI Preview Card. Its pointer-down handler
keeps the pending hover timer. Ordinary mouse focus does not restart that timer.
Record the pointer press before the Hover Card guard, then retain its timer.
Keep Tooltip cancellation and mouse-focus rejection unchanged.

The final real-event regression runs three times on each host. React passes
all three. Phoenix fails all three because the popup stays hidden. All six
runs record trusted entry and mouse press, a closed popup at press, and a press
before the authored 100 ms delay. The measured entry-to-press values are
between 0.3 and 1.1 milliseconds. The proof is
`/tmp/shadcn-phase44-red-pointer-proof.json`. It uses no new fixed sleep,
rendering mock, production test input, or timer replacement. The existing
Message Scroller owner also checks its real native trigger and outline action.
Its shorter delay is a composition check rather than the primary bug proof.

- Before the repair, the shared hover hook canceled pointer entry on pointerdown.
  This is intended for Tooltip, but the pinned Hover Card keeps its entry
  request. A real click
  opens the reference card; the port stays closed through 60 animation frames.
- Give Hover Card triggers an internal gesture marker and preserve their entry
  timer and pointer focus request. Keep Tooltip behavior and caller click actions.
  Include composed trigger parts and their supported native element variants.
- Extend the existing Hover Card browser suite with pointer click entry, pointer
  travel into the popup, and Escape. Prove current failure and repaired behavior
  on both pages. Pass existing shared hook and Tooltip tests.
- The sides accessibility failure already passes with the popup target draft
  in phase 6e.25 (21.9 seconds). Do not change headings to repair that report.
  Diagnose the remaining RTL top/bottom 8 px offset before any geometry change.
- Apply scoped source changes after the active run. Pass package and browser
  checks and complete Hover Card behavior, semantic, and pixel verification.

**Commit:** `fix(hover-card): preserve pointer entry during clicks` (`9b0c985`)

The Hover Card source, trusted pointer owner, caller composition check,
reviewed snapshots and port-body digest are committed in `9b0c985`. All three
Hover Card examples pass all four comparison layers. Package checks and
shared hook unit checks pass. The remaining RTL offset was repaired in phases
66 and 67. The four existing Attachments diagnostic cases pass without an AI
record write. Complete shared caller and final all-64 proof remain open.

### Phase 6e.45: settle native validation prompt paint

- Empty required forms show Chromium's native validation prompt after Submit.
  Field default, RTL, responsive, and Input form fail pixel comparison in this
  state. Native validity, focused input, focus-visible state, and CSS agree.
- A real responsive Submit capture isolates the changing pixels inside the
  native prompt. Repeated frame captures converge to zero difference; the last
  18 samples are identical. The prompt animation is outside document animations.
- Before the final pixel capture, detect the focused user-invalid native form
  control and sample its clip until consecutive images are stable. Use a bounded
  attempt count. Preserve the prompt, error message, input value, and focus.
  Keep every comparison threshold. Apply this wait only to native validation.
- Extend the existing Field browser suite through the public capture helper and
  the real Submit state. Prove old capture failure and the repaired zero-pixel
  result. Pass helper checks and complete Field and Input form pixel comparisons.
- The current real capture regression fails with 493 differing pixels.
  An image-stability draft passes that test and the complete responsive pixel
  example. Saved stable captures show the validation prompt on both pages.
  Escape does not dismiss this native prompt, so it is not a valid presence
  check. The final test changes focus, restores the same input focus and styles,
  and confirms that the image changes after prompt dismissal. That presence
  proof passes in 6.1 seconds with zero pixels in the original comparison.
  All ten screenshot helper tests pass. The complete responsive pixel check
  passes in 19.3 seconds with the added foreground capture step. Canonical
  application, other affected form examples, and the scoped commit remain pending.
- Apply the scoped repair after the active run, record the measured extra cost,
  and pass required checks before the commit.

The current regression on `11f3005`, with the phase 6e.40 name repair,
fails at the intended zero-pixel comparison with 450 different pixels.
The native input is empty, required, invalid, and focused on both pages.
The current complete Field default and RTL runs also fail only at their
native Submit images with 1,631 and 1,338 different pixels. Their accessibility,
interaction, and structure checks pass. Reports and saved images use
`/tmp/shadcn-native-validation-red` and `/tmp/shadcn-label-names-field-failures.json`.
Apply the reviewed bounded capture helper, then require fresh prompt-presence
proof and complete image checks. Keep all image limits and state lists.

The repaired regression passes with zero different pixels. Root reviewed both
prompt images and both dismissed images. Native value, validity, focus, and
focus styles remain unchanged. Capture time is 139.9 ms for React and
1,002.8 ms for Phoenix in this run, compared with 45.9 ms and 49.0 ms before
the repair. The complete regression takes 4.7 seconds. The capture loop permits
4 to 60 screenshots for a qualifying native validation state. Existing test
time limits remain in force.

All 10 capture helper tests and all 24 Select and Field behavior tests pass.
All 13 Field examples pass their complete four-layer checks, with 57 passes
in 7.0 minutes. Input Form passes complete pixel comparison with four passes
in 31.0 seconds. No skips, unstable results, state exclusions, or limit changes
occur. The fresh reports use `/tmp/shadcn-native-validation`. All 48 AI record
byte blocks remain unchanged. Storybook passes 80 tests. All 463 Shadcn
snapshots are current. Static checks pass with zero errors. No snapshot bytes
changed.

**Commit:** `fix(verification): settle native validation prompt paint` (`0ae3c40`)

### Phase 6e.46: name the Input Group security control

- The security example names its disclosure wrapper group, but leaves the
  icon button inside that group unnamed. The reference wrapper has no name.
  The caller comment says the port labels are required for local accessibility.
- Give the actual security button its name through existing trigger_rest.
  Keep the wrapper group's reference name empty. Preserve the other icon
  button names, pointer activation, keyboard use, and popup content.
- Prove the current generic name failure and repaired discovery and replay.
  Verify the button's accessible name and complete accessibility with the
  read-only replay prerequisite. Use existing public composition inputs.
- Apply the repair after the active run. Pass Storybook, browser, and complete
  Input Group button verification before the scoped commit.

Temporary draft: the existing named-button assertion fails on current code
and passes with the label on the child button. All five Input Group behavior
tests pass (9.1 s). Complete accessibility passes (26.3 s) with the prepared
read-only render replay repair. Generic interaction discovery agrees after
read-only probe repair, but closing returns focus to the child button instead
of the reference wrapper. Phase 6e.51 must repair that independent focus
contract before complete button verification can pass.

**Commit:** `fix(input-group): name the security control`

### Phase 6e.47: align Input Group dropdown composition

- Both dropdown example add-ons have a caller -mr-1 class absent in the pinned
  example. Captured semantic differences repeat this class across all states.
  The port uses a contents wrapper between the add-on and its menu button.
- The reference applies its negative margin through a structural CSS rule.
  Removing the caller class alone gives a 4 px shift and a 188 px default image
  difference. It is not a complete repair.
- Use the existing direct_trigger composition for both example menus and remove
  the extra caller class. This lets the structural rule reach the direct button.
  Keep menu options, small button sizes, input edits, and placement inputs.
- Temporary draft: complete semantic and pixel checks pass (34.7 s). All five
  Input Group behavior tests pass (9.2 s), including keyboard item selection,
  Escape, and outside dismissal. The temporary markup uses existing running
  servers; canonical template compilation remains pending.
- Add no test that only asserts the removed class stays absent. Apply after
  the active run and pass Storybook and complete dropdown verification.

**Commit:** `fix(input-group): align dropdown trigger composition`

### Phase 6e.48: align native input code selection paint

- The input code native values, selected ranges, visible characters, active
  slots, borders, and shadows agree on both pages. Pixel failures remain in
  the first slot after native input selection.
- The pinned input-otp package installs a transparent ::selection rule for
  its transparent native input. The port does not install that rule. Browser
  native selection can therefore paint over the displayed code slots.
- Install the scoped native selection rule with the existing input code
  behavior initializer. Keep class facts, editable values, selection, and
  native events. The rule must be installed once and affect only data-input-otp.
- Extend the existing Input OTP browser suite through real keyboard selection
  and the public image capture helper. Prove current pixel failure and a repaired
  exact image, with native values and slot characters preserved on both pages.
- Apply after the active run. Pass hook and browser checks and complete affected
  input code pixel examples before the scoped commit.

Temporary proof: the real keyboard selection test fails on current code
with 124 changed pixels. The scoped rule gives an exact image and preserves
the value 123459, range 5..6, focused input, and visible last character.
All six input code browser tests pass (22.4 s). Complete default, controlled,
alphanumeric, and RTL pixel checks pass (36.8 s). Source application and
package checks remain pending while run 3 is active.

**Commit:** `fix(input-otp): align native selection paint`

### Phase 6e.49: reserve input code password manager space

- Focused reference inputs use 40 px of extra width and a matching clip.
  The port remains at 100% width. The pinned package checks icon markers,
  pointer hit testing, and available room before it reserves that space.
- Implement the reviewed password manager behavior at the input code controller.
  Keep the native editable input and visible slots. Support the public strategy
  choice and lifecycle cleanup. Do not add unconditional width to satisfy one
  sample or disable the pinned feature in the reference.
- Prove default detection, no detected icon, insufficient room, and the none
  strategy through real browser inputs. Verify selection and native values.
  Check lifecycle behavior and complete affected semantic and pixel examples.
- Apply the scoped repair after the active run and pass required package checks.

**Commit:** `fix(input-otp): reserve password manager badge space`

### Phase 6e.50: preserve input code separator caller replacement

- The pinned InputOTPSeparator spreads caller props after its default class.
  The Form caller's mx-2 class replaces the recipe class. This produces a
  block separator and a 24 px icon. The port merges classes and keeps a flex
  separator with a 16 px icon, shifting the next group by 8 px.
- Match the caller replacement contract in the public separator. Preserve
  default recipe behavior when no caller class is given. Match the pinned
  icon size for the caller replacement path and retain native separator role.
- Extend existing component markup coverage only for the current caller
  override contract. Pass default and Form browser behavior and complete
  semantic and pixel comparison. Add no absence-only test.
- Apply after the active run and review affected snapshots before the commit.

**Commit:** `fix(input-otp): preserve separator caller class replacement`

### Phase 6e.51: preserve composed Popover trigger focus

- The Input Group security Popover uses a group wrapper as its trigger.
  The reference wrapper has tabindex 0. The port wrapper has no tab stop.
  Complete generic replay returns reference focus to the group and port focus
  to its child button. Naming the actual child button exposes this difference.
- Match the current wrapper trigger focus contract in the public Popover.
  Preserve child button opening through Enter and Space, popup focus, and
  return to the declared trigger. The reference wrapper is a focusable group;
  Enter and Space on that group do not open it. Use existing return focus
  inputs where suitable. Do not normalize away the browser focus difference.
- Verify pointer and keyboard entry and Escape return on both pages. Check
  nested button input behavior and disabled controls. Pass complete generic
  Input Group button behavior and accessibility with phases 6e.30 and 6e.46.
- Apply after the active run. Pass existing Popover browser and package checks
  before the scoped commit.

Temporary proof: the extended existing security test fails on current wrapper
focus return. A temporary wrapper tab stop and the existing declared trigger
return option pass all five Input Group browser tests (9.1 s). Complete
accessibility and generic interaction pass (34.9 s) with the prepared phase
6e.30 read-only probes and phase 6e.46 button name. Complete semantic and pixel
checks pass (2.1 min). Source template compilation
and package checks remain pending. No keyboard hook is required; the native
child button already handles Enter and Space.

**Commit:** `fix(popover): preserve composed trigger focus`

### Phase 6e.52: select unique Message previews before behavior checks

- The named Message tests give visit a selector for multiple messages,
  footers, or attachments. The helper requires one visible element. Current
  Actions fails because its readiness selector resolves to two footers.
- Give each existing Message test the unique preview root for readiness.
  Keep LiveView connection checks and all existing message counts, alignment,
  pinned content, media names, and button contracts. Change no helper timeout
  or expected content and add no duplicate test.
- Temporary proof: current Actions fails at its multiple footer selector.
  Corrected Actions, header/footer, and attachment pass. Default, avatar, and
  group still time out because a late avatar failure blocks the browser.
  All six tests pass (12.1 s) when combined with phase 6e.53.
- Apply after the active run and retain both repairs as separate scoped commits.

**Commit:** `fix(verification): select message previews before behavior checks`

### Phase 6e.53: keep failed avatar images responsive

- Avatar image error handling assigns hidden=true to the failed image.
  Its MutationObserver watches hidden and repeats the assignment after the
  error arrives. This can keep the browser in a DOM update loop. Message
  default, avatar, and group pages time out with missing local avatar files.
- A real delayed HTTP 404 after LiveView connection reproduces the browser
  block. An immediate 404 before observer setup does not reproduce it. Preserve
  this timing in the existing Avatar browser suite, not in a mock observer.
- Make image visibility writes idempotent. Set the native hidden property only
  when its value changes and use the native forced attribute toggle for the
  fallback. Keep native image load/error events and source update observation.
- Temporary proof: current late failure times out at the load event (8 s test
  limit). The candidate shows CN and accepts menu Enter/Escape (2.1 s). All six
  Message browser tests pass with phase 6e.52 (12.1 s). Verify recovery to a
  successful image and another failure in the same regression case. This
  recovery sequence passes (1.5 s); both Avatar browser tests pass (3.7 s).
- Apply this source repair before affected image readiness verification. Merge
  its Avatar browser test with the phase 6e.14 test rather than replacing that
  file. Pass package, hook, existing Avatar, Message, and affected pixel checks.

**Commit:** `fix(avatar): avoid repeated visibility updates after image failure`

### Repair worktree while run 3 remains active

- The original worktree and its HEAD remain fixed. Verification identities read
  that worktree's files and do not read other branch refs.
- Real source repairs can proceed in /private/tmp/live-shadcn-repairs on branch
  codex/shadcn-parity-repairs. It has separate Mix builds and asset dependencies.
  Its Storybook runs on port 15101; the reference remains on 14102.
- Phase 6e.53 is committed as c03708a. Base package tests (42), hook tests (93),
  full mix check, two actual rebuilt Avatar browser tests, and default/dropdown
  image checks pass. Phase 6e.52 is committed as 8652bce. All six Message browser
  tests pass against the rebuilt repair server after its compile completes.
- Phase 6e.48 is committed as f8f6e77. Six actual rebuilt input code browser
  tests and four complete image examples pass. Original worktree integration
  and complete component verification remain pending.
- Phase 6e.14 is committed as 684d701. All three Avatar browser cases and
  both generic behavior examples pass. Phase 6e.14a is committed as 51401a3.
  The real 600 ms Popover transition checks pass on both renderers, and the
  complete Bubble Popover accessibility check passes.
- Phase 6e.54 is committed as 262e197. Both nested menu tests fail before the
  repair on React because the reference omits expanded state after keyboard
  entry on macOS. The controlled visibility repair passes all 15 shared state
  browser tests and all 108 browser helper tests.
- Phase 6e.14b is committed as 987da33. The complete Sonner run passes all nine
  checks for both official examples. All three Bubble notice action images
  match at zero pixels. The package passes 149 tests and its full static check.
  Both contract checks and Sonner snapshots pass. Four reviewed snapshot root
  attributes and only the Sonner verification record are in the commit.
- The first separate Sonner run rejected input drift because preparation
  changed JSON key order in official-examples.json. The parsed values are
  unchanged. The second run used the prepared bytes and passed. Keep that
  order change unstaged until integration with the original prepared file.
- Keep commits scoped to the repair and its primary tests. Leave copied PLAN
  and TODO changes and local dependency links out of implementation commits.
  After run 3 ends, integrate these commits into the original worktree and
  preserve its existing snapshot and evidence changes.

### Phase 6e.54: observe open submenus without an expanded attribute

- The shared state suite has two current React timeouts on macOS. A native
  programmatic click opens Invite users and Label As... and focuses a child.
  The pinned Base UI submenu removes aria-expanded after keyboard entry on
  this platform. The verifier waits for an attribute that cannot become true.
- Use controlled popup visibility when a menuitem with aria-haspopup=menu
  has no expanded attribute. Keep explicit expanded states authoritative.
  Keep ordinary disclosure and close behavior. Do not alter reference markup.
- Use the two existing shared browser tests as the regression checks. Their
  current versions fail with and without the disclosure animation repair.
  Pass the complete shared suite and Node helper tests after the repair.

**Commit:** `fix(verification): observe controlled submenu visibility`

### Phase 6e.55: run caller commands after a Collapsible toggle

- The controlled Bubble example uses the existing global phx-click attribute
  to send a state event. The current trigger emits two phx-click attributes.
  The browser uses the local toggle and does not send the caller event. The
  existing long-answer browser test fails: expanded state is true, but the
  text and button label stay closed.
- Compose a caller JS command or event name after the local Disclosure command.
  Emit one click attribute. Preserve disabled behavior and the public API.
  Use the existing Bubble browser case as the primary regression check.
- Pass package tests and static checks and the long-answer browser check. Run
  complete Collapsible verification and review its port hash. Its first run
  passes semantic and pixel checks but finds the already planned settings
  label defect and file-tree time limit. Keep phases 22 and 23 as requirements
  for final complete Collapsible verification. Do not mark it verified yet.

**Commit:** `fix(collapsible): run caller commands after toggling`

### Phase 6e.56: bound stored verification error detail

- The completed baseline record is 4.3 MB and the large-file commit hook
  rejects it. Calendar and Date Picker semantic failure details contain
  2.29 MB and 1.24 MB. The full diagnostic log and raw record are saved in tmp.
- Bound new shadcn check detail to 2 KiB at publication. Keep a valid UTF-8
  prefix and a notice that full detail is in verification output. Keep CLI
  diagnostics complete. Preserve all outcomes, hashes, and out-of-scope data.
- Test the existing publication boundary with a long Unicode failure. It must
  remain failed, keep its identity, and serialize valid JSON. Existing short
  messages and AI records must remain unchanged. Add no test-only API.
- Pass tool tests and static checks. Normalize only the new baseline shadcn
  detail, prove all machine fields and AI bytes unchanged, and commit it.

**Commit:** `fix(verification): bound stored error diagnostics`

### Phase 6e.57: wait for disclosure caller events before observation

- The controlled Bubble trigger changes local expanded state before its server
  event changes the answer and label. The generic close check observes false
  expanded state with the old Show less label. The named browser check waits
  for the answer and passes. Confirm the event-loading state on the real page.
- Wait for a caller event acknowledgement before observing an opened or closed
  disclosure. Use the existing LiveView loading class. Preserve local-only and
  React behavior. Keep names, focus, control values, and state comparisons.
- Prove the old failure with a delayed real caller event. Pass the existing
  generic Bubble check after the repair and run the browser helper checks.
  Add no mock that duplicates the loading mechanism.

**Commit:** `fix(verification): wait for disclosure caller events`

The complete Separator and Button Group run passes all nine checks across 17
examples. The repair owns seven snapshot class changes and two result records.
All 48 AI record bytes remain unchanged. The branch Storybook suite passes all
80 tests with a 180-second test deadline. Its 64-record evaluator comparison
exceeds the normal 60-second deadline under concurrent browser load. Run test
fixture mutation before starting a server or a managed verifier in that checkout.

### Phase 6e.58: support checkable controls without an explicit identity

The public Checkbox and Switch attributes give `id`, `name`, and `field` nil defaults.
A real package render with only an accessible label fails in both components.
The shared toggle command receives a nil input identity and raises a case-clause
error.
The saved proof is `/tmp/shadcn-optional-checkable-render-proof.json`.
Repair the public defaults without requiring a previously optional attribute.
Use the smallest change that preserves separate control pairs, labels, focus,
checked state, submitted values, and caller events. Prove multiple unnamed
controls remain independent through real rendering and browser interaction.
Review contracts and snapshots and run package and browser checks.

The current render probe confirms the nil case in both controls. Supplying a
name or ID makes the same call render. The probe is
`/tmp/shadcn-checkable-current-render.exs`; its result is
`/tmp/shadcn-checkable-current-render-red.jsonl`.

Keep explicit IDs and their existing commands. For an unnamed control, omit
derived IDs and target its own adjacent native input through the existing
delegated checkable behavior. Do not generate a new ID on each render. Extend
that behavior to Switch label activation as well as Checkbox label activation.
Keep caller event order and render updates through the public component inputs.

The browser reset check also confirms that sticky JS attributes retain the old
visible value after a changed server value. Preserve that reset contract. The
production components will publish a private checked-state marker. The existing
delegated behavior will read changed markers after a LiveView patch and apply
the new value to the control and its input. A native change clears that server
override for the next client interaction. Keep the dirty and touched attributes.
The reset failure is recorded in
`/tmp/shadcn-checkable-current-reset-red.log` and its saved report and traces.

The browser owner will use a test-only LiveView endpoint with the actual public
components and the built application assets. It will cover two unnamed controls,
a named control, disabled and read-only controls, containing labels, keyboard
input, form values, and actual server events. The official examples all supply
IDs, so their comparisons do not cover the unnamed pairing contract. This
fixture adds no production route, flag, export, or callback injection. Keep the
existing package render and browser checks for named controls.

Phase 58 is complete in commit `77b85ec`. Both unnamed-control browser tests
pass, including client events, form values, label focus, Space input, and server
resets. The full Checkbox and Switch run passes all 85 checks in 7.2 minutes.
It has no skipped tests, failures, or flaky results. The saved report is
`/tmp/shadcn-checkable-current-browser-full-review.json`.

Base passes 42 Elixir tests, 92 JavaScript tests, and its static checks.
Shadcn passes 152 tests and its static checks. Both source contract checks pass.
Storybook passes all 80 tests and its static checks. The test input files match
their exact saved hashes after the suite. All 463 shadcn snapshots pass.
Exact review finds only 57 server-state markers and 11 Switch input markers in
26 changed snapshots. Classes, text, and actions match the previous snapshots.
The review is `/tmp/shadcn-checkable-current-snapshot-review.json`.

The separate agent-browser sessions confirmed named Switch pointer operation
and focused Space input in both directions. All owned browser sessions and
test servers are closed. All 48 AI record byte blocks are unchanged. No
verification record, pin, comparison threshold, or official example changed.
The read-only current evidence check reports all 64 targets as stale. The final
full verification run and release checks remain required.

**Commit:** `fix(checkables): support controls without explicit identities`

### Phase 6e.59: confirm the selected delivery time

- The complete default Drawer image check reports a 1,602-pixel difference
  after Confirm Delivery Time. The stored before record has the same failure.
  The pinned `DrawerDemo.handleConfirm` closes the popup and shows a notice.
  Its title is "Delivery time confirmed". Its description is the selected
  delivery label. The port footer only calls `LiveBase.Dialog.close`.
- Wire the example caller behavior through the existing selection and notice
  APIs. Keep the selected delivery time correct after a server update. Keep
  local dismissal and focus return. Do not add a component API for the fixture.
- Extend the existing delivery selection browser owner. Test the default and
  a later time on both pages. Require the correct notice title and selected
  label. Require a closed popup and focus return. Prove the current missing
  notice before applying the repair.
- Pass Storybook checks. Review snapshots. Repeat all default Drawer checks
  after the modal background repair. Keep the exact image threshold.

The repair is committed as `5da1514`. The existing delivery browser owner now
checks the default and later time on both pages. Both React cases passed before
the repair. Both Phoenix cases failed because the notice did not exist. The
selection form now reports the selected value. Both LiveView hosts add and
remove notices through the existing Sonner component. The close commands keep
focus return. Reopening keeps the selected radio after the server update.

All 17 Drawer browser tests passed. Agent-browser also confirmed later choices,
notice text, dismissal, and focus return on the preview and documentation
pages. Storybook passed 80 tests and all static checks. All 463 snapshots were
rendered. Only the default Drawer snapshot changed, with the form, event, and
empty live region. The exact image check now passes. The complete default
comparison has eight passing checks and one semantic failure with six trigger
`aria-hidden` differences. Phase 6e.37 must remove those differences. All 48
AI record byte blocks are unchanged. No verification record, pin, state, or
threshold changed. Commit hooks passed.

The complete default Drawer comparison now passes after the shared modal
repair in `8262f70`. The image threshold and all existing states are unchanged.

**Commit:** `fix(drawer): confirm the selected delivery time` (`5da1514`)

### Phase 6e.60: preserve parent Drawer size after a nested close

- The current nested Drawer semantic comparison reports six differences after
  Open Drawer, Open Nested Drawer, and Close. The reference parent popup is
  720 pixels high. The port parent popup is 564.5 pixels high. The content and
  footer positions differ by the same amount. The Close background also differs.
  The before command finished with three passing tests and one failure.
- Find the cause through the real nested open and close sequence. Check stack
  measurements, layout, transition completion, and pointer position. Keep this
  repair separate from modal background access and Tab ownership.
- Add or extend the browser owner for the observed size contract. Apply the
  smallest owner repair. Repeat all nested Drawer comparisons without changing
  states, measurements, colors, or thresholds.

The current normal nested comparison passes. A real popup width change while
four drawers are open exposes the measurement error. The existing browser
owner passes on React and fails on Phoenix: after the children close, the
parent is 198.328125 pixels high instead of the 720-pixel viewport height.
The trace also records repeated decreases in the parent's stored height.
The regression changes the actual popup width. It does not inject callbacks.

The installed reference measures `offsetHeight`, retains the parent's own
measured height while nested roots are present, and stores front drawer height
separately. The repair will follow those rules. Opening starts a fresh layout
measurement. Stack updates will read the front popup's stored layout height
and restore the parent's own height when the last child closes.

The repair is committed as `3357fc3`. The hook now measures layout height,
retains the parent's own height while nested roots are present, and updates
front drawer height separately. Each opening starts a fresh measurement.
The same real resize owner passes on both pages after the repair.

All 57 Drawer browser checks passed with no retries, skipped tests, or flaky
results. These cover 24 direct tests, all four comparison layers for all seven
official examples, and five shared metadata checks. The manual desktop check
confirmed stored and layout heights of 720 pixels while the parent was visually
scaled to 684 pixels. Public Close restored a 720-pixel parent, trigger focus,
and the retained page scroll lock. Escape then restored root trigger focus.

Base passed 92 JavaScript tests, 42 Elixir tests, and all static checks.
Storybook passed all 80 tests and static checks. All 463 shadcn snapshots are
current. All 48 AI record byte blocks are unchanged. No markup, contract,
source pin, state, comparison limit, or verification record changed. Commit
checks passed. Logs are `/tmp/shadcn-nested-size-current-parent-red.log`,
`/tmp/shadcn-nested-size-current-parent-green.log`, and
`/tmp/shadcn-nested-size-current-drawer-complete.log`.

The manual mobile check found a separate caller error. Phase 6e.63 must repair
that behavior before the Drawer family is complete.

**Commit:** `fix(drawer): preserve parent size after nested close` (`3357fc3`)

### Phase 6e.61: observe inherited hidden state

- The modal repair passes the complete default Drawer comparison. The default
  Dialog semantic comparison reports four trigger `aria-hidden` differences.
  React hides the trigger through its main ancestor. Phoenix hides the trigger
  directly because its popup remains inside the main region. Both browser
  accessibility trees exclude the trigger. The collector reads only the
  trigger's own attribute and reports these equal states as different.
- Observe `aria-hidden` through the element and its ancestors. Keep all other
  attributes and existing comparison limits. Use a real browser owner to prove
  inherited true, child false under parent true, and the visible state after
  the parent changes to false. Do not add a private test export or relax a rule.
- Pass the browser regression, existing collector tests, and affected default
  Dialog and Drawer comparisons. Keep source pins, states, and image limits.

The repair is committed as `22cbdbb`. The real browser collector test failed
before the repair because it reported an empty hidden state for the reference
trigger under an `aria-hidden="true"` main region. It now passes inherited
true, child false under parent true, and visible parent false cases. All 108
browser-tool tests passed. With the current modal repair in the working tree,
all 13 complete default Dialog and Drawer checks passed. All 48 AI record byte
blocks are unchanged. No comparison limit, state, source pin, or verification
record changed. Commit hooks passed.

**Commit:** `fix(verification): observe inherited hidden state` (`22cbdbb`)

### Phase 6e.62: prevent delayed focus in a closing popup

- The current modal run passes 65 of 67 checks. A fast outside click closes the
  default Drawer but sometimes loses focus return. Phoenix `JS.focus` runs
  immediately and again after two animation frames. The later callback can
  focus the still-mounted popup during its exit transition.
- Extend the existing outside-pointer browser owner. Deliver animation-frame
  callbacks at a lower rate through real browser frames to expose the ordering.
  Check the reference and port. Keep close and trigger focus assertions.
- Prevent a closing popup from taking focus back after dismissal. Preserve the
  caller's current outside focus and explicit focus commands while open. Keep
  the shared hook lifecycle and remove listeners on destruction. Complete this
  related focus repair with the shared Overlay repair if they share the owner.
- Pass the real before and after regression, affected modal browser owners,
  Base and Storybook checks, and complete affected comparisons.

The repair is committed with phase 6e.37 as `8262f70`. With slower real frame
callbacks, the reference passed and the port lost trigger focus before the
repair. Both now pass. The two existing text-focus tests also pass. Explicit
focus remains correct while the popup is open. The hook removes its focus
listener when the view is removed. The complete 68-test modal run and all
required package checks passed. Logs are stored in
`/tmp/shadcn-closing-focus-browser-red.log`,
`/tmp/shadcn-closing-focus-owner-green.log`, and
`/tmp/shadcn-modal-access-focus-current-complete.log`.

**Commit:** `fix(overlay): preserve modal access and focus` (`8262f70`)

### Phase 6e.63: match nested Drawer mobile direction and handle

- At 390 by 844 pixels, the reference nested Drawer opens downward, uses the
  vertical swipe axis, and has one swipe handle. The port opens to the right,
  uses the horizontal axis, and has no swipe handle. The pinned caller uses
  `useIsMobile` for both inputs. The current port supplies a fixed right
  direction at each of the four levels.
- Match the reference's 768-pixel breakpoint through the production caller.
  Supply the derived direction and handle state to all four nested drawers.
  Preserve open state, nested levels, edited caller state, and focus when the
  viewport crosses the breakpoint. Keep desktop direction and presentation.
- Extend the real browser owner for mobile direction, visible handles, nested
  dismissal, and an actual downward swipe. Use trusted browser input. Confirm
  current failures on the actual reference and port. Test breakpoint changes
  while open. Keep the existing shared Drawer resize, Tab, Escape, and focus
  contracts. Do not add a test-only export, flag, or callback injection.
- Review changed caller snapshots. Pass required package and Storybook checks,
  affected mobile tests, and all seven existing example comparisons. Keep
  source pins, state inventories, accessibility rules, and image limits.
- The current before evidence is
  `/tmp/shadcn-nested-mobile-before-proof.json`. The browser session is closed.

The repair is committed as `0cc6e36`. The production example sends its media
query state to each LiveView host. The existing Drawer inputs set direction
and handle visibility at all four levels. The same Drawer elements stay open
when the screen crosses 768 pixels.

Before the repair, the reference passed the mobile browser test. Both Phoenix
hosts failed because they used the right direction at 390 pixels. After the
repair, all three cases passed. The complete Drawer suite passed all 60 checks
for the seven official examples. This includes 27 direct interaction checks,
28 example comparisons, and five metadata checks. No check was skipped or
retried. The complete log is
`/tmp/shadcn-nested-mobile-current-drawer-complete.log`.

The manual agent-browser check passed. It checked four open levels, direction
and handles at 390, 768, and 767 pixels, a real handle drag, focus return, Escape,
and scroll release. The documentation example also passed. The browser session
is closed. The observations are in
`/tmp/shadcn-nested-mobile-current-manual-proof.json`.

Storybook passed all 80 tests and all static checks. The temporary test files
match their exact saved hashes. All 463 shadcn snapshots passed. Only
`drawer-nested.html` changed. Exact tree comparison shows the new hook wrapper
and the same child tags, attributes, action order, classes, and text. No public
package source changed. All 48 AI record byte blocks are unchanged. Source pins,
state lists, verification records, and comparison limits are unchanged. The
commit hooks passed and restored the five pending documentation files.

**Commit:** `fix(drawer): match nested mobile direction and handle`

### Phase 6e.64: preserve radio keyboard selection

The current ready-page browser probe finds a keyboard defect. In the default
example, ArrowDown moves React from Comfortable to Compact and focuses the
Compact control. Phoenix keeps Comfortable selected and focused. The saved
observations are `/tmp/shadcn-radio-current-arrow-reference.json` and
`/tmp/shadcn-radio-current-arrow-phoenix.json`. The label-focus repair does not
add arrow-key behavior. Existing radio browser checks cover pointer selection
and roles, so passing them does not prove keyboard selection.

Extend the existing radio browser owner with real key input on both pages.
Confirm the pinned reference behavior for direction, disabled items, wrapping,
and Tab entry before setting expectations. Prove the failure on current code.
Repair the group behavior and its focus and selection owners. Preserve native
values, form change events, labels, blocked controls, and the hook lifecycle.
Use the existing public inputs. Add no test-only production API. Pass complete
Radio Group comparisons and affected Field and Drawer checks. Keep all existing
examples, source pins, and comparison limits. Pass package and Storybook checks.

**Commit:** `fix(radio-group): preserve keyboard selection`

The ready reference confirms one Tab stop at the selected enabled radio.
All four arrows navigate and wrap. Disabled items are skipped. Home and End
are not selection keys. Shift permits arrow navigation; Control, Alt, and Meta
are navigation modifiers that the installed composite handler excludes.
The Arabic example supplies local `dir` attributes but no DirectionProvider.
Its horizontal key order remains left-to-right in the actual pinned reference.
Keep this context behavior instead of deriving key direction from local CSS.
The current port has no direction-context input for this hook.

The primary keyboard tests will cover repeated selection, checked native values,
one native change per changed value, unchanged-value Space input, and group Tab
entry and exit. Native radio properties can become dirty after a prior change;
the group must synchronize those properties before a form receives the next
change event. Keep the existing selection command as the behavior owner.
The hook will choose the enabled target, invoke that command, and set focus.
Maintain one group Tab stop on mount, focus, change, and LiveView updates. Remove
the new keyboard listener on hook destruction. Keep read-only controls from
changing their value.

The corrected baseline passes all five reference cases and fails all five port
cases. The report is `/tmp/shadcn-radio-keyboard-red-review.json`. Adding key
navigation and Tab stops makes both port Tab cases pass. The remaining three
keyboard cases fail on repeated native selection. Focus and ARIA state are
correct, but a checked attribute does not update a dirty native checked
property. The report is `/tmp/shadcn-radio-keyboard-native-red-review.json`.
The existing group change handler rejects that event because the property is
false. Accept the selected control's command state, synchronize the native
properties, and keep the event and group boundaries.

The repair is committed as `fe07215`. All ten keyboard and Tab cases pass.
The complete affected browser runs pass 77 checks. These include 16 direct
checks, 33 Radio Group comparisons, 13 Field comparisons, nine Drawer
comparisons, and six Drawer behavior checks. No check was skipped or retried.
The saved reports use the `/tmp/shadcn-radio-keyboard-` prefix.

Base passes 42 Elixir tests, 92 JavaScript tests, and its static checks.
Storybook passes 80 tests, all 463 snapshot checks, and its static checks.
The saved test input hashes match. No snapshot changed. The manual connected
browser check confirms wrapping, focus, native values, and one change event
per changed value. Its session is closed. All 48 AI record byte blocks remain
unchanged. The commit hooks passed and restored the five documentation files.

### Phase 6e.65: preserve radio item defaults and form values

A public render check finds two separate radio item defects. An item with its
required group and a value, but no ID, name, or field, raises an error in
`String.replace/4`. The public ID and name inputs are optional. An item whose
value matches its form field renders `aria-checked="false"`. The same render
check confirms that an explicit ID renders and that a nonmatching field value
is unselected. The observations are saved in
`/tmp/shadcn-radio-optional-render-proof.jsonl`.

Repair the public radio item boundary. Keep optional identity inputs optional.
Derive checked state from the item value and the form field value. Preserve
an explicit checked input, form identity, errors, names, and values. Keep
multiple items independent and keep one selected item per group. Use a real
browser fixture to check unnamed controls, repeated pointer and keyboard
selection, native form values, and server updates. Extend the existing test
owners. Add no test-only production API. Confirm each regression before the
repair. Pass the required package checks and complete affected example checks.
Keep source pins, upstream fact blocks, examples, states, and image limits.

**Commit:** `fix(radio-group): preserve item defaults and form values`

The final review confirms three more failures in this boundary. Distinct
field values can get the same generated ID. A group with explicit and optional
IDs can restore a stale checked attribute after a server patch. An associated
label outside the group can select a read-only input. Extend the existing
field and named browser cases to confirm these failures. Encode the exact
value bytes in generated IDs. Keep the last local selection until the server
state changes. Apply the same label guard to associated labels outside the
group, and remove that listener when the hook is destroyed.

The extended render test fails before the ID repair. The real field browser
case sends three changes for one click before that repair. The mixed ID case
restores the first checked control after selecting the third item. The isolated
outside read-only label sends one event before the label repair. The saved
results are `/tmp/shadcn-radio-identity-red.log`,
`/tmp/shadcn-radio-identity-label-red-review.json`, and
`/tmp/shadcn-radio-label-isolated-red.json`.

The final source passes all three fixture cases and all 98 affected browser
checks. The complete groups are Radio Group, Field radio and choice-card,
and the default Drawer. The direct checkable, Field, and Drawer owners also
pass. `/tmp/shadcn-radio-final-browser-review.json` records the results.
The named agent-browser session confirms unique field IDs, native submitted
values, mixed ID selection, caller updates, and read-only submission. Its
results are `/tmp/shadcn-radio-final-manual-field.json` and
`/tmp/shadcn-radio-final-manual-named.json`.

Base passes 42 Elixir tests, 92 JavaScript tests, and static checks. Shadcn
passes 154 tests and static checks. Storybook passes 80 tests, the 463 Shadcn
snapshot checks, and static checks. All three files changed by the Storybook
tests retain their original bytes. The radio contract passes both offline
and online checks. All 48 AI verification record blocks retain their exact
bytes. The ten affected snapshots add only 31 server state attributes.

The unscoped snapshot check also reports 22 existing AI example differences.
The inspected Task example differs only in command JSON key order. No AI
snapshot is changed. These repair checks do not replace the final all-64
Shadcn verification.

The scoped repair is committed as `11f3005`. Commit hooks pass and restore
the five working document files. The goal remains active.

#### Phase 6e.66: preserve raw popup alignment offsets

The phase 43 shared owner run passes 37 of 40 cases. The two existing Popover
RTL offset cases expect +12 for start and -12 for end. Phoenix returns the
opposite signs. The public `dir` input is on the popup; its body positioner
remains LTR. The pinned Base UI passes raw `alignOffset` to Floating UI,
which applies the positioner direction. The port additionally reverses the
value from popup direction. Keep the existing expectations. Add actual
computed direction checks to the same owner cases. Remove the extra reversal.
Keep crossAxis and alignmentAxis input values and collision behavior.

Fresh complete RTL Popover and Hover Card checks run all 13 cases. Eleven
pass. Hover Card semantic and pixel comparisons fail. The semantic report
contains six missing click popups and two hover x differences of eight pixels.
The saved hover images show this shift. The click failure belongs to phase 44.
The authored nonzero affected popups are the top and bottom Hover Card RTL
cards and four RTL Menubar root menus. Popover RTL has zero authored offset;
its existing nonzero browser owner protects the raw offset contract.

Reports and 24 distinct failure images are under
`/tmp/shadcn-popup-rtl-offset-red`. The direct shared failures are preserved in
`/tmp/shadcn-nested-menu-siblings-failures.json`. The unchanged offset owner
already demonstrates the intended pre-fix failure. The added setup assertions
change neither its input nor its expected result. No new test or seam is needed.
Run Base JavaScript tests, existing shared popup owners, and complete affected
menu comparisons after the repair. Repeat the complete RTL comparison and
record the remaining phase 44 click faults separately. Do not call that failed
full report a completed Hover Card verification.

The third shared failure is a Tooltip positioning owner that requests opening
with click. The pinned Tooltip cancels pending hover entry on press and click.
Use hover in that existing owner and preserve its visibility and side checks.
The Menubar reference-readiness change is a test correction. Commit it with
the Tooltip hover-input correction, apart from production menu and offset
repairs. Keep the real submenu entry-focus assertion with phase 43. It protects
keyboard entry before dismissal. Full inherited-document direction remains a
separate untested input.

**Commit:** `fix(floating): preserve raw alignment offsets` (`451f57b`)

The fresh complete RTL run again passes 11 of 13 checks. The remaining two
Hover Card failures report only the six missing click popups. The earlier
hover position differences are gone. This isolates the phase 44 pointer defect
and proves the raw offset repair without changing states or limits. The report
and preserved failures are under `/tmp/shadcn-popup-rtl-raw-offset-current`.

The raw offset source and its actual-direction assertions are committed in
`451f57b`. The separate Menubar readiness and Tooltip hover-input corrections
are committed in `ddba483`. Complete Dropdown Menu and Hover Card comparisons
pass after their scoped repairs. Separate Menubar and Context Menu failures
remain open. No complete shared or final verification is claimed here.

### Phase 6e.67: preserve computed position after an alignment flip

The complex Notifications submenu requests right-start with an offset of -3.
The saved trace shows final right-end alignment on both pages. Both pages have
the same available size and anchor size. React uses y = 571 pixels. Phoenix
uses y = 577 pixels. Floating UI already applies the offset to the final end
edge. Before the repair, the port added another six pixels after that
calculation. The pinned Base UI uses the returned coordinates directly.

Extend the existing two-host nested menu owner to require the actual final
right-end alignment and the authored end-edge offset of three pixels. Prove
that React passes and Phoenix returns nine pixels before the repair. Remove
only the post-flip correction. Keep raw offsets, alignmentAxis, collision
inputs, Select item alignment, dismissal, and all current comparison limits.
Run the Base JavaScript and static checks, existing shared popup owners, and
complete affected examples. Use a separate commit from phase 43 and phase 66.
The state regression must run first so this geometry failure does not conceal
its expected checkbox failure.

The fresh regression passes React and fails Phoenix at the authored offset.
Both menus have final right-end alignment. React returns three pixels. Phoenix
returns nine pixels. The two cases finish in 11.6 seconds. Raw proof and the
trace are saved under `/tmp/shadcn-menu-label-geometry-red`. Apply only the
reviewed correction removal before rebuilding the browser asset.

**Commit:** `fix(floating): preserve computed alignment after collision` (`d150bb8`)

The complete five-family run ended with 139 passes and 18 failures. All 13
Dropdown Menu examples and all three Hover Card examples pass all four browser
layers. All 38 accessibility cases pass. Tooltip sides has one transient
state failure. Three Menubar examples have fixed caller-choice semantic and
pixel failures. All 11 Context Menu examples have outside accessibility-state
semantic failures. Separate phases 69, 70, and 71 will repair these defects.
The report and saved traces are under `/tmp/shadcn-menu-hover-complete-green`.

The direct shared run has 146 passes and one Message Scroller anchor failure.
Base passes 42 Elixir and 92 JavaScript tests. Shadcn passes 154 tests.
Storybook passes 80 tests. All 463 Shadcn snapshots pass their check. Static
checks pass. The strict 53-file snapshot review and both selected body digest
checks pass. All 48 AI record byte blocks remain unchanged. A separate guarded
Attachments diagnostic passes all four existing cases. It publishes no AI
verification records.

Five scoped commits now preserve the reviewed files: `451f57b`, `ddba483`,
`321ce90`, `d150bb8`, and `9b0c985`. Repository hooks pass. The 70 source,
test, snapshot, and digest files match the saved final hashes. No source
changes remain from those five commits. Other complete shared caller checks
and the final all-64 verification remain required.

The correction removal and authored end-edge regression are committed in
`d150bb8`. Package checks and complete Dropdown Menu and Hover Card checks
pass. The 18 saved five-family failures and the later shared caller work stay
separate from this committed geometry repair. Complete shared caller and final
all-64 proof remain required.

### Phase 6e.68: finish message anchors and preserve reader input

The complete shared owner run passes 146 of 147 cases. The existing Anchoring
case expects a start target of 400 pixels and reports 402 pixels. A private
repeat keeps the exact test body and assertion. One of three repeats passes.
Two repeats fail at the same first user anchor. Both final DOM receipts show
scrollTop and native end at 402, a raw start target of 399.75, an exact target
of 400, clear entry markers, no transforms, and loaded fonts. The target
calculation remains correct after the assertion fails.

The entry finish handler returns when the viewport is at its native end.
The anchor spacer can create that end while the selected anchor is still
active. The pinned package releases the anchor through explicit wheel,
touchmove, and scroll-key input. Its resize work does not reject an active
anchor at native end. The port keeps its anchor after those reader inputs.
Remove the native-end return. Clear the active anchor for those reader inputs.
Keep pointerdown limited to releasing the frozen opening position.

The existing exact public Anchoring owner is the primary regression. Add a
two-row public browser owner for real wheel and Home input during actual
entry motion. Require trusted input, active motion, positive scroll travel,
and an exact final start position of zero. The tests must fail for the current
reader-input defect after those setup conditions pass. No fixed delay, mock,
production test flag, or tolerance is needed.

Delete the old mocked native-end unit assertion. It supplies an active anchor
without reader input and enforces the faulty return. Keep the existing visual
geometry and public end-command owners. Run the original exact Anchoring
owner repeatedly, the new reader-input owner, all Message Scroller browser
owners, Base tests and static checks, and all 11 complete official Message
Scroller examples. Preserve all limits, pins, snapshots, and AI record bytes.

**Commit:** `fix(message-scroller): finish anchors and preserve reader input` (`900701c`)

Home input has valid pre-fix failure proof in all three repeats. It receives
400 instead of zero after trusted input during actual entry. The first wheel
receipt records zero before input, so its setup fails. Correct that receipt
before using the wheel case as defect proof. No Message Scroller repair was
applied for those RED runs. Reports are `/tmp/shadcn-message-anchor-probe.json`
and `/tmp/shadcn-message-reader-red.json`.

The corrected wheel setup now has valid failure proof in all three repeats.
The actual pre-input position is 400 with active entry motion. The trusted
wheel receipt reaches zero during that motion. The final position returns to
400. The report is `/tmp/shadcn-message-wheel-corrected-red.json`. Both input
receipts and all failure traces have saved copies. The scoped source repair
and durable two-row browser owner are now committed in `900701c`.

The repaired exact Anchoring, wheel, and Home cases pass all nine repeated
checks. All 13 direct Message Scroller owners pass. Base passes 91 JavaScript
and 42 Elixir tests. Static checks and test/dev compilation pass. The complete
11-example run has 40 passes and nine failures in 672.1 seconds, with no skips
or unstable results. Anchoring passes all four layers. All 11 accessibility
and interaction cases pass. Four initial-layout semantic cases and five image
cases remain open. Keep full Message Scroller completion unchecked. Review
those saved failures as separate initial-layout and busy-paint work before any
further source repair. All 48 AI record byte blocks remain unchanged.

Reports are `/tmp/shadcn-message-anchor-reader-green.json`,
`/tmp/shadcn-message-phase68-owners.json`, and
`/tmp/shadcn-message-phase68-complete.json`. The last report has a saved
failure archive with unique trace and image copies.

Commit `900701c` contains the anchor finish, reader-input release, removal
of the invalid mocked assertion, and the two real input cases. Base checks
and all direct Message Scroller owners pass. The saved complete report has
40 passes and nine failures. Complete Message Scroller verification remains
open, with all four initial-layout semantic and five image failures preserved.

### Phase 6e.69: preserve tooltip trigger semantics

The complete popup comparison finds a real Tooltip sides state failure. The
opened Bottom trigger reports `aria-expanded="true"` in Phoenix and no expanded
attribute in React. All four sides use the same public caller loop. The saved
trace shows the attribute added before the hook removes it on the next frame.
The failure therefore depends on the reader's position between two real DOM
changes. Keep the current reader and all comparison limits.

Before the repair, public Tooltip defaulted `hover_expanded` to true. Its nil
caller click command used `Popover.toggle`. The shared InteractionTrigger hook
uses that command for hover when no separate hover command exists. The toggle
stores expanded state through the LiveView client attribute protocol. A later
raw DOM removal does not clear the stored operation. The existing
`Popover.tooltip_toggle` and `Popover.tooltip_close` commands change the same
popup state without writing disclosure state. Reuse those commands.

Set the public default to false in
`packages/live_shadcn/priv/registry/tooltip.ex`. Pass that choice to
`click_command` for the button, span, and addon-wrapper triggers. A nil enabled
caller must use `Popover.tooltip_toggle` for false and `Popover.toggle` for
explicit true. Keep caller click commands, disabled commands, authored trigger
attributes, client attribute ownership, and the existing close helper. Keep
the nil caller hover command nil because the fallback is now correct. Add no
duplicate hover command attribute or shared hook change.

The true mode keeps its existing Popover toggle and dismiss command path and
its existing hook cleanup. This phase does not change that explicit mode.
The current example source has no explicit true caller. Message Scroller
default, previous-context, and streaming explicitly set false. Their caller
click and hover commands must retain their current bytes. Button Group Voice
Mode and Message Scroller reset commands must still perform their caller
actions independently of tooltip opening.

Extend the one existing real public owner in
`storybook/test/browser/tooltip.spec.mjs`. Observe attribute changes with a
native MutationObserver before hover. Retain old values so a short added and
removed expanded value is still visible to the test. Wait for the actual
popup, then save its visibility, side, and observed expanded values before
assertions. Require the visible positioned popup to have produced no
disclosure state. Close with real Escape and apply the same contract through
closure. Disconnect the observer and dispose its handle in `finally`. Keep
the popup, frame delivery, timer behavior, and production API real.

This is a current accessibility API regression. A tooltip is an informational
popup rather than an expandable disclosure control. The test also requires
successful opening and closure, so an inert trigger cannot satisfy the absent
attribute assertion. The current positioning owner does not protect this
attribute history. The generic comparison reads one instant and can miss it.
Extend the owner instead of adding a duplicate case or a production test seam.

First prove RED on the real unchanged public default with the private copy of
this owner through the normal npm wrapper. A valid saved open receipt must
show Phoenix, `tooltip-default-trigger`, a visible popup, a physical side,
and a non-null expanded value. The expanded-value assertion must fail.
Connection failures, popup timeouts, and missing receipts are not this proof.
The private run covers Phoenix only. Use the pinned source and actual generic
comparison for the reference contract; do not claim a second private actor.
Record the fresh result only after that run is terminal.

Apply the source and repository owner patch after the earlier frozen commits.
Require green open and closed receipts with no expanded values. Pass the
existing package Tooltip composition and caller command owner. Pass the
existing Bubble focus owner, Button Group hover, focus and native action
owners, and Message Scroller reset owners. Run complete behavior,
accessibility, semantic and pixel comparisons for Tooltip, Bubble, Button
Group, Kbd and Message Scroller. Keep the final all-64 Shadcn run separate.

Update only `registry/spec/shadcn/tooltip.json` with the final Tooltip
port-body digest. Preserve all upstream fact bytes and pins. Regenerate the
five affected snapshot families. The current caller source and saved command
attributes predict these 11 changed files under `registry/snapshot/`:

- `bubble-tooltip.html`
- `button-group-input-group.html`
- `button-group-nested.html`
- `kbd-tooltip.html`
- `message-scroller-group-chat.html`
- `message-scroller-load-history.html`
- `tooltip-default.html`
- `tooltip-disabled.html`
- `tooltip-keyboard.html`
- `tooltip-rtl.html`
- `tooltip-sides.html`

The Message Scroller default, previous-context and streaming snapshots already
use the false command protocol and should stay unchanged. The snapshot index
must retain its bytes. Fresh rendering must confirm the actual deltas. Keep
unrelated AI snapshot gaps separate. Preserve AI verification record bytes,
official examples, semantic state inventory, and comparison limits.

The phase source and test scope is the Tooltip registry source and its browser
owner. The contract scope is the one Tooltip spec. The predicted snapshot
scope is the 11 files above. PLAN and TODO describe this separate repair.
Do not change `examples.ex`, shared InteractionTrigger or Floating source,
reader helpers, thresholds, source pins, or the earlier frozen repair files
as part of this phase.

**Commit:** `fix(tooltip): preserve tooltip trigger semantics`

The fresh private owner fails at the intended expanded-value assertion. The
popup is visible and positioned. Its native observer records two true values.
The report is `/private/tmp/shadcn-agent-tooltip-bottom/private-red.json`.
All failure attachments have saved copies. The reviewed Tooltip source and
browser owner are committed as `05281e0`. The commit contains only the 14 reviewed
source, test, contract and snapshot files. All five draft documents were restored.

The direct caller run has 25 passes and one invalid page-load failure. The
Voice Mode case stops at `page.goto` with `ERR_NETWORK_IO_SUSPENDED`, before
its caller behavior is tested. Its saved trace stays in the failure archive.
The same unmodified Voice Mode owner passes all three separate repeats.
Tooltip's actual open and closed receipts both contain empty expanded-value
lists. The open popup is visible and positioned; real Escape closes it.
Reports are `/tmp/shadcn-phase69-direct.json` and
`/tmp/shadcn-phase69-voice-repeat.json`. These are diagnostic reports, not
complete component or shared caller verification.

Shadcn passes 154 package tests and its static checks. Storybook passes 80
tests and its static checks. The three saved Storybook inputs retain their
bytes after tests. Offline and online Tooltip contract checks pass. All 463
Shadcn snapshots pass. Both strict snapshot reviews explain exactly 11 changed
files and 58 disclosure-operation removals. Other commands, array order,
markup, upstream facts, pins, the snapshot index and explicit-false caller
snapshots remain unchanged. All 48 AI record byte blocks are unchanged.
The saved proof files use `/tmp/shadcn-phase69-`.

The first 177-case run stopped at its suite time limit. It has 132 passes,
seven failures, and 38 cases that did not run. Four failures are the known
initial message layout differences. Two are known message image differences.
Streaming times out before valid paint proof. Both suite and teardown timeouts
remain recorded. The report and unique failure archive use
`/tmp/shadcn-phase69-five-complete`.

Fresh smaller image batches complete the missing cases without source changes.
All five Tooltip images and all 27 Bubble, Kbd, and Button Group images pass
with zero differences. The remaining seven Message Scroller image cases finish
with no timeout or skips. Four fail and three pass. Load History fails only
at reset, with a temporary History loaded notice in Phoenix and none in React.
The message card pixels match. Keep this notice capture finding separate from
initial layout and busy inventory.

The reviewed diagnostic reports cover all 172 comparisons for 43 examples.
Tooltip has 20 passes, Bubble 36, Button Group 48, and Kbd 24. Message Scroller
has 34 passes and ten failures. All declared visual-state coverage completes
for accessibility, layout and images. The interaction owner compares all
inferred control probes. The 14 source, test and artifact hashes remain exact.
Reports use `/tmp/shadcn-phase69-{tooltip-pixel,callers-pixel,message-pixel-tail}`.
The read-only review is `/tmp/shadcn-phase69-report-review.json`. This combined
review is diagnostic proof. It writes no canonical verification records.
Complete Message Scroller, shared caller and final all-64 proof remain open.

### Phase 6e.70: preserve caller-controlled choices

The fresh direct Menubar run has 19 passes and three intended Phoenix failures.
The React cases pass. Constant checked choices become unchecked in Phoenix.
The constant default Profiles value changes from Benoit. The saved report is
`/tmp/shadcn-menubar-controlled-red.json`.

Add an explicit controlled entry option to Dropdown Menu. Forward it through
Menubar and Context Menu. Controlled choices run the complete caller command
without automatic client state writes. Keep current client behavior by default.
Mark only the four fixed authored checkboxes and default Profiles as controlled.
Keep handled radio choices and RTL Profiles mutable. Keep all choices enabled.

Extend the existing Menubar browser owner for actual pointer and keyboard
input. Apply the separate render regression before source and prove its
callback-command failure. It checks all three public renderers, root and nested
paths, exact callbacks, and two server-supplied values. It protects transport
and render contracts. It does not claim a connected server patch receipt.

Pass direct menu owners, package checks, and all three complete menu families.
Record the independent Context outside-mask defect separately until phase 71.
Render the default, checkbox, and RTL Menubar snapshots. Seven phx-click
arrays should become empty arrays. Keep all other markup and command bytes.
Refresh all three final port_body digests for Dropdown Menu, Menubar, and
Context Menu. Keep pins, source facts, states, and comparison limits unchanged.
The private source and test patches are under
`/private/tmp/shadcn-agent-menubar-diagnosis/phase70/`.

**Commit:** `fix(menubar): preserve caller-controlled choices`

### Phase 6e.71: preserve Context Menu background accessibility

Saved reference traces show inherited background `aria-hidden=true` while a
Context Menu is open. The Phoenix background remains accessible in all 11
semantic cases. Pinned Base UI owns this mask through Context `MenuPopup`.
Its Context Root type omits `modal`. Add no unsupported false option.

Share only the existing Overlay ARIA leases with Floating. Change exactly
`packages/live_base/assets/js/modal_accessibility.js`,
`packages/live_base/assets/js/overlay.js`,
`packages/live_base/assets/js/floating.js`, and
`packages/live_shadcn/priv/registry/dropdown_menu.ex`. Select the root mode
from the actual Context branch. Preserve caller attributes, live regions,
nested portal ownership, hidden descendants, and overlapping lease cleanup.
Keep Overlay scroll/focus and Floating placement/dismissal/focus behavior.

After phases 69/70, recheck current hashes and patch context. Extend only the
existing 16-case `storybook/test/browser/context-menu.spec.mjs` owner.
Run the guarded private Default, Submenu, and Sides cases before source.
Require intended outside AX failure after the real popup opens. Then apply
the four-source repair and obtain GREEN. Pass all 16 Context cases and all
27 existing Drawer cases. Check exact restoration, caller updates, late nodes,
overlap, native submenu selection, and real Docs close/removal. Docs navigation
can close before hook destruction. It does not prove isolated destroy timing.
The overlap case protects the port contract, not a pinned two-root receipt.

Refresh the final `registry/spec/shadcn/dropdown-menu.json` port-body digest
and review only the 11 Context snapshots. Pass all direct Floating owners and
all four comparison layers for Context Menu, Dropdown Menu, Menubar, Popover,
Tooltip, Hover Card, Select, Combobox, Navigation Menu, Avatar, Breadcrumb,
Button Group, Data Table, Input Group, Item, Message Scroller, Open in Chat,
Sidebar, Table, Bubble, Date Picker, Kbd, Pagination, Input, Label, and Field.
Also check Dialog, Alert Dialog, Sheet, and Drawer. Run affected AI owners with
their actual prepared config when normal testMatch excludes them. Preserve AI
record bytes. Record known baseline failures separately and keep incomplete
comparison proof open. Pass Base, Shadcn, Storybook, static, contract, and
snapshot checks. Keep pins, facts, examples, states, and tolerances unchanged.

**Commit:** `fix(context-menu): preserve modal background accessibility`

### Phase 6e.72: preserve final Message Scroller opening

Phase 68 has nine repeated anchor/reader passes, 13 direct passes, and a
complete Anchoring comparison pass. Its complete Message Scroller run still
has 40 passes and nine failures. Saved traces show wrong initial positions
before semantic capture in Previous Context, Commands, Visibility, and
Opening Position. Keep the other image failures separate.

Extend only the existing Commands case in
`storybook/test/browser/message-scroller.spec.mjs`. Keep its pre-LiveSocket
receipt and all command actions. After exact layout readiness, require cleared
pending, positive native extent, exact native end, and an inactive/inert end
button. Obtain intended RED before any source change. Use real public input,
no sleeps, mock renderer, production test API, or relaxed pixel range.

The first source experiment changes only `storybook/assets/css/app.css`.
Remove the pending-row `content-visibility: hidden` rule. Keep normal public
row classes, pending markers, viewport invisibility, caller values, and the
hook controller. The pinned package keeps normal row visibility during
opening. This source experiment has no GREEN proof. Change one variable,
then rerun the same Commands owner and the four complete semantic cases.
If an offset remains, inspect opening target/read order and the real selected-tab
command separately before proposing another source change.

Pass all 13 direct owners, including exact Anchoring, wheel, and Home input.
Pass every state in all four comparison layers for all 11 official examples.
Pass affected package, Storybook, static, snapshot, and contract checks.
Review actual changed evidence inputs. The one-file experiment has no template
or port-body change. Preserve pins, facts, AI record bytes, examples, states,
and all tolerances. Keep broader Message Scroller completion open until its
remaining saved failures pass. Commit only an accepted repair with fresh proof.

**Commit:** `fix(message-scroller): preserve final opening position`

Fresh final-opening RED has three intended failures and no setup errors.
Each run clears pending and has positive native extent. Each then fails the
exact native end comparison with top 987 and end 1009. The report is
`/tmp/shadcn-message-phase72-opening-red.json`. All trace files have saved
copies. The one-file pending-row CSS experiment is now applied. Its GREEN
and complete caller proof remain open.

The same Commands owner passes all three GREEN runs after the CSS-only change.
All 13 direct owners pass, including exact Anchoring, wheel, Home, live resets,
history and tab commands. The four-example diagnostic has seven passes and
one failure. All four inferred interaction owners pass. Commands, Visibility
and Opening Position pass the full semantic comparison. All declared semantic
states complete. Previous Context passes its default state, but fails peek-128
and send-busy. Its trace shows a wrong opening on a fresh peek-state visit
before the slider action, and a separate one-pixel move during busy entry.
These residuals remain open. The CSS experiment is not yet committed. Reports
are `/tmp/shadcn-message-phase72-{opening-green,four-semantic,direct}.json`.
All unique failure attachments have saved copies.

The existing Previous Context direct test now also checks its final initial
position and end button before the slider action. Three fresh runs fail with
a 95-pixel shortfall. Changing the inline read order does not fix this failure.
The experiment has been removed. The template bytes match the prior source,
and both restored builds pass. Reports are
`/tmp/shadcn-message-phase72-previous-red.json` and
`/tmp/shadcn-message-phase72-opening-order.json`.

A private passive control and a private forwarding trace retain three rows
and busy true. React stays at top 392. Phoenix first reaches 392, then its entry
completion callback calls native scrollTo with target 390.75. The browser
returns top 391. This first change is outside the resize callback. Both trace
receipts have no logging errors or dropped events. The trace changes the
initial opening timing, but the busy flow still passes through 401 and 392
before the same final change. These records identify the busy write; they are
not acceptance proof. Reports are
`/tmp/shadcn-message-busy-writer-{control,instrumented}.json`.

A second rejected experiment marks only the inline-selected unheld viewport.
While pending, CSS gives that viewport visible layout and zero opacity. The
existing hook cleanup removes the marker. No observer, timer, frame or second
opening write is added. Commands passes all three direct runs. Previous
Context fails all three. One initial visit reaches top 228 but reset returns
133. Two initial visits remain 95 pixels short. The report is
`/tmp/shadcn-message-phase72-marked-layout.json`. The exact three baseline
files have been restored. Assets and both restored builds pass. An early
LiveView patch can remove the client marker because the viewport ignore list
does not include it. Its actual lifetime and the first native size read remain
to be measured. This experiment is not an accepted repair.

The current status task regenerates `docs/INVENTORY.md`. It reports 61 stale
shadcn ports and Direction with no DOM. The strict requirement check also
includes Data Table, Date Picker and Typography. All 64 requirements remain
unmet on this source. The saved current checks are
`/tmp/shadcn-current-{status,requirements}-3f13a26.log`. These checks do not
write new verification records.

### Phase 6e.73: preserve busy inventory during pixel capture

The saved Message Scroller pixel run captured a later React assistant row
against an earlier Phoenix user row for Default, Streaming and Animation.
That result does not prove a stream-following defect. The pixel owner enters
and settles React, then loads and settles Phoenix before both screenshots.
The authored busy inventory can expire during the other host's load.

Extend only `storybook/test/browser/pixel.spec.mjs`. Derive each busy contract
from the existing `messageScrollerActionDefinitions` export. Record actual
public DOM receipts immediately before and after each `shootCurrent` call.
Assert the same authored item count and `aria-busy="true"` at all four points.
Default, Streaming and Animation require one item. Previous Context requires
three. Keep IDs, text, geometry, scroll position, entry markers and button state
in the receipt for review. Count and busy are the asserted capture contract.
Keep image attachments before those assertions so a valid failure has paint
and state evidence. Do not claim receipt equality proves identical pixels.

Prove a fresh intended RED with the regression patch alone. It must reach real
screenshots, save all four receipts, and fail the named busy inventory at a
capture boundary. Startup, replay and screenshot failures are not this proof.
The prior saved images remain historical evidence until this RED is terminal.

After RED, retain the final viewport and shared clip. Navigate, connect where
needed, replay and settle each host again, then capture it before work on the
other host. Use the same real action and existing settle and capture helpers.
Add only two real navigations per busy state. Keep every non-busy path, timer,
readiness rule, state, pixel threshold, budget and existing test deadline.
The real reply window stays 1,000 ms. An expired own-host capture must still
fail. No timer hold, hidden retry, capture omission or production seam is added.

Require three exact selected runs for Default, Streaming and Animation.
Inspect all busy receipts and require zero pixel differences. Separate known
initial-layout failures from busy capture proof; complete owner GREEN remains
open while those failures remain. Then pass all 11 Message Scroller examples
through accessibility, interaction-parity, semantic and pixel owners. Include
Previous Context and all declared states. Keep existing direct Message
Scroller owners and independent anchoring, reader-input and reply proof.

No production source, port-body digest, snapshot, upstream fact or pin change
belongs to this phase. Keep AI records and VERIFY unchanged until the normal
final verification flow. The two private patches and review are under
`/private/tmp/shadcn-agent-message-paint/phase73/`. Apply regression.patch
first and owner-repair.patch only after valid fresh RED. Fresh RED and GREEN
are pending.

**Commit:** `test(browser): preserve busy inventory during pixel capture`

### Phase 6e.74: preserve history notices during pixel capture

The saved Load History reset images show the same message card. Phoenix also
has the History loaded notice; React has no notice. The pixel difference is
1,616 pixels outside the named slots. Both actual reset callers retain the
notice. Both actual notice timers use 4,000 ms. This is a capture timing finding.
It does not prove an opening CSS or Tooltip defect. Phase 6e.73 guards busy
inventory and does not cover this reset state.

Extend only the existing pixel owner after the exact phase 6e.73 patches.
Guard both authored notice actions through one predicate. Load History requires
eleven items and a disabled History Loaded button. Reset requires six items and
an enabled Load History button. Both require one real painted notice titled
History loaded and description Scroll up to see earlier messages.
Record native receipts before and after both final framing measurements and
both actual screenshots. Keep notice text, native visibility, flags, boxes,
item inventory, times and document visibility in the receipts. Require the
notice to fit the shared clip. Attach images and receipts before assertions,
including images for invalid notice receipts with zero differing pixels.

Prove a fresh intended RED with the regression patch alone. All final framing
receipts must contain the positive notice and authored action inventory. The
actual screenshots and capture receipts must then expose the notice mismatch.
Page-load, replay, framing and unrelated failures are not that RED. The saved
old images do not replace fresh proof.

After RED, extend the existing per-host capture path to both notice actions.
Replay and settle each host with its real action at the final viewport, then
capture it before loading the other host. Keep the proved shared clip and
positive before/after capture checks. Add only two real navigations per notice
action.
Keep all timers, pauses, server dismissal, readiness rules, budgets, thresholds,
deadlines and declared states. An own-host notice expiry must still fail.

Require three complete Load History pixel runs with valid positive receipts
and zero pixels in both notice actions. Then pass all 11 complete Message
Scroller examples in
accessibility, interaction-parity, semantic and pixel owners, plus the existing
direct owner. Keep separate opening and busy findings open until they pass.
No production source, digest, snapshot, pin, upstream fact or VERIFY change
belongs to this phase. Preserve AI records. Fresh RED and GREEN are pending.
The private patches are under `/private/tmp/shadcn-agent-message-toast/phase74/`.
Apply regression-after-73.patch first, then owner-repair-after-73.patch only
after valid fresh RED.

**Commit:** `test(browser): preserve history notices during pixel capture`

### Phase 6e.75: batch compiled badge evaluations

The current Docs compile path evaluates each identity separately. An eligible
record can collect shared inputs twice when its evidence is stale. The test
warm build was reported to take about ten minutes. That whole-build time does
not prove the isolated cost of Docs evaluation. Measure the current path before
changing it. Root reports terminal focused phase 6e.72 proof: three Commands
GREEN runs, all thirteen direct cases, three semantic cases and four interaction
cases passed. Permit independent read-only measurement after that focused proof
and after active leases and compilers end. Previous Context residuals and complete
Message Scroller proof remain open. Source application needs a separate decision.

Use the existing evidence_digests/2 for one fresh Docs evaluation batch. Select
present eligible shadcn records from the unchanged identity union. Keep all
missing, excluded and No DOM paths. Pass each computed digest through the
existing target and stale-reason checks. Preserve exact statuses, labels,
reasons, ordered checks, identity version, digest bytes and record format.
Keep the single-record API and all external-resource and recompile behavior.
The digest map belongs to one call. A later call reads changed bytes and added
or removed paths again. An empty eligible set skips shared evidence collection.
An explicit empty shadcn record can still read UPSTREAM.json during policy
selection. Add no long-lived cache or weaker input coverage.

Before application, compile the saved pre-change source and candidate source
as two distinct private modules. Use the same real source filename and unchanged
live input root. Compare the actual pre-change evaluator with the candidate
batch. Save complete evaluation maps, independent and
batch digest maps, elapsed time and reductions. Reject a timeout, changed
inputs or unequal results. Record measurement order and warm-state limits.
Then save actual test and dev Docs warm times with comparable preparation.
Do not claim a speed improvement from source inspection or the earlier whole
warm time. The private measurement and candidate are under
`/private/tmp/shadcn-agent-docs-compile/batch/`.

Extend the existing publication lifecycle test with actual batch badge states
after byte changes, path additions, path deletions and restoration. Strengthen
the existing compiled badge owner to compare the complete evaluation, including
ordered per-check reasons. Keep the existing rendered badge, policy, freshness
and reload owners. Add no source-string, call-count or timing-threshold test.
The stronger compiled contract must pass before and after the repair. A missing
new batch API is not evidence of a performance defect.

Pass the full private verification project and Storybook checks. Confirm all
current badge states, docs-only families, excluded AI, release compilation and
recovery after changes. Keep clean release checks open until actual proof is
saved. Keep snapshots, port digests, upstream facts, pins, budgets, thresholds,
states and AI records. Source changes make old evidence stale through the normal
rules. Preserve normal VERIFY ownership. Measurement, tests, application and
commit are pending.

**Commit:** `perf(verification): batch compiled badge evaluations`

The corrected private measurement is terminal and passes. All 113 complete
evaluation maps match. All 64 independent and batch digest values match.
All captured input bytes remain unchanged. The original evaluation takes
140.354 seconds and the batch takes 1.808 seconds in this one ordered run.
Original digest collection takes 75.747 seconds and the batch takes 1.313.
Warm state can favor the second path. The report is
`/tmp/shadcn-docs-batch-measurement.json`.

The complete compiled contract first exceeds its existing 60-second limit
in native wildcard traversal. No result comparison fails. The same unchanged
assertions pass with the diagnostic CLI limit of 300 seconds. Both cases pass
in 176.1 seconds. The timeout and completed logs are preserved. This does not
prove that the normal deadline passes. The batch source and the existing
publication freshness test are now applied.

The complete verification project passes 33 tests and all configured checks.
Storybook passes 80 tests with the diagnostic 300-second limit and all configured
checks. Its normal run passes 79 of 80 tests. The compiled badge owner still
exceeds its normal 60-second limit in shared file collection. Keep that normal
limit open for the separate scan repair. All three mutable Storybook inputs are
restored after both runs.

The post-application comparison also passes on stable current inputs. All 113
complete evaluations and 64 digest values match. The original evaluation takes
49.501 seconds and the batch takes 0.718 seconds. Native-first order and warm
state limit this measurement. The receipt is
`/tmp/shadcn-docs-batch-applied-measurement.json`.

Both forced Storybook builds pass without warnings. The test build takes 916.73
seconds and the development build takes 1816.04 seconds. These are current
whole-build times, with no comparable isolated Docs baseline. Do not use them
as a speed claim. All 48 AI record byte blocks remain unchanged. No snapshot,
pin, budget, state, policy, or verification record changes belong to this scope.
The normal test deadline and clean release proof remain open.

### Phase 6e.76: prune excluded identity directories

The phase 75 batch measurement preserves all current results and digests.
The stronger compiled badge owner still exceeds its normal 60-second limit.
The normal Storybook run passes 79 of 80 tests. The remaining owner times out
in shared input traversal before its result assertion completes. Preserve that
assertion and deadline. A diagnostic timeout increase is not the repair.

Skip traversal only inside directory paths already excluded by generated_path?/1.
Use the pinned native OTP wildcard engine and native file/link metadata calls.
Keep the native default dotfile filter, lexical symlink names and hidden roots.
Keep exact compile path order and duplicates, exact shared selected paths and
bytes, all declared globs, and the final regular-file and generated-copy checks.
A regular file with a generated directory name remains eligible. An allowed
symlink alias to a generated target remains eligible under its allowed name.
The generated asset digest check still proves logical and derivative bytes.
Add no broader exclusion, custom glob matcher or long-lived cache.

Before source application, measure the actual saved phase 75 source and the
private candidate as distinct modules against the same unchanged live root.
Use the same real source filename. End all input-writing tests, source leases
and compilers before measurement. Matching endpoint receipts cannot detect
every transient write that a concurrent test restores. Save raw compile lists,
exact shared byte
list equality, complete evaluations, digest values and input receipts. Include
added and deleted selected paths in the unchanged-input check. Use a finite
five-minute shared limit. Reject timeout, input changes or unequal data. Record
native-first order and its warm-state limit. The private candidate and proof
script are under `/private/tmp/shadcn-agent-docs-scan/phase76/`.

Extend the existing verification input owner with a real hidden-root fixture,
UTF-8 paths, lexical directory/file aliases and near generated names. Use the
unchanged native Path.wildcard result as the independent fixture oracle.
This compatibility case must pass before and after the candidate. It is not
a claimed functional RED. Existing publication lifecycle and digest-copy owners
retain byte-change, added/deleted-path and generated-copy proof. Add no copied
predicate, source assertion, call-count assertion, mock or timing-threshold test.

Pass normal private-project tests and checks. Pass complete compiled badge,
rendered badge and reload owners at the normal deadline. Pass full Storybook
tests and checks. Save comparable actual test/dev Docs warm times. Preserve
release behavior, facts, pins, snapshots, identity version, policies, states,
budgets, thresholds, AI records and normal VERIFY ownership. Changed source
bytes make existing evidence stale through the normal rules. Keep clean release,
Previous Context and complete Message proof open. Measurement, application,
normal-deadline GREEN and commit remain pending.

**Commit:** `perf(verification): prune excluded input directories`

The pre-application measurement passes with 821 compile entries and 676 shared
files. The final-tree comparison passes with 822 compile entries and 677 shared
files, including the new adapter. Both algorithms read the same tree in each
comparison. Complete results match for all 113 identities, and all 64 digests
match. Input receipts and accepted formatted source bytes remain unchanged.
The final receipt is `/tmp/shadcn-docs-scan-applied-measurement.json`.

The native-source primary test passes 25 cases in 8.1 seconds. After application,
the complete verification project passes 34 cases in 1.3 seconds and all
configured checks. Full Storybook passes all 80 cases in 8.5 seconds at the
normal deadline. It also passes all configured checks. This includes the
compiled badge comparison, both rendered badge locations, and reload recovery.
All three mutable Storybook input files are restored after testing.

Both forced Storybook builds pass without warnings. Test takes 17.21 seconds
and development takes 17.17 seconds with four schedulers. These whole-build
times follow the phase 75 builds. Measurement order and warm filesystem state
remain limits. All 48 AI record byte blocks are unchanged. Snapshots, port
bodies, pins, policies, states, budgets and verification records are unchanged.
The independent final formatted review finds only formatting changes to the
test and exact source/adapter equality with the candidate. Clean release and
complete Message proof remain open. The three-file scan commit is ready.

### Phase 6e.77: preserve upper-clamped entry positions

The entry completion trace proves an extra native write from 392 to 391 after
a prior anchor request was upper-clamped at 392. Preserve that real request
outcome only while the same connected active item, effective margin, generation,
spacer, native top and native extent remain current. A reachable anchor still
gets its exact completion correction. Keep real resize and patch work active.
Use no proximity threshold, busy exception, new timer or private test API.

The existing completion unit owner now covers reachable 402-to-400 correction,
the same reachable correction when native end is 402, and an upper-clamped
400.75 request that must retain 392. The test-only patch fails on the last row
with actual 390.75. After the source repair, all 39 Scroller and all 91 Base
JavaScript tests pass. The original atMessageEnd native read order supplies
the request range. Only an eligible clamped completion adds a fresh range read.
An inactive record can retain one prior item and spacer; the active-item guard
prevents it from controlling an old completion.

All 80 Storybook tests pass at the normal deadline in 8.1 seconds. The three
mutable test input files restore their exact bytes. Base and Storybook checks
pass. The uninstrumented browser repeats complete all seven Previous Context
states three times with no recorded divergences. Busy and reply have no
geometry differences in any repeat. Nine repeated exact anchor, wheel and
Home cases pass. All 13 direct cases complete with 12 passes and the existing
95-pixel initial-position failure. This does not complete Previous Context.

A separate check uses the committed CSS, with the pending CSS change saved
and restored exactly. Its three positive direct cases pass. All seven semantic
states complete, with busy and reply still equal and initial-related states
still failing. The callback result therefore does not depend on the pending
CSS removal. Both restored builds pass afterward.

Reports are `/tmp/shadcn-message-entry-clamp-{browser,direct}.json` and
`/tmp/shadcn-message-entry-clamp-head-css-browser.json`. Logs for the intended
unit RED, full JavaScript GREEN, Storybook tests and static checks share the
`/tmp/shadcn-message-entry-clamp-` prefix. Keep opening-contract review,
complete four-layer Message proof and clean release work open. Preserve AI
record bytes and normal evidence staleness.

**Commit:** `fix(message-scroller): preserve clamped entry positions`

## Phase 6e.78: preserve Select pointer focus and highlight

The final Message Scroller Animation comparison exposed an intermittent Select
highlight difference. A native pointer sequence makes the defect repeatable.
The pinned reference clears the pointer highlight and focuses the popup when
the pointer leaves an option. Phoenix retains the selected Fade highlight,
does not focus Slide Up on hover, and starts the next ArrowDown from Fade.

Scope the repair to option roving focus in `live_base/assets/js/roving.js`.
Keep selected values unchanged during hover. Use focus without scrolling.
Preserve keyboard highlight, disabled options, nested content, and cleanup.
Extend the existing Select browser owner with the same native pointer and
keyboard sequence on both hosts. Require intended failure before repair,
passing direct Select checks, complete Select comparisons, and repeated
Message Scroller Animation semantic checks. Keep all limits and states.

Commit: `fix(select): preserve pointer focus and highlight`.

## Phase 6e.79: keep the Command accessibility fixture visible

The grouped Command owner inserts an invalid unrelated preview under the body
while a modal is open. The modal now correctly hides this late outside node.
The test therefore cannot observe its intended independent violation.

Insert the same fixture inside the visible dialog and prove it remains
accessible before the scan. Keep the distinct preview target and the expected
single `aria-required-children` failure. Preserve production modal behavior.
The same owner can fill the React input before hydration. Its saved failure
shows `data-reference-ready` absent during the input action. Use the existing
reference readiness check before React interactions. Pass the unchanged
matcher contracts, filter test, and complete Command comparisons.

Commit: `test(command): keep the unrelated accessibility fixture visible`.

## Phase 6e.80: wait for Date Picker entry before observation

The dedicated Date Picker action path returns during the native popup entry
transition. Six native runs measured opacity below one and false contrast
failures. After the same finite animations ended, all those failures cleared.
The two hosts use the same weekday text color.

Use the existing finite-transition wait in the Date Picker action path.
Extend an existing browser owner with a real transition regression before the
repair. Keep production colors, durations, deadlines, and all comparison
states. Pass shared helper checks and complete Date Picker comparisons.

Commit: `fix(verification): wait for Date Picker entry transitions`.

## Phase 6e.81: finish Select entry before clearing pointer hover

The visual-state helper moves the pointer after a listbox click before the
popup is ready. Depending on entry timing, the pointer leaves the trigger or
an option. The resulting highlight differs. A real Scrollable Select test
with the existing slow-frame fixture reproduces the failure on React.

In listbox paths, wait for expanded state, a visible controlled listbox, and
the existing finite entry settlement before clearing hover. Cover discovery,
expanded entry, and nested entry through their existing helper paths. Leave
menu paths unchanged. Extend the existing browser owner with the native
pointer regression. Pass complete Select comparisons and repeated Message
Animation comparisons. Preserve inventory, thresholds, and production timing.

Commit: `fix(verification): finish Select entry before clearing hover`.

## Phase 6e.82: preserve Navigation Menu focus and accessibility

Both official Navigation Menu examples fail behavior, accessibility, and
semantic comparisons. Native diagnostics identify four causes. A plain link
uses the trigger-only `group` class. Click-away closes a popup before its
trigger toggles it open again. Autofocus moves pointer focus to the first link.
The nested popup navigation landmark duplicates the root landmark and places
content outside the active item in the accessibility tree.

Use the existing pinned CVA base for plain links. Use the existing Floating
dismiss-command path and keep pointer focus on the trigger. Represent the
popup as a container inside the root navigation landmark. Match native
`aria-owns` ownership with a span in each item and an identified viewport.
Keep the original root reading order and all trigger/content states.

Extend the existing Navigation browser owner with the native root accessibility
tree and open/close focus behavior. Preserve the single-item public form,
disabled items, outside dismissal, Escape, and RTL. Review both snapshots and
the added copy binding. Keep upstream facts unchanged. Require both complete
examples in all four layers without comparison exclusions or new limits.

Commit: `fix(navigation-menu): preserve focus and accessibility ownership`.

## Phase 6e.83: resolve remaining integrated comparison failures

The full run at `9f0e798` completed on 2026-10-11. It passed 53 of 64 groups.
All repairs in the first factory assignments passed this run. The following
failures still prevent release acceptance. Diagnose each failure against the
pinned native reference before editing its port or observation code.

| Owner | Group and current failure | Required proof and scoped commit |
|---|---|---|
| Coordinator | Hover Card sides has a legacy 11-pixel budget. | Require exact pixels, then set the budget to zero. `fix(hover-card): preserve native paragraph text runs`. |
| Menus worker | Label and Pagination inferred control discovery differs. | Compare actual native controls and interactions. `fix(examples): preserve Select field names`. |
| Menus worker | Toggle Group behavior and font-weight layout differ. Its legacy budget is 32 pixels. | Prove controlled choices, caller classes, and exact pixels. `fix(toggle-group): preserve native selection and caller layout`. |
| Menus worker | Progress control discovery, accessibility, and rendering differ. | Prove controlled updates and native control semantics. `fix(progress): preserve controlled example behavior`. |
| Message worker | Scroll Area fails five scroll behavior checks. | Prove edge state, thumb movement, local scrolling, horizontal scrolling, and RTL. `fix(scroll-area): preserve ordinary scroll measurements`. |
| Message worker | Marker notice behavior and pixels differ. | Prove the actual notice after the caller action. `fix(marker): render the native notice title`. |
| Message worker | Toast types adds an aria-hidden-focus failure. | Prove native focus, announcements, and cleanup. `fix(toast): preserve urgent notice focus and announcements`. |
| Message worker | Sidebar toggle differs by 448 pixels at the trigger. | Prove exact open and closed captures after real interaction. No source repair is justified by current repeat results. |
| Chart worker | Questionnaire Next validation, behavior, and pixels differ. | Prove invalid state, conditional updates, and reset behavior. `fix(questionnaire): preserve answer and reset behavior`. |
| Chart worker | Item has caller class conflicts and a one-pixel image difference. | Prove Item and composed Avatar class replacement and exact layout. `fix(item): preserve caller display and text layout`. |

Use separate worktrees and existing behavior owners. The coordinator owns the
shared pixel-budget file. Lower a legacy budget only after exact comparison
passes. Never increase a limit, omit a state, change a pin, or change AI records.
Keep all failures visible until reviewed repairs and complete scoped checks
pass. Update the exact commit title if diagnosis changes the repair scope.

Diagnosis has also identified composed caller repairs. Avatar and Toggle must
merge caller classes through the existing `Cn.merge` API. The controlled
Progress reference exposes two scalar Slider thumbs. Add an explicit optional
thumb count while keeping the documented one-thumb default and list behavior.
Both scalar controls must stay operable and update the same value.
The first candidate retained its last reported scalar value after a server
reset. A new selection of that value then sent no event. Refresh that baseline
after a server update and preserve duplicate input/change suppression. The new
thumb count must also remain operable when its server value changes. Prove
control binding, caller ownership, and cleanup through an update.
Commit: `fix(slider): preserve controlled values across updates`.

Hover Card sides has three paragraph text nodes in React and one in Phoenix.
Native boxes match, but glyph positions differ by 1/64 pixel. Explicit comment
boundaries remove the measured difference. Keep the paragraph on one line with
`phx-no-format`; formatter whitespace otherwise changes glyph positions again.

Completed coordinator proof: all three Hover Card examples pass every layer
at zero pixels after formatting. Commit `dea5c33` contains the text repair,
reviewed snapshot, and 11-to-zero budget reduction. Scroll Area and Marker
repairs are integrated as `b3d91d7` and `8053f16` after complete scoped proof.

Select field names are integrated as `185b361`. Toast focus and announcements
are integrated as `2a8bcbf`; all 25 Toast checks and 15 shared caller checks
pass. Toggle Group is integrated as `b3ba6a9`, including its 32-to-zero pixel
limit. Both legacy pixel limits are now zero. Progress and Slider updates are
integrated as `913f211` and `0622a6b`. Independent review found no further
blocker. All 96 Base hook tests, 52 non-pixel browser checks, and 11 complete
Slider/Progress image examples pass. All 24 official image states use zero
budgets. Questionnaire is integrated as `6e88c3c`. All 14 examples pass every
required layer. Its final seven direct tests also pass, including explicit
caller IDs. Independent review found no blocker.
Item and Avatar are integrated as `8d0dbb2`; all 21 examples pass all required
checks. The Item image example has zero pixel difference.

Questionnaire now marks generated description and error IDs through LiveView's
JS API. Raw client ID writes had caused empty description nodes after server
patches. Existing caller IDs remain intact. The hook forwards the declared
reset event because LiveView does not send it. The resumed example now shows
the pinned reset notice. Input updates clear invalid state on the item, its
choices, and the freeform control.

Sidebar passed one complete run and six image repeats after the first failure.
The next full run at `c6ba115` reproduced the exact 448-pixel failure. Phase
6e.85 records its proved cause and repair. The repeat passes did not close it.

The first full run's records are diagnostic evidence. Source repairs invalidate
that evidence. Repeat all affected verification on the combined source before
acceptance. Build and test new package archives after the final port changes.

## Phase 6e.84: finish nested dialog entry before capture

The full run at `c6ba115` passed 62 of 64 groups. Nested Drawer failed semantic
comparison because the pointer remained on the next trigger on Phoenix. The
same pointer position was outside that trigger on React. Their native hover
backgrounds differed. All other Drawer checks passed.

In `storybook/test/browser/visual-states.mjs`, wait for a controlled dialog to
be visible and finish finite entry transitions. Then move the pointer outside
before the next nested click and after the last dialog entry. Apply this to
expanded replay and nested action replay. Preserve menu and listbox behavior.
Do not change official states, component source, or comparison limits.

The existing browser owner must prove that nested pointer actions start after
entry, the unopened fourth trigger has no incidental hover, and the front
dialog retains focus. Require a failing check before the repair, passing checks
on both hosts, repeated nested comparisons, and shared popup caller checks.

**Commit:** `fix(verification): finish nested dialog entry before capture`

## Phase 6e.85: finish initial motion before action entry

The same full run reproduced Sidebar's 448-pixel image difference. Fresh images
match both saved failure images exactly. The failing state is interactive
action index 2, the header trigger. Index 1 is the rail. React's trigger moves
during initial entry. Playwright retries the unstable click and cycles its
scroll alignment. Its fourth attempt scrolls the document by 64 pixels.
Phoenix's stable trigger needs no retry and the document stays at zero.

Before the shared interactive-action click in `visual-states.mjs`, use the
existing finite transition wait. Check the real Sidebar action in the existing
browser owner, with a failing result before the repair and passing results
after it. Prove native focus, document scroll, and collapsed state. Repeat the
full Sidebar sequence and check other interactive-action callers.

Preserve Sidebar source, screenshot coordinates, native scrolling, official
states, pins, and zero image limits. Do not reset scroll to hide a difference.
Require independent review before integration.

**Commit:** `fix(verification): finish initial motion before action entry`

## Phase 6f: refresh evidence and verify release badges

- Finish verifier changes before the final full run. Prepare existing pinned
  inputs and locked dependencies. Confirm that the shadcn and AI refs have not
  advanced.
- In tools, run `mix ui.spec --check --offline --source shadcn` and
  `mix ui.spec --check --source shadcn`. In Storybook, run
  `mix snapshot --check` and identify existing unrelated gaps.
- Run `mix ui.verify --source shadcn`. Resolve shadcn failures through reviewed
  changes and scoped reruns. Add phases with exact commit messages to both plan
  files before substantial port repairs. Keep thresholds and official examples.
- Generate inventory with `mix ui.status`, then pass
  `mix ui.status --check --source shadcn --require-verified`. Preserve AI record
  bytes and account for AI status changes caused by shared input changes.
- Recompile Storybook after the evidence write. Check `/`, `/docs/button`,
  `/docs/dialog`, `/docs/data-table`, `/docs/date-picker`, `/docs/typography`, and
  `/docs/direction`. Badges and details must match pipeline results.
- In a temporary copy, change a hook and require Stale after compilation.
  Record a current failure and require Failed. Record incomplete evidence and
  require Not verified. Restore the fixture and verify recovery.
- Build the Storybook release image from a clean checkout. Check badges without
  runtime repository files. Do not deploy as part of this plan.
- Update `README.md`, `docs/ARCHITECTURE.md`, and `parity/README.md` with source
  selection, report provenance, badge meaning, and rerun instructions.

Progress: the shadcn-only refresh renders 463 snapshots; all pass the scoped
snapshot check. Of 159 refreshed files, 117 differ only in Phoenix JS JSON
object-key order. The other 42 files reflect previously reviewed class
binding/order, Tailwind conflict resolution, select hidden-input and label
ownership, menu-group label ownership, Dialog RTL label identifiers, and
resizable orientation repairs. The snapshot refresh changes no component
source. The full snapshot check still reports 17 AI
example snapshots (task, sources, chain-of-thought, reasoning, snippet,
attachments ×3, commit, environment-variables, mic-selector, plan, stack-trace,
tool, code-block, terminal, open-in-chat); these are outside the shadcn refresh.

Integration checks so far: private verification 33 tests, tools 164, Base 42,
shadcn 149, Storybook 80, browser helpers 108, parity helpers 32, and Base hooks
93 pass. The first Storybook run raced an evidence write; recompilation and a
stable-record rerun pass. Tools/Storybook/Base Credo, configured formatting, and
both workflow actionlint checks pass. Final evidence and release checks remain
unproven until the restarted full browser run and image validation finish.

**Commit:** `docs(verification): record current shadcn parity and badge results`

## Verification and phase completion

Run each phase's focused checks before its commit. At final integration, run
the private project's tests and `mix test` in tools, Storybook, live_base, and
live_shadcn. Run configured format and static checks for changed Elixir
projects, all browser helper tests, and parity Node tests. Test current behavior
and persistence contracts. Do not add tests that only assert removed code stays
absent.

Code phases must compile and pass their tests. Changed verifier inputs make old
evidence stale; keep this state visible. Do not claim the strict gate passes
until phase 6 completes. Completion requires the strict shadcn gate and release
badge checks. Record unrelated failures separately. Commit each phase with its
exact scoped message before starting the next phase.

## Risks and tradeoffs

- Conservative shared input coverage can require many reruns. Prefer correct
  invalidation first; measure cost before narrowing dependencies.
- New identity and report versions invalidate old shadcn evidence. Retain old
  records as stale until real checks replace them.
- Larger captures can expose real differences and increase work. Keep one
  browser worker, current batching, and content-visibility behavior.
- Shared code serves two registries. Limit policy changes to shadcn and test
  source isolation. AI repairs remain a separate task.
- Release badges are compiled data. Test build order and development reload so
  a correct record cannot produce a stale compiled badge.
- Corrected checks can expose port defects. Identify the component, example,
  state, and failing check before adding repair phases.

## Open questions

No user decision blocks implementation. Use the badge labels and release
behavior specified above. Measure full shadcn run time and invalidated target
counts during implementation. These measurements can guide later performance
work; they do not relax acceptance criteria.

Historical run 3 had 64 shadcn records, 24 passed and 40 failed. Later repairs
supersede that result. The latest complete run at `c6ba115` passed 62 of 64.
Drawer and Sidebar remain open until phases 6e.84 and 6e.85 pass full combined
verification. All 48 AI record byte blocks remain unchanged.
