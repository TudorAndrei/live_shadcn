# Plan: replace TSX generation with port synchronization

The checklist for this plan is in [TODO.md](TODO.md).

## Goal

Replace the general TSX-to-HEEx compiler with a small synchronizer. The
synchronizer will update safe upstream facts in reviewed HEEx ports. It will
stop and report drift when upstream changes structure or behavior. The change
must keep the current component output and verification standard. It must also
remove most of the 15,069 lines in the current reader and generator.

## Approach

### Keep reviewed ports

The files in `packages/live_shadcn/priv/registry/` and
`packages/live_ai_elements/lib/live_ai_elements/components/` will become the
maintained ports. They will no longer be full output from
`LiveShadcnTools.Gen.module/2`.

Each port will contain one marked block:

```elixir
# live-shadcn: upstream facts start
@upstream_facts %{
  "cva/buttonVariants/base" => "cn-button ...",
  "jsx/Button/return/class/0" => "inline-flex ..."
}
# live-shadcn: upstream facts end
```

The reviewed HEEx body will read these values through a small local helper or a
module attribute. `mix ui.add` will still copy a normal Elixir module. The
copied module will not depend on the maintainer tool.

The marked block is the only section that the synchronizer can change. A person
can edit the rest of the port. The contract will record a digest of that body,
so an unrecorded edit still fails the offline check.

### Use one deep module

Add `LiveShadcnTools.Converter` in
`tools/lib/live_shadcn_tools/converter.ex`. Its main interface will be:

```elixir
LiveShadcnTools.Converter.sync(input)
```

It will return one of these values:

```elixir
{:current, artifact}
{:updated, artifact, changes}
{:manual, drift}
{:error, diagnostics}
```

The input will contain the upstream TSX, Base UI pages, relevant style facts,
the current contract, and the current port. The artifact will contain canonical
contract JSON and the updated port source. `sync/1` will not write files. The
Mix task will own all writes.

Keep the result structs and private modules behind this interface. Do not add a
parser behavior or another public adapter. There will be one Oxc
implementation.

### Limit automatic changes

The first safe fact set will contain:

- Class literals in `className` and `cn` expressions.
- CVA base classes, variant classes, variant names, and defaults.
- Digests for the source files and relevant style sheets.

The synchronizer will calculate the data and ARIA state that each new class
string reads. A change to that state set is behavior drift. It will need a
manual port review.

The first version will not update `data-slot`, static HTML attributes, JSX
shape, exports, prop flow, hooks, context use, portals, primitive imports, or
Base UI behavior. It will include these items in the structural fingerprint.
Any change to them will return `{:manual, drift}` and will not change the port.

This limit is deliberate. It keeps the module small and prevents the new code
from becoming another React compiler.

### Replace the full ESTree transfer

Add `tools/priv/facts.mjs`. It will use the existing `oxc-parser` and
`oxc-walker` dependencies from `tools/package.json`.

The script will accept a batch of source files in one request. It will return:

- Stable fact keys and exact literal values.
- Source spans for diagnostics.
- Imports, exports, identifiers, operators, and call shape.
- A canonical structural fingerprint with safe fact values masked.

It will not return the full ESTree. It will not translate JavaScript
expressions into Elixir. Keep `tools/priv/parse.mjs` until the final cutover so
the old and new paths can run together.

### Use a compact contract

Keep the existing `registry/spec/<source>/<name>.json` paths. A version 2 file
will be a port contract, not a JSX intermediate form. It will contain:

- The schema and toolchain versions.
- The source name and component name.
- Upstream source and style digests.
- The structural fingerprint.
- The safe facts and their port bindings.
- The state reads and CSS variables derived from classes.
- The port body digest.
- Explicit ignored facts with a short reason.

Do not store the full JSX tree, translated expressions, recipe data, or full
style maps in the version 2 contract.

Keep `LiveShadcnTools.BaseUi` and `LiveShadcnTools.Style`. Move the small class
state reader from `LiveShadcnTools.Spec.reads/1` behind the converter. Delete
the rest of `LiveShadcnTools.Spec` after all contracts use version 2.

### Keep the current commands during migration

`Mix.Tasks.Ui.Spec` will support both contract versions during the pilot. It
will call `LiveShadcnTools.Spec.build/2` for old specs and
`LiveShadcnTools.Converter.sync/1` for version 2 contracts.

`Mix.Tasks.Ui.Gen` will keep generating old specs. For version 2 contracts, it
will only check that the port and contract agree. This keeps every phase green.

After all verified components use version 2:

- `mix ui.spec` will synchronize safe facts from fetched sources.
- `mix ui.spec --check` will compare fetched sources without writes.
- `mix ui.spec --check --offline` will check the committed contract and port
  without fetched sources.
- `mix ui.gen` and `Mix.Tasks.Ui.Gen` will be removed.

`Mix.Tasks.Ui.Verify.generated_check/1` and the offline CI job will use
`mix ui.spec --check --offline`. The reader CI job will continue to fetch
upstream and use `mix ui.spec --check --source` for each registry.

For a full registry run, `Mix.Tasks.Ui.Spec` will collect every result before it
writes. If one item returns manual drift or an error, it will write nothing.
This prevents a partial registry update.

### Preserve verification

The 109 verified entries must stay verified. The new path must preserve:

- Exact class text and class order.
- CVA values and compile-time `attr` values.
- Compile-time `attr` and `slot` declarations.
- Normal copy-in modules for `mix ui.add`.
- Deterministic contract and fact block bytes.
- Snapshot, browser, accessibility, React parity, and pixel checks.

`LiveShadcnTools.Drift` will compare version 2 facts and report safe updates and
manual drift. `Mix.Tasks.Ui.Status` can keep the current status names during
this change. Here, `generated` will mean that a port and its contract agree.
Renaming the inventory stages is outside this change.

### Dependencies and limits

Keep Node and the current Oxc packages. Do not add Rustler, Rust, Gleam,
Sourceror, a JavaScript runtime, or a shadcn runtime dependency.

The final new production code has this size target:

- `tools/priv/facts.mjs`: at most 600 lines.
- `LiveShadcnTools.Converter` and its internal data types: at most 800 lines.
- The final `Mix.Tasks.Ui.Spec` adapter: at most 250 lines.

The target is 1,100 to 1,650 new lines. `LiveShadcnTools.BaseUi` and
`LiveShadcnTools.Style` are not part of that target because they already exist
and will stay.

Stop after the pilot if the new path needs a general expression IR, behavior
profiles, or more than 1,650 production lines. That result would not meet the
goal.

## Implementation phases

### Phase 1: add the read-only synchronizer

- Add `tools/priv/facts.mjs` with batched Oxc parsing, stable fact keys, source
  spans, and structural fingerprints.
- Add `LiveShadcnTools.Converter.sync/1` in
  `tools/lib/live_shadcn_tools/converter.ex`.
- Define the version 2 contract and the marked fact block format.
- Reuse `LiveShadcnTools.BaseUi.parse!/2` and `LiveShadcnTools.Style.rules/1`.
- Derive state reads and CSS variables without building a JSX intermediate
  form.
- Add interface tests in `tools/test/converter_test.exs` for deterministic
  output, class changes, CVA changes, structural drift, state-contract drift,
  parse errors, and body edits.
- Keep the old pipeline unchanged and green.

**Commit:** `feat(converter): classify safe upstream changes`

### Phase 2: prove the contract with three ports

- Add temporary version routing to `Mix.Tasks.Ui.Spec` and
  `Mix.Tasks.Ui.Gen`.
- Add a checked migration helper under `tools/lib/live_shadcn_tools/` that
  creates a fact block and bindings from an old spec and its generated module.
- Convert `button` as the presentational case.
- Convert `dialog` as the behavior case.
- Convert `calendar` as the specialist case.
- Replace their old specs with version 2 contracts.
- Change their module text to say that the HEEx body is a reviewed port and
  only the marked fact block is synchronized.
- Require the same rendered markup, compile-time declarations, browser
  behavior, accessibility results, React parity, and pixel output.
- Measure the new production code. Stop if it breaks the 1,650-line limit or
  needs JavaScript expression translation.

Pilot result: the new path has 1,160 production lines when the temporary
migration helper and dual-route additions are included. The converter uses two
small class composition operations. It does not use a general expression IR.

**Commit:** `refactor(registry): prove fact-backed ports on three modules`

### Phase 3: migrate all verified ports

- Run the checked migration helper for every remaining verified shadcn and AI
  Elements entry in `docs/INVENTORY.md`.
- Replace each old spec with a version 2 contract.
- Fail the migration if a source fact has no explicit binding or ignored
  reason.
- Fail the migration if a port fact does not match the old generated source.
- Keep the two fetched entries without a verified port at their current stage.
- Update `LiveShadcnTools.Drift` so it can report version 2 fact and fingerprint
  changes.
- Re-run verification for every changed contract. Update
  `registry/VERIFY.json` and `docs/INVENTORY.md` only after the checks pass.

**Commit:** `refactor(registry): migrate verified modules to fact-backed ports`

### Phase 4: switch the maintainer workflow

- Replace the dual path in `Mix.Tasks.Ui.Spec` with the version 2 converter.
- Add `--offline` to check contracts and ports without fetched sources.
- Change `Mix.Tasks.Ui.Verify.generated_check/1` to use the offline spec check.
- Change `.github/workflows/ci.yml` to use the offline spec check.
- Change `.github/workflows/sync-upstream.yml` to run `mix ui.spec` without
  `mix ui.gen`.
- Make a structural drift fail the sync before it changes files or opens a pull
  request.
- Keep `--source shadcn` and `--source ai_elements` as separate reader gates.
- Update `Mix.Tasks.Ui.Status` only where it needs the new contract digest.

**Commit:** `refactor(tools): switch registry updates to port synchronization`

### Phase 5: remove the old compiler

- Delete `LiveShadcnTools.Ast`, `LiveShadcnTools.Tsx`,
  `LiveShadcnTools.Cva`, and the old parts of `LiveShadcnTools.Spec`.
- Delete `LiveShadcnTools.Gen`, `LiveShadcnTools.Gen.Heex`, and every recipe
  module under `tools/lib/live_shadcn_tools/gen/`.
- Delete `Mix.Tasks.Ui.Gen` and the temporary migration helper.
- Delete the old internal tests in `tools/test/ast_test.exs`,
  `tools/test/spec_test.exs`, and `tools/test/gen_test.exs` after the converter
  interface tests cover their current contracts.
- Keep the Base UI, style, fetch, drift, status, and verification modules.
- Remove dead aliases, helpers, test fixtures, and documentation for
  `mix ui.gen`.
- Do not add tests that only check that removed modules or files stay absent.
- Measure the final production line count and compare it with the target.

Final result: the Oxc extractor, converter, and final spec task contain 1,051
production lines. The replaced reader and generator contained 15,069 lines.
The new path removes 14,018 lines, or 93% of that code.

**Commit:** `refactor(tools): remove the TSX-to-HEEx compiler`

### Phase 6: document the reviewed-port workflow

- Update `README.md` and `docs/ARCHITECTURE.md` to show
  `ui.fetch -> ui.spec -> ui.verify`.
- Document safe updates, manual drift, the fact block, and the first-port
  process.
- Update generated module documentation and package text that still says every
  module is generated.
- Explain that Oxc extracts facts and fingerprints. It does not translate
  React behavior.
- Record the final line counts and the measured net deletion.

**Commit:** `docs(architecture): document port synchronization`

## Risks and tradeoffs

- A safe literal can gain a new data or ARIA state requirement. The converter
  will compare state-read sets and return manual drift before it changes the
  port.
- A structural fingerprint can move after an Oxc update. The contract records
  the toolchain version. Update Oxc in a separate change and review the full
  fingerprint migration.
- Stable fact keys can change when upstream moves syntax without changing
  behavior. Treat that as manual drift. Do not add fuzzy matching.
- A direct port can diverge from React behavior. The existing React parity,
  pixel, browser, and accessibility checks remain the proof.
- A full migration changes every contract digest. All affected entries must run
  through verification again before they can remain verified.
- The new process cannot create a correct first port from arbitrary TSX. A
  person or model must write and review that port. This is the main tradeoff
  that permits the code deletion.
- The temporary dual path adds code for two phases. Delete it as soon as all
  verified entries use version 2.

## Open questions

No user decision blocks phase 1.

- The pilot showed that one fact block can cover the specialist calendar. The
  component-specific binding manifest stays in the temporary migration helper,
  and the converter has no calendar rule.
- The first version treats `data-slot` and static attributes as manual drift.
  Add them to the safe set only after the complete migration, and only if the
  change removes more code than it adds.
- Keep the inventory status name `generated` for this change. A later
  documentation-only change can rename it to `ported` if that improves the
  public wording.
