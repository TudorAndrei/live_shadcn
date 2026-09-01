defmodule LiveShadcn.UI.SelectTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Select

  test "a supplied trigger id anchors the popup and option choice to that trigger" do
    html =
      render_component(&Select.select/1, %{
        id: "plan",
        trigger_id: "plan-control",
        option: [slot(:option, value: "pro", label: "Pro")]
      })

    document = Floki.parse_fragment!(html)

    [trigger] = Floki.find(document, "[data-slot='select-trigger']")
    assert Floki.attribute([trigger], "id") == ["plan-control"]
    assert Floki.attribute([trigger], "phx-click") |> hd() =~ "#plan-control"

    [positioner] = Floki.find(document, "#plan-positioner")
    assert Floki.attribute([positioner], "data-lb-anchor") == ["plan-control"]

    [option] = Floki.find(document, "#plan-option-pro")
    assert Floki.attribute([option], "phx-click") |> hd() =~ "#plan-control"
  end

  defp slot(name, attrs) do
    attrs
    |> Map.new()
    |> Map.put(:__slot__, name)
  end
end
