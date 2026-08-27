# Contributing

The maintainer workflow is `mix ui.fetch → mix ui.spec → mix ui.verify`.

Oxc keeps class and CVA facts current. Maintainers review and edit the HEEx port
body. The synchronizer does not translate React behavior.

## Setup

```bash
cd tools && mix deps.get && npm install
mix ui.fetch

cd ../storybook && mix setup
cd test/browser && npm install && npm run verify:install
```

Run `mix phx.server` in `storybook/` and open <http://localhost:4100>.

## Ownership rules

Each component has two committed files:

- a reviewed Elixir port in its package;
- a version-2 contract in `registry/spec/<source>/`.

The marked fact block belongs to the synchronizer. The remaining module belongs
to maintainers.

```elixir
# live-shadcn: upstream facts start
@upstream_facts %{
  "jsx/Button/class/0" => "cn-button inline-flex"
}
# live-shadcn: upstream facts end
```

Do not edit a fact value during a normal update. Edit the HEEx body when a
LiveView API or behavior needs a reviewed change. Then run the online spec task
to record the new body digest.

## Update existing ports

```bash
cd tools
mix ui.fetch
mix ui.spec --check --source shadcn
mix ui.spec --check --source ai_elements
mix ui.spec
```

The check classifies every change before any write:

| Result | Meaning |
|---|---|
| safe fact update | a known class or CVA fact changed value |
| manual drift | structure, state reads, or a Base UI contract changed |
| error | a source is missing, a digest is stale, or a fact has no policy |

`mix ui.spec` writes safe updates only when the full selected run has no manual
drift or error. Do not bypass a manual result. Review the upstream source and
change the port body, bindings, or ignored reasons as required.

## Add the first port for a component

The first port is manual because Oxc does not choose an API or translate React
behavior.

1. Run `mix ui.fetch` and add the source, tier, and classification to
   `registry/INVENTORY.json`.
2. Read the upstream `.tsx`, Base UI page, and nearest existing reviewed port.
3. Select or add the required `live_base` primitive.
4. Create the Elixir module at the path used by its source:
   `packages/live_shadcn/priv/registry/` or
   `packages/live_ai_elements/lib/live_ai_elements/components/`.
5. Add an empty marked fact block, write the public attributes and slots, and
   implement the HEEx behavior.
6. In `iex -S mix` under `tools/`, call
   `LiveShadcnTools.Converter.sync/1` with the fetched source bodies,
   style rules, Base UI pages, the reviewed port, `contract: nil`, and explicit
   `bindings`, `ignored`, and `uses` values. Write the returned `artifact.port`
   and `artifact.contract_json` to their normal paths.
7. Review every binding and ignored reason. A reason must explain why the port
   does not use the upstream fact.
8. Run `mix ui.spec --check <source>/<name>`.
9. Add a Storybook example, a snapshot, browser behavior tests, and React parity
   where it applies.
10. Run `mix ui.verify <source>/<name>`.

The converter accepts an empty fact block for the initial `contract: nil` call.
It returns the canonical fact block. Later runs require the block, contract, and
port body to agree.

## Behavior placement

Application state belongs on the server. Short-lived interface state and
browser measurements belong on the client.

Put reusable commands and hooks in `packages/live_base/`. Use a hook only when
`Phoenix.LiveView.JS` cannot express the work. A hook decides which element to
use; the `JS` command on that element decides what happens.

## Verification

```bash
cd tools
mix ui.spec --check --offline
mix ui.verify shadcn/select
mix ui.status --check
```

Verification checks contract agreement, snapshots, browser behavior,
accessibility, upstream geometry, and pixels. Every component also needs an
example in `storybook/lib/storybook_web/examples.ex`.

If a local port is in use, select isolated browser ports:

```bash
STORYBOOK_PORT=14101 PARITY_PORT=14102 mix ui.verify shadcn/select
```

## Before a pull request

```bash
# In tools/ and each packages/* project
mix test
mix check

cd tools
mix ui.spec --check --offline
mix ui.status --check

cd ../storybook
mix snapshot --check
```

If the change reads upstream sources, also run both online source checks after
`mix ui.fetch`.

Do not commit `registry/upstream/`. The repository commits source digests, not
copies of upstream files. Do not use a model in the scheduled synchronization
loop. A model can help draft a first port, but a maintainer must review the API,
behavior, bindings, and tests.
