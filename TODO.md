# TODO: finish shadcn and prepare a release

Follow [PLAN.md](PLAN.md) and the [release plan](docs/plans/release-completion/PLAN.md).
The [task board](docs/plans/release-completion/TODO.md) records assignments and proof.
The [historical checklist](docs/plans/release-completion/HISTORICAL-TODO.md) keeps
old diagnostic results. Its unchecked items are not the current work queue.

## Implementation

- [x] Commit and push the starting checkpoint (`20963b7`, `bccc53e`).
- [x] Use separate worker branches and one coordinator for integration.
- [x] Share current evidence evaluation, reject incomplete reports, capture
  overflow, and apply source-scoped verification gates (original phases 1–5).
- [x] Complete the reviewed port and example repairs in phases 6a–6e.
- [x] Preserve controlled menus and modal accessibility.
- [x] Complete Chart readiness and interactive hover.
- [x] Complete Popover, Input Group, and Input OTP behavior.
- [x] Complete Message Scroller opening and transient capture checks.
- [x] Preserve Select pointer focus and wait for popup entry before clearing hover.
- [x] Wait for Command hydration and Date Picker entry before observation.
- [x] Complete Navigation Menu focus, dismissal, and accessibility ownership.
- [x] Restore pinned inputs in clean CI and release test preparation.
- [x] Fix clean asset resolution and restrict shadcn `priv` to registry files.
- [x] Document complete consumer setup and enforce strict release evidence.
- [x] Review the combined implementation independently.
- [x] Repair the proved component faults from phase 6e.83.
- [x] Complete phase 6e.84,
  `fix(verification): finish nested dialog entry before capture`.
- [x] Complete phase 6e.85,
  `fix(verification): finish initial motion before action entry`.

## Final acceptance

The full run at `c6ba115` passed 62 of 64 groups. The Drawer and Sidebar entry
repairs are integrated as `005dfe2` and `3f6aa19`. Repeat verification on the
combined source. Focused worker results do not replace final acceptance.

- [x] All six Elixir test suites pass; current shadcn suite passes 162 tests.
- [x] Configured Elixir checks pass.
- [x] Base JavaScript: 96 tests pass.
- [x] Browser helpers: 107 tests pass. Parity helpers: 32 tests pass.
- [x] All 61 offline and fetched-source shadcn contracts pass.
- [x] All 463 shadcn snapshots are current.
- [x] Clean CI input restoration passes with all 398 pinned file hashes.
- [ ] Complete `mix ui.verify --source shadcn` on the combined source.
- [ ] Verify all 64 comparison targets; retain Direction as No DOM.
- [ ] Refresh inventory and pass the strict shadcn status check.
- [ ] Prove unchanged AI record bytes, upstream pins, examples, and limits.
- [ ] Recompile Storybook after final evidence; check index and Docs badges.
- [ ] Confirm failed, stale, incomplete, and recovery badge tests on final source.
- [ ] Check current badges in a clean release image without repository files.
- [ ] Rebuild final archives and repeat clean consumer checks on final source.
- [ ] Pass GitHub CI, update the release record, and push final scoped commits.
- [ ] Mark the release pull request ready for review.

## Release boundary

Prepare the existing `0.1.0` packages. Publishing, tagging, merging to main,
deployment, upstream updates, and AI Elements completion are outside this task.
AI Inline Citation has a reproduced pre-existing scroll failure. Its historical
evidence remains unchanged. No isolated Docs build speedup is claimed because
the old phase 6e.75 before/after build measurement was not saved.
