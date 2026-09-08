defmodule LiveBase.SidebarTest do
  use ExUnit.Case, async: true

  alias LiveBase.Sidebar

  test "toggle changes only the two state attributes rendered by the pinned sidebar" do
    attributes =
      for ["toggle_attr", %{attr: [name | _]}] <- Sidebar.toggle(sidebar: "nav").ops,
          do: name

    assert attributes == ["data-state", "data-collapsible"]
  end

  test "a sidebar trigger has no client-owned state attribute" do
    assert Sidebar.owned_attributes(:trigger).ops == []
  end
end
