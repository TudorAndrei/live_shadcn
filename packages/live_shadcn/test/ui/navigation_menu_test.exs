defmodule LiveShadcn.UI.NavigationMenuTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.NavigationMenu

  test "the single-item form keeps its content in the trigger's navigation ownership" do
    for open <- [false, true] do
      document =
        render_component(&NavigationMenu.navigation_menu/1, %{
          id: "pages",
          open: open,
          trigger: [slot(:trigger, "Documentation")],
          inner_block: [slot(:inner_block, "Page links")]
        })
        |> Floki.parse_fragment!()

      assert [_] = Floki.find(document, "nav")
      [trigger] = Floki.find(document, "button#pages-trigger")
      assert String.trim(Floki.text(trigger)) == "Documentation"
      assert Floki.attribute([trigger], "aria-expanded") == [to_string(open)]
      assert Floki.attribute([trigger], "aria-controls") == ["pages-popup"]
      [owner] = Floki.find(document, "li [aria-owns]")
      [viewport_id] = Floki.attribute([owner], "aria-owns")
      [viewport] = Floki.find(document, "##{viewport_id}")
      assert String.trim(Floki.text(viewport)) == "Page links"
    end
  end

  test "disabled triggers expose their state without an activation command in either public form" do
    for {trigger_id, assigns} <- [
          {"pages-trigger",
           %{
             disabled: true,
             trigger: [slot(:trigger, "Documentation")],
             inner_block: [slot(:inner_block, "Page links")]
           }},
          {"docs-trigger",
           %{
             item: [
               slot(:item, "Page links", id: "docs", trigger: "Documentation", disabled: true)
             ]
           }}
        ] do
      document =
        render_component(&NavigationMenu.navigation_menu/1, Map.put(assigns, :id, "pages"))
        |> Floki.parse_fragment!()

      [trigger] = Floki.find(document, "##{trigger_id}")
      assert Floki.attribute([trigger], "aria-disabled") == ["true"]
      assert Floki.attribute([trigger], "aria-expanded") == ["false"]
      assert Floki.attribute([trigger], "phx-click") == []
    end
  end

  defp slot(name, text, attrs \\ []) do
    attrs
    |> Map.new()
    |> Map.merge(%{__slot__: name, inner_block: fn _, _ -> text end})
  end
end
