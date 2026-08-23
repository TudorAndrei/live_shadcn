# Deploying the storybook

The storybook runs as one Cloudflare Container behind a Worker that does nothing
but hand every request to it. There is no routing to do: every reader sees the
same pages and none of them is behind a login.

| File | What it is |
|---|---|
| `wrangler.jsonc` | the Worker, the container, and which Dockerfile builds it |
| `src/index.ts` | the Worker — 40 lines, and the only hand-written code here |
| `../Dockerfile` | the image: a Phoenix release, built from the repository root |

## First deploy

Three things have to exist before the first `wrangler deploy`.

```bash
cd storybook/deploy
npm install
npx wrangler login
```

**A signing key.** The storybook holds no data and no session worth protecting,
but LiveView still signs its socket, and the release refuses to boot without
one:

```bash
cd ../ && mix phx.gen.secret          # copy the output
cd deploy && npx wrangler secret put SECRET_KEY_BASE
```

**The hostname readers will use.** Phoenix checks the socket's origin against
it, so a wrong value here is a storybook whose pages render and whose components
do nothing. Set `PHX_HOST` in `wrangler.jsonc` to the hostname you are
deploying to, before deploying:

```jsonc
"vars": { "PHX_HOST": "storybook.example.com" }
```

**An amd64 machine.** Cloudflare Containers run linux/amd64, and `wrangler
deploy` builds the image where it runs. On an Apple Silicon machine that means
emulation, and the BEAM does not survive it — `mix local.hex` dies with
`failed_to_start_child,user,nouser` before anything is compiled. Deploy from the
`Deploy storybook` workflow instead, which runs on an amd64 runner and needs two
repository secrets: `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`.

## What the build does that is unusual

The builder stage runs `mix ui.fetch`. The shadcn styling layer is git-ignored
on purpose — this repository records a digest per upstream file rather than
redistributing anybody else's source — so the image build reaches GitHub and
base-ui.com once, and the image carries the result.

That fetch is anonymous, and it works: only three of its requests go to
`api.github.com` and the rest go to `raw.githubusercontent.com` and
`base-ui.com`. If a build ever is rate-limited, put a token in `image_vars` and
do not commit it.

## Checking the image without deploying

The image is worth building on its own, and on an arm64 machine it builds
natively:

```bash
cd ../..                                        # the repository root
docker buildx build -f storybook/Dockerfile -t storybook:check .
docker run --rm -p 4199:4100 \
  -e SECRET_KEY_BASE="$(cd storybook && mix phx.gen.secret)" \
  -e PHX_HOST=localhost storybook:check
```

Then open <http://localhost:4199>. A page with no styling means `mix ui.fetch`
was skipped or failed, and the components will look like unstyled HTML.
