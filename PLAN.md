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

The decision [ROADMAP.md](ROADMAP.md) records under M4 and nobody had made: a
component built out of behaving components needs the **recipes** to compose, not
the markup. Three components — and they turned out to be three different faults,
not one, which is why none of them needed a composable recipe layer.

**`plan` was a reader bug.** Upstream writes `<CollapsibleTrigger asChild>` and
`<CollapsibleContent asChild>`; `asChild` is shadcn's spelling of Base UI's
`render` prop, and it says the element and the one inside it are **one**
element. The reader knew the Base UI name and not this one, so it deleted the
word as a React prop and kept the nesting. That one fault produced every
symptom: a `<button>` inside a `<button>`, a `plan_content` that was an empty
`<div>` beside the content it was meant to hold, and `trigger_class` merged onto
the wrong element. `checkpoint` and `mic-selector` each had a nested button from
the same cause.

The outer element keeps its identity — a recipe finds its trigger by the Base UI
part that element draws — and everything a reader sees comes from the inner one.
`ref` went with it: React's handle on a DOM node, written out as an HTML
attribute.

**`attachments` was `menubar`, one registry over.** Its three hover-card parts
are wrappers that add two defaults and a class string between them.
`presentational` already refuses to write a wrapper around a component whose
recipe folds — `menubar` exports thirteen of them — because those parts have to
agree about one id and no single part can be named. The only new thing here is
that the component to compose lives in the other package, where it is the
application's own copy. So the fold refuses, the part is dropped, and the
moduledoc says what to compose. `LiveShadcnTools.carries?/2` is the table that
decides it: a component *is* what it folds when its recipe carries that
behaviour — `task` and `plan` are collapsibles, `mic-selector` is a listbox drawn
inside a popover.

Three broken functions are gone, one of which wrote `align`, `alignOffset` and
`sideOffset` as HTML attributes on a `<div>` and self-closed the popup. A caller
who called it got a broken page; a caller who cannot find it reads one sentence
and composes `<.hover_card>`.

**`environment-variables` is the one that needed a recipe to reach a fold**, and
it needed no layer either. The switch recipe's contract is attributes — `role`,
`tabindex`, `aria-checked`, `data-checked` — and the `clipboard` recipe writes
them over the folded markup with `Tree.put_attrs_at_slot/3`, which is how the
switch recipe already decorates its own thumb. Not shadcn's behaviour, which
toggles a hidden input on the client: this switch reveals a secret, so it pushes
`on_toggle` and the server answers, which is the trade phase 1 stated.

`showValues` is a `:boolean` now rather than a `:string` holding a yes-or-no. A
field read off a React context is a prop — phase 1a decided that — and its
**type** is in the context's own interface, which the reader now reads through
`createContext<T>`. It read type aliases and not interfaces, so every
`interface Ctx { … }` in either registry was a definition nobody had.

**What this phase did not answer.** A behaving component referenced from inside
a bigger tree still folds as markup: `checkpoint` renders a tooltip no recipe
writes behaviour for, and `context` does the same. Neither is a wrapper, so
neither is dropped, and the honest fix is the composition layer this phase found
it did not need three times. Recorded rather than half-built.

**Commit:** `fix(ai-elements): a fold carries the recipe, not only the markup`

### Phase 4: An example for the three that have none — done

An example is the fixture every check drives — `mix snapshot`, axe, parity and
pixel all render it. Three components had none, which is why their record showed
four failures rather than two. It shows two now, and both are phase 5's.

The attachments example composes the application's own `<.hover_card>` around a
part of the dependency, which is exactly what phase 3 said a caller would do —
so the sentence in that moduledoc is now something a page demonstrates rather
than something a moduledoc claims. It is aliased rather than imported, because
`LiveShadcn.UI.Attachment` exports an `attachment/1` too and two registries
drawing an attachment is a fact about upstream rather than a collision.

`show_values` is an assign the preview LiveView owns, and the switch pushes
`toggle_values` to move it. An example that held it on the client would be
demonstrating something the component deliberately does not do.

Two browser suites, in the shape of `task.spec.mjs`, and between them they hold
the three decisions this plan made:

- `plan`: the trigger is **one** button, opening costs no round trip, and axe is
  clean open and closed
- `environment-variables`: the toggle is a switch a keyboard can reach, the
  secret **is not in the page** before it is asked for, flipping asks the server,
  and copying asks nobody

That second one is a negative test on purpose. A component that rendered the
secret and hid it would pass every other test on the page.

**Commit:** `feat(storybook): an example for the three that had none`

### Phase 5: A React reference for every AI Elements component — done

The backfill: thirteen files under `parity/src/examples/`, one per example with
a component behind it, ported from the matching `Examples` function.

Every difference the check reported was corrected in the reader or the recipe,
and there were nine of them. They are worth listing, because every one had been
generated, snapshotted, reviewed and shipped without anything noticing:

1. **A trigger's default markup was never drawn.** `{children ?? <div>…{title}…</div>}`
   was guarded by `@inner_block == []`, and a folded component's one slot
   belongs to its panel — so the guard asked about the panel and skipped the
   icons. Where the fallback contains the value, it *is* the markup and is
   drawn always; where it does not, it is the fallback for a title nobody gave.
2. **A prop the fold's call site chose was thrown away.** `<Badge variant="secondary">`
   is neither markup nor the badge's own default; it is what this component
   draws a badge with, so it is the generated attribute's default. `package-info`
   drew its change-type badge grey.
3. **A `cva` group behind a spread was frozen at the table's default.**
   `<Button disabled={…} type="submit" {...props}>` forwards `size`, and
   `question_submit` wore `cn-button-size-default` as a literal while declaring
   a `size` attribute that did nothing.
4. **One name meant two things.** `attachments` reads a layout `variant` — grid,
   inline, list — off a context and renders `<Button variant="ghost">`. Both
   became `@variant`. A literal on a name the component already spends is
   written into the class string instead, and the name keeps its meaning.
5. **An icon's size was written nowhere.** lucide's `size` prop is the `width`
   and `height` attributes, and as *attributes* rather than a class, which is
   the difference between 12px and 16px on the next component: shadcn styles an
   icon inside a button with `[&_svg:not([class*='size-'])]:size-4`, so a class
   disables that rule and an attribute loses to it.
6. **A list of class strings was read as no class string at all.** `attachments`
   writes its list and inline variants as arrays, and an attachment in a list
   came out with no border, no padding and no row.
7. **The caller's class was merged in two places.** A folded component merges a
   `className` prop; whether this component ever hands it one is a different
   question. `suggestion`'s scroll area was 448px wide where upstream's is 720.
8. **A folded component's own recipe stayed behind.** `Gen.Decorate` applies it
   where the whole contribution is attributes on a named slot — `separator`
   renames `orientation` to `data-orientation`, and `checkpoint` drew a
   separator zero pixels wide without it.
9. **A closed popover took up space.** The recipe's wrapper and its portal are
   `display: contents` now: Base UI renders no element for the root and portals
   the popup to the body, and an empty `<div>` between a trigger and its
   neighbour is a flex item — eight pixels of one, in an attachment list.

**Three differences are decisions rather than defects**, and they are recorded
in `parity-divergence.json` by the slot they show up on, so every other slot on
the same page still gates at zero:

- `plan` — AI Elements writes `asChild`; this shadcn build is Base UI, whose
  equivalent is `render`. Upstream therefore draws a `<button>` inside a
  `<button>`, which axe reports and is right to. Taking `asChild` at its word is
  a decision against upstream's own page, and the pixel check skips this one
  example for the same reason.
- `chain-of-thought` — upstream renders two collapsibles threaded by a React
  context, and the disclosure recipe folds a component into one function
  precisely because its parts have to agree about one id.
- `suggestion` — the scroll area is folded as markup and its recipe owns a hook,
  which is the half of phase 3 that was recorded rather than built.

Every other example gates at zero on both checks, and `streamdown` is shimmed on
the React side because the markdown renderer is the application's decision and
comparing two of them compares neither component.

**Two components had no example at all**, and each answered differently.
`mic-selector` gained one and verifies; its device list is the caller's here and
`navigator.mediaDevices` upstream, which a headless browser has none of, so it
is recorded beside the `asChild` divergence it shares with `plan`.
`open-in-chat` does not generate at all: every one of its twelve parts is a
wrapper around a part of `dropdown-menu`, and what is left once they are dropped
is a module whose one function renders its own children. That is a sentence
saying which component to compose, and [ROADMAP.md](ROADMAP.md) is where it now
lives.

**76 of 76 generated components verify.** The plan began with one.

**Commit:** `test(parity): a React reference for every AI Elements component`

### Phase 6: The gap tests cover both registries — done

`parity.spec.mjs` had a test called *every example has a React reference*, and
it was filtered to shadcn; `pixel.spec.mjs` walked past an unported example with
a bare `continue`. So the twelve missing AI Elements references were skipped by
both, silently. That is the shape of check this repository refuses everywhere
else, and it was only safe to widen once phase 5 had filled the gap.

The filter is gone, and an unported example is now a **skip with a reason** in
the pixel run rather than a test that was never registered. Moving one reference
out of the directory was the check: the gap test fails and names
`task.default`, and the pixel run reports it skipped for want of that file.

**Commit:** `test(parity): the gap tests cover both registries`

### Phase 7: Three components filed under the wrong recipe — done

Not reader gaps. The inventory assigns a recipe and these three did not fit the
one they were given. All three are filed `presentational` now, and what that
turned up was not what the filing predicted.

**`artifact` is a panel, and it verifies.** It has no trigger because it is not
a disclosure: a header, a title, a description, actions and a body. Filed
correctly it generates eight parts, and it is the twelfth AI Elements component
in the verified column.

**`voice-selector` is not a command dialog either.** Eleven of its parts are
wrappers around `<.dialog>` and `<.command>`, and the eight that are left are
its own: a name, a description, an age, an accent, a gender, a bullet and a
preview. It generates. It does not verify yet, and the reason is worth keeping:
`VoiceSelectorGender` computes an icon from a value in an `if` chain, which the
reader turns into a prop typed `:string` — so the icon cannot be passed. That is
the same gap `artifact_action` has, and it is the next piece of work.

**`model-selector` stops on a template literal.** `alt={`${provider} logo`}` —
a string with one interpolation, which the reader reads only when there is
nothing to interpolate. Phase 8's list is where it belongs.

Two more came out of the same pass. **`open-in-chat` does not generate at all**
and is recorded in [ROADMAP.md](ROADMAP.md) as a non-goal: every one of its
twelve parts is a wrapper, and what is left once they are dropped is a sentence
rather than a component. **`prompt-input` is refused rather than generated
wrong**: it renders five shadcn components it cannot name, and until the fold
carries them it says so. It had been generating those calls into a module no
application could compile — a hole this pass found and closed.

A part that a fold left empty is dropped now, and only when both halves are
true: it draws nothing, *and* something folded into it renders no element. A
React context provider that upstream needs and this does not is somebody's
public API, and removing it is a different decision.

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

Seven of the nine are done and each landed as its own commit. Five were the same
answer — the caller passes it — which is the answer every React context in this
registry gets, because a HEEx component has no ancestor to ask. Two are recorded
non-goals. `context` is the one left, and it is a formatting question rather
than a reader one: `Intl.NumberFormat` writes `1.2K` and `$0.02`, and Elixir has
neither in its standard library.

### Phase 9: The reader's own gaps, closed with the parser it already has

Phase 8 was about names the generator met. This is about expressions the reader
refused, which is the stage before: seventeen components never reached the
generator at all.

The reader decided whether `{…}` was a value by matching it against three
regular expressions. Each had been widened at least once, and a widened regular
expression says less each time about where the line now is. oxc has already read
the file, so the question goes to it: is every node in here a name, a literal, an
operator, or a call to a method this pipeline can write in Elixir? The method
list is short and closed, and a name goes in it in the same change that writes
its Elixir — a reader that accepts what the generator cannot write moves a gap
from one report to another rather than closing it.

Eight components read and generate that did not: `agent`, `code-block`,
`file-tree`, `inline-citation`, `schema-display`, `stack-trace`, `test-results`
and `web-preview`. Three findings came with them:

- **`stack-trace` is a clipboard component.** The fourth to write
  `useState(false)`, `navigator.clipboard.writeText`, and an icon chosen on the
  flag. Filed presentational it stopped at a name nothing declares.
- **JSX's text rule is not `String.trim/1`.** A line break is layout and JSX
  drops it; a space beside an expression is content and JSX keeps it. Trimming
  both drew `100 %` where upstream draws `100%`.
- **A call to a sibling that did not generate is a call to nothing.** `agent`
  renders `code-block`, and while `code-block` has no recipe the package stopped
  compiling. `reachable!/1` refused a call into another package and nothing
  refused one inside it.

**Commit:** `feat(spec): ask oxc what an expression is`

### Phase 10: The rest of them, one decision each

Nine components were left, and each wanted a decision rather than more reader.
All nine are made.

**Three are somebody else's runtime, and are non-goals.** `persona` is a Rive
WebGL2 canvas — one element, everything drawn into it, nothing that is markup.
`jsx-preview` compiles a JSX string at render, which is the injection this
pipeline is built to avoid. Both join `open-in-chat` and the React Flow family
in `ROADMAP.md`.

**Three are a library the page loads, and the markup is still markup.**
`audio-player` is media-chrome, whose React package renders custom elements —
`<media-play-button>` is HTML, and a HEEx template writes it. `conversation` is
`use-stick-to-bottom`, which is a box that scrolls and keeps itself at the
bottom: the `scroller` recipe already owns that, once a scrollbar of its own
stopped being required. `terminal` is `ansi-to-react`, and turning escape codes
into spans is a job Elixir already does — so it gets the seam the markdown
renderer has, `LiveAiElements.Ansi`.

**One is an animation, and animation is behaviour.** `shimmer` moves
`background-position` with `motion`, which calls the Web Animations API.
`LiveBase.Shimmer` calls the same API with the same two keyframes, read off
`initial` and `animate` — a `@keyframes` rule would have been a style rule
typed by a person, which is the one thing this project does not do.

**Two were arithmetic.** `code-block` masks a shiki bit field three times, so
the reader inlines a one-line value helper and the generator writes the mask out
— JavaScript reads a zero as false and Elixir does not, and every token would
have come out bold. `context` writes `1.2K` and `$0.02` with
`Intl.NumberFormat`; Elixir's standard library has neither and CLDR is a large
dependency for two shapes whose locale upstream hard-codes, so the module
carries the two functions the way it already carries `variant_class/3`.

Four findings the checks made along the way, each fixed at the source:

- **A class string can come from a plain table.** `methodStyles[method]` inside
  `cn()` is `cva` written plainly, and dropping it took the colour off every
  method a schema draws.
- **A `<pre>` indented like any other element prints the indentation.**
- **A part that calls a sibling has to hand it what upstream put in a context.**
  `terminal`'s own header drew an empty box because the output stopped at the
  root.
- **A recipe keyed by a Base UI part reaches every element that draws it.**
  Both of `terminal`'s buttons fold shadcn's `Button`, so the clipboard hook
  landed on the clear button too.

**Commit:** `feat(ai-elements): the last nine, one decision each`

### Phase 11: Nothing generated and unverified

**100 verified, and nothing left in between.** Every component this pipeline
generates now has an example, a React reference it is compared against, a markup
snapshot, an axe run and a pixel comparison. The eleven that are not verified are
the eleven recorded non-goals, and `mix ui.status` reads `0 generated`.

The last four were each one thing:

- **`file-tree`** wanted the ARIA the roles it already writes imply. A
  `role="treeitem"` has to be owned by a `tree` or a `group`, and upstream wraps
  its own in plain boxes; the chevron is a button with an icon and no words. The
  recipe adds two groups, a `role="none"`, an `aria-expanded` the folder already
  takes, and takes the chevron out of the accessibility tree — the row's other
  button already opens the folder, and naming the chevron would mean writing
  English. This was the decision recorded as open in phase 10, and it turned out
  not to be a decision between the axe floor and "markup is never typed by hand":
  every one of those attributes follows from a role upstream wrote.
- **`schema-display`** was the example rather than the component. It composed
  the parts without the root they belong in, and that root has a border.
- **`terminal`** was the `<pre>`. Indented like any other element it prints the
  indentation, and the line it gained was the newline before its own content.
- **`prompt-input`** is twenty-two wrappers around a menu, a select, a hover
  card and a command palette, and thirteen parts that are its own. The
  form-control recipe drops a wrapper the way the presentational recipe already
  did.

Three findings came with them, each fixed at the source:

- **A guard is a fact about the whole part.** `if (!isStreaming) return null` at
  the top of a render is markup that does not exist, and dropped it made
  `terminal`'s status an empty box in a header laid out with `gap-1`.
- **`!` binds tighter in Elixir than in JavaScript, and only where upstream
  bracketed it.** `!(variant === "grid")` and `!isProcessing && isListening` are
  different questions and were being written as the same one.
- **A `cva` table is the base, not the override.** `cn(variants({align}),
  "justify-between", className)` is the order upstream writes, and the generator
  had the table last.

One thing is left, and it is general rather than per-component: the class list is
not merged at render. `prompt-input`'s footer is where it shows.

**Commit:** `feat(ai-elements): nothing generated and unverified`

### Phase 12: The eleven that were not components after all

Phase 11 ended with eleven recorded non-goals and a claim that each was
somebody else's runtime, a string of markup, or a sentence about which component
to compose. Ten of the eleven were wrong, and each was wrong in the same way:
the entry described what the *library* does and not what the *file* draws.

- **Six React Flow files are a box and a class string.** `controls`, `panel`,
  `toolbar` and `node` are a `<div>` with the classes AI Elements writes over
  React Flow's own; `canvas` is that box and the background pattern behind it;
  `edge` is a `<path>`. What the library owns is where a thing sits and the
  geometry between two nodes — so an edge takes its path as an attribute, the
  way `code-block` takes its tokens.
- **`connection` is not React Flow at all.** Four numbers and a bezier written
  in a template literal, which is arithmetic.
- **`persona` is one `<canvas>`.** The Rive runtime paints into it, the way
  media-chrome upgrades a `<media-play-button>`.
- **`jsx-preview`'s content is the caller's.** `renderInWrapper={false}` is
  upstream saying it draws no element of its own, and what a server cannot
  compile is exactly what a slot is for.
- **`open-in-chat` is twelve links.** `<DropdownMenuItem asChild><a href={…}>`
  is one element and it is the link — a logo, a title and a query string. Read
  as twelve references to a menu it was a component with nothing in it, which is
  what the old entry said about it.

The eleventh is `direction`, and it is a re-export with no JSX in it. There is
nothing to generate, which is a fact about the file.

Nine findings came with them, each fixed at the source: a component that hands
its children back draws no element; a choice between two of those is not a
choice about markup; an object export is several components under one name; a
`-` is an operator; a bracket a person wrote holds an expression together; a
`?` and a `:` inside a template literal are not a ternary; `${…}` ends at the
brace that matches; a named number is a literal; and a prop with arithmetic
beside it is not a string.

**110 of 111 verified.**

**Commit:** `feat(ai-elements): the eleven that were not components after all`

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
