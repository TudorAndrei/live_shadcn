# Architecture

## Three runtime layers

```text
live_ai_elements   stream reducer and AI component ports
        |
   live_shadcn     reviewed shadcn ports, copied by mix ui.add
        |
    live_base      headless behavior and client hooks
        |
 phoenix_live_view
```

`live_base` depends only on `phoenix_live_view`. It owns reusable behavior such
as focus management, popup positioning, dismiss actions, and roving focus.
`live_shadcn` owns shadcn markup and API design. `live_ai_elements` owns AI
component markup and streaming data adapters.

## The data-attribute contract

shadcn class strings use data and ARIA attributes. `live_base` and the reviewed
ports must provide the same state contract.

The component source is not the only input. A shadcn style can add a state read:

```css
.cn-accordion-content {
  @apply data-open:animate-accordion-down data-closed:animate-accordion-up;
}
```

Here, `data-closed` does not occur in the component `.tsx` file. The style rule
still makes it part of the contract.

## Behavior ownership

The server owns application state. The client owns short-lived interface state,
browser measurements, and focus movement. LiveView declares most client work
with `Phoenix.LiveView.JS`.

| Hook | Used by | Reason |
|---|---|---|
| `Disclosure` | accordion and collapsible ports | measure content and hold transition state |
| `Overlay` | dialog, alert dialog, sheet, and drawer | focus containment, scroll lock, and exit timing |
| `Floating` | popover, tooltip, menu, and select | position from available browser space |
| `Roving` | tabs, menu, and select | move focus with arrow keys |

A hook decides which element to use. The `JS` command on the element decides
what happens. This keeps application actions on the server-declared component
API and keeps browser-only work in the browser.

Hooks read configuration from `data-lb-*` attributes. These names are internal
to `live_base`; shadcn class strings do not use them.

## Reviewed ports and synchronized facts

The HEEx module is a reviewed port. A maintainer owns its public attributes,
slots, markup, behavior, and use of `live_base`.

Only one marked block is synchronized:

```elixir
# live-shadcn: upstream facts start
@upstream_facts %{
  "cva/buttonVariants/default/size" => "default",
  "jsx/Button/class/0" => "cn-button inline-flex"
}
# live-shadcn: upstream facts end
```

The port reads these values through `upstream_fact/1`. The code outside the
markers can combine facts with reviewed literals. The synchronizer records the
digest of that body but does not rewrite it.

This separation is the main ownership rule:

| Data | Owner |
|---|---|
| class and CVA literals | upstream, synchronized by Oxc facts |
| fact bindings and ignored reasons | maintainer, stored in the contract |
| HEEx API, structure, and behavior | maintainer, stored in the port |
| Base UI primitives and hooks | `live_base` maintainers |

## Version-2 port contract

Each port has `registry/spec/<source>/<name>.json`. The contract is compact and
does not contain a translated JSX tree.

```jsonc
{
  "schema_version": 2,
  "source": "shadcn",
  "name": "button",
  "toolchain": {"oxc-parser": "0.74.0"},
  "upstream": {"shadcn/ui/button.tsx": "<sha256>"},
  "fingerprint": "<structural digest>",
  "file_fingerprints": {"shadcn/ui/button.tsx": "<digest>"},
  "source_facts": {"jsx/Button/class/0": "cn-button inline-flex"},
  "facts": {"jsx/Button/class/0": "cn-button inline-flex"},
  "bindings": {"copy": ["jsx/Button/class/0"], "derived": {}},
  "ignored": {},
  "uses": ["jsx/Button/class/0"],
  "state_reads": [],
  "css_vars": [],
  "base_ui": {},
  "styles": {},
  "port_body": "<sha256>"
}
```

`bindings.copy` maps an upstream fact directly into the port. A derived binding
can join facts and reviewed literals or apply the small Tailwind merge operation.
Every source fact must have a binding or an `ignored` reason.

## Oxc boundary

`tools/priv/facts.mjs` parses TypeScript and JSX with Oxc. It returns:

- static class literals;
- CVA bases, variants, compound variants, and defaults;
- source spans for diagnostics;
- a structural fingerprint with safe literal values masked.

Oxc does not translate JavaScript expressions into Elixir. It does not choose a
LiveView API, convert React state, select a `live_base` primitive, or write HEEx
behavior. Those decisions stay in the reviewed port.

## Maintainer stages

### `mix ui.fetch`

The task resolves upstream repositories to commit SHAs. It downloads sources to
the ignored `registry/upstream/` directory and records their digests in
`registry/UPSTREAM.json`.

### `mix ui.spec`

The task reads existing version-2 contracts and ports. It parses all required
upstream files in one run and computes every result before it writes.

| Change | Result |
|---|---|
| class or CVA value with the same fact key | safe fact update |
| component or call structure | manual drift |
| state-read set | manual drift |
| Base UI page digest | manual drift |
| missing binding or ignored reason | error |
| reviewed port-body edit | new body digest after online review |

One manual result stops all port and contract writes in a full run. The weekly
workflow therefore cannot apply safe updates beside an unreviewed structural
change.

`mix ui.spec --check --offline` uses only committed contracts and ports. It
checks the fact values, canonical fact-block format, contract JSON bytes, and
the reviewed port-body digest. CI and release jobs use this mode.

The reader gates stay separate:

```bash
mix ui.spec --check --source shadcn
mix ui.spec --check --source ai_elements
```

### `mix ui.verify`

Verification writes `registry/VERIFY.json`. A result remains valid only while
its contract digest is unchanged.

| Check | Question |
|---|---|
| generated | does the reviewed port match its contract? |
| snapshot | did rendered markup change? |
| browser | does behavior work, and is the result clean under axe-core? |
| parity | does the port draw the same measurable result as upstream React? |
| pixel | does the port paint the same result as upstream React? |

The historical key `generated` remains in the verification file to avoid an
unrelated persistence migration. Its current meaning is contract agreement.

## A first port

A new upstream component has no safe automatic translation. A maintainer must:

1. fetch the source and classify the inventory entry;
2. choose the nearest reviewed port and `live_base` primitive;
3. write the module API, markup, and behavior;
4. add the marked fact block and explicit bindings or ignored reasons;
5. use `LiveShadcnTools.Converter.sync/1` with `contract: nil` to create the
   first version-2 contract, then review the returned port and contract;
6. add Storybook examples, snapshots, browser behavior tests, and upstream
   parity where it applies;
7. run `mix ui.spec --check` and `mix ui.verify <source>/<name>`.

After this first review, normal updates use `mix ui.spec`.

## Sync workflow

The scheduled workflow runs fetch, port synchronization, snapshots, offline
contract checks, and browser verification. Safe fact changes can open a pull
request. Manual structural drift stops before port or contract writes.

In a user's application, `mix ui.sync` compares installed copies with the
package registry. It does not overwrite an edited copy.
