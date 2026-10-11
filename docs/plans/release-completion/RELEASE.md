# Release preparation record

Date: 2026-10-11. Scope: finish shadcn and prepare the existing Base and shadcn
`0.1.0` packages. Publication, tagging, merging, and deployment are outside
this assignment.

The full shadcn run, current badges, preservation checks, clean package
installation, clean release-image proof, and CI on the accepted evidence commit
pass. [Pull request 1](https://github.com/TudorAndrei/live_shadcn/pull/1) is ready
for review.

## Accepted source and evidence

- Source: `826910d857b7181b1b9842332788a9c310c71373`.
- Evidence commit: `7e7b83a`.
- `registry/VERIFY.json` SHA-256:
  `41da947b08bb1924255434fa8cfedc9de5d05724a3fc237dfccd6f7932591cb5`.
- Full command: `mix ui.verify --source shadcn`, from `tools`.
- Run: about 18:59–21:10 Europe/Bucharest; exit 0; all 64 comparison groups pass.
- Coverage: 61 ports plus Data Table, Date Picker, and Typography. Direction
  remains No DOM and does not count as a comparison pass.

The coordinator kept source fixed during the full run. Both entry repairs
from the preceding 62-of-64 run pass. No worker verification record was used
as final acceptance evidence.

`mix ui.status`, the general status check, and
`mix ui.status --check --source shadcn --require-verified` pass. Inventory shows
61 verified ports; the three documentation groups add up to 64 verified groups.
All 61 offline and fetched-source contracts and all 463 shadcn snapshots pass.

After the final evidence write, Storybook compilation and all 80 tests pass.
The tests cover stale, failed, incomplete, recovered, and compiled badge states.
Actual compiled evaluations and eight HTTP pages pass: the index and Docs for
Button, Dialog, Data Table, Date Picker, Typography, Direction, and Message.
The index has 64 Verified badges and one No DOM badge. Message uses the public
`shadcn-message` route. The evidence hash is unchanged after these checks.

Base has 42 passing Elixir tests; shadcn has 162. Base JavaScript has 96 passing
tests, browser helpers 107, and parity helpers 32. All six CI Elixir jobs,
source checks, and static browser contracts pass.
[CI run 38162900744](https://github.com/TudorAndrei/live_shadcn/actions/runs/38162900744)
also accepts the refreshed evidence and inventory on `7e7b83a`. Deployment was
skipped. The final documentation commit changes no runtime or verification
inputs; the pull request shows its current CI result.

## Preservation

Compared with checkpoint `bccc53e`, all 48 AI evidence value blocks retain their
exact bytes. AI package source, upstream pins, policy, official examples,
parity divergence rules, and all 61 upstream contract facts are unchanged.
The only budget changes add an explicit zero for Chart demo and reduce Hover
Card sides from 11 to zero and Toggle Group font selection from 32 to zero.
No state or example was removed to obtain a pass.

## Package installation

A clean source export produced both archives. Every payload file matches the
accepted source: Base has 67 files; shadcn has 74, including all 61 ports.
Neither archive contains build caches.

| Package | Version | Archive SHA-256 |
|---|---|---|
| `live_base` | `0.1.0` | `e7d6dfa4de534b01804d45312f49b9115994e4ca1acfbea308f04316dc9c545f` |
| `live_shadcn` | `0.1.0` | `23cf5d74cf4c70027536a7d4162636b25f13689a1bd9c9b2310ff79491af2735` |

A new signed local Hex registry and an empty isolated cache supplied the
archives to a Phoenix consumer. Downloaded archives and all installed files
match. Other dependency lock entries are unchanged. Five copied ports are
current. Compilation with warnings as errors and asset builds pass. All 30
Base JavaScript bundle inputs match the archive. The served bundle SHA-256 is
`20d55e21858ca159bc5a7135cfb3bf0ba41288347ce45ec27f51f112edce6f43`.

Repository-pinned Playwright 1.62.1 and Chromium 151.0.7922.34 pass Button,
Dialog Escape and focus return, Select, Carousel, and Message Scroller checks.
After 15 seconds idle, native frame, timer, and message callbacks pass. A
second Message append reaches 14 rows at exact bottom position 1010. Exactly
one Escape keydown and keyup occur. There are no JavaScript errors. Screenshot
and trace were saved and independently reviewed. All owned consumer servers
and browsers are stopped.

## Release image

The clean Linux ARM64 image is
`sha256:7ee5adda35357ae9b4506b80d16276f6981fff7b0613e0ff28c5e99f2bbe0e97`.
Its source and evidence labels match the accepted inputs. Only
`registry/VERIFY.json` differs from the 1461-file source archive. The image has
no repository mounts or runtime source directories.

Runtime proof passes: 64 compiled Verified groups, Direction as No DOM,
exactly 65 unique shadcn index badges, and all seven Docs pages listed above.
The private proof script requires one explicit JSON result marker because an
OTP 29 warning precedes RPC output. Raw output and script hashes are retained.
This parser correction changed no production source or image bytes.

The test container stopped with exit code 0, and its port is closed. The image
and proof files are retained. Nothing was published or deployed.

## Limits

The installed agent-browser 0.39.0 tool produces a trusted input stream after
one Escape on an empty page without package code. Correct event encoding
removes that input fault. Its Chrome 151.0.7922.47 consumer also has a separate
frame/capture failure whose cause remains unresolved. The passing pinned
browser proof uses the same installed packages and bundle. Its different
browser version and launch settings do not explain every earlier failure.
T3 browser snapshots also timed out. These limits are retained; no global tool
or package source change was made for the final consumer proof.

AI completion remains outside scope. AI Inline Citation has a reproduced
pre-existing scroll failure, and the historical full snapshot check found
17 AI example gaps. Their evidence remains unchanged. The old phase 6e.75
isolated Docs build measurement was not saved, so no isolated build speedup
is claimed.

## Factory process

One coordinator integrated reviewed commits from three workers with separate
worktrees and assigned files. Each assignment required a scoped commit,
commands, results, saved proof, and independent review. Failed full-run checks
returned to their owners. The coordinator kept source fixed for final
verification and published the accepted evidence. The same process is ready
for later work; see [the plan](PLAN.md) and [task board](TODO.md).

## Local proof files

The following files are local artifacts, not published downloads:

- `/private/tmp/factory-full-run-826910d-VERIFY.json`: immutable accepted copy.
- `/private/tmp/factory-final-after-badges-preservation.json`.
- `/private/tmp/factory-final-current-badges.json`.
- `/private/tmp/factory-release-826910d-proof/receipt.json` and
  `/private/tmp/factory-release-826910d-release-record.json`.
- `/private/tmp/factory-menus-826910d-handoff.json` and
  `/private/tmp/factory-chart-826910d-consumer-review.md`.
- `/private/tmp/factory-menus-826910d-consumer.png` and
  `/private/tmp/factory-menus-826910d-playwright-trace.zip`.
- `/private/tmp/live-shadcn-final-packages-826910d/packages/live_base/live_base-0.1.0.tar`.
- `/private/tmp/live-shadcn-final-packages-826910d/packages/live_shadcn/live_shadcn-0.1.0.tar`.
