# TODO: shadcn parity and verification badges

Follow [PLAN.md](PLAN.md). Phase 5 complete. Complete each phase,
run its checks, and make its exact commit before starting the next phase.

## Phase 1: share shadcn evidence evaluation

- [x] Add private `tools/verification/` project and fixture tests.
- [x] Add tools/Storybook path dependencies and private-project CI checks.
- [x] Share shadcn identity and evaluation across tools, status, and Docs.
- [x] Preserve producer digest bytes during extraction and preserve the AI path.
- [x] Test primitive, documentation-family, No DOM, missing, and stale records.
- [x] Prove both adapters match independent expected results.
- [x] Run private-project, tools identity/policy, and Storybook status tests.
- [x] Commit: `refactor(verification): share shadcn evidence evaluation`

## Phase 2: bind current inputs to badges

- [x] Version identity and include runtime, dependency, and verifier inputs.
- [x] Test changed hooks, CSS, references, shims, locks, port dependencies,
  and file sets.
- [x] Test equal identities for prepared and clean-checkout fixtures.
- [x] Check fetched bytes against committed digests during preparation.
- [x] Capture identity at test start and reject changes before publication.
- [x] Implement Verified, Failed, Stale, Not verified, and No DOM decisions.
- [x] Distinguish failure from skipped, incomplete, and diagnostic checks.
- [x] Update both badge locations and add readable per-check reasons.
- [x] Test all badge states against independent expected fixtures.
- [x] Test reload after evidence changes and added/deleted inputs.
- [x] Check builder inputs and compiled results in a clean temporary build.
- [x] Run shared-project, tools, and Storybook focused tests.
- [x] Commit: `fix(verification): bind shadcn badges to current pipeline evidence`

## Phase 3: validate reports and reject partial verification

- [x] Produce reports with test-time identity, scope, layer, states, and completion.
- [x] Use one identity implementation for direct and managed execution.
- [x] Validate identity, ownership, layer, examples, states, and global errors.
- [x] Reject old raw reports with a rerun reason.
- [x] Reject diagnostic filters in evidence runs and reject partial imports.
- [x] Preserve complete-example batches and require all required batches.
- [x] Keep validation, merge, and publication under the verifier lock.
- [x] Test source changes, wrong ownership/layer, top-level errors,
  and missing states.
- [x] Test valid multi-batch completion and safe rejection of invalid imports.
- [x] Run tools report/import tests and all browser helper tests.
- [x] Run a complete shadcn batch through direct and managed execution.
- [x] Commit: `fix(verification): reject stale and partial browser reports`

## Phase 4: capture overflow and preserve pixel diagnostics

- [x] Include visible unslotted overflow in `paintedBoxInDocument`.
- [x] Preserve page-chrome, hidden-content, clipping, portal, and lazy-layout rules.
- [x] Add a browser case where changed overflow must produce a pixel difference.
- [x] Test nested overflow, portals, clipping, and hidden descendants.
- [x] Handle null boxes in `localise` and preserve unmatched pixel counts.
- [x] Run `shoot.test.mjs` and all browser helper tests.
- [x] Run scoped parity/pixel checks for dialog, popover, tooltip, toast, and message-scroller.
- [x] Commit: `fix(parity): capture visible shadcn overflow`

## Phase 5: make shadcn workflow scope explicit

- [x] Add and test `--source shadcn` in `ui.verify` and `ui.status`.
- [x] Select ports and documentation families and apply No DOM policy.
- [x] Reject unknown options and invalid source/name combinations.
- [x] Add `--require-verified` to source-scoped status checking.
- [x] Prove incomplete evidence fails even when inventory text matches.
- [x] Install parity dependencies in upstream sync.
- [x] Make the shadcn sync write evidence and refresh inventory.
- [x] Add the strict shadcn CI gate and preserve unrelated checks.
- [x] Run tools tests, Node tests, and actionlint for both workflows.
- [x] Exercise clean-checkout installation and scoped verification.
- [x] Commit: `fix(ci): record and gate shadcn verification results`

## Phase 6: refresh evidence and verify release badges

- [ ] Prepare pinned sources without advancing the upstream manifest or ref.
- [ ] Run offline and fetched-source shadcn contract checks.
- [ ] Check snapshots and record unrelated baseline failures separately.
- [ ] Run `mix ui.verify --source shadcn` for every selected target.
- [ ] Resolve failures without weakening thresholds or dropping official examples.
- [ ] Add scoped phases to both documents before substantial port repairs if needed.
- [ ] Refresh inventory and pass `mix ui.status --check --source shadcn --require-verified`.
- [ ] Preserve AI record bytes and account for shared-input status changes.
- [ ] Recompile Storybook after the final record write.
- [ ] Check both badge locations for button, dialog, the three docs families,
  and direction.
- [ ] Test stale, failed, and incomplete badges and recovery in a temporary copy.
- [ ] Build a clean release image and check badges without runtime repository files.
- [ ] Update README, architecture, and parity documentation.
- [ ] Commit: `docs(verification): record current shadcn parity and badge results`

## Verification

- [ ] Run all private verification project tests.
- [ ] Run `mix test` in tools, Storybook, live_base, and live_shadcn.
- [ ] Run configured format and static checks for changed Elixir projects.
- [ ] Run `node --test ./*.test.mjs` in `storybook/test/browser`.
- [ ] Run `npm test` in `parity` with local test-port access.
- [ ] Pass complete current shadcn behavior, accessibility, semantic,
  and pixel checks.
- [ ] Verify every official shadcn example, including documentation families.
- [ ] Match shadcn results across pipeline, index, component pages,
  and release build.
- [ ] Prove no-browser, missing, partial, stale, failed, and ungated evidence
  cannot show Verified.
- [ ] Preserve component APIs and behavior except explicitly reviewed parity repairs.
- [ ] Confirm source isolation and unchanged AI policy, examples, and records.
- [ ] Add no tests that only assert removed code stays absent.

## Review

- [ ] Review input coverage, report ownership, status precedence, and release compilation.
- [ ] Review each test against a current behavior or persistence contract.
- [ ] Update both files before scope, approach, or phase boundaries change.
- [ ] Confirm every phase commit passed its checks and used its exact message.
- [ ] Record final shadcn run time and component/example counts.
- [ ] Pass the strict shadcn gate before marking the plan complete.
- [ ] Check TODO items only after their work and required commits succeed.
