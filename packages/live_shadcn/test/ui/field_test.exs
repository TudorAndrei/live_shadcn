defmodule LiveShadcn.UI.FieldTest do
  use ExUnit.Case, async: true

  import LiveShadcn.Test.Markup
  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Field

  test "caller title classes control display, width, and alignment" do
    html =
      render_component(&Field.field_title/1, %{
        class: "grid w-full items-start gap-2 sm:flex caller-title",
        inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Delivery" end}]
      })

    title_classes = html |> slot("field-label") |> classes()

    assert MapSet.subset?(
             MapSet.new(~w(cn-field-title grid w-full items-start gap-2 sm:flex caller-title)),
             title_classes
           )

    refute "flex" in title_classes
    refute "w-fit" in title_classes
    refute "items-center" in title_classes
  end
end
