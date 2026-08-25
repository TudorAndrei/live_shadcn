# To do

The checkbox form of [PLAN.md](PLAN.md), which holds the reasoning. Only work
that has not been done is listed here; what is finished is in
[ROADMAP.md](ROADMAP.md) and in the git history.

Scope is shadcn parity. AI Elements is M4 in the roadmap and Ouro is M5, and
neither belongs here.

Item 1 closes the last pixel gap. Item 2 is a recipe cleanup, item 3 is a test
harness, and item 4 needs an account rather than code.

## 1 — The calendar

The only `pending` pixel example, and the only shadcn component that does not
verify. 9,261 px against upstream.

### 1a — Resolve `buttonVariants({variant})` inside a `cn()` call

- [ ] Read a `cva` call that appears as an argument of a `cn()`, not only on its
      own. The reader already resolves `cva` elsewhere
- [ ] The nav button draws 32×36, as upstream does, instead of 32×32
- [ ] Keep the rule: a class the reader can only partly read is one it must not
      claim

### 1b — The grid still lays itself out

- [ ] Remove `style="width: 19px"` from `th` and `td` in `gen/calendar.ex`
- [ ] The grid measures 133.2 px wide, as React's does, instead of 141.7 px

### 1c — Four class strings are still typed by hand

- [ ] `previous_button`, `next_button`, `root` and `day_button` are read from
      upstream, not typed into `registry/spec/shadcn/calendar.json`
- [ ] Keep the fill-a-gap direction in `preserve_recipe_facts`: a parsed class
      fills a gap, it does not overwrite one. Without this, 1a cannot be seen to
      work
- [ ] `calendar.default` leaves `pending` in `pixel-budget.json` and is gated
- [ ] `mix ui.verify shadcn/calendar` passes all five checks

## 2 — The toast recipe reads upstream by its styling

- [ ] `gen/toast.ex:189` finds its part by anatomy, not by matching the class
      string `"flex min-w-0 flex-1 flex-col gap-1"`
- [ ] No recipe identifies an upstream part by how it is styled

## 3 — Three suites fail under load and pass alone

`workers: 1` is already set, so this is timing under load, not parallelism.

- [ ] Diagnose the Escape-key and measurement failures in `select`, `dialog` and
      `popover` before changing any timeout
- [ ] The full browser run is green three times in a row

## 4 — Publish 0.1.0

Each step needs an account. [DEFERRED.md](DEFERRED.md) is the guide.

- [ ] Publish to hex — needs a `HEX_API_KEY` secret under a `hex` environment
- [ ] Deploy the storybook — needs `CLOUDFLARE_API_TOKEN`,
      `CLOUDFLARE_ACCOUNT_ID` and a `SECRET_KEY_BASE` worker secret
- [ ] Prove the sync bot with one `Sync upstream` run by hand, and read the pull
      request body before the diff
