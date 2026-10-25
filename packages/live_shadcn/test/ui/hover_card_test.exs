defmodule LiveShadcn.UI.HoverCardTest do
  use ExUnit.Case, async: true

  import LiveShadcn.Test.Markup
  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.HoverCard

  test "the default hover card trigger remains a styled button" do
    trigger = slot(hover_card(), "hover-card-trigger")

    assert trigger |> elem(0) == "button"
    assert "cn-button" in classes(trigger)
    assert "cn-button-variant-link" in classes(trigger)
    assert "cn-button-size-default" in classes(trigger)
  end

  test "a native hover card trigger has only the caller class and interaction attributes" do
    trigger =
      hover_card(%{trigger_as: "native-button", trigger_class: "native-hover-card-trigger"})
      |> slot("hover-card-trigger")

    assert trigger |> elem(0) == "button"
    assert classes(trigger) == MapSet.new(["native-hover-card-trigger"])
    assert attribute(trigger, "type") == "button"
    assert attribute(trigger, "data-lb-open-on-hover") == :present
    assert attribute(trigger, "data-lb-open-delay") == "10"
    assert attribute(trigger, "data-lb-close-delay") == "100"
    assert attribute(trigger, "phx-hook") == LiveBase.InteractionTrigger.hook()
  end

  test "a native composed trigger preserves its class and rest attributes" do
    html =
      render_component(&HoverCard.hover_card_trigger/1, %{
        id: "details",
        as: "native-button",
        class: "native-outline-choice",
        "aria-label": "Open details",
        inner_block: [slot_assign(:inner_block, "Details")]
      })

    trigger = slot(html, "hover-card-trigger")

    assert trigger |> elem(0) == "button"
    assert classes(trigger) == MapSet.new(["native-outline-choice"])
    assert attribute(trigger, "aria-label") == "Open details"
    assert attribute(trigger, "data-lb-open-on-hover") == :present
  end

  defp hover_card(assigns \\ %{}) do
    render_component(
      &HoverCard.hover_card/1,
      Map.merge(
        %{
          id: "details",
          trigger: [slot_assign(:trigger, "Details")],
          inner_block: [slot_assign(:inner_block, "Content")]
        },
        assigns
      )
    )
  end

  defp slot_assign(name, text) do
    %{__slot__: name, inner_block: fn _, _ -> text end}
  end
end
