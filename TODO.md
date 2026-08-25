# To do

The checkbox form of [PLAN.md](PLAN.md), which holds the reasoning. Only work
that has not been done is listed here; what is finished is in
[ROADMAP.md](ROADMAP.md) and in the git history.

Scope is shadcn parity. AI Elements is M4 in the roadmap and Ouro is M5, and
neither belongs here.

**62 of 62 shadcn components generate and verify.** One item is left, and it
needs an account rather than code.

## 1 — Publish 0.1.0

Each step needs an account. [DEFERRED.md](DEFERRED.md) is the guide.

- [ ] Publish to hex — needs a `HEX_API_KEY` secret under a `hex` environment
- [ ] Deploy the storybook — needs `CLOUDFLARE_API_TOKEN`,
      `CLOUDFLARE_ACCOUNT_ID` and a `SECRET_KEY_BASE` worker secret
- [ ] Prove the sync bot with one `Sync upstream` run by hand, and read the pull
      request body before the diff

## Watch, rather than do

Not work, and not finished either. Each is a decision that is recorded and
whose cost is stated, and each has one thing that would reopen it.

- **`chart` is hand-written.** Its spec is typed and its example is not
  pixel-compared, both with reasons, in
  [ROADMAP.md](ROADMAP.md#chart-is-hand-written-and-this-is-the-reason).
  Reopen it if `mix ui.drift` ever needs to report a chart change, because it
  cannot today.
- **AI Elements specs are stale on purpose.** Re-reading them deletes
  `question`, `snippet` and `environment-variables`, whose `useRender` state
  keys have no answer yet. That is why `mix ui.spec --check` runs per registry.
  Reopen it with M4.
