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

    [portal] = Floki.find(document, "#_lv_portal_wrap_plan-portal")
    assert Floki.attribute([portal], "class") == []

    [positioner] = Floki.find(document, "#plan-positioner")
    assert Floki.attribute([positioner], "data-lb-anchor") == ["plan-control"]

    [option] = Floki.find(document, "#plan-option-pro")
    assert Floki.attribute([option], "phx-click") |> hd() =~ "#plan-control"
  end

  test "the trigger uses its visible value as its default accessible name" do
    html =
      render_component(&Select.select/1, %{
        id: "plan",
        value: "pro",
        option: [slot(:option, value: "pro", label: "Pro")]
      })

    [trigger] = Floki.find(Floki.parse_fragment!(html), "[data-slot='select-trigger']")

    assert Floki.attribute([trigger], "aria-labelledby") == ["plan-value"]
    assert Floki.attribute([trigger], "aria-label") == []
  end

  test "an explicit aria-label overrides the generated value label" do
    html =
      render_component(&Select.select/1, %{
        :"aria-label" => "Plan type",
        id: "plan",
        value: "pro",
        option: [slot(:option, value: "pro", label: "Pro")]
      })

    [trigger] = Floki.find(Floki.parse_fragment!(html), "[data-slot='select-trigger']")

    assert Floki.attribute([trigger], "aria-label") == ["Plan type"]
    assert Floki.attribute([trigger], "aria-labelledby") == []
  end

  test "an explicit aria-labelledby overrides the generated value label" do
    html =
      render_component(&Select.select/1, %{
        :"aria-labelledby" => "plan-label",
        id: "plan",
        value: "pro",
        option: [slot(:option, value: "pro", label: "Pro")]
      })

    [trigger] = Floki.find(Floki.parse_fragment!(html), "[data-slot='select-trigger']")

    assert Floki.attribute([trigger], "aria-labelledby") == ["plan-label"]
    assert Floki.attribute([trigger], "aria-label") == []
  end

  test "the client-owned selected label has a visible-value hook and forwards a supplied name" do
    html =
      render_component(&Select.select/1, %{
        id: "plan",
        value: "pro",
        labelledby: "plan-label",
        option: [slot(:option, value: "pro", label: "Pro")]
      })

    [value] = Floki.find(Floki.parse_fragment!(html), "[data-slot='select-value']")
    [trigger] = Floki.find(Floki.parse_fragment!(html), "[data-slot='select-trigger']")

    assert Floki.attribute([value], "data-label") == ["Pro"]
    assert Floki.attribute([value], "phx-hook") == [LiveBase.Listbox.hook()]
    assert Floki.attribute([value], "phx-mounted") |> hd() =~ "data-label"
    assert Floki.attribute([trigger], "aria-labelledby") == ["plan-label"]
  end

  test "text value mode keeps the client-owned value target without a visible wrapper" do
    html =
      render_component(&Select.select/1, %{
        id: "currency",
        value: "$",
        value_as_text: true,
        option: [slot(:option, value: "$", label: "$")]
      })

    document = Floki.parse_fragment!(html)

    assert Floki.find(document, "[data-slot='select-value']") == []

    [value] = Floki.find(document, "#currency-value")
    assert Floki.attribute([value], "class") == ["contents"]
    assert Floki.attribute([value], "phx-hook") == [LiveBase.Listbox.hook()]
    assert Floki.attribute([value], "phx-mounted") |> hd() =~ "data-label"
  end

  test "the Select positioner passes the official side and alignment offsets to Floating" do
    html =
      render_component(&Select.select/1, %{
        id: "offset-select",
        side_offset: 10,
        align_offset: -8,
        option: [slot(:option, value: "pro", label: "Pro")]
      })

    [positioner] = Floki.find(Floki.parse_fragment!(html), "#offset-select-positioner")

    assert Floki.attribute([positioner], "data-lb-offset") == ["10"]
    assert Floki.attribute([positioner], "data-lb-align-offset") == ["-8"]
  end

  test "the Select keeps its native form value at the Base UI visually hidden geometry" do
    html =
      render_component(&Select.select/1, %{
        id: "fruit",
        option: [slot(:option, value: "apple", label: "Apple")]
      })

    [input] = Floki.find(Floki.parse_fragment!(html), "#fruit-input")

    assert Floki.attribute([input], "aria-hidden") == ["true"]
    assert Floki.attribute([input], "tabindex") == ["-1"]
    assert Floki.attribute([input], "style") |> hd() =~ "clip-path: inset(50%)"
    assert Floki.attribute([input], "style") |> hd() =~ "width: 1px"
    assert Floki.attribute([input], "style") |> hd() =~ "position: fixed"
  end

  defp slot(name, attrs) do
    attrs
    |> Map.new()
    |> Map.put(:__slot__, name)
  end
end
