# TODO: complete shadcn and prepare a release

Follow [PLAN.md](PLAN.md). The coordinator owns this file.

## Checkpoint

- [x] Commit current documentation as `20963b7`.
- [x] Commit pending Message Scroller work as `bccc53e`.
- [x] Push the checkpoint to `origin/main`.
- [x] Record baseline failures separately from completed code.

## Task board

| Task | Code | Focused checks | Review | Integration | Final evidence |
|---|---|---|---|---|---|
| Menus and modal accessibility | Committed | 125 comparisons; 43 Context/Drawer cases pass | Passed | `11efb19`, `9ed0017` | Pending |
| Message Scroller and transient capture | Running | Initial/reset distinction under repair; busy capture passes | In progress | Pending | Pending |
| Chart readiness and hover | Committed | All 8 examples pass; narrow hover passes | Passed | `5ccae15`, `b7f58f1` | Pending |
| Input composition | Phases 51 and 46 committed; 47 running | Focus and name pass; Copy pixel mismatch open | In progress | In progress | Pending |
| Input OTP | Running on `codex/factory-chart` | Pending | Pending | Pending | Pending |
| Release and consumer installation | Install docs and CI repairs committed | Clean consumer passes; tools 167 pass; 398 pinned inputs restored | In progress | In progress | Pending |

## Integration findings

- Input Group Copy has a short-lived pixel mismatch. The transient capture owner
  will inspect the existing per-host path. Keep timers, states, and limits.
- The checkpoint CI fetched current upstream source and omitted test inputs.
  The locked-source restore and dependency setup now pass local checks.
- Release notes now describe the current 61 ports and complete Base hook setup.
- Repeat the package proof with final integrated sources before acceptance.

## Final acceptance

- [ ] All scoped repairs have reviewed commits.
- [ ] Base, shadcn, tools, private verification, and Storybook tests pass.
- [ ] AI package checks pass where shared work affects them.
- [ ] Browser helper and parity helper tests pass.
- [ ] Configured format, static, and workflow checks pass.
- [ ] Offline and fetched shadcn contracts pass.
- [ ] Shadcn snapshots pass.
- [ ] All 64 comparison targets have complete current evidence.
- [ ] Strict shadcn status passes; Direction remains No DOM.
- [ ] AI evidence bytes, pins, examples, states, and limits are preserved.
- [ ] Index and Docs badges agree with final evidence.
- [ ] Temporary stale, failed, incomplete, and recovery checks pass.
- [ ] Clean release-image badges work without runtime repository files.
- [ ] Built packages work in a clean consumer application.
- [ ] Release workflow requires the strict evidence check.
- [ ] Public setup and release instructions match tested behavior.
- [ ] Root PLAN and TODO reflect completed code and completed acceptance.
- [ ] Final reviewed commits are pushed.
- [ ] No package publication or deployment was performed by this assignment.
