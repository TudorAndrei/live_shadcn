# Roadmap

Component-by-component status lives in [docs/INVENTORY.md](docs/INVENTORY.md),
which `mix ui.status` regenerates from the files on disk. This page holds the
milestones and their exit criteria.

A milestone is done when its exit criteria are met, not when the work feels
finished.

---

## M0 — Bootstrap ✅

Monorepo, three packages, and stage one of the pipeline.

- [x] `live_base`, `live_shadcn`, `live_ai_elements` build and test on their own
- [x] Path dependencies swap to version dependencies under `HEX_PUBLISH`
- [x] `mix ui.fetch` pins upstream to a commit and records SHA-256 digests
- [x] `mix ui.status` derives the inventory from disk
- [x] CI matrix, and a weekly sync workflow

**Exit:** a fresh clone runs `mix ui.fetch --only accordion` and gets a
manifest. ✅

---

## M1 — The spine ✅

One component, all the way through, with nothing done by hand.

- [x] `mix ui.spec` parses the shadcn `.tsx`, the Base UI `.md`, **and the
      shadcn style sheets** into `registry/spec/shadcn/accordion.json`
- [x] `disclosure` recipe in `live_base`: `JS` commands for open and close, a
      hook for measurement and enter and exit, correct `data-panel-open`
- [x] `mix ui.gen` turns the spec into a HEEx module
- [x] `storybook/` renders it, with shadcn's own styling
- [x] `mix ui.verify`: markup snapshot, Playwright parity against the Base UI
      documentation example, axe-core clean

**Exit:** `<.accordion>` works and **no generated line was edited by hand**. ✅

### What M1 changed

M1 existed to find out whether the approach holds. Three things it corrected:

**The `.tsx` is not the whole contract.** `.cn-accordion-content` is styled with
`data-closed:animate-accordion-up`, and `data-closed` appears in no `.tsx` and on
no Base UI page. The spec now reads the style sheets too, and the styling layer
is fetched with the rest.

**Enter and exit cannot be `JS.transition`.** `JS.transition` toggles classes;
shadcn styles these states with data attributes, and `h-(--accordion-panel-height)`
asks for a number no static class string can compute. So the hooks take on two
jobs they were not designed for: measuring, and holding a state for the length
of a transition. Those four steps are shared code, not a fifth hook. The
discrete flip is still a `JS` command, so a click still costs no round trip.

**Four exports become one function.** React threads the item's identity through
context. HEEx cannot, so `<.accordion>` takes an `:item` slot and derives every
id from the item's own.

**Risk:** this is the milestone that decided whether the whole approach holds. It
held.

---

## M2 — The eight core recipes ✅

Eight recipes cover 102 of 112 components.

- [x] `disclosure`, `dialog`, `popover`, `listbox`, `menu`, `tabs`,
      `form-control`, `presentational`
- [x] Every shadcn tier-1 component generated and verified — 22 of 22. The
      other twelve tier-1 components are AI Elements, which is M4.
- [x] `mix ui.add` copies components into a host application with a version stamp
- [x] `mix ui.sync` reports upstream drift and refuses to overwrite edited files
- [x] Icon set is configurable — `lucide_icons` by default, since shadcn's
      `IconPlaceholder` already names five sets

**Exit:** a scratch Phoenix app runs `mix ui.add button dialog select`, the
three components compile under its own namespace, and each renders with the
contract it was generated with. ✅

42 components verified in all, by 118 browser tests.

### Where the reader got to

53 of the 62 shadcn components read into a spec. The nine that do not are not
gaps in the reader:

| Component | Built on |
|---|---|
| `calendar` | react-day-picker |
| `carousel` | embla-carousel |
| `chart` | recharts |
| `command` | cmdk |
| `input-otp` | input-otp |
| `resizable` | react-resizable-panels |
| `message-scroller`, `questionnaire` | `@shadcn/react` |
| `sidebar` | its own state machine, several returns deep |

None of them is a Base UI component, so none has a data-attribute contract to
generate against. They are the specialist recipes M6 already schedules, and the
reader says so by name rather than failing obscurely.

### What the reader had to learn

Two things the accordion never showed:

**Variants are data.** shadcn writes them as a `cva` table — which variants
exist, what each is called, which is the default, what class string each
carries. The spec records all four, so `<.button variant="destructive">` gets
its `values:` list from upstream rather than from somebody retyping it.

**A `.tsx` says more than markup.** `render={<a />}`, `useRender`, ternaries,
`??`, conditional children, `.map` over a list, style objects, and references to
other components in the same registry all appear. Each is a decision the
generated component has to make too, so each became a node in the spec rather
than something dropped.

**Four hooks, and no more.** That is what the architecture reserved, and every
recipe since has fitted in them. M1 added measurement and transition timing.
Both went inside the hooks that already existed:

| Hook | Used by | Because |
|---|---|---|
| `Disclosure` | accordion, collapsible | a height only the browser can compute |
| `Overlay` | dialog, alert dialog, sheet | scroll lock, focus containment, timing |
| `Floating` | popover, tooltip, menu, select | where a popup lands is a measurement |
| `Roving` | tabs, menu, select | `phx-key` filters one key, and there are four |

`Disclosure`, `Floating` and `Overlay` all show and hide something that
animates. Those four steps live in one shared module, so three hooks cannot each
get them slightly wrong.

Everything else — every attribute a class string reads, every open and close,
every choice — is a `Phoenix.LiveView.JS` command. No click reaches the server
unless the caller asked for one.

**One hook, two behaviours, one attribute.** Arriving at a tab shows its panel;
arriving at a menu item does not choose it. The same roving hook does both, told
which by `data-lb-activate`. That is the boundary the hooks are held to: they
decide *which* element, never *what happens to it* — what happens is the `JS`
command already on that element.

**A form control is a form field.** Base UI publishes one attribute contract for
every control it has — `data-checked`, `data-invalid`, `data-required`,
`data-filled` — and `Phoenix.HTML.FormField` already carries every fact it
needs. So `<.checkbox field={@form[:subscribe]} />` is the whole API, and the
recipe's job is only to join the two.

Three things that took a browser to get right, and each one is now a test:

- a `<label for>` cannot name a `<span role="checkbox">`, because a label names
  a *labelable* element and that is not one
- a radio is not a round checkbox: choosing one is choosing instead of the
  others, and its hidden input is `type="radio"` so the browser enforces that too
- `role` comes from the Base UI module, not from the shape. A radio announced as
  a checkbox is worse than one not announced at all.

---

## M3 — Publish 0.1.0

- [ ] `live_base` and `live_shadcn` on hex. Both build and pass `hex.publish
      --dry-run`. A `v*` tag runs the checks and publishes them in dependency
      order. Nothing is tagged yet.
- [ ] Storybook deployed, one public URL. The image builds, serves, and carries
      the styling layer. Nothing is deployed yet.
- [ ] Sync bot proves itself: one real upstream change lands as a pull request
      whose diff is readable. The run works and has been done by hand. It has
      not opened a pull request, because nothing is pushed.
- [x] `CONTRIBUTING.md` explains how to add a recipe

**Exit:** somebody who is not us installs it from hex and it works.

The three open boxes need an account, not more code: a hex API key, a
Cloudflare token, and a push. [DEFERRED.md](DEFERRED.md) has the steps.

### Four bugs preparing to publish found

Each was in a part nobody had run.

**A name is not an identity.** Upstream has a `message` in the shadcn registry
and a different `message` in AI Elements. Every stage keyed its files on the
name, so the two shared one spec and one verification entry, and the inventory
marked the AI Elements one verified on the strength of a browser run against
shadcn's. A component is now `{source, name}` everywhere. M4 needs that anyway
to land 49 AI Elements components in their own package.

**The pre-commit hook was editing generated files.** It stripped a trailing
space from a generated `@moduledoc` and rewrote the end of every snapshot.
`mix ui.gen --check` compares both byte for byte, so the next run failed and
the diff showed nothing to explain why. The fixers now skip everything a
pipeline stage writes, and the generator no longer emits the trailing space.

**The image had never been built.** The Dockerfile pinned
`hexpm/elixir:1.20.3-erlang-29.0.1-debian-bookworm-20250630-slim`, which Docker
Hub does not publish. An empty `GITHUB_TOKEN` sent `Bearer` with nothing after
it, which is a 401 rather than a lower rate limit. The image now builds and
serves, styling layer included.

**Two upstream files changed on every fetch.** shadcn's index points each
component at whatever documents it, and for one built on a React library that
is the library's own site. The fetcher followed the link and stored a GitHub
repository page as `resizable`'s Base UI contract. GitHub puts a fresh page
token in every response, so those digests never settled and the weekly sync
would have opened a pull request every week saying nothing had changed.

The secret scanner had been reporting those tokens all along. Earlier in this
milestone the scan was widened to skip the directory instead of asking why
source files had tokens in them. It scans the directory again now, and passes.

---

## M4 — AI Elements

The components are the small part. The reducer is the product.

- [x] `LiveAiElements.Part` — the view model: `id`, `type`, `status`, `seq`
- [x] `LiveAiElements.Stream.reduce/2` → `insert_part`, `append_delta`, `set_state`
- [x] Open Responses adapter, the reference implementation. It carries `item_id`
      per part and `sequence_number` for ordering, which is exactly what
      `phx-update="stream"` needs
- [x] Delta hook: a token append must never touch an assign
- [ ] Tier-1 AI components — 3 of 12 generated and verified: **sources**,
      **suggestion**, **task**. The other nine are chain-of-thought, reasoning,
      tool, message, conversation, prompt-input, code-block, context, shimmer
- [x] Jido adapter, built second on purpose, to prove the adapter boundary holds

**Exit:** a golden test replays a recorded Open Responses stream and produces the
same part list every time. ✅ — five recordings replay to committed part lists,
three from Open Responses and two from Jido.

### What the reducer decided

**A delta never touches an assign, and that is a test.** `assign/3` pin-matches
the new value against the old and returns the socket untouched when they match,
so an event carrying only a delta returns an equal state and no render runs.
Keeping that means counting nothing on the delta path — one remembered sequence
number would make every token a render, and would announce itself nowhere. The
suite checks it over five hundred tokens.

**So the server holds no text while a part streams.** Accumulating it is the
counting the rule forbids. Every provider's terminal event carries the complete
text, so the authoritative copy arrives in one step at the end and one
`stream_insert` replaces what the hook appended. The cost is stated rather than
hidden: a reader who reconnects mid-part loses that one part until it closes.

**Jido moved nothing.** Its identity is per LLM call rather than per content
part, nothing announces a part before its first token, and a tool's input
arrives whole instead of streaming. Three real differences, and none needed a
fifth operation or a sixth field on a part.

### What reading AI Elements found

The reader now reads both registries: 13 of the 49 AI Elements components spec,
and every one that does not is named with the reason rather than skipped.

**A spec with no parts was being written.** AI Elements exports where it
declares — `export const Name = memo(({ … }) => …)` — and the reader only knew
shadcn's `export { … }` at the foot of the file. So all 49 produced a spec with
no parts, which on disk is indistinguishable from one the reader understood.
The reader knows both shapes now, and refuses to write a spec with no parts at
all.

**A dependency cannot name a module `mix ui.add` renames.** Every AI Elements
component is built out of shadcn components, and the obvious generated call is
`LiveShadcn.UI.Collapsible.collapsible`. That module does not exist in an
application: `mix ui.add` copies the file in and rewrites it to
`MyAppWeb.Components.UI.Collapsible`, and it cannot reach into a compiled
dependency to rewrite the call. So the markup has to be folded in the way a
Base UI part already is. Until the reader does that, `mix ui.gen` names the
component instead of generating it wrong.

**A `part` key shadowed a `part` key.** `render={<Button />}` merges the
replacement's keys over the primitive it replaces. A component reference that
recorded its function under `part` therefore overwrote the Base UI part the
primitive was documented under, and the dialog's close button silently lost its
`phx-click`. The key is `function` now.

**A partial verify discarded 41 results.** `mix ui.verify shadcn/dialog` wrote a
`VERIFY.json` holding one entry. It merges now: a run over one component says
nothing about the others, and demoting a component is what a spec change is for.

### The fold, and what generating one component found

An AI Elements component now absorbs the markup of the shadcn component it
renders, rather than calling it. `task` is the first one through: generated by
the disclosure recipe out of shadcn's collapsible, and verified — snapshot,
behaviour in a browser, axe clean — including a check that opening it still
costs no round trip.

**A folded part brings its siblings.** shadcn's scroll-area draws its scrollbar
by calling another function in its own module. Folded into an AI Elements
component, that call named a function nothing defines, and only the compiler
caught it. A part that comes across brings whatever it names with it.

**React props are not attributes.** `<Collapsible asChild defaultOpen={…}>`
configures a React component that the fold has just replaced, so none of it is
markup: `asChild` and `defaultOpen={@default_open}` both reached generated HEEx,
and neither is something a browser or an assign has heard of. HTML attributes
are lowercase and React props are camelCase, which is the whole test.

**A stale generated module outlives its spec.** A component that generated
yesterday and does not today left its module on disk, where it broke the build.
The generator owns those files, so it takes one back when it can no longer
write it.

**A reference's own children were never read.** `<DropdownMenuTrigger><Button /></…>`
is two references, and folding the outer one spliced its children straight into
the tree without looking at them. The inner one arrived unread, and `mix ui.gen`
then reported a component as unreachable that was one recursion away.

**A folded part's props come with it.** shadcn's scroll-area computes an
attribute from its own `orientation`, and once that markup is here so is the
prop — with the default shadcn gave it, because that is the value React used
when upstream rendered `<ScrollArea>` without one.

**An argument to a component is not an attribute of an element.** Two tests,
both learned by putting the wrong thing in generated HEEx. A camelCase name is
React's, which is how `asChild` and `defaultOpen={@default_open}` got there. A
name the target destructured is React's too: `<Button size="sm">` put
`size={@size}` on a `<button>`, where the size is a class string that the
folded markup already computes from the same prop.

**The generator wrote through what it could not read.** An expression it did
not understand was emitted verbatim, so `href={providers.chatgpt.createUrl(query)}`
reached a `.ex` file and failed to compile. It refuses now, which is what the
rest of the pipeline already did.

**A fold can render the content twice.** shadcn's scroll-area puts `{children}`
inside its viewport, and the AI Elements component that renders `<ScrollArea>`
puts its own children inside the reference. `suggestion` drew three buttons six
times, in two wrappers, and each copy looked right on its own — valid markup, a
stable snapshot, nothing for axe to object to. Where the content belongs when a
fold produces two markers is a decision the fold does not make yet, so the
generator refuses instead.

### A JavaScript library is not a reason to write one

An AI Elements component that renders a third-party React component used to be
refused outright: no Base UI contract, so nothing to generate against. That is
right for a library whose job is behaviour, and wrong for one whose job Elixir
already does.

The reader now maps a package to the **job**, not to a library. `<Streamdown>`
becomes an `external` node with the role `markdown`, and the generated
component calls `LiveAiElements.Markdown` — a seam. Which renderer sits behind
it is an application's decision, the way the icon set already is.

| Upstream | Used by | Elixir | Decision |
|---|---|---|---|
| `streamdown` | reasoning, message | `phoenix_streamdown` | adopted, optional |
| `shiki` | code-block | `lumis` | documented, not yet wired |
| `nanoid` | prompt-input | `nanoid` | available when needed |
| `motion/react` | shimmer | — | the shimmer is a CSS animation |
| `use-stick-to-bottom` | conversation | — | a scroll hook, so the `scroller` recipe |
| `tokenlens` | context | — | a table of model context windows, so data |
| `cmdk` | shadcn command | — | the `listbox` recipe |

`phoenix_streamdown` is the same idea as this repository, one layer up: it
re-renders only the block still changing rather than the whole message, and it
closes the syntax a half-finished message left open so a lone `**` does not
turn the rest of the conversation bold.

**It has a trap, and the seam walks around it.** It always asks MDEx for syntax
highlighting, and MDEx raises unless a highlighter is installed. It catches
that and renders the block as escaped text — every block, not only the code
ones — so a conversation shows `**bold**` and nothing says why. The adapter
asks for no highlighting when none is configured, and says in one place how to
add `lumis` and get it.

**Markdown is content, not children.** `<Streamdown>{children}</Streamdown>`
looks like a wrapper and is not one: AI Elements types those children as a
`string`, because a renderer takes source text and produces the markup itself.
A HEEx slot holds rendered markup, which is the wrong end of the same pipe. So
a part that renders markdown takes a `content` prop and no slot.

**A recipe is what a component is built on.** `sources` was down as a popover.
It renders `<Collapsible>`, so it is a disclosure, and saying so was the whole
change: the fold then found the Base UI parts the recipe was looking for. What
an AI Elements component's recipe is, is decided by the shadcn component it
composes, not by what it looks like on the page.

### Four parser bugs, each of which cut a component short

Every one of them was silent, and every one dropped markup rather than failing.

**A rescue said "not a component".** An arrow function whose markup could not
be read was dropped, and the file that rendered it failed thirty lines later
with "the spec reader does not know what `<CodeBlockContent>` is". The reason
travels with the name now. Whether it matters is the spec reader's decision,
because a file is full of small arrow helpers that render nothing and one
nobody exports is not a component.

**A statement ended at its own signature.** `const CheckpointIcon = ({ … }: T) =>`
closes its brackets on the line before its body, so reading to the first
balanced line stopped at the arrow and left the component with no markup.

**The first `return (` was not the component's.** A body is full of other
people's returns — `useEffect(() => { … return () => clearTimeout(t) })` writes
one — and taking the first in the text picked that cleanup out of `Reasoning`
and then asked for a JSX element and found nothing.

**A bracketed return is not always one element.**
`return (!isAtBottom && <Button />)` is an expression that decides which, and
reading it as an element found `!`.

Together they were hiding seven components' worth of markup, and `reasoning`,
`prompt-input` and `code-block` had been specced with their root part missing.

### An icon can be a prop

`{ icon: Icon = DotIcon }`, then `<Icon />`. React renames a prop that holds a
component, because JSX reads a lowercase tag as an HTML element — `<icon />`
would be an element nobody has heard of. So the rename is a signal, and what it
signals is that this prop is a thing to render.

The generated component takes `icon` as a name — `attr :icon, :string, default:
"dot"` — because a name is what a caller passes when the icon set is
configuration.

### What stops the other nine

Not markup. The reader reads every one of them now. What stops them is that
upstream computes something in JavaScript, and a template cannot:

| Component | Stopped by |
|---|---|
| chain-of-thought, message | React state — `isOpen`, `currentBranch` |
| tool, context, prompt-input | a local computed from props — `derivedName` |
| code-block | a local holding one of two icons, by state |
| reasoning | a render prop — `getThinkingMessage` |
| shimmer | `motion`, which here is a CSS animation |
| conversation | `use-stick-to-bottom`, so the `scroller` recipe |

The first three rows are one thing: logic. A recipe owns behaviour — the
disclosure recipe owns opening and closing, and that is why `task` and `sources`
generate at all. So each of these needs either a recipe that owns what upstream
is computing, or a prop the caller supplies. Neither is a reader change.

**`data-[state=open]` is read by nobody.** This one is not fixed, and it is the
larger of the two things left.

Tailwind writes a state variant two ways. `data-open:` names an attribute, and
the reader has always recorded it. `data-[state=open]:` names an attribute *and
a value*, and the reader ignores it — silently, which is the one thing this
reader is not allowed to do. AI Elements writes the second form 53 times,
because it targets the Radix-era shadcn where the attribute was `data-state`;
our primitives set Base UI's `data-open` and `data-closed` instead. So a folded
component's enter and exit animations are inert and nothing says why.

It is not only AI Elements. shadcn's own sources and style sheets use the
arbitrary form about 3,300 times across some thirty attribute names —
`data-[side=]`, `data-[size=]`, `data-[variant=]` and the rest. Most name
something already emitted for another reason, which is why nothing has looked
broken. Recognising them means every recipe learning to compute every name they
surface, and that is its own piece of work rather than a fix to squeeze in
here.

---

## M5 — Ouro integration

Ouro is the first real application, and the proof the contract survives contact.

- [ ] `live_shadcn` components replace the hand-written chat and settings CSS
- [ ] `live_ai_elements` renders the `:thinking_start`, `:tool_call`, and
      `:tool_result` events Ouro already emits and currently throws away
- [ ] daisyUI token bridge, or daisyUI removed

**Exit:** Ouro's `assets/app.css` drops below 800 lines, from 1,842.

---

## M6 — Coverage

- [ ] 60 tier-2 components
- [ ] Specialist recipes: `scroller`, `toast`, `carousel`, `chart`, `calendar`,
      `resizable`
- [ ] Tier-2 AI Elements

Tier 3 is deliberately unscheduled. Canvas, sandbox, terminal, and web preview
are heavy React. They may never be worth porting.

---

## Non-goals

- **No React.** Not through `live_react`, not through web components.
- **No framework dependency in `live_base`.** One dependency:
  `phoenix_live_view`.
- **No hand-maintained styling.** If a class string is typed by a person, the
  pipeline has a gap. Fix the pipeline. This covers the style sheets as well as
  the class strings: both are fetched, and neither is retyped.
- **No model in the daily loop.** A model may draft a new recipe once. A person
  reviews it and it is then frozen.
