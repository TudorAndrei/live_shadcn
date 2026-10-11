# TODO: complete shadcn and prepare a release

Follow [PLAN.md](PLAN.md). The coordinator owns this file.
Full-run source: `9f0e798`. CI-only repair: `1e27f4c`.
The completed run passed 53 of 64 groups. Phase 6e.83 repairs the remaining
11 groups before the next acceptance run.

## Checkpoint

- [x] Commit current documentation as `20963b7`.
- [x] Commit pending Message Scroller work as `bccc53e`.
- [x] Push the checkpoint to `origin/main`.
- [x] Record baseline failures separately from completed code.

## Task board

| Assignment | Reviewed integration commits | Focused result | Final proof |
|---|---|---|---|
| Menus and modal accessibility | `11efb19`, `9ed0017` | 125 comparisons; 43 Context/Drawer cases pass | Passed the full run at `9f0e798` |
| Message opening and transient capture | `56c2f72`, `95c3628`, `3541f72` | Direct opening/reset checks and repeated busy/notice captures pass | Passed the full run at `9f0e798` |
| Chart readiness and hover | `5ccae15`, `b7f58f1` | All 8 examples pass | Passed the full run at `9f0e798` |
| Input composition and Copy capture | `2c9c71d`, `b6c7530`, `b918809`, `b5d9da7` | Input Group and Popover checks pass after clipboard permission setup | Passed the full run at `9f0e798` |
| Input OTP | `7e6eacd`, `2f77c1f` | All 10 examples; 12 direct browser cases pass | Passed the full run at `9f0e798` |
| Select pointer and popup entry | `3af5353`, `605180f` | 33 full comparisons; 88 direct caller checks; 20 Animation checks pass | Passed the full run at `9f0e798` |
| Command and Date Picker readiness | `88e5228`, `e044858` | All 6 Command and 8 Date Picker examples pass | Passed the full run at `9f0e798` |
| Navigation Menu | `9f0e798` | 13 comparisons; native focus, dismissal, and accessibility checks pass | Passed the full run at `9f0e798` |
| CI, packages, and setup | `d0ec6ac`, `3e07a86`, `a60dcf1`, `bb62605`, `bfc1d43`, `1e27f4c` | Clean asset build, locked inputs, and first consumer proof pass | Consumer passed at `9f0e798`; new final archives are required |

## Closed integration findings

- Copy capture needed browser clipboard permission. Real clipboard completion
  is now checked before and after capture.
- Message Animation exposed a Select pointer defect and a popup entry race.
  Both repairs passed native reference checks and repeated full comparisons.
- Navigation Menu needed correct focus, dismissal, and accessibility ownership.
  Both default and RTL examples now pass all comparison layers.
- Command and Date Picker checks observed content before it was ready.
  Their owners now wait for hydration or finite entry transitions.
- The clean asset build needed Storybook's `motion` alias.
- The shadcn archive included ignored Dialyzer caches. It now packages only
  runtime registry files under `priv/registry`.
- Clean CI needed pinned upstream inputs before tools and browser helper tests.
  All 398 restored files match the unchanged manifest.
- AI Inline Citation fails the same Next scroll check at pre-menu source
  `637975c`. The menu changes did not introduce this failure. AI completion
  remains outside this assignment.

## Remaining full-run failures

Follow root phase 6e.83 for repair scope and required proof.

| Owner | Groups | Failed checks |
|---|---|---|
| Coordinator | Hover Card | Nonzero legacy pixel budget |
| Menus worker | Label, Pagination, Toggle Group, Progress | Behavior, control discovery, accessibility, layout, and legacy Toggle Group budget |
| Message worker | Scroll Area, Marker, Toast, Sidebar | Scroll behavior, notice behavior, accessibility, and pixels |
| Chart worker | Questionnaire, Item | Validation behavior, caller classes, semantic rendering, and pixels |

- [ ] Repair and review all 11 groups.
- [ ] Recheck affected composed callers, including Avatar and Toggle.
- [ ] Require zero for the two legacy nonzero budgets after exact proof.
- [ ] Repeat full combined verification and final package proof.

## Final acceptance

- [x] All scoped repairs have reviewed commits.
- [x] Base, shadcn, tools, private verification, and Storybook tests pass.
- [x] AI package checks pass where shared work affects them.
- [x] Browser helper and parity helper tests pass.
- [x] Configured Elixir checks pass; changed workflows pass local checks.
- [x] Offline and fetched shadcn contracts pass.
- [x] Shadcn snapshots pass.
- [ ] All 64 comparison targets have complete current evidence.
- [ ] Strict shadcn status passes; Direction remains No DOM.
- [ ] AI evidence bytes, pins, examples, states, and limits are preserved.
- [ ] Index and Docs badges agree with final evidence.
- [ ] Temporary stale, failed, incomplete, and recovery checks pass on final source.
- [ ] Clean release-image badges work without runtime repository files.
- [ ] Rebuild and check final packages after phase 6e.83.
- [x] Release workflow requires the strict evidence check.
- [x] Public setup and release instructions match tested behavior.
- [ ] GitHub CI passes on the final commit.
- [ ] Root PLAN and TODO reflect completed acceptance.
- [ ] Final reviewed commits are pushed and the pull request is ready.
- [ ] No package publication or deployment was performed by this assignment.

## Package proof at `9f0e798`

The `0.1.0` archives were built from a clean copy of `9f0e798`.
Every package file matches that commit. The shadcn archive contains all 61 ports
and 13 other files. Neither archive contains build caches.

A new signed local Hex registry and an empty isolated Hex cache supplied both
packages to the consumer. Other dependency lock entries did not change. All
five copied ports are current. Asset build and compilation with warnings as
errors pass. Installed Base JavaScript and all 30 bundle inputs match the
archive. A fresh browser session passes Button, Dialog focus return, Select
value and close, Carousel navigation, and Message Scroller at its exact bottom.
The session remains connected and reports no JavaScript errors.

| Archive | SHA-256 |
|---|---|
| `live_base-0.1.0.tar` | `cf32e79eaa31261f7fa4d1152440b8647b321e224b36c4cd4d975140e876b177` |
| `live_shadcn-0.1.0.tar` | `4802034b9005b47d0b39677f6f3cac9f415c2b077766159b221b165a48055648` |

The first consumer browser session stopped animation progress and lost its
connection. The fresh session passed with the same bundle. Trace export failed;
DOM receipts, console results, and a screenshot support the passing checks.
No valid trace is claimed. The consumer server and browser are stopped.
