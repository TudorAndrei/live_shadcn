defmodule LiveShadcn.UI.SidebarTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Sidebar

  test "the provider renders the pinned minimum-height class once" do
    html = render_component(&Sidebar.sidebar_provider/1, %{inner_block: []})
    [provider] = html |> Floki.parse_fragment!() |> Floki.find("[data-slot='sidebar-wrapper']")

    assert provider
           |> Floki.attribute("class")
           |> hd()
           |> String.split()
           |> Enum.count(&(&1 == "min-h-svh")) == 1
  end
end
