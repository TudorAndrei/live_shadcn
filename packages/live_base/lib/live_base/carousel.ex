defmodule LiveBase.Carousel do
  @moduledoc """
  The browser behavior behind a CSS scroll-snap carousel.

  The viewport scrolls with the platform. The hook only determines whether a
  previous or next control can move it, so a server patch never guesses a
  measurement it cannot know.
  """

  alias Phoenix.LiveView.JS

  @hook "LiveBase.Carousel"

  @doc "The client hook name the carousel root declares."
  def hook, do: @hook

  @doc "Preserves a control state the hook measures across LiveView patches."
  def owned_attributes(js \\ %JS{}),
    do: JS.ignore_attributes(js, ~w(data-disabled), [])
end
