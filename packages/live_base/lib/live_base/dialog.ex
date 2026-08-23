defmodule LiveBase.Dialog do
  @moduledoc """
  The behavior behind anything that opens over the page and takes the focus
  with it: dialog, alert dialog, sheet, drawer.

  ## What the recipe owns

  A dialog is one open state and four consequences of it. The state is a
  `Phoenix.LiveView.JS` command; the consequences are not all expressible as
  one:

  | Consequence | Where it lives |
  |---|---|
  | the attributes a class string reads | a `JS` command |
  | where the focus goes, and where it comes back to | a `JS` command |
  | the focus staying inside while it is open | the client hook |
  | the page behind not scrolling | the client hook |
  | the enter and exit transitions | the client hook |

  ## The attribute contract

  | Element | Attribute | When |
  |---|---|---|
  | trigger | `data-popup-open` | present while open |
  | backdrop, popup | `data-open` | present while open |
  | backdrop, popup | `data-closed` | present while closed |
  | backdrop, popup | `data-starting-style` | while animating in |
  | backdrop, popup | `data-ending-style` | while animating out |

  ## Identifiers

  Every id is derived from the dialog's own, the same way a disclosure derives
  an item's:

      "confirm"              the dialog
      "confirm-trigger"      the button that opens it
      "confirm-backdrop"     the layer behind it
      "confirm-popup"        the dialog itself
      "confirm-title"        what names it
      "confirm-description"  what describes it

  """

  alias Phoenix.LiveView.JS

  @hook "LiveBase.Overlay"

  @doc "The client hook name the popup declares in `phx-hook`."
  def hook, do: @hook

  @doc "The id of the button that opens a dialog."
  def trigger_id(dialog), do: "#{dialog}-trigger"

  @doc "The id of the layer behind a dialog."
  def backdrop_id(dialog), do: "#{dialog}-backdrop"

  @doc "The id of the dialog itself."
  def popup_id(dialog), do: "#{dialog}-popup"

  @doc "The id of the heading that names a dialog."
  def title_id(dialog), do: "#{dialog}-title"

  @doc "The id of the text that describes a dialog."
  def description_id(dialog), do: "#{dialog}-description"

  @doc """
  Opens a dialog.

  `JS.push_focus` remembers where the reader was before the focus moves, so
  `close/2` can put it back. A dialog that opens from a button and closes to
  nowhere loses a keyboard reader's place on the page.
  """
  def open(js \\ %JS{}, dialog) do
    js
    |> JS.set_attribute({"data-popup-open", ""}, to: "##{trigger_id(dialog)}")
    |> JS.set_attribute({"aria-expanded", "true"}, to: "##{trigger_id(dialog)}")
    |> JS.remove_attribute("hidden", to: layers(dialog))
    |> JS.set_attribute({"data-open", ""}, to: layers(dialog))
    |> JS.remove_attribute("data-closed", to: layers(dialog))
    |> JS.push_focus()
    |> JS.focus_first(to: "##{popup_id(dialog)}")
  end

  @doc """
  Closes a dialog and returns the focus to whatever opened it.

  `hidden` is not removed here. The hook adds it once the exit transition has
  finished, because an element hidden mid-animation never animates.
  """
  def close(js \\ %JS{}, dialog) do
    js
    |> JS.remove_attribute("data-popup-open", to: "##{trigger_id(dialog)}")
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{trigger_id(dialog)}")
    |> JS.remove_attribute("data-open", to: layers(dialog))
    |> JS.set_attribute({"data-closed", ""}, to: layers(dialog))
    |> JS.pop_focus()
  end

  @doc """
  Marks the attributes the client owns so a server render does not close a
  dialog the reader has open.
  """
  def owned_attributes(js \\ %JS{}, part)

  def owned_attributes(js, :trigger),
    do: JS.ignore_attributes(js, ["aria-expanded", "data-popup-open"], [])

  def owned_attributes(js, part) when part in [:backdrop, :popup] do
    JS.ignore_attributes(
      js,
      ["data-open", "data-closed", "data-starting-style", "data-ending-style", "hidden"],
      []
    )
  end

  # The backdrop and the popup change together, always. Base UI documents the
  # same attributes on both because they animate as one thing.
  defp layers(dialog), do: "##{backdrop_id(dialog)}, ##{popup_id(dialog)}"
end
