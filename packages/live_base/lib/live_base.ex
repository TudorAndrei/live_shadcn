defmodule LiveBase do
  @moduledoc """
  Headless behavior primitives for Phoenix LiveView.

  `LiveBase` is the Elixir counterpart of Base UI. It owns no styling. Its only
  job is to emit the data attributes that shadcn class strings key on, and to
  provide the behavior that changes them.

  ## The contract

  A primitive must set exactly the attributes Base UI documents for the same
  component. `live_shadcn` copies shadcn class strings verbatim, and those
  strings read attributes such as:

      data-panel-open  data-starting-style  data-ending-style
      data-side        data-highlighted     data-disabled

  A primitive that invents an attribute name silently breaks every class string
  that reads the documented one.

  ## Where behavior runs

  Behavior is declared on the server with `Phoenix.LiveView.JS` and runs on the
  client. Opening a panel costs no round trip and no re-render.

  A JavaScript hook is used only where a `JS` command cannot reach:

    * floating position, through `@floating-ui/dom`
    * arrow-key roving focus
    * typeahead, for select, combobox, and command
    * scroll lock
  """
end
