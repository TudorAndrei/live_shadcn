# TODO: shadcn parity and verification badges

Active task status: [release completion](docs/plans/release-completion/TODO.md).
Use that board for parallel assignments and separate code from acceptance.
The checklist below includes historical state that needs reconciliation.

Follow [PLAN.md](PLAN.md). Phases 6e.6 through 6e.13 are complete.
Phase 6f is in progress. Complete each phase, run its checks, and make its exact
commit before starting the next phase.

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

## Phase 6e.2: enforce badge gating and input-set reload

- [x] Add failing tests for ungated/contradictory records and input-set reload.
- [x] Repair check precedence and Mix input-path-set tracking.
- [x] Repeat both-route temporary-copy state, file-set, and recovery checks.
- [x] Pass private-project, tools, and Storybook tests and static checks.
- [x] Commit: `fix(verification): enforce badge gating and input-set reload`

## Phase 6e.3: complete browser report provenance

- [x] Regression-test source-safe incremental publication and locked validation.
- [x] Record and validate actual expected/completed browser state coverage.
- [x] Capture direct scoped identity through Mix and derive report completion.
- [x] Reject incomplete, skipped, interrupted, filtered, and wrong-owner imports.
- [x] Pass private/tools/browser-helper tests.
- [x] Verify a complete direct batch/import and managed component,
  preserving AI bytes.
- [x] Commit: `fix(verification): complete browser report provenance`

## Phase 6e.4: prepare reproducible release badge inputs

- [x] Add a packaging regression test and install locked Base npm dependencies.
- [x] Regression-test digest-named asset copies and nested asset directories.
- [x] Exclude only proven generated copies and verify builder/checkout identity.
- [x] Build a clean image and check compiled badges without repository files.
- [x] Commit: `fix(release): prepare reproducible badge inputs`

## Phase 6e.4a: restore inventory and static checks

- [x] Add a failing inventory command test for excluded AI components.
- [x] Render excluded status and preserve stored AI evidence.
- [x] Reduce report validator nesting without changing validation behavior.
- [x] Pass the status regression, private verification tests, and tools tests.
- [x] Pass configured static checks for both changed projects.
- [x] Confirm strict shadcn status reports verification gaps without a crash.
- [x] Commit: `fix(verification): restore inventory and static checks`

## Phase 6e.5: bind shared build manifests to evidence

- [x] Add mutation tests for Mix/configuration/Base npm inputs and shared CSS sources.
- [x] Include those inputs in evidence and compilation path tracking.
- [x] Check fetched shared CSS sources against committed digests.
- [x] Pass prepared/clean identity and private/tools/Storybook tests.
- [x] Pass offline and fetched shadcn contract checks.
- [x] Commit: `fix(verification): bind shared build manifests to evidence`

## Phase 6e.6: align complete button comparison states

- [x] Test submenu Escape behavior and focus return before repairing Base roving.
- [x] Test finite transitions before repairing default-state readiness.
- [x] Diagnose and regression-test group-demo/render state discovery timeouts.
- [x] Diagnose and regression-test destructive/RTL accessibility mismatches.
- [x] Repair proven causes without removing examples/states or relaxing thresholds.
- [x] Test and repair rapid submenu closure focus.
- [x] Pass shared menu and state-helper browser suites with current fixture readiness.
- [x] Test and repair nested radio replay without moving outside an open submenu.
- [x] Test and repair group display and submenu width class precedence.
- [x] Review updated port hashes and affected snapshots.
- [x] Pass complete button behavior, accessibility, semantic, and pixel checks.
- [x] Commit: `fix(button): align complete official comparison states`

## Phase 6e.7: complete badge status semantics

- [x] Regression-test real incomplete/no-browser record shapes and preparation failures.
- [x] Repair precedence and record explicit preparation failure evidence.
- [x] Add direction to documentation navigation and routing with No DOM badges.
- [x] Check both badge locations, stale precedence, recovery, and AI isolation.
- [x] Pass private/tools/Storybook tests and static checks.
- [x] Commit: `fix(verification): complete badge status semantics`

## Phase 6e.8: isolate Dialog documentation inputs

- [x] Prove the connected route failure and test label associations.
- [x] Give RTL Dialog inputs and labels distinct IDs.
- [x] Refresh only the RTL Dialog snapshot.
- [x] Pass focused route, preview, formatting, and shadcn snapshot checks.
- [x] Commit: `fix(storybook): isolate dialog example inputs`

## Phase 6e.9: preserve initially open disclosure states

- [x] Prove replay failure on both real Accordion renderers.
- [x] Preserve expanded path triggers and nested action paths.
- [x] Pass the shared state suite and verify all Accordion states.
- [x] Commit: `fix(verification): preserve initially open disclosure states`

## Phase 6e.10: stop tracking the generated reference link

- [x] Remove the generated reference link from the index and fix ignore patterns.
- [x] Check source preparation, generated file ignores, and unchanged pinned refs.
- [x] Commit: `chore(parity): untrack generated upstream link`

## Phase 6e.11: honor Accordion caller width and disabled state

- [x] Prove caller width merge failures in the existing Accordion class test.
- [x] Apply the shared class merger to the Accordion root.
- [x] Prove and repair inherited root disablement for parts and client commands.
- [x] Review its port hash and refresh affected root classes.
- [x] Pass package tests and complete Accordion verification.
- [x] Commit: `fix(accordion): honor caller width and disabled state`

## Phase 6e.12: document native and composed examples

- [x] Prove the route lacks a usable native direction example.
- [x] Show native HTML usage and the real Direction policy source.
- [x] Show valid source manifests and adaptation guidance for documentation families.
- [x] Pass the route test, Storybook tests, and static checks.
- [x] Commit: `fix(storybook): document native and composed examples`

## Phase 6e.13: restore Alert Dialog Escape dismissal

- [x] Prove the corrected keyboard and backdrop test fails on the port.
- [x] Keep backdrop dismissal disabled and restore Escape dismissal.
- [x] Review the port hash and refresh affected snapshots.
- [x] Pass package static checks and complete Alert Dialog verification.
- [x] Commit: `fix(alert-dialog): restore Escape dismissal`

## Phase 6e.14: settle Avatar images before behavior comparison

- [ ] Prove the Avatar trigger race with a delayed image regression.
- [ ] Use controlled images and wait for the final image state before probes.
- [ ] Keep trigger-name comparison and the Avatar menu contract.
- [ ] Pass browser helper tests and complete Avatar verification.
- [ ] Commit: `fix(verification): settle avatar image behavior probes`

## Phase 6e.14a: settle disclosure render transitions

- [x] Prove expanded-state entry can return during a real Popover transition.
- [x] Wait for finite transitions after the generic disclosure path.
- [x] Pass the shared state suite and affected Bubble accessibility example.
- [x] Commit: `fix(verification): settle disclosure render transitions`

## Phase 6e.14b: align Sonner notice layout and fonts

- [x] Inspect a persistent complete-example report and both notice images.
- [x] Match the confirmed reference font family and title weight.
- [x] Review the port hash and affected snapshots.
- [x] Pass package checks, Sonner verification, and the Bubble action pixel check.
- [x] Match verified notice offsets, radius, and blank description layout.
- [x] Commit: `fix(sonner): align reference notice layout and fonts`

## Phase 6e.15: align Bubble official example behavior and states

- [x] Review each Bubble failure against pinned examples and captured traces.
- [x] Correct notice selectors and preserve content and success assertions.
- [x] Align caller-owned text classes, trigger naming, and collapsed composition.
- [x] Diagnose and repair the Popover contrast and notice pixel differences.
- [x] Review affected snapshots and any changed port hash.
- [x] Pass complete Bubble verification and focused regression checks.
- [x] Commit: `fix(bubble): align official example behavior and states`

## Phase 6e.16: merge Separator caller widths in Button Groups

- [x] Prove conflicting Button Group widths and direct caller overrides.
- [x] Merge Separator classes and compose it in Button Group separator.
- [x] Preserve orientation, roles, caller attributes, and content.
- [x] Review both port hashes and affected snapshots.
- [x] Pass package checks and complete Button Group and Separator verification.
- [x] Commit: `fix(separator): merge caller widths in button groups`

## Phase 6e.17: preserve DayPicker day button classes

- [x] Prove the missing day button class at the existing Calendar test boundary.
- [x] Correct the derived binding and synchronize contract and port facts.
- [x] Preserve day cells, selection, modifiers, and focus behavior.
- [x] Check the shared day class in all eight Date Picker examples.
- [x] Review fact changes and affected snapshots.
- [x] Pass package checks, both contract checks, and complete Calendar verification.
- [x] Commit: `fix(calendar): preserve DayPicker day button classes`

## Phase 6e.18: align Card spacing button values

- [x] Set empty native values through the existing example slot option.
- [x] Preserve controlled selection keys and click commands.
- [x] Verify native values and connected spacing changes on both pages.
- [x] Review the affected snapshot and pass complete Card verification.
- [x] Commit: `fix(card): align spacing example button values`

## Phase 6e.19: wait for Carousel movement before measurement

- [x] Review captured motion and choose a browser readiness condition.
- [x] Wait for requestAnimationFrame movement without a test-only component API.
- [x] Poll for the expected final distance in the named spacing test.
- [x] Check the distinct visual-state readiness contract on real pages.
- [x] Preserve autoplay, partial width, vertical, spacing, RTL, and thresholds.
- [x] Pass helper checks and complete Carousel verification.
- [x] Commit: `fix(verification): wait for carousel movement before capture`

## Phase 6e.19b: preserve Carousel status text boundaries

- [x] Prove the caption digit difference with the exact API pixel check.
- [x] Compare actual text nodes, positions, and paint timing.
- [x] Preserve numeric text boundaries if the real-page draft proves the cause.
- [x] Preserve status meaning, API updates, and autoplay behavior.
- [x] Pass the API pixel and behavior checks and complete Carousel verification.
- [x] Commit: `fix(carousel): preserve status text boundaries`

## Phase 6e.19a: stabilize responsive Chart state discovery

- [ ] Diagnose the intermittent missing React legend hover state.
- [ ] Wait for rendered plot parts if initial rendering causes the gap.
- [ ] Prove the readiness contract on a real delayed reference page.
- [ ] Preserve tooltip anatomy examples and every real hover state.
- [ ] Pass shared state checks and the complete legend example on both pages.
- [ ] Commit: `fix(verification): wait for responsive chart state discovery`

## Phase 6e.20: complete the Chart demo hover state

- [ ] Add the demo tooltip and cursor through public Chart composition.
- [ ] Keep the current monthly tooltip and RTL behavior.
- [ ] Verify demo hover date, active value, pointer leave, and series changes.
- [ ] Compare all demo states and repair any confirmed layout differences.
- [ ] Keep exact semantic and pixel thresholds and all official states.
- [ ] After exact demo pixel proof, add its explicit zero budget.
- [ ] Review snapshots and any changed port hash.
- [ ] Pass Storybook and browser checks and complete Chart verification.
- [ ] Commit: `fix(chart): complete interactive demo hover behavior`

## Phase 6e.20a: align Checkbox table selection

- [x] Prove the current partial-selection header difference on both pages.
- [x] Use the pinned header state in the example-owned controller.
- [x] Keep public indeterminate support and the Data Table mixed state.
- [x] Test partial, full, one-row clearing, and all-row clearing states.
- [x] Pass the complete table example and focused browser checks.
- [x] Commit: `fix(checkbox): align table selection example`

## Phase 6e.21: keep Checkbox focus on the visible control

- [x] Confirm native label activation and hidden input focus.
- [x] Test both label forms and Space after a pointer click on real pages.
- [x] Redirect hidden input focus at the component or shared form boundary.
- [x] Preserve one state change, submitted values, disabled, and readonly behavior.
- [x] Review the port hash and affected snapshots.
- [x] Pass package and browser checks and complete Checkbox verification.
- [x] Commit: `fix(checkbox): preserve label state and focus`

## Phase 6e.22: size accessibility time limits for complete state coverage

- [x] Use the captured file-tree timeout as the before result.
- [x] Set bounded allowances from the discovered accessibility state count.
- [x] Cover both official comparison and local-only accessibility paths.
- [x] Keep action waits and the overall upper bound.
- [x] Pass complete file-tree accessibility and existing time-policy checks.
- [x] Commit: `fix(verification): size accessibility time limits by state count`

## Phase 6e.23a: observe only visible interaction controls

- [x] Prove the closed-state control count fault on real pages.
- [x] Use the existing visibility rule for observed controls.
- [x] Check open and closed values on both pages.
- [x] Pass helper and Collapsible browser checks.
- [x] Commit: `fix(verification): observe visible interaction controls`

## Phase 6e.23: preserve Collapsible settings label links

- [x] Keep correct port labels and unchanged pinned reference source.
- [x] Check the exact raw duplicate-ID and unmatched-label reference defect.
- [x] Add one named reference-name normalization for this example only.
- [x] Keep all other behavior fields and comparisons exact.
- [x] Prove correct port labels and reject wrong labels or changed reference patterns.
- [x] Cover closed and open settings panels on real pages.
- [x] Attach and document the normalization reason.
- [x] Pass helper and browser checks and complete Collapsible verification.
- [x] Commit: `fix(verification): preserve corrected settings label semantics`

## Phase 6e.24: hide outside Combobox add-ons while open

- [x] Prove the decorative outside add-on difference on both pages.
- [x] Distinguish outside add-ons from parts inside the popup.
- [x] Hide outside add-ons while open and restore them on close.
- [x] Verify inside popup add-ons stay exposed.
- [x] Review the old mocked test against stronger browser coverage.
- [x] Pass Base checks and complete Combobox verification.
- [x] Review any port ownership change, hash, and snapshots.
- [x] Commit: `fix(combobox): hide outside add-ons while the popup is open`

## Phase 6e.25: compare portalled accessibility targets by logical ownership

- [x] Prove both pages have the same actual Command listbox violation.
- [x] Normalize corresponding portal targets to logical preview ownership.
- [x] Preserve rule, slot, occurrence, and unrelated-target distinctions.
- [x] Prove an added violation on another target still fails.
- [x] Pass helper checks and grouped and scrollable accessibility examples.
- [x] Document the ownership rule without changing thresholds.
- [x] Commit: `fix(verification): compare logical accessibility portal targets`

## Phase 6e.26a: merge translation utility conflicts

- [x] Prove the remaining translation conflict through the existing browser comparison.
- [x] Prove variant and directional translation conflicts at the public Cn API.
- [x] Add axis groups and pinned directional composite conflicts.
- [x] Preserve independent axes and variant scopes.
- [x] Pass package and static checks and the basic Command comparison.
- [x] Review affected rendered classes.
- [x] Commit: `fix(cn): merge translation utility conflicts`

## Phase 6e.26: merge Dialog caller popup position classes

- [x] Prove the caller position conflict at the existing basic Command browser boundary.
- [x] Merge popup classes while keeping focus and dismissal behavior.
- [x] Review the port hash and affected snapshots.
- [x] Pass package checks and the focused Dialog position comparisons.
- [ ] Complete Dialog verification after its planned dependent repairs.
- [x] Check the complete basic Command example.
- [x] Commit: `fix(dialog): merge caller popup position classes`

## Phase 6e.26b: merge Dialog caller footer alignment classes

- [x] Use the complete Share semantic class mismatch as the before result.
- [x] Apply the shared class merger at the public Dialog footer boundary.
- [x] Pass package tests, static checks, and both Dialog contract checks.
- [x] Render all shadcn snapshots and review the single footer class change.
- [x] Pass complete Share interaction, accessibility, semantic, and pixel checks.
- [x] Commit: `fix(dialog): merge caller footer alignment classes`

## Phase 6e.27: align Command example tests and composition

- [x] Use exact group or item selectors for the intended Settings assertion.
- [x] Keep shortcuts, counts, boundaries, and keyboard focus assertions.
- [x] Align default caller input composition while keeping public label support.
- [x] Finish accessibility target and Dialog position prerequisites.
- [x] Review snapshots and any port change.
- [x] Pass Storybook and browser checks and complete Command verification.
- [x] Commit: `fix(command): align official example composition and tests`

## Phase 6e.28: align Calendar month navigation labels

- [x] Use the captured Date Picker focus name failures as the before result.
- [x] Select pinned previous and next month names through the existing locale.
- [x] Match the confirmed navigation landmark names for all declared locales.
- [x] Cover English, Arabic, and Persian at the public rendering boundary.
- [x] Keep the browser locale fallback and current navigation behavior.
- [x] Check Date Picker names after opening and after month changes.
- [x] Complete the day class repair and review snapshots and the port hash.
- [x] Pass package checks and complete Calendar and Date Picker verification.
- [x] Commit: `fix(calendar): align localized month navigation labels`

## Phase 6e.29: observe visible popup controls in interaction checks

- [x] Use the captured Dialog control mismatch as the before result.
- [x] Observe the preview and visible controlled popup without duplicate nodes.
- [x] Keep visible field names, values, states, and focus in the comparison.
- [x] Test open fields and fields after Escape on both pages.
- [x] Prove that a changed visible popup control still fails comparison.
- [x] Preserve the Avatar readiness repair when changing the shared helper.
- [x] Pass helper checks and complete Dialog interaction verification.
- [x] Commit: `fix(verification): observe visible controls in popup scope`

## Phase 6e.30: preserve read-only fields during state replay

- [x] Use the captured read-only Link fill timeout as the before result.
- [x] Exclude read-only fields from text mutation probes and replay locators.
- [x] Keep these fields in observations and accessibility scans.
- [x] Replay Share states on both pages and keep the Link value unchanged.
- [x] Confirm that a normal editable field remains in the state model.
- [x] Pass helper checks and complete close-button verification.
- [x] Commit: `fix(verification): preserve read-only controls during replay`

## Phase 6e.31: focus a Dialog that has no focusable child

- [x] Prove the no-close-button popup focus failure in the existing browser suite.
- [x] Add a shared popup focus fallback after reviewing related overlay owners.
- [x] Preserve child focus, explicit host focus, containment, and dismissal.
- [x] Test popup focus, Tab, Escape, and focus return.
- [x] Review snapshots and changed input identities.
- [x] Pass Base and package checks and complete empty Dialog example checks.
- [ ] Complete full Dialog verification after the remaining dependent repairs.
- [x] Commit: `fix(dialog): focus the popup when no child accepts focus`

## Phase 6e.32: keep sample Dialog Save actions on the current page

- [x] Use the confirmed native form ownership difference as the before result.
- [x] Prevent native navigation in the default and RTL sample form commands.
- [x] Preserve public form submission and component APIs.
- [x] Test URL, open state, edited values, Cancel, and Escape on both pages.
- [x] Review snapshots and pass Storybook and complete affected checks.
- [x] Commit: `fix(dialog): preserve sample state after Save actions` (`c7dd40b`)

## Phase 6e.33: finish popup focus entry before a nested action

- [x] Confirm the opening focus command ordering on the real Dialog pages.
- [x] Test Username replay focus before capture on both renderers.
- [x] Wait at the nested path boundary if opening focus causes the difference.
- [x] Preserve focus comparison, states, and exact pixel thresholds.
- [x] Pass shared state checks and review nested menu and combobox replay.
- [x] Pass complete default and RTL Dialog checks.
- [ ] Finish full Drawer/Dialog checks after the phase 6e.39 width repair.
- [x] Commit: `fix(verification): finish popup entry before nested actions` (`a17b728`)

## Phase 6e.34: keep a modal trigger target stable during replay

- [x] Prove the current default Drawer reference replay timeout.
- [x] Retain the disclosure target while the modal hides it.
- [x] Keep hidden controls out of new probe discovery.
- [x] Test open state, close state, and focus return on both pages.
- [x] Preserve other pending shared interaction helper repairs.
- [x] Pass all helper checks and six actual disclosure browser cases.
- [x] Pass complete Drawer interaction verification after phase 6e.35.
- [x] Commit: `fix(verification): retain disclosure targets during modal replay`
  (`c03e126`)

## Phase 6e.35: use the pinned Drawer opening focus

- [x] Use the captured and real browser focus differences as the before results.
- [x] Focus the Drawer popup through its opening command.
- [x] Preserve desktop Dialog first-child focus and all focus return behavior.
- [x] Test modal, non-modal, nested, and responsive cases.
- [x] Review snapshots and the port hash.
- [x] Pass affected package checks, all 45 browser cases, and non-modal full checks.
- [x] Pass all 57 current Drawer browser checks for the seven official examples.
- [ ] Complete the nested mobile caller repair and final fresh Drawer verification.
- [x] Commit: `fix(drawer): focus the popup when it opens` (`97ca5bd`)

## Phase 6e.36: align delivery Drawer title classes

- [x] Merge public FieldTitle classes through the existing class merger.
- [x] Give every delivery row the pinned caller class.
- [x] Add the public class override owner and retain delivery selection checks.
- [x] Review snapshots and the changed port hash.
- [x] Pass package and Storybook checks and prove all title class differences resolved.
- [ ] Finish full Field checks after the radio focus and validation image repairs.
- [x] Finish full default Drawer checks after modal accessibility and
  confirmation repairs.
- [x] Commit: `fix(field): merge title classes in delivery drawer rows` (`8a6b74f`)

## Phase 6e.37: preserve modal Drawer background accessibility

- [x] Review the pinned outside-node marking and shared Overlay lifecycle.
- [x] Hide only the modal background and restore previous attributes.
- [x] Preserve live regions, non-modal access, portal parts, and nested popups.
- [x] Test background access, restoration, nesting, and authored hidden state.
- [x] Pass affected Base and browser checks and complete affected verification.
- [x] Commit: `fix(overlay): preserve modal access and focus` (`8262f70`)

## Phase 6e.38: replay actions in a compact Drawer

- [x] Confirm compact popup geometry after entry completes.
- [x] Apply entry readiness before diagnosing remaining pointer failures.
- [x] Replay Close through a real supported user action.
- [x] Keep all valid states and retain named pointer, drag, and snap checks.
- [x] Test dismissal, focus return, and resulting modality on both pages.
- [x] Pass shared state checks and complete snap-points verification.
- [x] Commit:
  `fix(verification): replay compact drawer actions through user controls`
  (`36fec6c`)

## Phase 6e.39: align the responsive Drawer desktop Dialog class

- [x] Complete the Dialog class merge and popup entry prerequisites.
- [x] Add the pinned desktop caller class through the existing input.
- [x] Preserve mobile composition, breakpoint, fields, and responsive switching.
- [x] Review affected snapshots and pass Storybook and browser checks.
- [x] Pass complete responsive example verification.
- [x] Commit: `fix(drawer): align responsive desktop dialog composition` (`e8197da`)

## Phase 6e.40: preserve labelled control names in observations

- [x] Apply the tested referenced-label observation draft.
- [x] Pass real English and Arabic Select observations and helper tests.
- [x] Pass complete Field default and RTL generic verification.
- [x] Commit:
  `fix(verification): preserve labelled control names in observations`
  (`20369b0`)

## Phase 6e.41: keep radio label focus on the visible control

- [x] Apply the tested radio focus listener draft and lifecycle cleanup.
- [x] Pass real label clicks, selected-value checks, and radio/Field suites.
- [x] Pass package checks and complete affected example verification.
- [x] Commit: `fix(radio-group): keep focus on the visible control` (`f79a404`)

## Phase 6e.42: preserve the Input form Country name

- [x] Connect the example Select to its Country label with the public input.
- [x] Prove current failure and repaired names after option selection.
- [x] Pass Storybook, browser, and complete Input form verification.
- [x] Commit: `fix(input): preserve the country field name` (`bd2ae35`)

## Phase 6e.43: preserve nested choices and menu labels

- [x] Apply the command-attribute and logical popup dismissal draft.
- [x] Preserve deterministic JSON key order for the new snapshot command attribute.
- [x] Pass two real nested checkbox choices and outside dismissal.
- [x] Pass hook, package, and direct menu owner checks for this repair.
- [ ] Pass all remaining complete menu checks after the separate caller and mask
  repairs.
- [x] Pass complete complex example semantic and pixel comparison.
- [x] Prove missing real menu names before the label repair.
- [x] Preserve root and submenu names and caller label overrides.
- [x] Prove the complex example's linked email checkbox failure.
- [x] Preserve the complex example's linked email checkbox state.
- [x] Diagnose and repair the observed submenu position difference in phase 67.
- [x] Commit: `fix(dropdown-menu): preserve nested choices and menu labels` (`321ce90`)

## Phase 6e.44: preserve Hover Card entry during pointer clicks

- [x] Prove lost entry with six trusted-event checks and valid timing inputs.
- [x] Add the Hover Card gesture marker to all supported trigger parts.
- [x] Pass pointer click, popup travel, and Escape on both pages.
- [x] Pass shared hook unit and direct Tooltip behavior checks.
- [ ] Pass remaining complete shared caller checks.
- [x] Diagnose remaining RTL geometry before changing offsets.
- [x] Pass package checks and complete Hover Card verification.
- [x] Commit: `fix(hover-card): preserve pointer entry during clicks` (`9b0c985`)

## Phase 6e.45: settle native validation prompt paint

- [x] Add a bounded image stability wait for focused native validation states.
- [x] Preserve the prompt, current state, and all comparison thresholds.
- [x] Prove current capture failure and repaired zero-pixel browser capture.
- [x] Pass helper checks and complete Field and Input form pixel comparison.
- [x] Record capture cost and commit after the active run.
- [x] Commit: `fix(verification): settle native validation prompt paint` (`0ae3c40`)

## Phase 6e.46: name the Input Group security control

Temporary draft: the current unnamed button fails the name check. The repair
passes five browser tests and complete accessibility. Generic interaction still
requires the composed trigger focus repair in phase 6e.51.

- [ ] Use existing trigger_rest to name the actual icon button.
- [ ] Prove wrapper discovery, named button, popup behavior, and accessibility.
- [ ] Pass Storybook and complete Input Group button verification.
- [ ] Commit: `fix(input-group): name the security control`

## Phase 6e.47: align Input Group dropdown composition

Temporary draft: removing the margin class alone shifts the input by 4 px.
Direct trigger composition plus caller alignment passes complete semantic and
pixel checks (34.7 s) and five browser behavior tests (9.2 s).

- [ ] Use existing direct menu triggers and match caller add-on classes.
- [ ] Preserve menu options and input edits.
- [ ] Pass Storybook, menu behavior, and complete semantic and pixel comparison.
- [ ] Commit: `fix(input-group): align dropdown trigger composition`

## Phase 6e.48: align native input code selection paint

Temporary draft proof: current selection differs by 124 px; repaired capture
is exact. Six browser tests and four complete pixel examples pass. Canonical
source application and package checks remain pending.

- [ ] Install the scoped native selection rule once through the behavior initializer.
- [ ] Prove real selection pixel failure and repaired exact capture.
- [ ] Preserve native values, ranges, visible characters, and events.
- [ ] Pass hook, browser, and complete affected pixel checks.
- [ ] Commit: `fix(input-otp): align native selection paint`

## Phase 6e.49: reserve input code password manager space

- [ ] Implement reviewed icon detection, available room, and strategy choices.
- [ ] Preserve selection and native events and clean up listeners and timers.
- [ ] Prove icon, no-icon, insufficient-room, and none strategy behavior.
- [ ] Pass package, browser, semantic, and pixel checks.
- [ ] Commit: `fix(input-otp): reserve password manager badge space`

## Phase 6e.50: preserve input code separator caller replacement

- [ ] Match public caller class replacement and icon sizing.
- [ ] Preserve default recipe and separator role.
- [ ] Pass default/Form behavior and complete semantic and pixel comparison.
- [ ] Review snapshots and pass required package checks.
- [ ] Commit: `fix(input-otp): preserve separator caller class replacement`

## Phase 6e.51: preserve composed Popover trigger focus

Temporary proof: current focus return fails. Five Input Group browser tests
and complete interaction/accessibility pass with the prepared name and read-only
probe repairs. Complete semantic and pixel checks also pass. Canonical
template compilation and package checks are pending.

- [ ] Match wrapper tab stop and child button Enter/Space opening.
- [ ] Preserve popup focus and return to the declared trigger.
- [ ] Prove pointer and keyboard entry, Escape return, and disabled controls.
- [ ] Pass complete Input Group button and existing Popover verification.
- [ ] Commit: `fix(popover): preserve composed trigger focus`

## Phase 6e.52: select unique Message previews before behavior checks

- [x] Use the unique preview root for each existing Message readiness check.
- [x] Keep all named content, count, media, and button contracts.
- [x] Pass all six Message browser tests with the Avatar failure repair.
- [x] Commit: `fix(verification): select message previews before behavior checks`

## Phase 6e.53: keep failed avatar images responsive

- [ ] Make native image and fallback visibility updates idempotent.
- [ ] Preserve delayed failure, successful recovery, and later failure behavior.
- [ ] Merge the real browser regression with phase 6e.14 Avatar coverage.
- [ ] Pass hook, package, Avatar, Message, and affected pixel checks.
- [ ] Commit: `fix(avatar): avoid repeated visibility updates after image failure`

## Isolated repair integration

- [x] Integrate repair branch commits after the original full run ends.
- [x] Preserve the original snapshot and evidence changes during integration.
- [ ] Run required complete verification against the integrated source.

Committed in codex/shadcn-parity-repairs: c03708a (Avatar failure) and 8652bce
(Message readiness selectors), and f8f6e77 (native input code selection paint).
Further repair branch commits: 684d701 (Avatar image readiness), 51401a3
(popup animation readiness), 262e197 (submenu visibility), and 987da33
(Sonner notice layout and fonts). The shared browser suite passes all 15 tests.
The helper suite passes all 108 tests. Complete Sonner verification passes all
nine checks. The Bubble notice image check passes at zero pixels.

All seven original repair commits are now on main. The caller-event and
accessibility time-limit repairs are also on main. The merge preserves all
baseline records
except the new Sonner result. Main passes 108 browser helper tests, 93 Base
JavaScript tests, and the shadcn static checks. Complete affected component
verification remains required where a phase check box is still open.

## Phase 6e.54: observe open submenus without an expanded attribute

- [ ] Preserve explicit expanded state and use visibility for unnamed state
  on a controlled menuitem submenu.
- [ ] Keep close checks correct when the reference removes expanded state.
- [ ] Pass both existing nested menu browser checks and the full shared suite.
- [ ] Pass browser helper tests and complete affected component verification.
- [ ] Commit: `fix(verification): observe controlled submenu visibility`

## Phase 6e.55: run caller commands after a Collapsible toggle

- [x] Compose caller JS commands and event names with local toggle behavior.
- [x] Keep disabled triggers noninteractive and emit one click attribute.
- [x] Pass the existing long-answer regression and package checks.
- [x] Run complete Collapsible verification and record the remaining phase 22
  and 23 failures.
- [x] Review the port hash.
- [x] Commit: `fix(collapsible): run caller commands after toggling`

## Phase 6e.56: bound stored verification error detail

- [x] Keep a valid UTF-8 error summary below 2 KiB in new shadcn records.
- [x] Preserve outcomes, identities, short messages, and out-of-scope data.
- [x] Keep full CLI diagnostics and pass publication tests and tool checks.
- [x] Normalize baseline detail and prove all machine fields and AI bytes unchanged.
- [x] Commit: `fix(verification): bound stored error diagnostics`

## Phase 6e.57: wait for disclosure caller events before observation

- [x] Confirm the pending caller event after a local disclosure state change.
- [x] Wait for event completion before observing open and closed states.
- [x] Keep all observable comparisons and local-only behavior.
- [x] Pass the real delayed-event regression and the helper checks.
- [x] Commit: `fix(verification): wait for disclosure caller events`

## Phase 6e.58: support checkable controls without an explicit identity

- [x] Repair the confirmed Checkbox and Switch render failure when field, id,
  and name are absent.
- [x] Preserve each control pair, label, checked state, focus, submitted value,
  and caller event.
- [x] Prove multiple unnamed controls remain independent on a real page.
- [x] Review contracts and affected snapshots and pass package and browser checks.
- [x] Commit: `fix(checkables): support controls without explicit identities`

## Phase 6e.59: confirm the selected delivery time

- [x] Confirm the missing notice in the pinned caller and current image result.
- [x] Prove missing default and selected-time notices through the real browser owner.
- [x] Wire the selected label and confirmation notice through existing caller APIs.
- [x] Keep selection, dismissal, and focus return correct after server updates.
- [x] Pass default and later delivery confirmation cases on both pages.
- [x] Pass Storybook checks and review snapshots.
- [x] Pass complete default Drawer checks after the modal background repair.
- [x] Commit: `fix(drawer): confirm the selected delivery time` (`5da1514`)

## Phase 6e.60: preserve parent Drawer size after a nested close

- [x] Capture six differences in the current nested close comparison.
- [x] Find the cause through the real nested open and close sequence.
- [x] Extend the browser owner for the observed size contract.
- [x] Repair parent size and review the Close background difference.
- [x] Pass complete nested Drawer checks without changing thresholds or states.
- [x] Commit: `fix(drawer): preserve parent size after nested close` (`3357fc3`)

## Phase 6e.61: observe inherited hidden state

- [x] Confirm equal hidden states through the actual browser accessibility trees.
- [x] Prove inherited hidden state in the real collector browser owner.
- [x] Observe parent true without changing other attributes or limits.
- [x] Pass collector tests and complete affected default comparisons.
- [x] Commit: `fix(verification): observe inherited hidden state` (`22cbdbb`)

## Phase 6e.62: prevent delayed focus in a closing popup

- [x] Capture failed focus return after a fast outside click.
- [x] Confirm the repeated focus command in the installed LiveView source.
- [x] Prove the ordering through the existing real browser owner.
- [x] Keep closing popups from replacing the caller's current outside focus.
- [x] Preserve explicit focus while open and the hook lifecycle.
- [x] Pass affected modal and package checks and complete comparisons.
- [x] Commit with the shared owner:
  `fix(overlay): preserve modal access and focus` (`8262f70`)

## Phase 6e.63: match nested Drawer mobile direction and handle

- [x] Compare actual mobile direction, axis, and handle state on both pages.
- [x] Confirm the fixed port input and reference mobile query inputs.
- [x] Supply matching direction and handle state at all four nested levels.
- [x] Preserve open state, nesting, and focus across breakpoint changes.
- [x] Prove current failure and repaired mobile direction and swipe behavior.
- [x] Preserve desktop appearance, Tab, Escape, focus, and resize behavior.
- [x] Pass Storybook checks and review caller snapshots. No package source changed.
- [x] Pass all existing Drawer comparisons without changing states or limits.
- [x] Commit: `fix(drawer): match nested mobile direction and handle` (`0cc6e36`)

## Phase 6e.64: preserve radio keyboard selection

- [x] Confirm reference key, direction, disabled-item, wrapping, and Tab behavior.
- [x] Prove the current keyboard failure through the existing real browser owner.
- [x] Repair group keyboard focus and selection through the public inputs.
- [x] Preserve native values, events, labels, blocked controls, and hook cleanup.
- [x] Pass package, Storybook, and all affected complete example checks.
- [x] Commit: `fix(radio-group): preserve keyboard selection` (`fe07215`)

## Phase 6e.65: preserve radio item defaults and form values

- [x] Confirm anonymous item render failure and matching field selection failure.
- [x] Prove the regressions through the existing package and browser owners.
- [x] Preserve optional identity inputs and independent radio item pairs.
- [x] Select the matching field value and preserve explicit checked input.
- [x] Preserve native form values, repeated selection, events, and server updates.
- [x] Pass package, Storybook, and all affected complete example checks.
- [x] Commit: `fix(radio-group): preserve item defaults and form values`

## Phase 6e.66: preserve raw popup alignment offsets

- [x] Preserve current Popover RTL offset failures and fresh Hover Card shift images.
- [x] Keep the authored expected signs and assert the real fixture directions.
- [x] Remove the extra popup-direction reversal from the raw offset.
- [x] Pass Base JavaScript and existing shared popup owner checks.
- [x] Pass complete Dropdown Menu and Hover Card comparisons after their scoped
  repairs.
- [x] Isolate Hover Card click faults, then repair them in phase 44.
- [ ] Pass remaining complete Menubar and Context Menu comparisons.
- [x] Commit popup test input and readiness corrections separately (`ddba483`).
- [x] Commit: `fix(floating): preserve raw alignment offsets` (`451f57b`)

## Phase 6e.67: preserve computed position after an alignment flip

- [x] Confirm final alignment and coordinates in the saved real trace.
- [x] Prove the end-edge offset failure through the existing two-host menu owner.
- [x] Remove only the extra correction after the position calculation.
- [x] Preserve raw offsets, alignmentAxis, collisions, and Select item alignment.
- [x] Pass required package and direct owner checks for the scoped repair.
- [x] Pass complete Dropdown Menu and Hover Card checks.
- [ ] Pass remaining complete shared caller checks.
- [x] Commit: `fix(floating): preserve computed alignment after collision` (`d150bb8`)

## Phase 6e.68: finish message anchors and preserve reader input

- [x] Prove the stable native-end error with the unchanged exact owner.
- [x] Prove wheel and Home input during actual message entry.
- [x] Finish active anchors without a native-end exception.
- [x] Release anchors for reader scroll input and preserve pointer behavior.
- [x] Remove the invalid mocked native-end assertion.
- [x] Pass repeated exact anchoring and all direct Message Scroller owners.
- [x] Pass Base tests and static checks.
- [ ] Pass all 11 complete Message Scroller examples. Preserve the nine saved failures.
- [x] Commit: `fix(message-scroller): finish anchors and preserve reader input`
  (`900701c`)

## Phase 6e.69: preserve tooltip trigger semantics

- [x] Record the fresh private Phoenix RED after its wrapper run is terminal.
- [x] Confirm the saved receipt has a visible positioned popup and a non-null
  expanded value before the intended assertion fails.
- [x] Extend the existing Tooltip browser owner with native attribute history,
  saved open and closed receipts, real Escape, and observer cleanup.
- [x] Set the public default to false and use the existing tooltip toggle
  protocol for nil callers on all three trigger compositions.
- [x] Preserve explicit true commands, disabled commands, authored attributes,
  client state ownership, and each caller click command.
- [x] Pass fresh green open and closed receipts without disclosure state.
- [x] Pass the existing package Tooltip composition and caller command tests.
- [x] Pass Bubble focus and Message Scroller reset action tests. The direct run
  has 25 passes and one invalid Voice Mode page load.
- [x] Pass the same Voice Mode hover, focus and action owner in three exact repeats.
- [x] Pass all four comparison layers for Tooltip, Bubble, Button Group and Kbd.
- [ ] Complete Message Scroller comparison proof. The current diagnostic has
  34 passes and ten failures. Preserve the earlier suite timeout and all images.
- [x] Update only the Tooltip port-body digest and pass its offline and online
  contract checks with all upstream fact bytes unchanged.
- [x] Regenerate the five affected snapshot families and review the actual
  deltas against the 11-file prediction in PLAN.
- [x] Preserve the three explicit-false Message Scroller snapshots, snapshot
  index, source pins, AI record bytes, examples, states and comparison limits.
- [x] Pass required package and Storybook checks without source changes from
  test execution. Keep unrelated AI snapshot gaps separate.
- [x] Commit this repair after the original frozen scoped commits.
- [x] Commit: `fix(tooltip): preserve tooltip trigger semantics` (`05281e0`)

## Phase 6e.70: preserve caller-controlled choices

- [x] Prove three actual fixed-choice failures and passing React cases.
- [ ] Prove exact controlled callback render RED before source.
- [ ] Preserve fixed caller values and all complete callback commands.
- [ ] Pass all direct menu owners and package checks.
- [ ] Pass all three complete menu families with current states and limits.
- [ ] Review three Menubar snapshots and all three port-body digests.
- [ ] Commit: `fix(menubar): preserve caller-controlled choices`

## Phase 6e.71: preserve Context Menu background accessibility

- [ ] Recheck phase 71 code hashes after phases 69/70.
- [ ] Apply only the existing Context owner extension and obtain intended AX RED.
- [ ] Apply the four-source ARIA lease repair and obtain focused GREEN.
- [ ] Pass all 16 Context cases and all 27 existing Drawer cases.
- [ ] Preserve exact caller values, live regions, nested portals, and hidden menus.
- [ ] Check late nodes, caller updates, overlap, disconnected owners, and cleanup.
- [ ] Preserve Overlay scroll/focus and all existing Floating behavior.
- [ ] Keep Docs close/removal proof separate from isolated destroy proof.
- [ ] Pass all affected direct owners and complete comparisons for the 26 Floating
  and four Overlay families in PLAN.md. Keep known baseline failures open.
- [ ] Run affected AI owners with their actual config and preserve record bytes.
- [ ] Refresh only the final Dropdown digest and 11 Context snapshots.
- [ ] Pass required package, Storybook, static, contract, and snapshot checks.
- [ ] Preserve pins, facts, examples, states, and tolerances.
- [ ] Commit: `fix(context-menu): preserve modal background accessibility`

## Phase 6e.72: preserve final Message Scroller opening

- [x] Extend the existing Commands owner and obtain intended final-opening RED.
  All three runs have stable top 987 and native end 1009 after pending clears.
- [x] Test only the pending-row CSS rule removal first; keep source scope to one
  file.
- [x] Obtain three exact Commands GREEN runs.
- [ ] Pass all four complete semantic cases. Three pass. Previous Context
  still differs in peek-128 and send-busy after its default state passes.
- [x] Inspect remaining opening or selected-tab offsets before further source changes.
  The read-order experiment fails and has been removed. A private trace finds
  the entry completion write that changes busy top 392 to 391.
- [ ] Repair the initial Previous Context position and the separate busy write.
  The marked visibility and zero-opacity experiment is also rejected.
  Commands passes three runs, but Previous Context fails three runs.
  All baseline source bytes and assets have been restored.
- [ ] Pass all 13 direct cases, including exact Anchoring, wheel, and Home input.
  The prior 13 cases pass. The added initial Previous Context check now fails
  in three runs with a 95-pixel shortfall.
- [ ] Pass all four comparison layers for all 11 official Message Scroller examples.
- [ ] Pass affected package, Storybook, static, snapshot, and contract checks.
- [ ] Keep independent image failures and broader completion open until they pass.
- [ ] Preserve pending markers, caller values, pins, AI bytes, states, and tolerances.
- [ ] Commit only the accepted repair with fresh proof.
- [ ] Commit: `fix(message-scroller): preserve final opening position`

## Phase 6e.73: preserve busy inventory during pixel capture

- [ ] Apply only the existing pixel-owner regression before the repair.
- [ ] Record fresh intended RED with screenshots and all four real busy receipts.
- [ ] Preserve authored counts of one item, or three for Previous Context,
  and busy true before and after each actual screenshot.
- [ ] Capture each host after its own fresh action replay and settle, before
  loading the other host. Keep the final viewport and shared clip.
- [ ] Keep timers, readiness, budgets, thresholds, deadlines, states, examples,
  production source, pinned reference bytes, digests, snapshots and AI records.
- [ ] Require three selected runs for Default, Streaming and Animation with
  all busy receipts valid and exact zero pixel differences.
- [ ] Keep separate initial-layout findings open until their own repairs pass.
- [ ] Pass all 11 complete Message Scroller examples in all four actual layers,
  including interaction-parity and Previous Context.
- [ ] Preserve existing direct anchor, input, stream, reply and reset owners.
- [ ] Commit: `test(browser): preserve busy inventory during pixel capture`

## Phase 6e.74: preserve history notices during pixel capture

- [ ] Apply the notice regression after the exact phase 6e.73 patches.
- [ ] Save fresh intended RED with both actual screenshots and native receipts.
- [ ] Guard both notice actions with their authored count, actual button text
  and disabled state, plus the real notice title and description before and
  after each final framing measurement and actual screenshot.
- [ ] Require all final framing receipts to be valid before accepting the
  actual capture notice mismatch as RED. Preserve zero-difference failure images.
- [ ] Replay and capture each host through the existing per-host path before
  loading the other host. Keep the notice inside the proved shared clip.
- [ ] Preserve native notice timers, pauses, server dismissal, state inventory,
  readiness, thresholds, budgets, deadlines, pins, facts, digests and snapshots.
- [ ] Pass three complete Load History pixel runs with valid positive receipts
  and zero pixels in both notice actions. Keep any separate failures open.
- [ ] Pass all 11 Message Scroller examples in all four actual layers and the
  existing direct owner. Preserve AI records and normal VERIFY ownership.
- [ ] Commit: `test(browser): preserve history notices during pixel capture`

## Phase 6e.75: batch compiled badge evaluations

- [x] Start independent read-only measurement after terminal focused phase 6e.72
  proof and after active source leases and compilers end.
- [x] Keep Previous Context residuals and complete Message proof open. Decide
  separately before source application.
- [x] Compile saved pre-change and candidate sources as distinct private modules
  with the same real source filename and live root. Save actual evaluation time.
- [x] Require complete result equality and exact independent/batch digest bytes.
- [x] Reject timeout and input changes. Record warm-state and timing-order limits.
- [ ] Save comparable actual test and dev Docs warm times before and after.
  Current forced whole builds pass at 916.73 seconds for test and 1816.04 for
  development. There is no comparable isolated pre-change Docs baseline.
- [x] Use one fresh evidence batch with no data retained between calls.
- [x] Preserve policy reads for explicit empty shadcn records. An empty eligible
  set skips shared evidence collection.
- [ ] Preserve status and reason precedence, ordered checks, single-record APIs,
  external resources, added/deleted path detection and compiled release behavior.
- [x] Extend the existing publication lifecycle and complete compiled badge owners.
- [x] Pass full private verification and Storybook tests and static checks.
  Verification passes 33 tests and all checks. Storybook passes all checks and
  80 tests with the diagnostic limit. The normal 60-second run remains 79/80.
  Phase 6e.76 then passes all 80 Storybook tests at the normal deadline in 8.5 seconds.
- [ ] Keep rendered badge states, reload recovery and clean release proof current.
- [x] Preserve facts, pins, identity bytes, snapshots, budgets, states, AI records
  and normal VERIFY ownership. Mark old source evidence stale through normal rules.
- [x] Commit: `perf(verification): batch compiled badge evaluations` (`7feb22d`).

## Phase 6e.76: prune excluded identity directories

- [x] Save the actual native and pruned compile lists with exact order and duplicates.
- [x] Require exact shared path and binary byte equality before JSON conversion.
- [x] Compare complete evaluation maps, digest bytes and unchanged input receipts.
- [x] Use distinct private baseline/candidate modules and the same real source path.
- [x] End input-writing tests, source leases and compilers before measurement.
- [x] Reject timeout, changed inputs or unequal results within the finite measurement.
- [x] Preserve native hidden-root, dotfile, UTF-8 and lexical symlink behavior.
- [x] Prune only current excluded directory contents. Keep regular leaf files and
  the content proof for generated digest copies.
- [x] Pass the existing-owner path compatibility case before and after the repair.
- [x] Keep the existing publication freshness and generated-copy contracts intact.
- [x] Pass full private verification tests and configured static checks.
- [x] Pass compiled, rendered and reload badge owners at the normal deadline.
- [x] Pass full Storybook tests and checks. Keep the diagnostic timeout increase
  separate from normal-deadline GREEN proof.
- [x] Save comparable actual test/dev Docs warm times and measurement order limits.
  Forced whole Storybook builds pass at 17.21 seconds for test and 17.17 for
  development. Keep the native-first and warm-state limits explicit.
- [x] Preserve facts, pins, snapshots, policies, identity version, states, budgets,
  thresholds, AI records, release behavior and normal VERIFY ownership.
- [x] Keep clean release, Previous Context and complete Message proof open.
- [x] Commit: `perf(verification): prune excluded input directories` (`3f13a26`).

## Phase 6e.77: preserve upper-clamped entry positions

- [x] Trace the real entry completion write and compare it with the passive control.
- [x] Extend the existing completion owner and prove the intended unit RED.
- [x] Preserve reachable 402-to-400 correction, including a reachable native end.
- [x] Reuse the existing native range read and guard the actual clamp outcome.
- [x] Pass all 39 Scroller and all 91 Base JavaScript tests.
- [x] Pass all 80 Storybook tests at the normal deadline and restore input bytes.
- [x] Pass Base and Storybook configured checks.
- [x] Complete seven semantic states three times with busy and reply equal.
- [x] Pass nine repeated exact anchor, wheel and Home browser cases.
- [x] Run all 13 direct cases. Twelve pass; the known initial check remains failed.
- [x] Confirm the repair with committed CSS and restore the pending CSS exactly.
- [ ] Review the pinned initial and reset contracts with actual native receipts.
- [ ] Pass complete Message comparisons and final publication checks.
- [x] Commit: `fix(message-scroller): preserve clamped entry positions` (`715e2b5`).

## Phase 6e.78: preserve Select pointer focus and highlight

- [x] Prove the native hover, leave, and next-key difference on both hosts.
- [ ] Extend the existing Select browser owner and save the intended failure.
- [ ] Repair option pointer focus without changing selection or keyboard highlight.
- [ ] Preserve disabled options, nested content, scroll position, and cleanup.
- [ ] Pass direct Select checks, complete comparisons, and repeated Animation checks.
- [ ] Commit: `fix(select): preserve pointer focus and highlight`.

## Phase 6f: refresh evidence and verify release badges

- [x] Prepare pinned sources without advancing the shadcn or AI ref.
- [x] Run offline and fetched-source shadcn contract checks.
- [x] Check snapshots and record unrelated baseline failures separately.
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
