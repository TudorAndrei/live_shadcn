# Publication and deployment

The current assignment prepares a release. Publication and deployment follow
after the [release completion checks](docs/plans/release-completion/TODO.md)
pass. The checkpoint is on GitHub. Accounts are not the only remaining work.

## Required acceptance

Before creating a release tag, require all 64 shadcn comparison targets to have
current evidence. Check the three documentation families and retain Direction
as No DOM. Prove installation with built package files in a clean Phoenix
application. Prove compiled badges in a clean Storybook release image.

Run these commands in `tools/` after the final source changes and verification:

```bash
mix ui.spec --check --offline --source shadcn
mix ui.status --check --source shadcn --require-verified
```

These commands inspect stored evidence. They do not replace the full browser
run. The release workflow repeats the strict evidence check before publication.

## Package publication

The release workflow publishes `live_base`, then `live_shadcn`. It requires
`HEX_API_KEY` in the GitHub `hex` environment. The `v*` tag must match both
package versions. Local package builds use `HEX_PUBLISH=1 mix hex.build` to
check version dependencies without publishing.

Create a release tag only after explicit release authorization. A tag starts
publication. If Base publishes but shadcn fails, inspect the published versions
before rerunning the workflow. Do not assume the operation was atomic.

AI Elements remains experimental and is not in this publication workflow.

## Storybook deployment

The maintained deployment uses Fly. The `deploy` job in
`.github/workflows/ci.yml` runs after all required jobs pass on a push to `main`.
It uses `FLY_API_TOKEN` from the GitHub `storybook` environment and
`storybook/fly.toml`. A successful push to main can therefore deploy.

The Fly application needs its runtime `SECRET_KEY_BASE`. Its configured
`PHX_HOST` must match the public host so that LiveView sockets can connect.
Keep secret values outside the repository. Build context is the repository
root. The workflow uses this command:

```bash
flyctl deploy --remote-only -c storybook/fly.toml .
```

The optional Cloudflare files remain in `storybook/deploy/`. They are not the
current CI deployment path. There is no separate `Deploy storybook` workflow.

## Upstream synchronization

`.github/workflows/sync-upstream.yml` fetches pinned source inputs, synchronizes
safe facts into reviewed ports, verifies shadcn, and prepares a pull request.
Structure or behavior changes require manual port review. The old `ui.gen`
workflow no longer defines component ownership.

A real upstream update and its reviewed pull request are later operational
proof. Do not advance source pins to complete the current release checks.
