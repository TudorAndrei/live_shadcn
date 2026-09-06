defmodule LiveShadcn.UI.ContextMenuTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.ContextMenu

  test "a context gesture trigger uses the shared menu renderer" do
    html =
      render_component(&ContextMenu.context_menu/1, %{
        id: "canvas",
        trigger_class: "aspect-video",
        trigger: [slot(:trigger, "Right click here")],
        entry: [
          slot(:entry, "File", kind: "label"),
          slot(:entry, "Copy", kind: "item", value: "copy", shortcut: "⌘C"),
          slot(:entry, "", kind: "separator"),
          slot(:entry, "Show bookmarks", kind: "checkbox", value: "bookmarks", checked: true),
          slot(:entry, "",
            kind: "radio-group",
            group: "people",
            label: "People",
            value: "pedro",
            items: [
              %{value: "pedro", label: "Pedro Duarte"},
              %{value: "colm", label: "Colm Tuite"}
            ]
          )
        ]
      })

    document = Floki.parse_fragment!(html)

    [trigger] = Floki.find(document, "div[data-slot='context-menu-trigger']")
    assert Floki.attribute([trigger], "phx-hook") == ["LiveBase.InteractionTrigger"]

    assert Floki.attribute([trigger], "data-lb-open-on-context") == [
             "data-lb-open-on-context"
           ]

    assert Floki.attribute([trigger], "class") |> hd() =~ "aspect-video"

    [content] = Floki.find(document, "[data-slot='context-menu-content']")
    classes = Floki.attribute([content], "class") |> hd() |> String.split()
    assert "cn-context-menu-content" in classes
    refute "cn-dropdown-menu-content" in classes

    assert [_, _] = Floki.find(document, "[data-slot='context-menu-group']")
    assert [_, _] = Floki.find(document, "[data-slot='context-menu-label']")
    assert [_] = Floki.find(document, "[data-slot='context-menu-shortcut']")
    assert [_] = Floki.find(document, "[data-slot='context-menu-separator']")

    [checkbox] = Floki.find(document, "[data-slot='context-menu-checkbox-item']")
    assert Floki.attribute([checkbox], "role") == ["menuitemcheckbox"]
    assert Floki.attribute([checkbox], "aria-checked") == ["true"]

    [radio_group] = Floki.find(document, "[data-slot='context-menu-radio-group']")
    assert Floki.text(radio_group) =~ "People"
    assert [_, _] = Floki.find([radio_group], "[data-slot='context-menu-radio-item']")
  end

  test "submenu content uses Context Menu classes without Dropdown Menu classes" do
    html =
      render_component(&ContextMenu.context_menu/1, %{
        id: "canvas",
        trigger: [slot(:trigger, "Right click here")],
        entry: [
          slot(:entry, "More Tools",
            kind: "submenu",
            value: "more-tools",
            grouped: true,
            items: [
              %{kind: "item", value: "save", label: "Save Page..."},
              %{kind: "separator"},
              %{kind: "item", value: "delete", label: "Delete", variant: "destructive"}
            ]
          )
        ]
      })

    document = Floki.parse_fragment!(html)

    [trigger] = Floki.find(document, "[data-slot='context-menu-sub-trigger']")
    trigger_classes = Floki.attribute([trigger], "class") |> hd() |> String.split()
    assert "cn-context-menu-sub-trigger" in trigger_classes
    refute "cn-dropdown-menu-sub-trigger" in trigger_classes

    [content] = Floki.find(document, "[data-slot='context-menu-sub-content']")
    content_classes = Floki.attribute([content], "class") |> hd() |> String.split()
    assert "cn-context-menu-content" in content_classes
    assert "cn-context-menu-subcontent" in content_classes
    refute "cn-dropdown-menu-content" in content_classes
    refute "cn-dropdown-menu-sub-content" in content_classes

    [delete] = Floki.find([content], "[data-variant='destructive']")
    assert Floki.text(delete) =~ "Delete"
  end

  defp slot(name, text, attrs \\ []) do
    attrs
    |> Map.new()
    |> Map.merge(%{__slot__: name, inner_block: fn _, _ -> text end})
  end
end
