# Contributing

The pipeline is `mix ui.fetch → mix ui.spec → mix ui.gen → mix ui.verify`. Three
of those four stages are pure data. The one place a person writes code that ends
up in a component is a **recipe**, and this page is about writing one.

## Setting up

```bash
cd tools && mix deps.get
mix ui.fetch                      # upstream sources, styles and theme
mix ui.spec                       # -> registry/spec/<source>/*.json
mix ui.gen                        # -> packages/live_shadcn/priv/registry/*.ex

cd ../storybook && mix setup
cd test/browser && npm install && npm run verify:install   # Chromium, once
```

Then `mix phx.server` in `storybook/` and open <http://localhost:4100>.

## The rule everything else follows from

**Nothing that reaches a component is typed by a person.** Not a class string,
not a `data-slot`, not the list of variants a component accepts. If you find
yourself copying one out of upstream, the pipeline has a gap — widen the reader
or the recipe, and let the generator emit it.

A recipe is the exception, and it is a narrow one. A recipe says three things:

1. which Base UI part plays which role
2. what expression computes each attribute the spec says an element carries
3. how the parts nest into one component

It never says what an element looks like, what tag it is, or what classes it
has. Those are facts, and the spec already holds them.

## Writing a recipe

### 1. Read the spec first

```bash
cd tools
mix run -e 'IO.puts(File.read!("../registry/spec/shadcn/select.json"))'
```

Look for two things: which parts Base UI documents, and what each part's
`reads` says. `reads` is the list of attributes the class strings key on — it is
the contract you have to satisfy, and it is already written down.

### 2. Add the module

A recipe lives in `tools/lib/live_shadcn_tools/gen/` and exports `module/2`.
Take an existing one as the shape; `disclosure` is the simplest with behavior,
`presentational` the simplest without.

The part that matters is `attribute!/2`:

```elixir
def attribute!("data-checked", _role), do: {:code, "flag(@checked)"}
def attribute!("data-side", _role), do: :client

def attribute!(name, role) do
  raise "the … recipe does not know how to compute #{name} on the #{role}."
end
```

**Raise on an attribute you have not thought about.** Do not return `nil` and do
not skip it. Base UI documents that attribute because a class string reads it,
and a component that quietly omits it is a component whose styling is wrong in a
state nobody tested. The raise is how you find out at generation time instead.

Then register it in `LiveShadcnTools.Gen`:

```elixir
@recipes %{… "select" => Listbox}
```

### 3. Decide where each attribute lives

Three answers, and only three:

| Answer | Means | Example |
|---|---|---|
| `{:code, expr}` | the server renders it | `data-checked`, `data-disabled` |
| `:client` | a hook owns it | `data-side`, `data-starting-style` |
| raise | nobody has decided yet | anything else |

The server owns application state. The client owns what the reader has done and
what the browser measured. If you are unsure which, ask whether the server could
possibly know it: it cannot know where a popup landed, and it cannot know that
somebody has touched a field.

### 4. Behavior goes in `live_base`, not in the recipe

A recipe emits markup. The `Phoenix.LiveView.JS` commands that markup calls
belong in `packages/live_base/lib/live_base/`, so an application can use them
without generating anything.

Reach for a hook only when no command can express the thing, and say why in the
module's doc. The four that exist are there for measurements, timing, scroll
lock, focus containment, and which element a key means — and each one holds to
the same line: **a hook decides which element, never what happens to it.**

## Verifying

```bash
cd tools && mix ui.gen && mix ui.verify select
```

`mix ui.verify` checks four things:

| Check | Question |
|---|---|
| generated | does the module on disk still match its spec? |
| snapshot | has the markup a reader gets changed? |
| browser | does it behave like Base UI, and is it clean under axe-core? |
| parity | does it draw what the React it was generated from draws? |

A component with behavior needs a suite of its own in
`storybook/test/browser/<name>.spec.mjs`. Transcribe it from the Base UI
documentation page — that page is the specification, and a test that agrees with
our implementation rather than with upstream proves nothing.

Every component needs an example in `storybook/lib/storybook_web/examples.ex`.
The examples are the fixtures: `mix snapshot` renders them and the browser suite
drives them. They are also the one place hand-written markup is expected, and
they are the honest test of the generated API — **if the example is awkward to
write, the component is awkward, and correct output does not make up for it.**

## Adding a component to an existing recipe

Often nothing needs writing at all:

```bash
cd tools
# Say which recipe and tier it is, in registry/INVENTORY.json
mix ui.spec <name> && mix ui.gen <name>
```

If it generates, add an example and a browser suite and verify it. If it raises,
the message names exactly what is missing.

## Before opening a pull request

```bash
# In each of tools/, packages/*/ and storybook/
mix format && mix compile --warnings-as-errors && mix test

cd tools && mix ui.gen --check && mix ui.status --check
cd ../storybook && mix snapshot --check
cd test/browser && npm run verify
```

`--check` is what keeps the generated files honest: it fails if a file no longer
matches what its spec produces, whether that is because the spec moved or
because somebody edited the output.

## What not to do

- **Do not edit anything in `packages/live_shadcn/priv/registry/`.** Those files
  are generated. `mix ui.gen --check` will catch you, and the fix is upstream.
- **Do not commit anything from `registry/upstream/`.** It is gitignored on
  purpose: `registry/UPSTREAM.json` records a digest per file, so drift is
  visible without this repository redistributing anybody else's source.
- **Do not use a model in the daily loop.** A model may draft a new recipe once.
  A person reviews it and it is then frozen. Fetching, speccing and generating
  are parsing and templating, and they stay that way.
