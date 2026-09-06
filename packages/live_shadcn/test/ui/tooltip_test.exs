defmodule LiveShadcn.UI.TooltipTest do
  use ExUnit.Case, async: true

  import LiveShadcn.Test.Markup
  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Tooltip

  test "an addon-wrapper trigger is the input group addon without an extra wrapper" do
    html =
      render_component(&Tooltip.tooltip/1, %{
        id: "voice",
        trigger_as: "addon-wrapper",
        trigger_slot: "input-group-addon",
        trigger_align: "inline-end",
        trigger_class: "cn-input-group-addon cn-input-group-addon-align-inline-end",
        trigger: [slot_assign(:trigger, "Voice")],
        inner_block: [slot_assign(:inner_block, "Voice Mode")]
      })

    document = Floki.parse_fragment!(html)
    [addon] = Floki.find(document, "#voice-trigger")

    assert attribute(addon, "data-slot") == "input-group-addon"
    assert attribute(addon, "data-lb-input-group-addon") == :present
    assert attribute(addon, "data-align") == "inline-end"
    assert attribute(addon, "role") == "group"
    refute Enum.any?(elem(addon, 2), &is_tuple/1)
    assert Floki.find(document, "[data-slot='input-group-addon']") == [addon]
  end

  test "caller-click mode keeps its click and hover commands separate" do
    html =
      render_component(&Tooltip.tooltip/1, %{
        id: "voice",
        trigger_click: Phoenix.LiveView.JS.add_class("voice-enabled", to: "#voice-input"),
        trigger: [slot_assign(:trigger, "Voice")],
        inner_block: [slot_assign(:inner_block, "Voice Mode")]
      })

    trigger = slot(html, "tooltip-trigger")

    assert attribute(trigger, "data-lb-caller-click") == :present
    assert attribute(trigger, "phx-click")
    assert attribute(trigger, "data-lb-hover-command")
    refute attribute(trigger, "phx-click") == attribute(trigger, "data-lb-hover-command")
  end

  defp slot_assign(name, text) do
    %{__slot__: name, inner_block: fn _, _ -> text end}
  end
end
