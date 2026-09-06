defmodule LiveBase.ScrollerTest do
  use ExUnit.Case, async: true

  alias LiveBase.Scroller

  test "message scroller state and pending state remain client-owned across a patch" do
    assert [["ignore_attrs", %{attrs: root_attrs}]] = Scroller.message_attributes(:root).ops
    assert root_attrs == ["data-scrollable", "data-autoscrolling", "data-current-anchor-id"]

    assert [["ignore_attrs", %{attrs: viewport_attrs}]] =
             Scroller.message_attributes(:viewport).ops

    assert viewport_attrs == ["data-scrollable", "data-autoscrolling", "data-current-anchor-id"]

    assert [["ignore_attrs", %{attrs: pending_attrs}]] = Scroller.pending_attributes().ops
    assert pending_attrs == ["data-pending-scroll"]

    assert [["ignore_attrs", %{attrs: button_attrs}]] = Scroller.message_attributes(:button).ops
    assert button_attrs == ["data-active", "inert", "tabindex"]
  end

  test "scroll to message dispatches the requested id and alignment to its root" do
    assert [
             [
               "dispatch",
               %{
                 event: "message-scroller:scroll-to",
                 to: "#messages",
                 detail: %{id: "message-7", align: "center", behavior: "smooth", scrollMargin: 12}
               }
             ]
           ] =
             Scroller.scroll_to_message("messages", "message-7",
               align: "center",
               behavior: "smooth",
               scroll_margin: 12
             ).ops
  end
end
