defmodule LiveShadcn.UI.ToggleGroupTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.ToggleGroup

  test "selection values do not become native button values" do
    for {native_value, expected} <- [{nil, []}, {"submit-bold", ["submit-bold"]}] do
      html =
        render_component(&ToggleGroup.toggle_group/1, %{
          id: "format",
          item: [
            %{
              __slot__: :item,
              value: "bold",
              native_value: native_value,
              inner_block: fn _, _ -> "Bold" end
            }
          ]
        })

      button = html |> Floki.parse_fragment!() |> Floki.find("button")
      assert Floki.attribute(button, "value") == expected
    end
  end
end
