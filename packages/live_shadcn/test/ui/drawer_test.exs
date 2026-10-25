defmodule LiveShadcn.UI.DrawerTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Drawer

  test "a modal drawer renders its public parts and snap-point contract" do
    html =
      render_component(&Drawer.drawer/1, %{
        id: "delivery",
        snap_points: ["31rem", 1],
        show_swipe_handle: true,
        trigger: [slot(:trigger, "Open")],
        title: [slot(:title, "Delivery")],
        description: [slot(:description, "Select a time")],
        inner_block: [slot(:inner_block, "Times")],
        close: [slot(:close, "Close", variant: "outline")]
      })

    document = Floki.parse_fragment!(html)

    [trigger] = Floki.find(document, "#delivery-trigger")
    assert Floki.attribute([trigger], "data-slot") == ["drawer-trigger"]
    assert Floki.attribute([trigger], "aria-controls") == ["delivery-popup"]

    assert [_] = Floki.find(document, "#delivery-backdrop[data-snap-points]")
    assert [_] = Floki.find(document, "#delivery-viewport[data-modal='true']")
    assert [_] = Floki.find(document, "[data-slot='drawer-swipe-handle']")

    [popup] = Floki.find(document, "#delivery-popup")
    assert Floki.attribute([popup], "role") == ["dialog"]
    assert Floki.attribute([popup], "phx-hook") == [LiveBase.Drawer.hook()]
    assert Floki.attribute([popup], "data-lb-dismissible") == [""]
    assert Floki.attribute([popup], "data-lb-snap-points") == ["[\"31rem\",1]"]

    [close] = Floki.find(document, "[data-slot='drawer-close']")
    assert Floki.text(close) =~ "Close"
  end

  test "non-modal and nested drawers do not render a modal backdrop" do
    for attrs <- [%{modal: false}, %{nested: true, parent: "parent"}] do
      html =
        render_component(
          &Drawer.drawer/1,
          Map.merge(attrs, %{
            id: "child",
            trigger: [slot(:trigger, "Open")],
            inner_block: [slot(:inner_block, "Body")]
          })
        )

      document = Floki.parse_fragment!(html)
      assert Floki.find(document, "[data-slot='drawer-overlay']") == []
    end
  end

  defp slot(name, text, attrs \\ []) do
    attrs
    |> Map.new()
    |> Map.merge(%{__slot__: name, inner_block: fn _, _ -> text end})
  end
end
