defmodule LiveBase.Carousel do
  @moduledoc """
  The browser behavior behind a carousel.

  Embla owns movement and measurement in the browser. The hook also keeps the
  previous and next controls in sync with the current slide.
  """

  alias Phoenix.LiveView.JS

  @hook "LiveBase.Carousel"

  @doc "The client hook name the carousel root declares."
  def hook, do: @hook

  @doc "Preserves a control state the hook measures across LiveView patches."
  def owned_attributes(js \\ %JS{}),
    do: JS.ignore_attributes(js, ~w(data-disabled disabled), [])
end
