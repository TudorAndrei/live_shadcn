# Deferred

Work that is written and checked but not carried out, because each step needs an
account rather than more code.

Everything here is the remainder of [M3](ROADMAP.md#m3--publish-010).

| Step | Blocked on | Where the code is |
|---|---|---|
| Push to GitHub | a push | the repository is unpushed |
| Publish to hex | a hex API key | `.github/workflows/release.yml` |
| Deploy the storybook | a Cloudflare token | `storybook/deploy/` |
| Prove the sync bot | the push above | `.github/workflows/sync-upstream.yml` |

---

## 1. Push to GitHub

Nothing else here can run until this happens. The remote is
`git@github.com:TudorAndrei/live_shadcn.git` and the branch is `main`.

CI runs on the push: five package suites, the generated-output checks, and the
Playwright and axe-core suite in Chromium.

---

## 2. Publish to hex

Both packages build and pass `mix hex.publish --dry-run` today.

### Set up once

Add a repository secret named `HEX_API_KEY` under a GitHub environment named
`hex`. Get the key with:

```bash
mix hex.user key generate --permission api:write
```

### Release

The tag is the version, and the workflow refuses to publish if `@version` in
either `mix.exs` disagrees with it.

```bash
git tag v0.1.0
git push origin v0.1.0
```

The workflow reruns every check, then publishes `live_base` and after it
`live_shadcn`. That order matters. Under `HEX_PUBLISH`, `live_shadcn` depends on
`live_base` by version rather than by path, so the other order publishes a
package whose dependency does not exist. The second publish retries for two
minutes while hex's registry catches up.

### Before tagging 0.2.0 or later

Bump `@version` in both `packages/live_base/mix.exs` and
`packages/live_shadcn/mix.exs`, and add a section to each `CHANGELOG.md`.

### Cannot be undone

A hex release can only be retired after an hour, not removed.

---

## 3. Deploy the storybook

The image builds, runs, and serves styled pages. It has been checked end to end
locally. It has never been pushed to Cloudflare.

`storybook/deploy/README.md` is the full guide. The short version:

### Set up once

1. Two repository secrets under a GitHub environment named `storybook`:
   `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`.

2. A signing key, as a Worker secret. LiveView signs its socket with it and the
   release will not boot without one:

   ```bash
   cd storybook && mix phx.gen.secret
   cd deploy && npx wrangler secret put SECRET_KEY_BASE
   ```

3. The public hostname, in `storybook/deploy/wrangler.jsonc`:

   ```jsonc
   "vars": { "PHX_HOST": "storybook.example.com" }
   ```

   Phoenix checks the socket's origin against this. A wrong value gives a
   storybook whose pages render and whose components do nothing.

### Deploy

Run the `Deploy storybook` workflow. It is `workflow_dispatch` only.

### Or Fly, which is configured

`storybook/fly.toml` is the second target: one shared-cpu machine that stops
when nobody is reading and starts on the next request. The build context is the
repository root, because the storybook depends on the packages by path and its
asset build reads the registry beside them.

```bash
fly apps create live-shadcn-storybook
fly secrets set -c storybook/fly.toml SECRET_KEY_BASE="$(cd storybook && mix phx.gen.secret)"
fly deploy -c storybook/fly.toml .
```

Every one of them takes `-c`. `flyctl` reads the app name out of a `fly.toml` in
the working directory, and this one is a directory down — without `-c` it says
"the config for your app is missing an app name".

`PHX_HOST` is in the file rather than a secret — it is the public hostname, and
Phoenix checks the socket's origin against it. `--remote-only` is the default
worth knowing about on Apple Silicon: the image must be linux/amd64, and Fly's
remote builder is one. `.dockerignore` at the repository root says what the
upload leaves out, and `mise.toml` pins `flyctl`.

Neither target has been deployed.

### Do not deploy from an Apple Silicon Mac

Cloudflare Containers run linux/amd64, and `wrangler deploy` builds the image
wherever it runs. On arm64 that means emulation, and `mix local.hex` dies under
it with `failed_to_start_child,user,nouser` before anything compiles. The
workflow runs on an amd64 runner, which is why it exists.

To check the image locally, build it for your own architecture instead:

```bash
docker buildx build -f storybook/Dockerfile -t storybook:check .
docker run --rm -p 4199:4100 \
  -e SECRET_KEY_BASE="$(cd storybook && mix phx.gen.secret)" \
  -e PHX_HOST=localhost storybook:check
```

Open <http://localhost:4199>. Unstyled pages mean `mix ui.fetch --styles` failed
in the builder stage.

### What the build does that is unusual

The builder stage runs `mix ui.fetch --styles`. The shadcn styling layer is
git-ignored on purpose, because this repository records a digest per upstream
file rather than redistributing anybody else's source — so it is the one thing
the image needs that the branch does not carry. The specs, the generated modules
and the snapshots are all on the branch and are compiled as they stand.

`--styles` reads the commit out of `registry/UPSTREAM.json`, so what the image
carries is what the branch pins. Eleven anonymous requests, all to
`raw.githubusercontent.com`. If a build is ever rate-limited, put a token in
`image_vars` in `wrangler.jsonc` and do not commit it.

---

## 4. Prove the sync bot

The exit criterion is one real upstream change landing as a pull request whose
diff is readable.

The run itself works. Running it by hand is what found the fetcher storing
GitHub pages as Base UI documentation. What it has not done is open a pull
request, because nothing is pushed.

After the push, run the `Sync upstream` workflow by hand rather than waiting for
Monday. It fetches, respecs, regenerates, redraws the snapshots, runs the full
browser suite, and opens a pull request only if `registry/` or the generated
components moved.

Read the pull request body first. `mix ui.drift` compares specs and says whether
a class string moved or an attribute appeared. `git diff --stat` would say four
files and 807 lines, which is true and useless.

---

## Not deferred, just unscheduled

M4 through M6 in [ROADMAP.md](ROADMAP.md) are ordinary work with nothing
blocking them. M4 is next.
