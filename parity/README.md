# parity

The upstream React references for the reviewed ports.

## Why it exists

`mix ui.verify` had three checks, and all three read the same spec. The module
matches the spec, the snapshot matches the module, the behaviour matches what
the spec recorded of Base UI's contract. So a spec that read upstream *wrongly*
passes every one of them: a class string the reader dropped is missing from the
module, missing from the snapshot, and missing from the expectation.

Nothing was reading upstream except the reader. This does, by rendering it.

It also gives a hand-written component something to be checked against. A
component with no contract check has no snapshot worth the name;
what it has is upstream, drawn beside it.

## What it renders

The sources in `registry/upstream/` are unmodified and use the commits in
`registry/UPSTREAM.json`. Vite maps imports to eight adapters in `src/shim/`:

| Shim | Purpose |
|---|---|
| `utils.ts` | Provides the `cn` class helper. |
| `use-mobile.ts` | Reports viewport width for the registry hook import. |
| `icon-placeholder.tsx` | Uses the Lucide icon named by the official example. |
| `next-image.tsx` | Renders Next Image inputs as a native image, including fill positioning. |
| `next-link.tsx` | Renders Next Link inputs as a native anchor. |
| `next-font-google.ts` | Maps Vazirmatn to the locally installed font. |
| `streamdown.tsx` | Renders assistant prose as text when no markdown renderer is configured. |
| `streamdown-plugin.ts` | Resolves plugin imports used with the text-only Streamdown adapter. |

The directory also contains `lucide.tsx`, an icon-name helper imported by the
local Sidebar reference. It is not a Vite import alias.

**The markdown renderer is shimmed, and that is a decision.** AI Elements
renders assistant prose with Streamdown. The reviewed ports render no
markdown at all: `LiveAiElements.Markdown` is a seam, and which renderer sits
behind it is the application's, on the argument that everybody who renders LLM
output already has one. A comparison that rendered Streamdown here and
`phoenix_streamdown` there would be comparing two markdown renderers, and
neither of them is the component. With no renderer configured the seam renders
the text as text, and that is what the shim draws.

`upstream.mjs` copies the fetched sources into `src/upstream/` before the server
starts, because Node resolves a bare import by walking up from the file that
wrote it, and `registry/upstream/` has no `node_modules` above it. The copies
are gitignored. `storybook/assets/upstream.mjs` does the same for the style
sheets, for the same reason.

## The style sheet is the storybook's

`src/main.tsx` imports `storybook/priv/static/assets/app.css`, and
`storybook/assets/css/app.css` lists this directory in its `@source`. One
Tailwind build covers both trees.

Two builds would emit two sets of utilities, and every difference the comparison
reported would be a difference between the builds.

Run `npm run build:css` in `storybook/assets` before comparing.

## An example

For shadcn, `mix ui.fetch` reads all `ComponentPreview` entries from the pinned
official component pages. The parity app loads the exact official React file
from the pinned checkout. `mix ui.verify` requires each entry in that list to
have a Storybook HEEx preview.

AI Elements uses one local reference file per example, named
`<component>.<example>.tsx`, because its public examples do not have the same
one-file-per-documentation-preview contract.

An example that exists only in the official shadcn documentation is a parity
gap. It cannot produce a Verified status.

Each Storybook example is a port of the official example, not a second design.
**The two examples have to ask for the same thing.** The React side uses the
official file without a local rewrite. A difference introduced by the HEEx port
is therefore a difference that the report assigns to the port.

## Running it

Complete the [repository setup](../CONTRIBUTING.md#setup) first. It restores
pinned inputs and installs the tools parser, Storybook Mix and asset
dependencies, browser npm dependencies and Chromium, and parity npm dependencies.
Then run from the repository root:

```bash
cd tools
mix ui.verify --source shadcn
mix ui.status
mix ui.status --check --source shadcn --require-verified
```

The verifier prepares pinned sources and shared CSS, then owns one Storybook
server and one reference server for the run. The repository's mise environment
sets `STORYBOOK_PORT=14101` and `PARITY_PORT=14102`. Stop development servers
on those ports first. It verifies fetched bytes
against committed digests; do not advance upstream refs just to rerun checks.
Tracked Storybook example images are also served by Vite and included in the
shadcn evidence identity.

For a scoped rerun, use `mix ui.verify shadcn/dialog`. A direct, complete-example
batch can be run and imported separately after a managed run has prepared
the sources and shared CSS:

```bash
cd storybook/test/browser
STORYBOOK_PORT=14101 PARITY_PORT=14102 PARITY_PREPARED=1 \
  PREVIEW_SOURCE=shadcn PREVIEW_COMPONENTS=button PREVIEW_EXAMPLES=default \
  PLAYWRIGHT_JSON_OUTPUT_FILE=/tmp/button-parity.json \
  npm run verify -- '(?:^|/)parity\.spec\.mjs$' --project chromium
cd ../../../tools
mix ui.verify shadcn/button --examples default --record parity=/tmp/button-parity.json
```

The import records this batch but remains Not verified until all examples and
required layers are complete. Direct single-component accessibility and pixel
batches also carry importable metadata. Mixed-layer/component commands and test
filters are diagnostic, not importable evidence. Direct runs produce reports,
not persisted badges; the Mix verifier owns publication to `registry/VERIFY.json`.

## Which registry it gates

The maintained verification workflow gates shadcn, including the data-table,
date-picker, and typography documentation families. AI Elements reference
selection and evidence portability are outside this workflow; its policy,
examples, and stored records are preserved.

Every official shadcn example must be covered. A known composition difference
belongs in a reviewed, named normalization rule, not a disabled check.

## Report provenance and badges

Managed and direct runs capture the shared versioned identity before testing.
Version-2 reports carry source/component/example ownership, layer, state
coverage, completion, and global Playwright errors. The actual comparison loops
annotate discovered and completed states; the wrapper derives completion from
those annotations and executed test results, rather than trusting a preset flag.
Imports reject stale identities, wrong ownership or layers, raw legacy reports,
and partial states. Complete
example batches may accumulate, but Verified requires every required batch.
Validation and publication run under the source lease, with an identity recheck
before the atomic record write.

`PARITY_DEBUG_STATE` and other diagnostic filters cannot create complete
evidence. Rerun the unfiltered component when investigating a failure is done.
Do not replace evidence hashes or relax pixel budgets to make a badge pass.

Storybook and the pipeline share five outcomes: Verified, Failed, Stale,
Not verified, and No DOM. Freshness is checked before an old failure is
classified. Component pages show short per-check reasons. Recompile after the
last evidence write; release badges are compiled data, not runtime repository
reads.

## What is compared

Not markup. Two renderers of the same component differ in ways nobody should be
told about: React creates `base-ui-_r_2_` where the reviewed port takes
an id from its caller, and only one side has `phx-click`.

What they must agree on is what a reader sees. For every element carrying a
`data-slot` — the vocabulary both sides share, and the one the spec is built
around — the comparison reads its box relative to the component and a fixed list
of computed properties. See `storybook/test/browser/measure.mjs`.
