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

The sources in `registry/upstream/`, unmodified, at the commit
`registry/UPSTREAM.json` pins. Nothing here reimplements a component. Three
files are shimmed, in `src/shim/`, and each is something upstream imports and
shadcn's registry does not publish:

| Shim | Why |
|---|---|
| `utils.ts` | `cn`, which every class string is built with |
| `use-mobile.ts` | a hook that reports the viewport width, read only by `sidebar` |
| `icon-placeholder.tsx` | shadcn writes an icon as one name per icon library; this renders the lucide one, which is the set `LiveShadcn.Icon` ships |
| `streamdown.tsx` | the markdown renderer, which is the one shim standing in for a package upstream really does depend on — see below |

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

One file per example, named `<component>.<example>.tsx`, exporting a component
by default. The filename is the only record of what has been ported:
`storybook/test/browser/parity.spec.mjs` reads this directory and compares it
against the storybook's own list, so a component nobody ported is named rather
than quietly skipped.

Each one is a port of the matching `StorybookWeb.Examples` function, not a
second design. **The two examples have to ask for the same thing.** Where a Base
UI default differs from what the reviewed port does — Base UI unmounts a
closed accordion panel and the disclosure recipe hides it, so a hook can measure
it — the example says so out loud and passes `keepMounted`. A difference the
examples introduce is a difference the report blames on the components.

## Running it

    cd parity && npm install && npm run dev     # http://127.0.0.1:4102

Playwright starts it on its own, so `mix ui.verify` needs no separate step. The
comparison is `parity` in `registry/VERIFY.json`.

## Which registry it gates

`shadcn`. The AI Elements references are here and nothing compares them.

AI Elements composes with `asChild`. This repository pins shadcn's Base UI base,
where that prop does not merge, does not warn, and does not reach the DOM: Base
UI draws its own `<button>` around the element that was to become the trigger.
The reader reads `asChild` as one element — which is what both Radix's `asChild`
and Base UI's `render` do — so the reference is the only side drawing two.

**Editing a reference to agree with a port is the one thing this application
must never do.** It would prove that the port agrees with the porter.

The gate is one line in `storybook/test/browser/registries.mjs`. What holds
`live_ai_elements` uses the historical `generated` key for its contract check,
plus `snapshot` and `browser`+axe. Its markup
is a composition of the shadcn components this application does gate.

## What is compared

Not markup. Two renderers of the same component differ in ways nobody should be
told about: React creates `base-ui-_r_2_` where the reviewed port takes
an id from its caller, and only one side has `phx-click`.

What they must agree on is what a reader sees. For every element carrying a
`data-slot` — the vocabulary both sides share, and the one the spec is built
around — the comparison reads its box relative to the component and a fixed list
of computed properties. See `storybook/test/browser/measure.mjs`.
