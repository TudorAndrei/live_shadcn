defmodule StorybookWeb.PreviewController do
  @moduledoc """
  The list of preview pages, as JSON.

  The browser suite reads this instead of carrying its own copy of which
  components have examples. One list, one place it can go stale.
  """

  use Phoenix.Controller, formats: [:json]

  alias StorybookWeb.Examples

  def index(conn, _params) do
    previews =
      Map.new(Examples.components(), fn component ->
        {component, Enum.map(Examples.all(component), & &1.id)}
      end)

    json(conn, previews)
  end
end
