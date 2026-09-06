defmodule LiveShadcn.UI.PopoverTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Popover

  test "a wrapper trigger keeps the input group addon and button contracts" do
    html =
      render_component(&Popover.popover/1, %{
        id: "security",
        trigger_target: "wrapper",
        trigger_wrapper_slot: "popover-trigger",
        trigger_wrapper_align: "inline-start",
        trigger_wrapper_class:
          "cn-input-group-addon flex cursor-text items-center justify-center select-none cn-input-group-addon-align-inline-start order-first",
        trigger_slot: "button",
        trigger_label: "Connection security information",
        trigger_variant: "secondary",
        trigger_data_size: "icon-xs",
        trigger_class:
          "cn-input-group-button flex items-center shadow-none cn-input-group-button-size-icon-xs",
        trigger: [slot(:trigger, "Info")],
        inner_block: [slot(:inner_block, "Details")]
      })

    document = Floki.parse_fragment!(html)
    [trigger] = Floki.find(document, "#security-trigger")
    [button] = Floki.find([trigger], "button")

    assert Floki.attribute([trigger], "aria-haspopup") == ["dialog"]
    assert Floki.attribute([trigger], "aria-controls") == ["security-popup"]
    assert Floki.attribute([trigger], "data-slot") == ["popover-trigger"]
    assert Floki.attribute([trigger], "role") == ["group"]
    assert Floki.attribute([trigger], "data-align") == ["inline-start"]
    assert Floki.attribute([button], "data-slot") == ["button"]
    assert Floki.attribute([button], "data-size") == ["icon-xs"]

    assert "cn-input-group-addon" in (Floki.attribute([trigger], "class")
                                      |> hd()
                                      |> String.split())

    assert "cn-input-group-button" in (Floki.attribute([button], "class")
                                       |> hd()
                                       |> String.split())
  end

  test "a direct trigger has no owner wrapper and accepts trigger data attributes" do
    html =
      render_component(&Popover.popover/1, %{
        id: "date-picker",
        trigger_target: "direct",
        trigger_rest: %{"data-empty" => "true"},
        trigger: [slot(:trigger, "Pick a date")],
        inner_block: [slot(:inner_block, "Calendar")]
      })

    document = Floki.parse_fragment!(html)
    [trigger] = Floki.find(document, "#date-picker-trigger")

    assert Floki.find(document, "#date-picker") == []
    assert Floki.attribute([trigger], "data-empty") == ["true"]
  end

  test "a direct input group trigger keeps popup attributes on the icon button" do
    html =
      render_component(&Popover.popover/1, %{
        id: "date-picker-input",
        trigger_target: "direct",
        trigger_component: "input-group-button",
        trigger_label: "Select date",
        trigger_size: "icon-xs",
        trigger_variant: "ghost",
        trigger: [slot(:trigger, "Calendar")],
        inner_block: [slot(:inner_block, "Calendar")]
      })

    document = Floki.parse_fragment!(html)
    [trigger] = Floki.find(document, "button#date-picker-input-trigger")
    class = Floki.attribute([trigger], "class") |> hd()

    assert Floki.attribute([trigger], "data-size") == ["icon-xs"]
    assert Floki.attribute([trigger], "aria-haspopup") == ["dialog"]
    assert Floki.attribute([trigger], "aria-expanded") == ["false"]
    assert Floki.attribute([trigger], "aria-controls") == ["date-picker-input-popup"]
    assert class =~ "cn-button-size-default"
    assert class =~ "cn-input-group-button-size-icon-xs"
  end

  defp slot(name, text) do
    %{__slot__: name, inner_block: fn _, _ -> text end}
  end
end
