defmodule LiveShadcn.UI.TabsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Tabs

  test "a caller width replaces the upstream tabs list width" do
    html =
      render_component(&Tabs.tabs/1, %{
        id: "settings",
        list_class: "w-full",
        tab: [
          %{
            __slot__: :tab,
            value: "profile",
            label: "Profile",
            inner_block: fn _, _ -> "Profile settings" end
          }
        ]
      })

    [list] = Floki.find(Floki.parse_fragment!(html), "[data-slot='tabs-list']")

    assert Floki.attribute([list], "class") == [
             "cn-tabs-list-variant-default bg-muted cn-tabs-list group/tabs-list inline-flex items-center justify-center text-muted-foreground group-data-vertical/tabs:h-fit group-data-vertical/tabs:flex-col w-full"
           ]
  end
end
