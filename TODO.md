# TODO: shadcn parity and verification badges

Follow [PLAN.md](PLAN.md). Phase 6e complete. Complete each phase,
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

## Phase 6a: restore pinned shadcn source facts

- [x] Restore `calendar`, `carousel`, and `sidebar` facts to the pinned shadcn ref.
- [x] Restore snapshots and tests that changed only because of the wrong facts.
- [x] Connect grouped dropdown-menu labels to their menu groups.
- [x] Record current port-body hashes for reviewed port changes.
- [x] Run the offline shadcn contract check.
- [x] Run focused package, snapshot, and browser checks for the three components.
- [x] Commit: `fix(registry): restore pinned shadcn source facts`

## Phase 6b: serve shared example assets to the reference

- [x] Serve tracked Storybook static files from the parity Vite server.
- [x] Include static example assets in shadcn evidence identity.
- [x] Test that an asset-byte change invalidates evidence.
- [x] Run focused sidebar accessibility, semantic, and pixel checks.
- [x] Record exposed component defects without mixing them into the asset change.
- [x] Commit: `fix(parity): serve shared example assets`

## Phase 6c: align the sidebar with pinned browser contracts

- [x] Preserve the pinned collapsible and menu-item DOM structure.
- [x] Normalize equal axe targets by stable DOM structure.
- [x] Normalize the current sidebar team IDs and repair the behavior selector.
- [x] Match menu-label ownership, closed-popup semantics, classes, and toggle
  attributes.
- [x] Add regression tests before each repair.
- [x] Refresh affected port-body hashes and the sidebar snapshot.
- [x] Run focused package, snapshot, behavior, accessibility, semantic, and
  pixel checks.
- [x] Commit: `fix(sidebar): align pinned browser contracts`

## Phase 6d: pin the Base UI documentation source

- [x] Add a regression test for a versioned Base UI deployment source.
- [x] Pin Base UI documentation to its immutable 1.7.0 release deployment.
- [x] Translate component and utility links to deployment paths.
- [x] Fetch the existing shadcn and AI refs without advancing them.
- [x] Keep all reviewed page digests and source facts current.
- [x] Pass the full offline check and focused Base UI fetched-source checks.
- [x] Record separate shadcn structure differences for repair.
- [x] Commit: `fix(fetch): pin Base UI documentation source`

## Phase 6e: align pinned shadcn structure facts

- [x] Add focused regression tests for the five structure differences.
- [x] Review menubar, navigation-menu, popover, slider, and toast against their
  pinned source files.
- [x] Update only the stale facts, ports, snapshots, and tests that the review
  requires.
- [x] Review and refresh the five contracts' immutable Base UI 1.7.0 page identities.
- [x] Pass focused component checks.
- [x] Pass full offline and fetched-source shadcn contract checks.
- [x] Commit: `fix(registry): align pinned shadcn structure facts`

## Phase 6e.1: preserve out-of-scope verification records

- [x] Add a failing regression test for out-of-scope record preservation.
- [x] Limit obsolete-target pruning to shadcn and restore all 48 AI records.
- [x] Prove a real scoped no-browser write preserves AI record bytes.
- [x] Run focused and full tools tests.
- [x] Align the combobox ownership test and pass Base package and hook tests.
- [x] Commit: `fix(verification): preserve out-of-scope evidence records`

## Phase 6f: refresh evidence and verify release badges

- [ ] Prepare pinned sources without advancing the shadcn or AI ref.
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
