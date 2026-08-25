# To do

The checkbox form of [PLAN.md](PLAN.md), which holds the reasoning. Only work
that has not been done is listed here; what is finished is in
[ROADMAP.md](ROADMAP.md) and in the git history.

Scope is shadcn parity. AI Elements is M4 in the roadmap and Ouro is M5, and
neither belongs here.

**Parity is reached**: 62 of 62 shadcn components verify on all five checks, and
65 of 66 pixel examples are gated at zero. Items 1 and 2 came out of reaching
it; item 3 needs an account rather than code.

## 1 — `mix ui.spec --check` is red, and no gate watches it

63 specs do not match what the reader produces from the same sources. Stale at
the commit before the calendar work too, so this is a hole in the record rather
than a regression.

- [ ] Run `mix ui.drift` and say what actually moved, before regenerating 63
      files
- [ ] Regenerate what should move, and verify every component the regeneration
      demotes
- [ ] Decide whether `ui.spec --check` can join CI. It cannot while three AI
      Elements components stop the reader, so either answer those three first or
      run the gate per registry
- [ ] A spec that drifts from its own source turns a build red

## 2 — One class string is still typed, and it is typed twice

- [ ] `gen/toast.ex` hand-writes `flex min-w-0 flex-1 flex-col gap-1` in the
      `sonner` heredoc. It is upstream's string, and the `toast` half of the
      same recipe reads it out of the spec
- [ ] Give the sonner half the same reading rather than its own copy of the
      anatomy
- [ ] No recipe holds a literal upstream class string

## 3 — Publish 0.1.0

Each step needs an account. [DEFERRED.md](DEFERRED.md) is the guide.

- [ ] Publish to hex — needs a `HEX_API_KEY` secret under a `hex` environment
- [ ] Deploy the storybook — needs `CLOUDFLARE_API_TOKEN`,
      `CLOUDFLARE_ACCOUNT_ID` and a `SECRET_KEY_BASE` worker secret
- [ ] Prove the sync bot with one `Sync upstream` run by hand, and read the pull
      request body before the diff
