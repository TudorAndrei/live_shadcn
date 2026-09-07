defmodule StorybookWeb.SliderPreviewTest do
  use StorybookWeb.ConnCase, async: true

  test "controlled values use the reference number display after a change", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/preview/slider/controlled")
    render_hook(view, "slider_controlled_value", %{"values" => ["0.3", "1"]})
    text = view |> element("span.text-sm") |> render() |> Floki.parse_fragment!() |> Floki.text()
    assert String.trim(text) == "0.3, 1"
  end
end
