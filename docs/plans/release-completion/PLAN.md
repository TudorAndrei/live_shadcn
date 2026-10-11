# Plan: complete shadcn and prepare a release

Base: `bccc53e`, pushed to `origin/main` on 2026-10-11.
Task status: [TODO.md](TODO.md).
Technical repair details: [root plan](../../../PLAN.md).

Completed: all 64 comparison groups, current badges, clean package installation,
release-image proof, and CI on the accepted evidence commit pass.
See [the release record](RELEASE.md) for source identity, hashes, and limits.

## Goal

Finish current shadcn verification and prepare Base and shadcn for release.
Require current evidence for all 64 comparison targets and retain Direction
as No DOM. Prove installation in a clean Phoenix application and badges in a
clean release image. Publication, deployment, upstream updates, AI completion,
and Ouro integration are outside this assignment.

## Baseline

The offline contract check passes for all 61 ports. All 64 comparison targets
have stale evidence. Base JavaScript passes 91 tests. Browser helper tests pass
107 of 108. The remaining helper expects the CSS rule removed in the pending
Message Scroller checkpoint. That checkpoint does not complete phase 72.

The root plan records completed code and incomplete integrated proof together.
Do not repeat a repair just because its old checkbox is open. Avatar readiness,
Avatar failure handling, OTP selection paint, and submenu visibility already
have commits. Review current source before using any saved draft patch.

## Work rules

One coordinator owns integration, root PLAN and TODO, this board, and final
evidence publication. Each worker has a separate branch and worktree. Keep
dependency copies, build output, ports, reports, and temporary fixtures local
to that worktree. Use `ERL_FLAGS='+S 4:4'` to limit each BEAM process.

Each assignment must return scoped commits, changed files, exact commands,
results, evidence paths, and unresolved failures. Use conventional commits.
Preserve pinned sources, official examples, states, thresholds, and AI record
bytes. Never replace evidence digests by hand. Never weaken a comparison to
make it pass. Test observable behavior; add no tombstone tests.

Workers can prepare component contracts and snapshots in their own worktrees.
The coordinator reviews these changes before integration. Do not transfer
worker VERIFY records as final proof. Only the final verifier can publish
acceptance evidence for the integrated source. Keep one browser worker per run.

Review each change independently before integration. If a repair needs another
worker's shared file, report the dependency first. Integrate the prerequisite,
then continue from the new base. Do not resolve conflicts by dropping either
worker's behavior. A failed diagnostic is not a completed task.

## First assignments

### Menus and modal accessibility

Implement root phases 70 and 71 in that order. Own menu ports, their current
package and browser tests, and shared modal accessibility in `live_base`.
The shared files are `modal_accessibility.js`, `overlay.js`, and `floating.js`.
Use the phase 70 draft under `/private/tmp/shadcn-agent-menubar-diagnosis/phase70`
only after checking its base and current source. Require controlled caller
commands, exact ARIA restoration, nested portals, live regions, and cleanup.
Run direct menu and Drawer tests. Run complete comparisons for the changed
families, then report shared-caller checks that depend on other repairs.

Commits: `fix(menubar): preserve caller-controlled choices`, then
`fix(context-menu): preserve modal background accessibility`.

### Message Scroller and transient capture

Finish root phase 72, then phases 73 and 74. Keep the committed phase 77 clamp
repair. Own Scroller behavior, opening CSS, Message Scroller examples and
tests, and the transient pixel capture path. Fix the initial/reset contract
using pinned native behavior. Resolve the helper assertion against the actual
opening contract. Use existing browser owners for proof, not source-string
checks. Preserve exact anchors, wheel input, Home input, and stream behavior.

Review phase 73 and 74 drafts in `/private/tmp/shadcn-agent-message-paint` and
`/private/tmp/shadcn-agent-message-toast`. Prove busy and notice state at actual
capture time. Keep timers, thresholds, and state coverage unchanged. Require
all 11 examples in all four comparison layers before acceptance.

Commits: `fix(message-scroller): preserve final opening position`,
`test(browser): preserve busy inventory during pixel capture`, and
`test(browser): preserve history notices during pixel capture`.

### Chart readiness and hover

Implement root phases 19a and 20. Own Chart examples, Chart controllers,
Chart-specific readiness, and existing Chart tests. Shared state helpers may
change only for Chart readiness. Do not change Message capture or menu logic.
Require responsive plot readiness, correct hover date/value, pointer leave,
and hover after connected series changes. Preserve all official hover states
and exact semantic/pixel limits. Coordinate edits in the large examples file
by component region. Review changed snapshots and contract facts.

Commits: `fix(verification): wait for responsive chart state discovery`, then
`fix(chart): complete interactive demo hover behavior`.

## Later assignments

### Input composition

Finish phase 51 before phases 46 and 47. Own Popover and Input Group composition
and their existing tests. Start source work after the menu owner releases
Floating changes. Require keyboard entry, Escape focus return, disabled
controls, a named security button, and direct dropdown composition. Verify
complete Input Group and Popover examples.

Commits: use the exact phase 51, 46, and 47 messages from the root plan.

### Input OTP

Finish phases 49 and 50. Phase 48 selection paint is already implemented.
Own OTP behavior, port, and tests. Require password-manager space behavior,
native values and events, cleanup, caller classes, and separator semantics.
Verify all official OTP examples with current source.

Commits: `fix(input-otp): reserve password manager badge space`, then
`fix(input-otp): preserve separator caller class replacement`.

### Release and consumer installation

Add `mix ui.status --check --source shadcn --require-verified` to the release
workflow. Check workflow syntax and the existing status contract. Build local
package files and install them in a clean Phoenix application. Follow the
public setup instructions; correct required JavaScript, CSS, and hook setup.
Exercise Button, Dialog, Select, Carousel, and Message Scroller.

Decide the copied dependency contract from existing public promises and tests.
The current installer changes only the module declaration, so copied parents
still use package components. Prefer a compatible, documented dependency
policy. If automatic local dependency copying requires an API decision that
the repository does not settle, report the exact choice before changing it.

Correct stale architecture, coverage, and release instructions. Keep old
milestone history separate from current acceptance. Preserve package versions
until the final release version is decided. Do not publish or deploy.

Commits: `fix(release): require current shadcn verification`,
`docs(installation): document complete consumer setup`, and further scoped
fixes only when clean-host proof requires them.

The checkpoint CI also found missing test preparation and an unpinned fetch.
Add `mix ui.fetch --locked` to restore recorded URLs and validate their digests
without changing the manifest. Use it in CI and release test preparation.
Install Storybook dependencies before tools integration tests and browser npm
dependencies before the helper suite. Keep the sync workflow's update mode.
Prove restoration in an empty temporary checkout and retain all existing tests.

Commit: `fix(ci): restore pinned inputs before verification`.

The clean asset build also needs a `motion` alias in the Storybook bundler.
Prove the build with Base's local `node_modules` unavailable. A package archive
inspection found ignored Dialyzer caches under shadcn's broad `priv` entry.
Package `priv/registry` and prove all 61 ports remain in the built archive.

Commits: `fix(build): resolve motion from Storybook dependencies` and
`fix(release): package only runtime registry files`.

## Integration and acceptance

Repeat this factory cycle for later work. Use one coordinator and up to three
workers. Give each worker one bounded assignment, owned files, a separate
worktree, and an acceptance command. Put each assignment through these states:
queued, active, proof complete, review complete, and accepted. A commit moves
to accepted only after the coordinator reviews it and checks the combined
source. Assign a different worker to review shared controllers. Stop source
writes before the final run. Build packages from that exact source revision.
Keep failed checks on the board until current evidence closes them.

1. Review and integrate code commits. Keep focused results and unresolved
   shared-caller checks distinct. Run affected package and helper checks.
2. Finish all source, fixture, contract, snapshot, and verifier changes before
   final evidence. Stop writes during the full run.
3. In `tools`, run offline and fetched shadcn contract checks, then
   `mix ui.verify --source shadcn`. Fix any current failures with reviewed
   scoped commits. Recheck all evidence invalidated by those changes.
4. Run `mix ui.status`, then
   `mix ui.status --check --source shadcn --require-verified`.
5. Recompile Storybook after the last evidence write. Check index and Docs
   badges for Button, Dialog, the three documentation families, and Direction.
   Prove stale, failed, incomplete, and recovery states in a temporary copy.
6. Build a clean release image and check badges without repository files at
   runtime. Prove consumer installation with built package files.
7. Run the applicable CI checks, reconcile all completion records, and push
   the reviewed integrated work. Mark complete only after every gate passes.

Final commit: `docs(verification): record current shadcn parity and badge results`.

## Risks

Shared inputs invalidate all shadcn evidence. Separate worktrees prevent
concurrent edits from changing a worker's source, but do not make branch
evidence valid after integration. Shared browser load can affect timing; queue
expensive comparisons when contention appears. A full run can expose more
defects. Keep those failures visible and create bounded repair assignments.
