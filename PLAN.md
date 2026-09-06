# Plan: shadcn parity and verification badges

Status: in progress. Phase 1 complete.
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

### Phase 6: refresh evidence and verify release badges

- Finish verifier changes before the final full run. Prepare existing pinned
  inputs and locked dependencies. Confirm that the upstream manifest and ref
  have not advanced.
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
