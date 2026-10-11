# TODO: complete shadcn and prepare a release

Follow [PLAN.md](PLAN.md). The coordinator owns this file.
Latest full-run source: `826910d`. All 64 groups pass, including Drawer and
Sidebar. The strict inventory check and preservation check pass. Storybook
passes all 80 tests after final evidence. Its current index and Docs pages
show 64 Verified groups and Direction as No DOM. Accepted evidence is committed
as `7e7b83a`. Final package installation and clean release-image badge proof
pass. CI passes on the accepted evidence commit. The pull request is ready
for review. See [the release record](RELEASE.md).

Base 42, shadcn 162, Base hooks 96, browser helpers 107, and parity helpers 32
pass. All 61 contracts and 463 snapshots are current. Configured checks and
the asset build pass.

## Checkpoint

- [x] Commit current documentation as `20963b7`.
- [x] Commit pending Message Scroller work as `bccc53e`.
- [x] Push the checkpoint to `origin/main`.
- [x] Record baseline failures separately from completed code.

## Task board

| Assignment | Reviewed integration commits | Focused result | Final proof |
|---|---|---|---|
| Menus and modal accessibility | `11efb19`, `9ed0017` | 125 comparisons; 43 Context/Drawer cases pass | Passed the final full run at `826910d` |
| Message opening and transient capture | `56c2f72`, `95c3628`, `3541f72` | Direct opening/reset checks and repeated busy/notice captures pass | Passed the final full run at `826910d` |
| Chart readiness and hover | `5ccae15`, `b7f58f1` | All 8 examples pass | Passed the final full run at `826910d` |
| Input composition and Copy capture | `2c9c71d`, `b6c7530`, `b918809`, `b5d9da7` | Input Group and Popover checks pass after clipboard permission setup | Passed the final full run at `826910d` |
| Input OTP | `7e6eacd`, `2f77c1f` | All 10 examples; 12 direct browser cases pass | Passed the final full run at `826910d` |
| Select pointer and popup entry | `3af5353`, `605180f` | 33 full comparisons; 88 direct caller checks; 20 Animation checks pass | Passed the final full run at `826910d` |
| Command and Date Picker readiness | `88e5228`, `e044858` | All 6 Command and 8 Date Picker examples pass | Passed the final full run at `826910d` |
| Navigation Menu | `9f0e798` | 13 comparisons; native focus, dismissal, and accessibility checks pass | Passed the final full run at `826910d` |
| CI, packages, and setup | `d0ec6ac`, `3e07a86`, `a60dcf1`, `bb62605`, `bfc1d43`, `1e27f4c` | Clean asset build, locked inputs, and first consumer proof pass | Final `826910d` archives and clean consumer proof pass |

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

## Repairs from earlier full-run failures

Root phase 6e.83 records repair scope. All groups in this table pass the final
full run at `826910d`.

| Owner | Groups | Failed checks |
|---|---|---|
| Coordinator | Hover Card | Complete at zero pixels, `dea5c33` |
| Menus worker | Label, Pagination, Toggle Group, Progress | Select names `185b361`; Toggle Group `b3ba6a9`; Progress/Slider `913f211`, `0622a6b`; all focused checks and independent review pass |
| Message worker | Scroll Area, Marker, Toast, Sidebar | Repairs integrated as `b3d91d7`, `8053f16`, and `2a8bcbf`; Sidebar entry repair `3f6aa19` also passes the final full run |
| Chart worker | Questionnaire, Item | Item and Avatar `8d0dbb2`; Questionnaire `6e88c3c`; all focused checks and independent review pass |

- [x] Review all 11 groups and repair the proved faults.
- [x] Recheck affected composed callers, including Avatar and Toggle.
- [x] Require zero for the two legacy nonzero budgets after exact proof.
- [x] Repeat full combined verification and final package proof.

## Entry repairs from the second full run

| Assignment | State | Required proof |
|---|---|---|
| Menus worker: nested Drawer entry, phase 6e.84 | Integrated `005dfe2` | Both hosts fail before and pass after; 3 repeated nested comparisons and 416 related browser checks pass |
| Message worker: initial action entry, phase 6e.85 | Integrated `3f6aa19` | Exact original images and click-retry cause proved; 6 direct regressions, 27 full Sidebar checks, 35 shared checks, and 13 action caller checks pass; independent review passes |
| Chart worker: setup documentation | Integrated `46b5428` | Setup commands, class contracts, and deployment instructions match current source |

- [x] Integrate `fix(verification): finish nested dialog entry before capture`.
- [x] Integrate `fix(verification): finish initial motion before action entry`.
- [x] Integrate `docs(setup): align preparation and deployment instructions`.
- [x] Check the combined changes and freeze source for the next full run.

The coordinator's combined run passes all 37 browser checks, including both
new regressions. All 107 Node helper tests pass. No checks are skipped or flaky.
All 61 offline and fetched-source contracts and all 463 snapshots pass again.
The combined source stayed fixed through the successful final run. Worker
comparison records remain supporting proof only; the coordinator published
the final acceptance evidence.

## Final acceptance

- [x] All scoped repairs have reviewed commits.
- [x] Base, shadcn, tools, private verification, and Storybook tests pass.
- [x] AI package checks pass where shared work affects them.
- [x] Browser helper and parity helper tests pass.
- [x] Configured Elixir checks pass; changed workflows pass local checks.
- [x] Offline and fetched shadcn contracts pass.
- [x] Shadcn snapshots pass.
- [x] All 64 comparison targets have complete current evidence.
- [x] Strict shadcn status passes; Direction remains No DOM.
- [x] AI evidence bytes, pins, examples, states, and limits are preserved.
- [x] Index and Docs badges agree with final evidence.
- [x] Temporary stale, failed, incomplete, and recovery checks pass on final source.
- [x] Clean release-image badges work without runtime repository files.
- [x] Rebuild and check final packages on final source.
- [x] Release workflow requires the strict evidence check.
- [x] Public setup and release instructions match tested behavior.
- [x] GitHub CI passes on the accepted evidence commit `7e7b83a`.
- [x] Root PLAN and TODO reflect completed acceptance.
- [x] Final reviewed commits are pushed and the pull request is ready.
- [x] No package publication or deployment was performed by this assignment.

## Historical package proof at `9f0e798`

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

## Final package proof at `826910d`

Both 0.1.0 archives pass clean signed Hex installation. All 141 payload files
match source, including all 61 shadcn ports. The repository-pinned browser
passes the full consumer flow, 15-second idle checks, a second Message append
at exact bottom, native callbacks, screenshot, and trace. Independent review
passes. All owned consumer servers and browsers are stopped.

[The release record](RELEASE.md) contains final hashes and the separate
agent-browser input and frame/capture limits. These replace the earlier package
results for acceptance; earlier diagnostic results remain available above.
