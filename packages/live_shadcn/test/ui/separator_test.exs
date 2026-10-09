defmodule LiveShadcn.UI.SeparatorTest do
  use ExUnit.Case, async: true

  import LiveShadcn.Test.Markup
  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Separator

  test "caller widths replace the defaults without changing separator semantics" do
    for orientation <- ["horizontal", "vertical"] do
      html =
        render_component(&Separator.separator/1, %{
          orientation: orientation,
          class: "data-horizontal:w-12 data-vertical:w-3",
          rest: %{title: "Section boundary"}
        })

      separator = slot(html, "separator")

      assert Enum.filter(classes(separator), &String.starts_with?(&1, "data-horizontal:w-")) ==
               ["data-horizontal:w-12"]

      assert Enum.filter(classes(separator), &String.starts_with?(&1, "data-vertical:w-")) ==
               ["data-vertical:w-3"]

      assert attribute(separator, "role") == "separator"
      assert attribute(separator, "aria-orientation") == orientation
      assert attribute(separator, "data-orientation") == orientation
      assert attribute(separator, "title") == "Section boundary"
    end
  end
end
