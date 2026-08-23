defmodule LiveBase.Disclosure do
  @moduledoc """
  The behavior behind anything that opens and closes a panel: accordion,
  collapsible, sidebar.

  ## What the recipe owns

  A disclosure is a set of items. Each item has a trigger and a panel, and the
  trigger opens and closes the panel. That is the whole model. What differs
  between an accordion and a sidebar is the markup and the class strings, which
  come from the component spec, not from here.

  ## The attribute contract

  Base UI documents which attribute goes where, and shadcn class strings read
  those names. This module sets exactly those:

  | Element | Attribute | When |
  |---|---|---|
  | trigger | `aria-expanded` | `true` while open |
  | trigger | `data-panel-open` | present while open |
  | item, header, panel | `data-open` | present while open |
  | panel | `data-closed` | present while closed |
  | panel | `data-starting-style` | while animating in |
  | panel | `data-ending-style` | while animating out |

  `data-closed` is the one name Base UI does not publish. The shadcn style
  sheets read it to choose the collapse animation, so it is upstream's, not
  ours; it is simply upstream's other half.

  ## Where each attribute is set

  The discrete flip — open or closed — is a `Phoenix.LiveView.JS` command, so a
  click costs no round trip and no re-render. See `toggle/2`.

  The two attributes that are *timed* rather than discrete,
  `data-starting-style` and `data-ending-style`, and the
  `--*-panel-height` variable the class strings interpolate, are set by the
  `LiveBase.Disclosure` client hook. No JS command can measure a box or hold an
  attribute for the length of a transition, and a height that no static class
  string can compute is exactly what the hook exists for.

  ## Identifiers

  A trigger has to name its panel in `aria-controls`, and a panel has to name
  its heading in `aria-labelledby`, so the parts of one item need to know each
  other's ids. HEEx has no implicit component context, so the recipe fixes the
  scheme instead: every id is derived from the item id.

      "faq-1"          the item
      "faq-1-header"   the heading
      "faq-1-trigger"  the button
      "faq-1-panel"    the panel

  """

  alias Phoenix.LiveView.JS

  @hook "LiveBase.Disclosure"

  @doc "The client hook name a panel element declares in `phx-hook`."
  def hook, do: @hook

  @doc "The heading id of an item."
  def header_id(item), do: "#{item}-header"

  @doc "The trigger id of an item."
  def trigger_id(item), do: "#{item}-trigger"

  @doc "The panel id of an item."
  def panel_id(item), do: "#{item}-panel"

  @doc """
  Opens the item if it is closed, closes it if it is open.

  ## Options

    * `:item` — required, the item id
    * `:root` — required, the id of the element that groups the items
    * `:multiple` — whether other items stay open. Defaults to `false`, which
      matches the Base UI default and closes every other item first.

  Closing the others before flipping this one is what makes single-open mode
  work without asking the server which item is open: the selector excludes the
  clicked item, so the flip that follows is still correct whichever state it
  was in.
  """
  def toggle(js \\ %JS{}, opts) do
    item = Keyword.fetch!(opts, :item)
    root = Keyword.fetch!(opts, :root)

    js
    |> close_others(root, item, Keyword.get(opts, :multiple, false))
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{trigger_id(item)}")
    |> JS.toggle_attribute({"data-panel-open", ""}, to: "##{trigger_id(item)}")
    |> JS.toggle_attribute({"data-open", ""}, to: stateful(item))
  end

  @doc "Opens an item, whatever state it is in."
  def open(js \\ %JS{}, opts) do
    item = Keyword.fetch!(opts, :item)

    js
    |> close_others(Keyword.fetch!(opts, :root), item, Keyword.get(opts, :multiple, false))
    |> JS.set_attribute({"aria-expanded", "true"}, to: "##{trigger_id(item)}")
    |> JS.set_attribute({"data-panel-open", ""}, to: "##{trigger_id(item)}")
    |> JS.set_attribute({"data-open", ""}, to: stateful(item))
  end

  @doc "Closes an item, whatever state it is in."
  def close(js \\ %JS{}, opts) do
    item = Keyword.fetch!(opts, :item)

    js
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{trigger_id(item)}")
    |> JS.remove_attribute("data-panel-open", to: "##{trigger_id(item)}")
    |> JS.remove_attribute("data-open", to: stateful(item))
  end

  @doc """
  Marks the attributes this recipe owns on the client so a server render does
  not undo a click.

  LiveView patches the DOM back to what the server last rendered. The open state
  lives only in the browser, so the elements that carry it have to opt out of
  patching for those attribute names, and only those.

  Pass the part: `:trigger`, `:item`, `:header` or `:panel`.
  """
  def owned_attributes(part) when part in [:trigger, :item, :header, :panel],
    do: owned_attributes(%JS{}, part)

  @doc "See `owned_attributes/1`."
  def owned_attributes(js, :trigger),
    do: JS.ignore_attributes(js, ["aria-expanded", "data-panel-open"], [])

  def owned_attributes(js, part) when part in [:item, :header],
    do: JS.ignore_attributes(js, ["data-open"], [])

  def owned_attributes(js, :panel) do
    JS.ignore_attributes(
      js,
      [
        "data-open",
        "data-closed",
        "data-starting-style",
        "data-ending-style",
        "hidden",
        "style"
      ],
      []
    )
  end

  defp close_others(js, _root, _item, true), do: js

  defp close_others(js, root, item, false) do
    triggers = "##{root} [data-panel-open]:not(##{item} *)"

    js
    |> JS.set_attribute({"aria-expanded", "false"}, to: triggers)
    |> JS.remove_attribute("data-panel-open", to: triggers)
    |> JS.remove_attribute("data-open", to: "##{root} [data-open]:not(##{item}):not(##{item} *)")
  end

  defp stateful(item),
    do: "##{item}, ##{header_id(item)}, ##{panel_id(item)}"
end
