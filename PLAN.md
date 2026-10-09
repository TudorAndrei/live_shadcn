# Plan: shadcn parity and verification badges

Status: in progress. Phases 6e.6 through 6e.13 are complete. Phase 6f refreshes
the full verification evidence and checks release badges.
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

## Findings to resolve

| ID | Current code and problem | Required result |
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

### Phase 6f: refresh evidence and verify release badges

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
snapshot check. Of 159 refreshed files, 118 differ only in Phoenix JS JSON
object-key order. The remaining changes reflect previously committed class
binding/order, Tailwind conflict resolution, select hidden-input and label
ownership, menu-group label ownership, and resizable orientation repairs. No
port was changed by this refresh. The full snapshot check still reports 17 AI
example snapshots (task, sources, chain-of-thought, reasoning, snippet,
attachments ×3, commit, environment-variables, mic-selector, plan, stack-trace,
tool, code-block, terminal, open-in-chat); these are outside the shadcn refresh.

Integration checks so far: private verification 27 tests, tools 160, Base 42,
shadcn 147, Storybook 74, browser helpers 101, parity helpers 32, and Base hooks
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
