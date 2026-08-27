# TODO: replace TSX generation with port synchronization

This checklist follows [PLAN.md](PLAN.md). Complete one phase, run its checks,
and make its listed commit before work starts on the next phase.

## Phase 1: add the read-only synchronizer

- [x] Add batched Oxc fact extraction in `tools/priv/facts.mjs`.
- [x] Add `LiveShadcnTools.Converter.sync/1` in
      `tools/lib/live_shadcn_tools/converter.ex`.
- [x] Define stable keys, source spans, the structural fingerprint, the version
      2 contract, and the marked fact block.
- [x] Keep class and CVA literals as the only automatic source changes.
- [x] Return manual drift for state-read, JSX, export, prop-flow, hook, context,
      portal, primitive import, and Base UI contract changes.
- [x] Add `tools/test/converter_test.exs` at the external interface.
- [x] Verify that the same input returns identical contract and port bytes.
- [x] Verify that this phase does not change any existing spec or port.
- [x] Run `cd tools && mix test`.
- [x] Run `cd tools && mix check`.
- [x] Commit: `feat(converter): classify safe upstream changes`

## Phase 2: prove the contract with three ports

- [x] Add temporary version routing to `Mix.Tasks.Ui.Spec` and
      `Mix.Tasks.Ui.Gen`.
- [x] Add a checked migration helper for old specs and generated modules.
- [x] Convert `registry/spec/shadcn/button.json` and
      `packages/live_shadcn/priv/registry/button.ex`.
- [x] Convert `registry/spec/shadcn/dialog.json` and
      `packages/live_shadcn/priv/registry/dialog.ex`.
- [x] Convert `registry/spec/shadcn/calendar.json` and
      `packages/live_shadcn/priv/registry/calendar.ex`.
- [x] Verify that class text, class order, CVA defaults, and CVA values do not
      change.
- [x] Verify that all three ports keep their compile-time `attr` and `slot`
      declarations.
- [x] Run `cd tools && mix test`.
- [x] Run `cd tools && mix ui.gen --check button dialog calendar`.
- [x] Run `cd packages/live_shadcn && mix test`.
- [x] Run `cd storybook && mix snapshot --check button dialog calendar`.
- [x] Run the browser, accessibility, React parity, and pixel checks for
      `button`, `dialog`, and `calendar`.
- [x] Count the new production lines. Stop if the count is above 1,650 or if the
      converter needs a general expression IR.
- [x] Commit: `refactor(registry): prove fact-backed ports on three modules`

## Phase 3: migrate all verified ports

- [x] Convert every remaining verified shadcn port and contract to version 2.
- [x] Convert every remaining verified AI Elements port and contract to version
      2.
- [x] Keep the two fetched entries at their current stage.
- [x] Check that every extracted fact has a binding or an ignored reason.
- [x] Check that every bound old fact matches its current port value.
- [x] Check that every fact block has canonical key order and stable bytes.
- [x] Update `LiveShadcnTools.Drift` for version 2 contracts.
- [x] Run `cd tools && mix test`.
- [x] Run `cd tools && mix ui.spec --check --source shadcn` after
      `mix ui.fetch`.
- [x] Run `cd tools && mix ui.spec --check --source ai_elements` after
      `mix ui.fetch`.
- [x] Run `cd tools && mix ui.gen --check` while the dual path still exists.
- [x] Run `cd packages/live_base && mix test`.
- [x] Run `cd packages/live_shadcn && mix test`.
- [x] Run `cd packages/live_ai_elements && mix test`.
- [x] Run all storybook snapshots.
- [x] Run the full browser, accessibility, React parity, and pixel suite.
- [x] Run `cd tools && mix ui.verify` for all changed contracts.
- [x] Run `cd tools && mix ui.status` and confirm that all 109 verified entries
      remain verified.
- [x] Commit: `refactor(registry): migrate verified modules to fact-backed ports`

## Phase 4: switch the maintainer workflow

- [ ] Remove old-spec routing from `Mix.Tasks.Ui.Spec`.
- [ ] Add `mix ui.spec --check --offline`.
- [ ] Make full-registry writes all-or-nothing.
- [ ] Change `Mix.Tasks.Ui.Verify.generated_check/1` to the offline spec check.
- [ ] Change `.github/workflows/ci.yml` to the offline spec check.
- [ ] Remove `mix ui.gen` from `.github/workflows/sync-upstream.yml`.
- [ ] Make the sync workflow stop before writes on manual structural drift.
- [ ] Keep separate source checks for shadcn and AI Elements.
- [ ] Update `Mix.Tasks.Ui.Status` for the version 2 contract digest where
      required.
- [ ] Run `cd tools && mix test`.
- [ ] Run `cd tools && mix ui.spec --check --offline` without
      `registry/upstream/`.
- [ ] Run both fetched-source checks.
- [ ] Run `cd tools && mix ui.status --check`.
- [ ] Commit: `refactor(tools): switch registry updates to port synchronization`

## Phase 5: remove the old compiler

- [ ] Delete `tools/lib/live_shadcn_tools/ast.ex`.
- [ ] Delete `tools/lib/live_shadcn_tools/tsx.ex`.
- [ ] Delete `tools/lib/live_shadcn_tools/cva.ex`.
- [ ] Delete the replaced code from `tools/lib/live_shadcn_tools/spec.ex`.
- [ ] Delete `tools/lib/live_shadcn_tools/gen.ex` and
      `tools/lib/live_shadcn_tools/gen/`.
- [ ] Delete `tools/lib/mix/tasks/ui.gen.ex`.
- [ ] Delete the temporary migration helper.
- [ ] Delete the replaced internal tests from `tools/test/ast_test.exs`,
      `tools/test/spec_test.exs`, and `tools/test/gen_test.exs`.
- [ ] Keep current API, security, persistence, and behavior tests. Do not add
      tests that only check that deleted code stays absent.
- [ ] Remove dead aliases, functions, and fixtures.
- [ ] Run `cd tools && mix format`.
- [ ] Run `cd tools && mix test`.
- [ ] Run `cd tools && mix check`.
- [ ] Run the test and check aliases in `packages/live_base`,
      `packages/live_shadcn`, and `packages/live_ai_elements`.
- [ ] Run `cd tools && mix ui.spec --check --offline`.
- [ ] Confirm that `tools/priv/facts.mjs`, the converter, and the final spec task
      contain no more than 1,650 new production lines in total.
- [ ] Record the old count of 15,069 lines, the final count, and the net
      deletion in `PLAN.md`.
- [ ] Commit: `refactor(tools): remove the TSX-to-HEEx compiler`

## Phase 6: document the reviewed-port workflow

- [ ] Update the pipeline in `README.md`.
- [ ] Update the stages and ownership rules in `docs/ARCHITECTURE.md`.
- [ ] Remove statements that say every port is generated or must not be edited.
- [ ] Document safe fact updates and manual structural drift.
- [ ] Document how to create and verify the first port for a new upstream
      component.
- [ ] Document that Oxc extracts facts and does not translate React behavior.
- [ ] Run Markdown and repository formatting checks.
- [ ] Run `cd tools && mix ui.status --check`.
- [ ] Commit: `docs(architecture): document port synchronization`

## Verification

- [ ] No behavior change in the 109 currently verified entries.
- [ ] All class strings and their order match the current ports before the
      migration.
- [ ] All CVA values, defaults, and compile-time accepted values match.
- [ ] `mix ui.add` still copies standalone Elixir modules.
- [ ] Two runs on the same input return byte-identical contracts and fact
      blocks.
- [ ] A class-only change updates only safe facts and the marked block.
- [ ] A CVA-only change updates the table and compile-time accepted values.
- [ ] A new data or ARIA state read returns manual drift and writes nothing.
- [ ] A JSX shape, export, prop-flow, hook, context, portal, primitive import,
      `data-slot`, static attribute, or Base UI contract change returns manual
      drift and writes nothing.
- [ ] A syntax error reports the source file and span.
- [ ] An edited port body fails the offline check until its contract records the
      new body digest.
- [ ] A full-registry failure leaves all contracts and ports unchanged.
- [ ] All package tests and static checks pass.
- [ ] All snapshots pass.
- [ ] All browser and accessibility checks pass.
- [ ] All React parity and pixel checks pass.
- [ ] `registry/VERIFY.json` and `docs/INVENTORY.md` are current.
- [ ] The final replacement stays within the 1,650-line target.

## Review

- [x] Review the converter interface and version 2 contract before phase 2.
- [x] Review the `button`, `dialog`, and `calendar` diff before phase 3.
- [ ] Update `PLAN.md` and `TODO.md` before work continues if the design changes.
- [ ] Complete and commit each phase before the next phase starts.
- [ ] Check that every phase commit uses the exact conventional commit message
      in this file.
- [ ] Check all TODO items before the migration is complete.
