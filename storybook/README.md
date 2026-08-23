# Storybook

The demo application. It exists so a person can look at a component, and so
`mix ui.verify` has a real browser to drive.

```bash
mix setup          # deps.get, then npm install
mix phx.server     # http://localhost:4100
```

`mix ui.fetch` has to have run first. The styling is not written here: it is
shadcn's own, assembled from the sheets in `registry/upstream/`, which are
gitignored. `npm run upstream` copies them into the asset pipeline, because
Tailwind resolves the bare imports shadcn writes from the directory of the file
that wrote them.

## What is where

| Path | What it is |
|---|---|
| `lib/storybook_web/examples.ex` | the examples, and the only markup written by hand |
| `lib/storybook_web/live/preview_live.ex` | one example on a bare page, for axe-core |
| `storybook/*.story.exs` | the `phoenix_storybook` entries, at `/storybook` |
| `test/browser/` | the Playwright suite `mix ui.verify` runs |
| `lib/mix/tasks/snapshot.ex` | renders every example into `registry/snapshot/` |

The examples are the fixtures. That is deliberate: if the markup in
`examples.ex` is awkward to write, the generated API is awkward, and correct
output does not make up for it.

## Styles

Every `cn-` rule upstream publishes is nested inside `.style-<name>`, so the
style is a class on the document. `vega` is shadcn's first-listed style and the
one the demo uses; changing it means importing a different sheet in
`assets/css/app.css` and setting the matching class in config.

## Deploying

The whole thing is one image:

```bash
docker build -f storybook/Dockerfile -t live-shadcn-storybook .
docker run -p 4100:4100 \
  -e SECRET_KEY_BASE="$(mix phx.gen.secret)" \
  -e PHX_HOST=storybook.example.com \
  live-shadcn-storybook
```

The build context is the repository root, not `storybook/`: the demo depends on
the packages by path, and the asset build reads the registry beside them.

Two things about that build are worth knowing:

- It runs `mix ui.fetch` in the builder stage, because the shadcn styling layer
  is gitignored. That means the build needs network access to GitHub and
  base-ui.com, once. It fetches the commit `registry/UPSTREAM.json` pins, so the
  image is still reproducible.
- The release keeps its `Docs` chunks. `phoenix_storybook` reads a component's
  `@doc` at runtime to show it, and a stripped release has nothing to show.

Everything that varies by environment is read at boot: `SECRET_KEY_BASE`,
`PHX_HOST`, `PORT`. One image runs anywhere.

## Browser checks

```bash
cd test/browser
npm install
npm run verify:install     # once, downloads Chromium
npm run verify
```

The suite is transcribed from the Base UI documentation, and it runs on one
worker on purpose: every test drives the same development server, and a
verification run that is flaky under load verifies nothing.
