defmodule LiveShadcn.UI.SliderTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Slider

  test "a scalar value renders one range input and one thumb" do
    html =
      render_component(&Slider.slider/1, %{
        id: "previous-context-peek",
        value: 64,
        min: 64,
        max: 128,
        label: "Previous context peek"
      })

    document = Floki.parse_fragment!(html)

    assert Floki.find(document, "[data-lb-slider-input]") |> length() == 1
    assert Floki.find(document, "[data-slot='slider-thumb']") |> length() == 1

    [input] = Floki.find(document, "#previous-context-peek-0")
    assert Floki.attribute([input], "value") == ["64"]
    assert Floki.attribute([input], "aria-label") == ["Previous context peek"]
    assert Floki.find(document, "#previous-context-peek-1") == []
  end

  test "an on_change event is available to the registered slider hook" do
    html =
      render_component(&Slider.slider/1, %{
        id: "previous-context-peek",
        value: 64,
        min: 64,
        max: 128,
        on_change: "message_scroller_peek"
      })

    document = Floki.parse_fragment!(html)
    [slider] = Floki.find(document, "#previous-context-peek")

    assert Floki.attribute([slider], "phx-hook") == ["LiveBase.Slider"]
    assert Floki.attribute([slider], "data-lb-change-event") == ["message_scroller_peek"]
  end

  test "a value list renders one range input and thumb for each value" do
    html =
      render_component(&Slider.slider/1, %{
        id: "tier-range",
        value: [20, 80],
        min: 0,
        max: 100
      })

    document = Floki.parse_fragment!(html)

    assert Floki.find(document, "[data-lb-slider-input]") |> length() == 2
    assert Floki.find(document, "[data-slot='slider-thumb']") |> length() == 2
  end
end
