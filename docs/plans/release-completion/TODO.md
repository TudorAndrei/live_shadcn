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
| Message Scroller and transient capture | Three commits ready | 13 direct cases; 48 of 49 comparisons pass | Passed | Pending | Pending |
| Chart readiness and hover | Committed | All 8 examples pass; narrow hover passes | Passed | `5ccae15`, `b7f58f1` | Pending |
| Input composition | Phases 51 and 46 integrated; 47 ready | 80 of 81 Input Group/Popover comparisons pass | Passed | In progress | Pending |
| Input OTP | Two commits ready | All 10 examples; 12 direct browser tests pass | Passed | Pending | Pending |
| Release and consumer installation | Install docs and CI repairs integrated; build repairs active | Clean consumer and local Hex resolution pass; tools 167 pass | In progress | In progress | Pending |

## Integration findings

- Input Group Copy fails because Chromium denies clipboard write permission.
  The transient capture owner will check the permission setup used by the
  existing direct test. Preserve timers, states, and limits.
- Message Scroller Animation has an intermittent Select highlight difference.
  The menu owner will inspect the actual pointer and keyboard state.
- AI Inline Citation fails its Next scroll check on pre-menu source `637975c`
  and on the repair branch. The menu changes did not introduce this failure.
- The Storybook asset build cannot resolve `motion` without Base's local
  `node_modules`. Add the missing asset alias and prove the clean build.
- The local shadcn package includes ignored Dialyzer caches under `priv`.
  Restrict package contents to runtime registry files and inspect a new archive.
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
