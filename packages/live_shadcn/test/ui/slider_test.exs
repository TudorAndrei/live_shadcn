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

  test "explicit scalar thumbs share one value and retain distinct form controls" do
    html =
      render_component(&Slider.slider/1, %{
        id: "scalar",
        name: "amount",
        value: 50,
        thumb_count: 2
      })

    inputs = html |> Floki.parse_fragment!() |> Floki.find("input[type=range]")

    assert Floki.attribute(inputs, "id") == ["scalar-0", "scalar-1"]
    assert Floki.attribute(inputs, "value") == ["50", "50"]
    assert Floki.attribute(inputs, "name") == ["amount", "amount"]
  end

  test "thumb_count requires a positive integer and only duplicates scalar values" do
    for count <- [0, -1, 1.5, "2"] do
      assert_raise ArgumentError, ~r/thumb_count/, fn ->
        render_component(&Slider.slider/1, %{id: "scalar", value: 50, thumb_count: count})
      end
    end

    assert_raise ArgumentError, ~r/scalar/, fn ->
      render_component(&Slider.slider/1, %{id: "range", value: [20, 80], thumb_count: 2})
    end
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
