defmodule LiveShadcn.UI.NativeSelectTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.NativeSelect

  test "caller position class replaces the wrapper position and options keep their parts" do
    html =
      render_component(&NativeSelect.native_select/1, %{
        class: "absolute end-0 top-0",
        inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Options" end}]
      })

    option_html =
      render_component(&NativeSelect.native_select_option/1, %{
        rest: %{value: "letters"},
        inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Letters" end}]
      })

    document = Floki.parse_fragment!(html)
    option_document = Floki.parse_fragment!(option_html)
    [wrapper] = Floki.find(document, "[data-slot='native-select-wrapper']")
    [option] = Floki.find(option_document, "[data-slot='native-select-option']")
    [class] = Floki.attribute([wrapper], "class")

    assert class =~ "absolute"
    refute class =~ "relative"
    assert option |> Floki.text() |> String.trim() == "Letters"
  end
end
