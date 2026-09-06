defmodule LiveBase.Command do
  @moduledoc """
  The browser behavior for a Command list.

  The hook filters rendered items. It keeps focus on the search field while
  arrow keys change the active option.
  """

  @hook "LiveBase.Command"

  @doc "The client hook name used by a Command root."
  def hook, do: @hook
end
