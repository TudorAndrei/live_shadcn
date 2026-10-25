defmodule LiveShadcn.UI.MessageScrollerTest do
  use ExUnit.Case, async: true

  import Phoenix.Component, only: [sigil_H: 2]
  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.MessageScroller

  test "the provider passes scroll configuration without adding a wrapper" do
    html =
      render_component(&provider_example/1, %{
        auto_scroll: true,
        default_scroll_position: "last-anchor",
        scroll_edge_threshold: 4,
        scroll_margin: 12,
        scroll_previous_item_peek: 24
      })

    assert html =~ ~s(data-scroll-position="last-anchor")
    assert html =~ ~s(data-auto-scroll="true")
    assert html =~ ~s(data-scroll-edge-threshold="4")
    assert html =~ ~s(data-scroll-margin="12")
    assert html =~ ~s(data-previous-peek="24")
    refute html =~ "message-scroller-provider"
  end

  test "the root and viewport declare the message-specific controller contract" do
    html =
      render_component(&MessageScroller.message_scroller/1, %{
        id: "messages",
        auto_scroll: true,
        default_scroll_position: "start",
        scroll_edge_threshold: 4,
        scroll_margin: 16,
        scroll_previous_item_peek: 32,
        inner_block: [slot(:inner_block, "Messages")]
      })

    [root] = Floki.find(Floki.parse_fragment!(html), "#messages")
    assert Floki.attribute([root], "data-lb-message-scroller") == ["data-lb-message-scroller"]
    assert Floki.attribute([root], "data-lb-message-auto-scroll") == ["true"]
    assert Floki.attribute([root], "data-lb-message-default-position") == ["start"]
    assert Floki.attribute([root], "data-lb-message-scroll-edge-threshold") == ["4"]
    assert Floki.attribute([root], "data-lb-message-scroll-margin") == ["16"]
    assert Floki.attribute([root], "data-lb-message-previous-peek") == ["32"]
    assert Floki.attribute([root], "phx-mounted") |> hd() =~ "data-scrollable"
    assert Floki.attribute([root], "data-pending-scroll") == []

    viewport =
      render_component(&MessageScroller.message_scroller_viewport/1, %{
        id: "messages-viewport",
        controller: "messages",
        default_scroll_position: "start",
        inner_block: [slot(:inner_block, "Messages")]
      })

    [viewport] = Floki.find(Floki.parse_fragment!(viewport), "#messages-viewport")

    assert Floki.attribute([viewport], "data-lb-message-scroller-viewport") == [
             "data-lb-message-scroller-viewport"
           ]

    assert Floki.attribute([viewport], "data-lb-message-controller") == ["messages"]
    assert Floki.attribute([viewport], "aria-label") == ["Messages"]
    assert Floki.attribute([viewport], "phx-hook") == [LiveBase.Scroller.hook()]
    assert Floki.attribute([viewport], "phx-mounted") |> hd() =~ "data-current-anchor-id"
    assert Floki.attribute([viewport], "phx-mounted") |> hd() =~ "data-pending-scroll"
    assert Floki.attribute([viewport], "data-pending-scroll") == []
    refute Floki.attribute([viewport], "data-lb-stick-to-bottom") != []

    for position <- ["end", "last-anchor"] do
      end_root =
        render_component(&MessageScroller.message_scroller/1, %{
          id: "messages-#{position}",
          default_scroll_position: position,
          inner_block: [slot(:inner_block, "Messages")]
        })

      [end_root] = Floki.find(Floki.parse_fragment!(end_root), "#messages-#{position}")
      assert Floki.attribute([end_root], "data-pending-scroll") == [""]

      end_viewport =
        render_component(&MessageScroller.message_scroller_viewport/1, %{
          id: "messages-#{position}-viewport",
          controller: "messages-#{position}",
          default_scroll_position: position,
          inner_block: [slot(:inner_block, "Messages")]
        })

      [end_viewport] =
        Floki.find(Floki.parse_fragment!(end_viewport), "#messages-#{position}-viewport")

      assert Floki.attribute([end_viewport], "data-pending-scroll") == [""]
    end
  end

  test "content, items, and controls keep log and inactive button contracts" do
    content_html =
      render_component(&MessageScroller.message_scroller_content/1, %{
        inner_block: [slot(:inner_block, "Message")]
      })

    assert content_html =~ "data-message-scroller-spacer"
    assert content_html =~ "aria-hidden=\"true\""

    [content] =
      Floki.find(Floki.parse_fragment!(content_html), "[data-slot='message-scroller-content']")

    assert Floki.attribute([content], "role") == ["log"]
    assert Floki.attribute([content], "aria-relevant") == ["additions"]

    item =
      render_component(&MessageScroller.message_scroller_item/1, %{
        message_id: "message-7",
        scroll_anchor: true,
        inner_block: [slot(:inner_block, "Seven")]
      })

    [item] = Floki.find(Floki.parse_fragment!(item), "[data-slot='message-scroller-item']")
    assert Floki.attribute([item], "data-message-id") == ["message-7"]
    assert Floki.attribute([item], "data-scroll-anchor") == ["true"]
    assert Floki.attribute([item], "data-lb-message-intrinsic-size") == ["auto 10rem"]

    button =
      render_component(&MessageScroller.message_scroller_button/1, %{
        direction: "start",
        behavior: "auto",
        inner_block: []
      })

    [button] =
      Floki.find(Floki.parse_fragment!(button), "button[data-slot='message-scroller-button']")

    assert Floki.attribute([button], "type") == ["button"]
    assert Floki.attribute([button], "data-lb-message-scroll-behavior") == ["auto"]
    assert Floki.attribute([button], "data-active") == ["false"]
    assert Floki.attribute([button], "inert") == ["inert"]
    assert Floki.attribute([button], "tabindex") == ["-1"]
    assert Floki.attribute([button], "phx-mounted") |> hd() =~ "data-active"
    assert Floki.attribute([button], "class") |> hd() =~ "cn-button-variant-secondary"
    assert Floki.attribute([button], "class") |> hd() =~ "data-[direction=start]:top-4"
    refute Floki.attribute([button], "class") |> hd() =~ "transition-all"
  end

  test "root, viewport, and item class values have no trailing whitespace" do
    root =
      render_component(&MessageScroller.message_scroller/1, %{
        id: "messages",
        inner_block: [slot(:inner_block, "Messages")]
      })

    viewport =
      render_component(&MessageScroller.message_scroller_viewport/1, %{
        id: "messages-viewport",
        inner_block: [slot(:inner_block, "Messages")]
      })

    item =
      render_component(&MessageScroller.message_scroller_item/1, %{
        inner_block: [slot(:inner_block, "Message")]
      })

    for html <- [root, viewport, item] do
      [class] = Floki.attribute(Floki.parse_fragment!(html), "class")
      assert class == String.trim(class)
    end
  end

  defp provider_example(assigns) do
    ~H"""
    <MessageScroller.message_scroller_provider
      auto_scroll={@auto_scroll}
      default_scroll_position={@default_scroll_position}
      scroll_edge_threshold={@scroll_edge_threshold}
      scroll_margin={@scroll_margin}
      scroll_previous_item_peek={@scroll_previous_item_peek}
      :let={config}
    >
      <span
        data-auto-scroll={to_string(config.auto_scroll)}
        data-scroll-position={config.default_scroll_position}
        data-scroll-edge-threshold={config.scroll_edge_threshold}
        data-scroll-margin={config.scroll_margin}
        data-previous-peek={config.scroll_previous_item_peek}
      >
        Messages
      </span>
    </MessageScroller.message_scroller_provider>
    """
  end

  defp slot(name, text) do
    %{__slot__: name, inner_block: fn _, _ -> text end}
  end
end
