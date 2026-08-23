defmodule LiveBase.Menu do
  @moduledoc """
  The behavior behind a list of things to choose from, opened beside its
  trigger: dropdown menu, context menu, menubar.

  ## What it adds to a popover

  A menu opens the same way a popover does, and `LiveBase.Popover` already does
  that. Two things are its own:

  **A roving tab stop.** The arrow keys move through the items, and the item
  arrived at takes both the focus and `data-highlighted` — the APG's roving
  tabindex, and what Base UI's own menu does. The focus starts on the menu, so
  a screen reader announces the menu before its first item.

  Moving is not choosing. Arriving at an item marks it; choosing it is a
  separate keypress or click, and only that closes the menu.

  **Choosing closes.** Every item closes the menu when it is chosen, because a
  menu that stayed open would need a second gesture to dismiss.

  ## The attribute contract

  | Element | Attribute | When |
  |---|---|---|
  | trigger | `data-popup-open`, `data-pressed` | while open |
  | item | `data-highlighted` | while the arrow keys are on it |
  | item | `data-disabled` | when it refuses to be chosen |
  | checkbox item | `data-checked` / `data-unchecked` | its own state |
  | radio item | `data-checked` / `data-unchecked` | one per group |
  """

  alias LiveBase.Popover
  alias Phoenix.LiveView.JS

  @hook "LiveBase.Roving"

  @doc "The client hook name the menu popup declares in `phx-hook`."
  def hook, do: @hook

  @doc "The id of the item at a given value."
  def item_id(menu, value), do: "#{menu}-item-#{value}"

  @doc """
  Chooses an item: closes the menu, then does whatever the caller said.

  One element cannot carry two `phx-click` bindings, so the two commands are
  joined here rather than emitted side by side. The caller's may be an event
  name or a `Phoenix.LiveView.JS` command of their own; both are appended after
  the close, so the menu is already shut by the time their handler runs.
  """
  def choose(menu, command \\ nil), do: menu |> Popover.close() |> then(&also(&1, command))

  defp also(js, nil), do: js
  defp also(js, name) when is_binary(name), do: JS.push(js, name)

  # There is no public way to append one command to another, and a menu item
  # that closed the menu *or* did its job would be neither.
  defp also(%JS{ops: ours}, %JS{ops: theirs}), do: %JS{ops: ours ++ theirs}

  @doc """
  Marks an item highlighted and unmarks the rest.

  The arrow keys move it, through the `LiveBase.Roving` hook. This command is
  for moving it any other way — a click that should mark without choosing, or a
  server-side change of mind.
  """
  def highlight(js \\ %JS{}, opts) do
    menu = Keyword.fetch!(opts, :menu)
    item = "##{Keyword.fetch!(opts, :item)}"

    js
    |> JS.remove_attribute("data-highlighted",
      to: "##{Popover.popup_id(menu)} [role^='menuitem']"
    )
    |> JS.set_attribute({"data-highlighted", ""}, to: item)
  end

  @doc "Marks the attributes the client owns so a server render does not undo them."
  def owned_attributes(js \\ %JS{}, part)

  def owned_attributes(js, :item),
    do: JS.ignore_attributes(js, ["data-highlighted"], [])

  def owned_attributes(js, part), do: Popover.owned_attributes(js, part)
end
