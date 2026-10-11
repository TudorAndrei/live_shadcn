# Storybook

The demo application. It exists so a person can look at a component, and so
`mix ui.verify` has a real browser to drive.

Complete the [repository setup](../CONTRIBUTING.md#setup) from the repository
root first. It restores pinned inputs, installs Mix and npm dependencies, and
builds the shared assets. Then run this command in `storybook/`:

```bash
mix phx.server     # repository mise default: http://localhost:14101
```

The styling comes from the pinned sheets in `registry/upstream/`.
`npm run upstream` in `assets/` copies them into the asset pipeline so Tailwind
can resolve their package imports.

## What is where

| Path | What it is |
|---|---|
| `lib/storybook_web/examples.ex` | reviewed examples for the public ports |
| `lib/storybook_web/live/preview_live.ex` | one example on a bare page, for axe-core |
| `storybook/*.story.exs` | the `phoenix_storybook` entries, at `/storybook` |
| `test/browser/` | the Playwright suite `mix ui.verify` runs |
| `lib/mix/tasks/snapshot.ex` | renders every example into `registry/snapshot/` |

The examples are the fixtures. That is deliberate: if the markup in
`examples.ex` is awkward to write, the public API is awkward, and correct
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

- It runs `mix ui.fetch --styles` in the builder stage, because the shadcn
  styling layer is gitignored. This fetch uses the GitHub commit pinned in
  `registry/UPSTREAM.json`. The other build steps also need access to the OS,
  Node, Hex, and npm package sources.
- The release keeps its `Docs` chunks. `phoenix_storybook` reads a component's
  `@doc` at runtime to show it, and a stripped release has nothing to show.

Everything that varies by environment is read at boot: `SECRET_KEY_BASE`,
`PHX_HOST`, `PORT`. One image runs anywhere.

## Browser checks

The repository setup installs `tools` npm dependencies, Storybook Mix and asset
dependencies, `storybook/test/browser` npm dependencies and Chromium, and
`parity` npm dependencies. Complete that setup before the first run.

Stop development servers on the verification ports. From the repository root:

```bash
cd tools
mix ui.verify --source shadcn
mix ui.verify --source ai_elements
```

The verifier prepares the pinned React references and shared assets. It owns
one Storybook server and one reference server, on ports 14101 and 14102 with
the repository's mise environment. The browser checks use one worker.
See [the parity guide](../parity/README.md#running-it) for scoped and direct runs.

AI Elements runs authored behavior and local accessibility checks for every
component. Its verification result does not claim React or Base UI parity.
