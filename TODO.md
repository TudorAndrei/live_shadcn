# To do

The checkbox form of [PLAN.md](PLAN.md), which holds the reasoning. Only work
that has not been done is listed here; what is finished is in
[ROADMAP.md](ROADMAP.md) and in the git history.

Scope is shadcn parity. AI Elements is M4 in the roadmap and Ouro is M5, and
neither belongs here.

62 of 62 shadcn components generate and 61 verify. Item 1 is the one that does
not; item 2 needs an account rather than code.

## 1 — The chart is a hand-written component wearing a spec

Its spec has no parts and two hand-typed class strings, because the reader
refuses `chart.tsx`. Everything else here follows from that.

### 1a — Teach the reader `chart.tsx`

- [ ] An `@external_primitives` entry for `recharts` — `ResponsiveContainer`,
      `Tooltip` and `Legend`. Tried, and it works as far as it goes
- [ ] The `<style>` block is the one left: upstream builds it as a template
      string through `dangerouslySetInnerHTML`, which is a computation rather
      than markup
- [ ] `chart.json` has parts, and no class string in it is typed

### 1b — Three class strings are typed, and two of them are wrong

- [ ] `classes["container"]` is missing twelve `[&_.recharts-*]` selectors
- [ ] the tooltip's value is missing `text-foreground`
- [ ] the legend's item is missing `[&>svg]:h-3 [&>svg]:w-3
      [&>svg]:text-muted-foreground`
- [ ] No recipe holds a literal upstream class string

### 1c — The comparison cannot see any of it

`chart.default` is `pending` at 21,169 px because only one side draws:
`<ResponsiveContainer>` sizes its inner wrapper to 0×0 for anything that is not
a recharts element.

- [ ] Decide: give the reference a recharts element to draw and deal with the
      mount animation, or compare the chrome with an empty child and say the
      plot is the caller's
- [ ] `chart.default` leaves `pending` and is gated
- [ ] `mix ui.verify shadcn/chart` passes all five checks

## 2 — Publish 0.1.0

Each step needs an account. [DEFERRED.md](DEFERRED.md) is the guide.

- [ ] Publish to hex — needs a `HEX_API_KEY` secret under a `hex` environment
- [ ] Deploy the storybook — needs `CLOUDFLARE_API_TOKEN`,
      `CLOUDFLARE_ACCOUNT_ID` and a `SECRET_KEY_BASE` worker secret
- [ ] Prove the sync bot with one `Sync upstream` run by hand, and read the pull
      request body before the diff
