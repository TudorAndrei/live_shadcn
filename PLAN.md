# Plan: live_ai_elements, held to what live_shadcn now proves

The checkbox form of this page is [TODO.md](TODO.md). The shadcn plan this
replaces is finished; [ROADMAP.md](ROADMAP.md) holds it, and the one thing left
there — publishing 0.1.0 — is blocked on an account and listed at the end of
[TODO.md](TODO.md).

## Goal

`live_shadcn` went from *generating* 52 components to *verifying* 62 by building
one thing: a check that reads upstream by rendering it, and a record that
refuses to call a component verified until it passes. `live_ai_elements` has
none of that. 49 components are in the registry, **14 generate, and exactly one
verifies** — `snippet`, and only because somebody once wrote it a React
reference.

This plan applies the same machinery to the same standard: every AI Elements
component that generates should also verify, and the components the corrected
shadcn specs now unblock should land. It is not a plan to grow coverage — the 22
components that have no spec at all are out of scope, and the eight tier-3 ones
may never be worth porting.

## Approach

### What the shadcn work already supplies

Four things, and the first is free:

**The shadcn specs were wrong, and AI Elements reads them.** An AI Elements
component folds in the markup of the shadcn component it renders, off disk. 38
shadcn specs were stale until last week. Re-reading the AI Elements specs
against the corrected ones makes **`mic-selector` generate with no further
work** — checked, it does.

**`mix ui.spec --check --source`.** The gate exists and takes a registry. AI
Elements cannot use it while three components stop the reader, which is phase 1.

**`parity.spec.mjs`, `pixel.spec.mjs`, and the outline.** The two checks that
read upstream instead of the spec, and the failure report that names the element
rather than the number. They work for any component with a React reference.

**Two precedents for state the server does not own**: a `LiveBase` hook where
the client is the only one who can know (`toast`, `scroller`, `calendar`), and
`JS.toggle_attribute` where nothing needs to be measured (`sidebar`).

### Look for it on hex before building it, where that is a real question

Upstream reaches for a React library the moment a component needs behaviour, and
the reflex here must not be to reimplement whatever it reached for. **Search hex
first, and record what was found**, either way — a search nobody wrote down is a
search the next person repeats.

It is a real question when a library does work a person would otherwise be
writing: syntax highlighting for `code-block`, an audio meter for
`speech-input`, a markdown renderer, a plot. Those get the search before they
get a line of code, and the answer goes in this file.

**It is not a real question for a browser API.** The clipboard is
`navigator.clipboard.writeText`, in the browser and nowhere else; no server-side
package can supply it, and the only thing hex could offer is somebody else's
packaged hook. `live_base` is that package here, and it takes exactly one
dependency by a non-goal [ROADMAP.md](ROADMAP.md) already states — so anything
landing in `live_base` is built rather than depended on.
`LiveBase.Clipboard` is a few lines beside `LiveBase.Toast`.

Stated because the first draft of this plan searched hex for "clipboard",
listed `clipboard` (the system one — `pbcopy`, `xclip`), `kino_clipboard` and
`clipixir`, and dressed three non-candidates up as due diligence. The rule is
worth keeping; applying it to a browser API is not.

### Where it stands, exactly

| | Count | |
|---|---:|---|
| generate | 14 | 1 verifies |
| spec, no module | 13 | each with a stated reason |
| no spec | 22 | 8 of them tier 3 |

Of the 14 that generate, 10 fail only `parity` and `pixel`, and for one reason:
**no React reference exists.** Three more — `attachments`,
`environment-variables`, `plan` — have no storybook example at all, so `browser`
and `snapshot` fail too.

### The order, and why it is this order

The reference backfill is the centre of the plan, and it must land green. Two
things have to be true first: the components must have examples to render, and
the defects a reference would immediately find must be fixed. Those defects are
already known — [ROADMAP.md](ROADMAP.md) records them under *Folding a component
that behaves*, and all three are still in the generated output today:

- `attachments.ex:186` puts `align={@align}` and `side={@side}` on a plain
  element, because a fold copies a popover's markup and not the recipe that
  positioned it.
- `plan.ex` renders a `<button>` inside a `<button>`.
- `environment_variables.ex` draws its toggle as a `<span>` with no
  `role="switch"` and no `aria-checked`.

So: unblock the reader, re-read, fix the fold, give the three an example, then
backfill the references, then widen the gate that would have named the gap.

### Explicitly out of scope

- The 22 components with no spec. Tier 3 — `canvas`, `sandbox`, `terminal`,
  `web-preview` and four more — is heavy React and the roadmap already says it
  may never be worth porting.
- `live_shadcn`. Its plan is finished and its gates stay green throughout.
- The `chart`, which is hand-written by decision, recorded in the roadmap.

## Implementation Phases

### Phase 1: The three state keys the generator cannot bind

`question`, `snippet` and `environment-variables` stop the generator the moment
their specs are re-read, and the whole plan is behind them. Each is React
holding something for the length of a render, which is neither the server's
state nor a prop:

| Component | Key | Answer |
|---|---|---|
| `snippet` | `isCopied` | a `LiveBase` hook — copying is `navigator.clipboard`, and the tick afterwards is client state nobody else can know |
| `question` | `text` | an attribute — a textarea's value is application state, and the server owns it |
| `environment-variables` | `showValues` | an attribute and an event. See below: it is not a toggle |

**`showValues` is not one decision, it is three**, and only the third is hard.
It picks between an eye and a crossed-out eye, which is two SVGs and a `data-`
variant. It sets `checked` on a folded `shadcn/switch`, which is phase 3's work
and means the control has to stay a real switch rather than become a bare
toggle. And then:

```tsx
const displayValue = showValues ? value : "•".repeat(Math.min(value.length, 20))
```

That is **different text, not different styling**, with a length rule. No
attribute variant changes an element's content, so somebody has to render the
other string — and this one is a secret.

So the server owns it: `show_values` is an attribute, the switch pushes an
event, and **the real value is only ever sent once it has been asked for.**
Upstream keeps it in JavaScript and renders dots; a server that rendered the
value and hid it with CSS would put every secret in the page source. One round
trip, stated rather than hidden — the same trade `command` makes by filtering on
the server.

It split in two once the work started, because two of the three turned out to
be the *same* reader gap and the third needs a mechanism the pipeline does not
have.

#### Phase 1a: two props the reader made and then filtered back out — done

Neither `text` nor `showValues` needed a decision. The reader had already made
a prop for each, and `props_read/2` — which keeps only the params something in
the markup actually reads — threw both away, because neither reaches the tree
as a name:

- `value={question.text}` mentions `question`, never `text`. A field read off a
  React context is now recorded on the part as `context_fields` and counts as a
  read. Four parts in 567 read a context, so the key is written only where it
  means something.
- `!showValues && "select-none"` reaches the tree as the *text* of a condition.
  Every other expression in the spec records its identifiers; a conditional
  class did not, and now does.

The second turned up two shadcn specs — `carousel` and `sidebar` — that gain an
`orientation` param for the same reason. **Neither component changes**;
`mix ui.gen --check` is green and the snapshots do not move. Both re-verified.

`question` generates.

#### Phase 1b: `isCopied`, and a choice the client owns — done

`snippet` and `environment-variables` both stopped here, on the same name and
the same shape:

```tsx
const Icon = isCopied ? CheckIcon : CopyIcon
```

The reader reads it correctly — a `choice` node with `when: "isCopied"`. The
generator renders a choice with `:if` on both branches, which is a **server**
decision, and there is no way in this pipeline to say *the client owns this
one*. Every client-owned thing here is an attribute a class string reads;
none is a choice between two elements.

Binding `isCopied` to an assign would work today and is the wrong answer: it
costs a round trip and a server-side timer per copy, and it makes the caller
write `handle_event("copied", …)` and `Process.send_after` — for a 2-second
icon swap the server has no interest in.

So the pipeline learns to say it, rather than a one-component recipe absorbing
what the pipeline could not — which is what
[ROADMAP.md](ROADMAP.md) 7c warns about.

A choice whose condition a recipe declares client-owned now renders **both**
branches, each marked with the state it belongs to and the one the client does
not start in `hidden`. `measure.mjs` already skips a hidden node as "ready for a
client-side state change", so the parity check reads the two pages as the same
page — which is what makes the design a comparison rather than an exception.

`LiveBase.Clipboard` writes to the clipboard and swaps which branch is hidden,
and `owned_attributes/1` is `JS.ignore_attributes` over `hidden` inside the
button, so a patch during those two seconds does not put the server's guess
back. Nothing is pushed: the element dispatches `lb:copied` and `lb:copy-error`,
which is upstream's `onCopy` and `onError` without the round trip.

The recipe is `clipboard`, and it is two components: the parts are
presentational, and one button is not. What the button copies is a prop, because
React reads it off a context inside the click handler — a callback the reader
never sees, and a context a HEEx component does not have. Which is also the
honest answer for a secret: a value the page was never given cannot be copied
from the page.

`snippet` and `environment-variables` generate, and `snippet` is re-verified
with its React reference re-ported to the same default.

**Two things the browser found, and nothing else could.** `hidden` is
`HTMLElement`'s, and both branches are an `<svg>`: `element.hidden = false` set
a JavaScript property nothing reads and left the icon exactly as it was. The
snapshot could not see it — both icons are in the markup either way — and the
suite that clicks the button is what said so. It is `toggleAttribute` now.

And a connected socket is not a mounted hook. `page.goto` resolves on the
server-rendered HTML, `live.mjs` then waits for the socket, and the hook mounts
after that — so a click in between is dropped. The hook writes `data-lb-ready`
when it is listening, which a style sheet can read and the suite waits for.

**Commit:** `fix(spec): a prop read through a context or a condition`
**Commit:** `feat(ai-elements): a choice the client owns, and the clipboard`

### Phase 2: Re-read every AI Elements spec, and gate the reading — done

The free half, and it was free: 22 specs moved, and **`mic-selector` generates
with no work of its own** — the corrected shadcn specs are what it was waiting
for. It folds `command`'s markup in and comes out a listbox.

`mix ui.drift` said what moved before anything was regenerated: 18 attributes,
46 class strings, 34 parts, 12 variants, across nine components. The three
command-based ones account for most of it; the rest is a data attribute here and
a class string there.

Four generated components changed, and one changed what a reader sets eyes on:
`package-info`'s badge now writes `data-variant`, which is shadcn's and was
missing. The other three gained attributes upstream destructures.

`confirmation` lost three exported parts, and that is the re-read doing its job.
`ConfirmationRequest`, `ConfirmationAccepted` and `ConfirmationRejected` each
return `null` unless the context is in one particular state; the spec on disk
had them as wrappers that always render their children, which is not what
upstream draws. The reader no longer claims them. Phase 3 is where a fold
carries the recipe, and these three are the same question asked about a context
rather than a positioner.

Every AI Elements component whose spec moved is re-verified, and the record now
says exactly what the plan predicted: ten fail only `parity` and `pixel` for
want of a React reference, three have no example, and `mic-selector` joins them
as the fourth. `snippet` is the one that verifies.

The gate is in CI as a second step beside the shadcn one.

**The gate stays one per library, decided rather than left over.** `--source`
exists because AI Elements could not run at all, and now it can — but two gates
are still the right shape. Each library is published on its own, each fails for
its own reasons, and one registry going red must not take the other's gate with
it or hide behind it. The build says which library moved.

**Commit:** `fix(spec): re-read every AI Elements spec, and gate it in CI`

### Phase 3: A fold that carries behaviour, not only markup

The decision [ROADMAP.md](ROADMAP.md) records under M4 and nobody has made: a
component built out of behaving components needs the **recipes** to compose, not
the markup. Three components, one decision.

- `attachments` folds `shadcn/hover-card`: the positioner's props have to reach
  the popover recipe rather than land on an element as attributes
- `plan` folds `shadcn/collapsible` and `shadcn/card`: the disclosure recipe
  puts its trigger inside a `<button>` the card has already opened
- `environment-variables` folds `shadcn/switch`: the toggle loses `role`,
  `tabindex` and `aria-checked`, which axe reports and is right to

**Commit:** `fix(ai-elements): a fold carries the recipe, not only the markup`

### Phase 4: An example for the three that have none

An example is the fixture every check drives — `mix snapshot`, axe, parity and
pixel all render it. Three components have none, which is why their record shows
four failures rather than two.

- `Examples.attachments_default/1`, `environment_variables_default/1`,
  `plan_default/1`, and their entries in `Examples.components/0` and `all/1`
- A browser suite for the two with behaviour, as `task.spec.mjs` is one
- `mix snapshot` and axe green for all three

**Commit:** `feat(storybook): an example for the three that had none`

### Phase 5: A React reference for every AI Elements component

The backfill. 14 files under `parity/src/examples/`, one per generated
component, ported from the matching `Examples` function — a port, not a second
design, per `parity/README.md`.

Every difference the check reports is a finding about the **reader**. Correct it
in `tools/lib/live_shadcn_tools/`, never in the reference. When a comparison
fails, read the outline the failure attaches before anything else.

- One reference per generated component, oldest-generated first
- Every reported difference corrected in the reader or the recipe
- A pixel budget decided for each: gated at zero, a measured budget, or a skip
  with its reason. Never pending-and-forgotten
- `mix ui.verify` reports every generated AI Elements component verified

**Commit:** `test(parity): a React reference for every AI Elements component`

### Phase 6: The gap tests cover both registries

`parity.spec.mjs` has a test called *every example has a React reference*, and
it is filtered to shadcn — `pixel.spec.mjs` filters its undecided list by which
examples are ported. So the ten missing AI Elements references were skipped by
both, silently. That is the shape of check this repository refuses everywhere
else, and it is only safe to widen once phase 5 has filled the gap.

- Drop the `source === "shadcn"` filter in `parity.spec.mjs`
- Make `pixel.spec.mjs` name an unported example rather than skip it
- A new AI Elements component with no reference turns the suite red

**Commit:** `test(parity): the gap tests cover both registries`

### Phase 7: Three components filed under the wrong recipe

Not reader gaps. The inventory assigns a recipe and these three do not fit the
one they were given.

- `model-selector` and `voice-selector`: *no Positioner part, so it is not a
  listbox*. They render a command **dialog**, not a popup anchored to a trigger
- `artifact`: *no Trigger part, so it is not a disclosure*
- Each is either re-filed in `registry/INVENTORY.json` or recorded as a non-goal
  with its reason

**Commit:** `fix(inventory): the recipe three components are built on`

### Phase 8: The nine the generator meets an undeclared name in

Each stops with *the generator met `x`, which the component never destructured*
—
an expression the markup reads and the component's signature never introduced.
One decision each, not one change for all nine.

`code-block` (`preStyle`), `commit` (`date.toISOString()`), `connection` and
`context` (template literals), `image` (`props.alt`), `open-in-chat`
(`providers.chatgpt.createUrl(query)`), `queue` (`orientation`), `speech-input`
(`[0, 1, 2]`), `transcription` (`segments`).

- Read the nine and group them: a prop the caller passes, a value the reader
  should compute, or a non-goal
- Land the groups, splitting this phase per group

**Commit:** `feat(ai-elements): markup that reads an undeclared name`

## Risks & Tradeoffs

- **Phase 5 is the long one.** shadcn's equivalent was 51 references and it
  found real defects in the reader every time. Budget for the same here: the
  references are the cheap part and the corrections are not.
- **Phase 3 may want a shared mechanism rather than three fixes.** If the
  positioner, the trigger and the switch all need the same thing — the folded
  part's recipe rather than its markup — the phase is one change to the fold and
  not three patches. Decide after reading all three, not before.
- **Phase 1's hook adds client state to a package that had almost none.**
  `LiveBase.Clipboard` is small, but it is the first hook whose only job is a
  browser API rather than a measurement. Stated rather than hidden.
- **Phase 2 will demote components.** A spec that moves invalidates its
  verification, which is the mechanism working; the phase is not finished until
  each one is verified again.
- **Nothing here makes `live_ai_elements` publishable.** Its version is
  `0.1.0-dev` and 22 of 49 components have no spec. This plan makes what exists
  trustworthy, which is the prerequisite, not the release.

## Decided

- **A component upstream builds on a React library gets a hex search before it
  gets a line of code**, and the search is recorded whichever way it goes — but
  only where a library would do real work. A browser API is not a hex question,
  and `live_base` takes one dependency by an existing non-goal. See *Look for it
  on hex before building it, where that is a real question*.
- **`environment-variables` keeps the switch, and the server owns
  `show_values`.** It masks a secret by changing text, not styling, so the
  question was never which control to draw — it was who is allowed to know the
  value. Phase 1 and phase 3 land it together.
- **The spec gate is one per library.** Each is published on its own and fails
  for its own reasons, and neither should hide behind the other.

## Open Questions

- **What is the pixel budget policy for a component whose upstream needs a
  React library to draw?** `chart` set the precedent — a recorded skip with its
  reason — and several AI Elements components may land in the same place. The
  hex search above changes this: where a LiveView package already draws the
  thing, the two sides may be comparable after all, and a skip would be giving
  up early.
