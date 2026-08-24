defmodule LiveBase.Slider do
  @moduledoc """
  The behavior behind a slider: one `<input type="range">` per thumb, drawn.

  ## Why the input is still there

  Base UI's slider page documents "a ref to access the nested input element",
  and that input is the whole of the control. It is what a reader drags, what a
  keyboard moves by arrow and by page, what a screen reader announces as a
  value between a minimum and a maximum, and what a form submits. Every one of
  those is the platform's, and none is worth writing again.

  What the platform will not do is let a style sheet reach the track and the
  thumb. So each input is invisible over its own thumb, and the hook puts the
  thumb and the filled part of the track where the input's value says.

  ## What the server knows

  Whatever the form tells it. The input carries a `name`, so a `phx-change` on
  the form around it reports the value the same way a text field does — there
  is no event of this component's own, and nothing to ask for.

  ## The attribute contract

  | Attribute | When |
  |---|---|
  | `data-dragging` | while a reader is holding a thumb |
  | `data-focused` | while a thumb has focus |
  | `data-touched` | once a reader has focused one, and after |
  | `data-orientation` | always, `horizontal` or `vertical` |
  | `data-disabled` | when the slider refuses interaction |
  """

  alias Phoenix.LiveView.JS

  @hook "LiveBase.Slider"

  @doc "The client hook name the root declares in `phx-hook`."
  def hook, do: @hook

  @doc "The id of one thumb's input, given the slider and the thumb's position."
  def input_id(slider, index), do: "#{slider}-#{index}"

  @doc """
  The attributes the client owns once the page is live.

  All three are facts about a reader's hand and a reader's focus, which the
  server never sees and would otherwise erase on the next patch.
  """
  def owned_attributes(js \\ %JS{}),
    do: JS.ignore_attributes(js, ~w(data-dragging data-focused data-touched), [])
end
