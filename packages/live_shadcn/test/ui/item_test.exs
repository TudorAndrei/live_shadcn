defmodule LiveShadcn.UI.ItemTest do
  use ExUnit.Case, async: true

  import LiveShadcn.Test.Markup
  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Item

  defp item(assigns \\ %{}) do
    assigns =
      Map.merge(
        %{inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Profile" end}]},
        assigns
      )

    render_component(&Item.item/1, assigns)
  end

  defp item_title(assigns \\ %{}) do
    assigns =
      Map.merge(
        %{inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Profile" end}]},
        assigns
      )

    render_component(&Item.item_title/1, assigns)
  end

  test "renders the default Item root as a div" do
    markup = item()

    assert [_] = Floki.find(Floki.parse_fragment!(markup), "div[data-slot='item']")
    assert "cn-item" in classes(slot(markup, "item"))
    assert "cn-item-variant-default" in classes(slot(markup, "item"))
    assert "cn-item-size-default" in classes(slot(markup, "item"))
  end

  test "renders an anchor Item root with its link contract" do
    markup = item(%{as: "a", href: "#", target: "_blank", rel: "noopener noreferrer"})

    assert [anchor] = Floki.find(Floki.parse_fragment!(markup), "a[data-slot='item']")
    assert Floki.attribute([anchor], "href") == ["#"]
    assert Floki.attribute([anchor], "target") == ["_blank"]
    assert Floki.attribute([anchor], "rel") == ["noopener noreferrer"]
  end

  test "limits the root tag to the upstream Item render targets" do
    as = Enum.find(Item.__components__()[:item][:attrs], &(&1.name == :as))

    assert as.opts[:values] == ["a", "div"]
    assert as.opts[:default] == "div"
  end

  test "renders the upstream title clamp, flex, and clipping class order" do
    assert Floki.attribute([slot(item_title(), "item-title")], "class") == [
             "cn-item-title line-clamp-1 flex w-fit items-center"
           ]
  end

  test "lets a caller title class take the same precedence as upstream cn" do
    classes = classes(slot(item_title(%{class: "line-clamp-1"}), "item-title"))

    assert "line-clamp-1" in classes
    refute "flex" in classes
  end
end
