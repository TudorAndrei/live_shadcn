defmodule LiveShadcn.UI.DropdownMenuTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.{ContextMenu, DropdownMenu, Menubar}
  alias Phoenix.LiveView.JS

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
    [label] = Floki.find(document, "[data-slot='dropdown-menu-label']")
    separators = Floki.find(document, "[data-slot='dropdown-menu-separator']")

    assert [_, _, _] = groups
    assert [_, _] = separators
    assert Floki.attribute([label], "role") == ["presentation"]
    assert [label_id] = Floki.attribute([label], "id")
    assert Floki.attribute([hd(groups)], "aria-labelledby") == [label_id]

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
            items: [
              %{
                value: "more",
                label: "More",
                kind: "submenu",
                items: [%{value: "email", label: "Email"}]
              }
            ]
          )
        ]
      })

    submenus =
      html
      |> Floki.parse_fragment!()
      |> Floki.find("[data-slot='dropdown-menu-sub-content']")

    assert [_, _] = submenus

    for submenu <- submenus do
      assert Floki.attribute([submenu], "aria-orientation") == ["vertical"]

      classes = Floki.attribute([submenu], "class") |> hd() |> String.split()
      assert "cn-dropdown-menu-content" in classes
      assert "cn-dropdown-menu-sub-content" in classes
      assert "overflow-x-hidden" in classes
      assert "overflow-y-auto" in classes
      assert Enum.filter(classes, &String.starts_with?(&1, "w-")) == ["w-auto"]
      assert Enum.count(classes, &(&1 == "cn-menu-target")) == 2
    end
  end

  test "a composed trigger keeps the input group button contract" do
    html =
      render_component(&DropdownMenu.dropdown_menu/1, %{
        id: "more",
        trigger_variant: "ghost",
        trigger_class:
          "cn-input-group-button flex items-center shadow-none cn-input-group-button-size-icon-xs",
        trigger_attrs: %{"data-size" => "icon-xs"},
        trigger: [slot(:trigger, "More")],
        entry: [slot(:entry, "Settings", kind: "item", value: "settings")]
      })

    document = Floki.parse_fragment!(html)
    [trigger] = Floki.find(document, "#more-trigger")

    assert Floki.attribute([trigger], "aria-haspopup") == ["menu"]
    assert Floki.attribute([trigger], "aria-controls") == ["more-popup"]
    assert Floki.attribute([trigger], "data-size") == ["icon-xs"]
    assert Floki.find([trigger], "button button") == []

    assert "cn-input-group-button" in (Floki.attribute([trigger], "class")
                                       |> hd()
                                       |> String.split())
  end

  test "a direct composed trigger merges the button and input group classes in upstream order" do
    html =
      render_component(&DropdownMenu.dropdown_menu/1, %{
        id: "attachments",
        direct_trigger: true,
        trigger_variant: "outline",
        trigger_class:
          "cn-input-group-button flex items-center shadow-none cn-input-group-button-size-icon-sm",
        trigger_attrs: %{"aria-label" => "Add files"},
        trigger: [slot(:trigger, "Add")],
        entry: [slot(:entry, "Photo", kind: "item", value: "photo")]
      })

    [trigger] = Floki.find(Floki.parse_fragment!(html), "#attachments-trigger")

    assert Floki.attribute([trigger], "class") == [
             "cn-button group/button shrink-0 justify-center whitespace-nowrap transition-all " <>
               "outline-none select-none disabled:pointer-events-none disabled:opacity-50 " <>
               "[&_svg]:pointer-events-none [&_svg]:shrink-0 cn-button-variant-outline " <>
               "cn-button-size-default cn-input-group-button flex items-center shadow-none " <>
               "cn-input-group-button-size-icon-sm"
           ]
  end

  test "a clipboard item copies client-side and keeps its menu action" do
    html =
      render_component(&DropdownMenu.dropdown_menu/1, %{
        id: "payments",
        trigger: [slot(:trigger, "Open")],
        entry: [
          slot(:entry, "Copy payment ID",
            kind: "item",
            value: "copy-payment-id",
            clipboard: "pay_123",
            "phx-click": "payment_copied"
          )
        ]
      })

    [item] =
      html
      |> Floki.parse_fragment!()
      |> Floki.find("#payments-item-copy-payment-id")

    assert Floki.attribute([item], "phx-hook") == ["LiveBase.Clipboard"]
    assert Floki.attribute([item], "data-lb-clipboard") == ["pay_123"]

    mounted = Floki.attribute([item], "phx-mounted") |> hd()
    assert mounted =~ "data-highlighted"
    assert mounted =~ "data-lb-ready"
    assert mounted =~ "[data-lb-state]"

    click = Floki.attribute([item], "phx-click") |> hd()
    assert click =~ "data-closed"
    assert click =~ "push"
    assert click =~ "payment_copied"
    assert position(click, "push") > position(click, "data-closed")
  end

  test "caller-controlled choices preserve callbacks and render server values" do
    for renderer <- [
          &DropdownMenu.dropdown_menu/1,
          &Menubar.menubar_menu/1,
          &ContextMenu.context_menu/1
        ],
        {checked, selected} <- [{true, "email"}, {false, "paper"}] do
      checkbox_command =
        JS.push("set_bookmarks", value: %{checked: not checked})
        |> JS.dispatch("menu:requested", to: "#status", bubbles: false)

      entries = [
        %{
          kind: "checkbox",
          value: "bookmarks",
          label: "Bookmarks",
          checked: checked,
          controlled: true,
          "phx-click": checkbox_command
        },
        %{
          kind: "radio-group",
          group: "delivery",
          value: selected,
          controlled: true,
          "phx-click": "select_email",
          items: [
            %{value: "email", label: "Email"},
            %{
              value: "paper",
              label: "Paper",
              "phx-click": JS.push("select_delivery", value: %{value: "paper"})
            }
          ]
        }
      ]

      html =
        render_component(renderer, %{
          id: "controlled",
          trigger: [slot(:trigger, "Open")],
          entry:
            Enum.map(entries, fn entry ->
              slot(:entry, entry[:label] || "", Map.to_list(entry))
            end) ++
              [slot(:entry, "More", kind: "submenu", value: "more", items: entries)]
        })

      document = Floki.parse_fragment!(html)

      for menu <- ["controlled", "controlled-more"] do
        [checkbox] = Floki.find(document, "##{menu}-item-bookmarks")
        assert Floki.attribute([checkbox], "aria-checked") == [to_string(checked)]

        assert command(checkbox, "phx-click") == [
                 ["push", %{"event" => "set_bookmarks", "value" => %{"checked" => not checked}}],
                 [
                   "dispatch",
                   %{"event" => "menu:requested", "to" => "#status", "bubbles" => false}
                 ]
               ]

        for value <- ["email", "paper"] do
          [radio] = Floki.find(document, "##{menu}-item-#{value}")
          assert Floki.attribute([radio], "aria-checked") == [to_string(selected == value)]

          expected =
            if value == "email",
              do: [["push", %{"event" => "select_email"}]],
              else: [["push", %{"event" => "select_delivery", "value" => %{"value" => "paper"}}]]

          assert command(radio, "phx-click") == expected
        end

        for [control] <- [
              Floki.find(document, "##{menu}-item-bookmarks"),
              Floki.find(document, "##{menu}-item-email"),
              Floki.find(document, "##{menu}-item-paper")
            ] do
          assert command(control, "phx-mounted") == [
                   ["ignore_attrs", %{"attrs" => ["data-highlighted"]}]
                 ]
        end
      end
    end
  end

  defp command(element, attribute) do
    [encoded] = Floki.attribute([element], attribute)
    Jason.decode!(encoded)
  end

  defp slot(name, text, attrs \\ []) do
    attrs
    |> Map.new()
    |> Map.merge(%{__slot__: name, inner_block: fn _, _ -> text end})
  end

  defp position(value, needle), do: value |> :binary.match(needle) |> elem(0)
end
