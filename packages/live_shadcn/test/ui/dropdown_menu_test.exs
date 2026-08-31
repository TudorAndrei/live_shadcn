defmodule LiveShadcn.UI.DropdownMenuTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.DropdownMenu

  test "grouped menus put each section in an upstream menu group" do
    html =
      render_component(&DropdownMenu.dropdown_menu/1, %{
        id: "account",
        grouped: true,
        trigger: [slot(:trigger, "Open")],
        entry: [
          slot(:entry, "My Account", kind: "label"),
          slot(:entry, "Profile", kind: "item", value: "profile"),
          slot(:entry, "", kind: "separator"),
          slot(:entry, "Team", kind: "item", value: "team"),
          slot(:entry, "", kind: "separator"),
          slot(:entry, "Log out", kind: "item", value: "log-out")
        ]
      })

    document = Floki.parse_fragment!(html)
    groups = Floki.find(document, "[data-slot='dropdown-menu-group']")
    separators = Floki.find(document, "[data-slot='dropdown-menu-separator']")

    assert [_, _, _] = groups
    assert [_, _] = separators

    assert ["MyAccountProfile", "Team", "Logout"] ==
             Enum.map(groups, fn group ->
               group
               |> Floki.text()
               |> String.replace(~r/\s+/, "")
             end)
  end

  test "submenu content keeps the content contract it wraps" do
    html =
      render_component(&DropdownMenu.dropdown_menu/1, %{
        id: "account",
        trigger: [slot(:trigger, "Open")],
        entry: [
          slot(:entry, "Invite users",
            kind: "submenu",
            value: "invite-users",
            items: [%{value: "email", label: "Email"}]
          )
        ]
      })

    [submenu] =
      html
      |> Floki.parse_fragment!()
      |> Floki.find("[data-slot='dropdown-menu-sub-content']")

    assert Floki.attribute([submenu], "aria-orientation") == ["vertical"]

    classes = Floki.attribute([submenu], "class") |> hd() |> String.split()
    assert "cn-dropdown-menu-content" in classes
    assert "cn-dropdown-menu-sub-content" in classes
    assert "overflow-x-hidden" in classes
    assert "overflow-y-auto" in classes
  end

  defp slot(name, text, attrs \\ []) do
    attrs
    |> Map.new()
    |> Map.merge(%{__slot__: name, inner_block: fn _, _ -> text end})
  end
end
