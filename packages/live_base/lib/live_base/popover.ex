defmodule LiveBase.Popover do
  @moduledoc """
  The behavior behind anything that opens beside its trigger rather than over
  the whole page: popover, tooltip, hover card, dropdown menu, select.

  ## What is a command and what is a hook

  Opening is a `Phoenix.LiveView.JS` command, the same as everywhere else: the
  attributes flip, the focus moves, and nothing reaches the server.

  *Where* it opens is not. `data-side` reports the side the popup actually
  landed on after the browser ran out of room below; `--available-height` is
  how much room was left. Both are measurements of a layout that does not exist
  until the popup is shown, so both belong to the `LiveBase.Floating` hook —
  which is the floating position the architecture reserved a hook for.

  ## The attribute contract

  | Element | Attribute | Who sets it |
  |---|---|---|
  | trigger | `data-popup-open`, `data-pressed` | the command |
  | positioner, popup | `data-open`, `data-closed` | the command |
  | positioner, popup | `data-side`, `data-align` | the hook |
  | positioner | `data-anchor-hidden` | the hook |
  | popup | `data-starting-style`, `data-ending-style` | the hook |

  ## Dismissal

  A popover closes on Escape and on a click outside it. Neither needs a hook:
  `phx-window-keydown` with `phx-key` is the first, and `phx-click-away` is the
  second. What they must not do is close a popover the click *opened*, which is
  why the trigger is excluded from the away-click.
  """

  alias Phoenix.LiveView.JS

  @hook "LiveBase.Floating"

  @doc "The client hook name the positioner declares in `phx-hook`."
  def hook, do: @hook

  @doc "The id of the button that opens a popover."
  def trigger_id(popover), do: "#{popover}-trigger"

  @doc "The id of the element the popup is positioned against."
  def positioner_id(popover), do: "#{popover}-positioner"

  @doc "The id of the popup itself."
  def popup_id(popover), do: "#{popover}-popup"

  @doc """
  Opens a popover.

  The focus moves into the popup for a popover and a menu, and stays where it
  is for a tooltip. `:focus` says which, because a tooltip that stole the focus
  would be a tooltip nobody could type past.
  """
  def open(js \\ %JS{}, popover, opts \\ []) do
    js
    |> JS.set_attribute({"data-popup-open", ""}, to: "##{trigger_id(popover)}")
    |> JS.set_attribute({"data-pressed", ""}, to: "##{trigger_id(popover)}")
    |> JS.set_attribute({"aria-expanded", "true"}, to: "##{trigger_id(popover)}")
    |> JS.remove_attribute("hidden", to: layers(popover))
    |> JS.set_attribute({"data-open", ""}, to: layers(popover))
    |> JS.remove_attribute("data-closed", to: layers(popover))
    |> then(&if Keyword.get(opts, :focus, true), do: focus(&1, popover), else: &1)
  end

  # The popup itself, not its first control. A popover may hold nothing
  # focusable at all, and a dialog that opens without moving the focus leaves a
  # screen reader on the page behind it.
  defp focus(js, popover), do: JS.focus(js, to: "##{popup_id(popover)}")

  @doc "Closes a popover."
  def close(js \\ %JS{}, popover) do
    js
    |> JS.remove_attribute("data-popup-open", to: "##{trigger_id(popover)}")
    |> JS.remove_attribute("data-pressed", to: "##{trigger_id(popover)}")
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{trigger_id(popover)}")
    |> JS.remove_attribute("data-open", to: layers(popover))
    |> JS.set_attribute({"data-closed", ""}, to: layers(popover))
  end

  @doc """
  Opens a closed popover and closes an open one.

  The flip reads the trigger's own state, so the server never has to know which
  way round it is.
  """
  def toggle(js \\ %JS{}, popover) do
    js
    |> JS.toggle_attribute({"data-popup-open", ""}, to: "##{trigger_id(popover)}")
    |> JS.toggle_attribute({"data-pressed", ""}, to: "##{trigger_id(popover)}")
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{trigger_id(popover)}")
    |> JS.remove_attribute("hidden", to: layers(popover))
    |> JS.toggle_attribute({"data-open", ""}, to: layers(popover))
    |> JS.toggle_attribute({"data-closed", ""}, to: layers(popover))
  end

  @doc """
  Closes a popover when the reader clicks outside it.

  Written for `phx-click-away` on the popup. The trigger's own click is not an
  away-click: it toggles, and closing here as well would undo it in the same
  gesture.
  """
  def dismiss(js \\ %JS{}, popover), do: close(js, popover)

  @doc "Marks the attributes the client owns so a server render does not close it."
  def owned_attributes(js \\ %JS{}, part)

  def owned_attributes(js, :trigger),
    do: JS.ignore_attributes(js, ["aria-expanded", "data-popup-open", "data-pressed"], [])

  def owned_attributes(js, part) when part in [:positioner, :popup] do
    JS.ignore_attributes(
      js,
      [
        "data-open",
        "data-closed",
        "data-side",
        "data-align",
        "data-anchor-hidden",
        "data-starting-style",
        "data-ending-style",
        "hidden",
        "style"
      ],
      []
    )
  end

  defp layers(popover), do: "##{positioner_id(popover)}, ##{popup_id(popover)}"
end
