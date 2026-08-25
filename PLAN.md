# Plan

What is left. Everything that is finished is recorded in
[ROADMAP.md](ROADMAP.md) and in the git history; this page holds only work that
has not been done. The checkbox form of this page is [TODO.md](TODO.md).

**Scope: shadcn parity, and nothing else.** AI Elements and the Ouro
integration are out of this plan. [ROADMAP.md](ROADMAP.md) holds both — M4 for
AI Elements, M5 for Ouro — and each is a plan of its own when its turn comes.

## Where this stands

62 of 62 shadcn components generate. `mix ui.verify` makes five checks —
`generated`, `snapshot`, `browser`, `parity`, `pixel` — and all five are green
for 61 of them. The exception is `calendar`.

The pixel census covers 66 examples. 64 are gated at zero differing pixels, one
carries a measured budget (`scroll-area.default`, 137 px of glyph
rasterisation), and one is `pending`: `calendar.default`. A `pending` example
still runs and still prints its difference; it is measured and reported, but not
yet gated.

`mix ui.gen --check`, `mix ui.status --check` and `mix snapshot --check` are
green on a clean tree, and CI runs all three.

Four jobs are left. One of them closes the last pixel gap, one is a recipe
cleanup, one is a test-harness problem, and the last needs an account rather
than code.

---

## 1 — The calendar: a correct structure, an incorrect class

This is the only `pending` pixel example, and the only shadcn component that
does not verify.

The structural half is done. The reader now reads **25 of the 29 class strings**
out of the `classNames` prop that shadcn hands react-day-picker, where it read
four before. `nav` is a sibling of `month` positioned over it, as upstream
builds it, every wrapper sits at the coordinates React puts it at, and the
chevrons are the lucide icons upstream renders.

The number did not improve: 8,077 px → 9,261 px. A correct structure exposed an
incorrect class, and that is what is left.

### 1a — Resolve `buttonVariants({variant})` inside a `cn()` call

Upstream writes:

```tsx
button_previous: cn(
  buttonVariants({ variant: buttonVariant }),
  "size-(--cell-size) p-0 …",
)
```

The reader keeps only the string literals in that call, so the class is recorded
without anything the `cva` table contributes. The nav button comes out 32×32
where upstream draws 32×36.

The reader already resolves a `cva` call elsewhere. This is teaching it to do so
one level in, inside the arguments of a `cn()`.

The rule this work established is worth restating, because it was learned by
breaking it: **a class the reader can only partly read is one it must not
claim.** Taking the string literals alone shipped a 7×24 button. A confident
wrong answer is worse than none.

### 1b — The grid still lays itself out

`gen/calendar.ex:70` and `:75` write `style="width: 19px"` onto every `th` and
`td`. The grid comes out 141.7 px wide against React's 133.2 px.

That typed measurement is the last one in this recipe, and it is the sign that
the recipe still lays the grid out itself instead of reading how
react-day-picker lays it out. Remove the measurement, not the difference.

### 1c — Four class strings are still typed by hand

`previous_button`, `next_button`, `root` and `day_button` in
`registry/spec/shadcn/calendar.json` are typed rather than read. Each is a
`cn()` whose arguments the reader can only partly read, so it refuses them under
the rule in 1a. Item 1a is what releases them.

There is a second rule from the same work, and it is a defect the reader would
have kept hiding: **a parsed class fills a gap; it does not overwrite one.**
`preserve_recipe_facts` replaced the whole map, so once a class was typed by
hand, no amount of teaching the reader could dislodge it — the calendar learned
to read 25 strings and went on reporting the 4 typed ones, silently, because the
reader's answer was computed and then thrown away. Keep the fill-a-gap
direction when 1a lands, or 1a cannot be seen to work.

**Done when** `calendar.default` leaves `pending` and is gated, and
`mix ui.verify shadcn/calendar` passes all five checks.

---

## 2 — The toast recipe reads upstream by its styling

`gen/toast.ex:189` finds a part by matching a hard-coded Tailwind class string:

```elixir
helper!(toaster["tree"], &(&1["class"] == "flex min-w-0 flex-1 flex-col gap-1"))
```

It is the last recipe that identifies an upstream part by how it is styled
rather than by what it is, and it breaks the moment upstream reflows that
string — silently, because a class string that no longer matches simply finds
nothing.

Find the part by its anatomy, as every other recipe does. This is the last
outstanding case of the roadmap's non-goal: *if a class string is typed by a
person, the pipeline has a gap.*

---

## 3 — Three suites fail under load and pass alone

`select`, `dialog` and `popover` each have Escape-key and measurement tests that
fail in a full run and pass in isolation. `workers: 1` is already set in
`playwright.config.mjs`, so this is not parallelism — it is timing under
sustained load.

Diagnose before changing a timeout. A test that needs a longer wait under load
is usually a test that waits for the wrong thing; `measure.mjs` already owns the
settle discipline that the behaviour specs should be reusing.

---

## 4 — Publish 0.1.0

Not code. [DEFERRED.md](DEFERRED.md) is the full guide, and every step there is
blocked on an account rather than on work:

| Step | Blocked on |
|---|---|
| Publish to hex | a `HEX_API_KEY` repository secret under a `hex` environment |
| Deploy the storybook | `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, and a `SECRET_KEY_BASE` worker secret |
| Prove the sync bot | one `Sync upstream` run by hand, and a readable pull request |

Do this after item 1, so that what is published tells the truth about its own
coverage.

---

## Verification

Run this at each boundary. It is the list in
[CONTRIBUTING.md](CONTRIBUTING.md):

```bash
# in each of tools/, packages/*/ and storybook/
mix format && mix compile --warnings-as-errors && mix test

cd tools && mix ui.gen --check && mix ui.status --check
cd ../storybook && mix snapshot --check
cd test/browser && npm run verify        # behaviour, axe, parity and pixels
```

A `--check` failure is the purpose of the gate. It means a generated file no
longer agrees with what its spec produces, because the spec moved or because
somebody edited the output.

The browser half runs locally, never in CI. CI checks the **record**:
`mix ui.status --check` refuses an inventory whose verification no longer
matches the specs on disk, so a spec that moves without a fresh
`mix ui.verify` demotes its component and turns the build red.

If a port this suite needs is held by something else, the run refuses before a
single test starts. Override it rather than guessing:

```bash
STORYBOOK_PORT=4201 PARITY_PORT=4202 mix ui.verify shadcn/calendar
```

## Files that will move

| Path | Which item |
|---|---|
| `tools/lib/live_shadcn_tools/tsx.ex`, `spec.ex` | 1a — resolving a `cva` call inside `cn()` |
| `tools/lib/live_shadcn_tools/gen/calendar.ex` | 1b — the typed `width: 19px` |
| `registry/spec/shadcn/calendar.json` | 1c — generated. Regenerated, never edited |
| `tools/lib/live_shadcn_tools/gen/toast.ex` | 2 — find the part by anatomy |
| `storybook/test/browser/*.spec.mjs` | 3 — the settle discipline |
| `registry/snapshot/`, `registry/VERIFY.json`, `docs/INVENTORY.md` | generated. Regenerated, never edited |
| `ROADMAP.md`, `DEFERRED.md`, `CONTRIBUTING.md` | the record |
