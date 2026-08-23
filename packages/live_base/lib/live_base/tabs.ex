defmodule LiveBase.Tabs do
  @moduledoc """
  The behavior behind a set of panels of which exactly one is shown.

  ## What the recipe owns

  Tabs are a radio group that happens to reveal something. Choosing one is
  choosing instead of the others, so the command that activates a tab is the
  one that deactivates the rest — a tab set with two active tabs is not a tab
  set with a styling problem, it is two panels on top of each other.

  ## The attribute contract

  | Element | Attribute | When |
  |---|---|---|
  | tab | `aria-selected` | `true` on the active one |
  | tab | `data-active` | present on the active one |
  | panel | `data-hidden` | present on every panel but one |
  | root, list, tab, panel | `data-orientation` | always |

  ## Keyboard

  The APG asks for arrow keys along the row and Home and End at its ends. That
  is the one thing here a `JS` command cannot do: `phx-key` filters one key per
  binding, and one element cannot carry four of them.

  So the `LiveBase.Roving` hook sits on the list and works out which tab a key
  means, then clicks it. What choosing a tab *does* stays in the command on the
  tab itself. The hook decides which, never what.
  """

  alias Phoenix.LiveView.JS

  @hook "LiveBase.Roving"

  @doc "The client hook name the tab list declares in `phx-hook`."
  def hook, do: @hook

  @doc "The id of a tab, given the tab set and the tab's own value."
  def tab_id(tabs, value), do: "#{tabs}-tab-#{value}"

  @doc "The id of a panel, given the tab set and its tab's value."
  def panel_id(tabs, value), do: "#{tabs}-panel-#{value}"

  @doc """
  Activates one tab and deactivates the rest.

  ## Options

    * `:tabs` — required, the id of the tab set
    * `:value` — required, the value of the tab being activated
    * `:focus` — whether to move the focus to it. True for a keypress, false
      for a click, which has already moved it.
  """
  def activate(js \\ %JS{}, opts) do
    tabs = Keyword.fetch!(opts, :tabs)
    value = Keyword.fetch!(opts, :value)
    tab = "##{tab_id(tabs, value)}"
    panel = "##{panel_id(tabs, value)}"

    js
    |> deactivate(tabs, tab)
    |> JS.set_attribute({"aria-selected", "true"}, to: tab)
    |> JS.set_attribute({"data-active", ""}, to: tab)
    |> JS.set_attribute({"tabindex", "0"}, to: tab)
    |> JS.remove_attribute("data-hidden", to: panel)
    |> JS.remove_attribute("hidden", to: panel)
    |> then(&if Keyword.get(opts, :focus, false), do: JS.focus(&1, to: tab), else: &1)
  end

  # Every other tab in this set, found by role. A caller who built the set with
  # a comprehension has no list of ids to keep in step.
  defp deactivate(js, tabs, except) do
    others = "##{tabs} [role='tab']:not(#{except})"

    js
    |> JS.set_attribute({"aria-selected", "false"}, to: others)
    |> JS.remove_attribute("data-active", to: others)
    |> JS.set_attribute({"tabindex", "-1"}, to: others)
    |> JS.set_attribute({"data-hidden", ""}, to: "##{tabs} [role='tabpanel']")
    |> JS.set_attribute({"hidden", ""}, to: "##{tabs} [role='tabpanel']")
  end

  @doc """
  Marks the attributes the client owns so a server render does not move the
  reader back to the tab they started on.
  """
  def owned_attributes(js \\ %JS{}, part)

  def owned_attributes(js, :tab),
    do: JS.ignore_attributes(js, ["aria-selected", "data-active", "tabindex"], [])

  def owned_attributes(js, :panel),
    do: JS.ignore_attributes(js, ["data-hidden", "hidden"], [])
end
