defmodule LiveBase.Menubar do
  @moduledoc """
  The client behavior for the top-level items in a menubar.

  The popup menus use `LiveBase.Menu`. This hook only moves between the
  top-level triggers and moves an open menu when the pointer crosses the bar.
  """

  @hook "LiveBase.Menubar"

  @doc "The client hook name for a menubar root."
  def hook, do: @hook
end
