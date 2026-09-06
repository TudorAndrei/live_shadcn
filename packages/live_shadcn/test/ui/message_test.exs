defmodule LiveShadcn.UI.MessageTest do
  use ExUnit.Case, async: true

  import LiveShadcn.Test.Markup
  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Message

  test "each Message part renders its pinned slot and base class" do
    for {name, render} <- [
          {"message-group", &Message.message_group/1},
          {"message", &Message.message/1},
          {"message-avatar", &Message.message_avatar/1},
          {"message-content", &Message.message_content/1},
          {"message-footer", &Message.message_footer/1},
          {"message-header", &Message.message_header/1}
        ] do
      html = render_component(render, %{})
      element = slot(html, name)

      assert attribute(element, "data-slot") == name
      assert "cn-#{name}" in classes(element)
    end
  end

  test "a Message defaults to start alignment and exposes end alignment" do
    default = render_component(&Message.message/1, %{}) |> slot("message")
    ending = render_component(&Message.message/1, %{align: "end"}) |> slot("message")

    assert attribute(default, "data-align") == "start"
    assert attribute(ending, "data-align") == "end"
  end

  test "Message parts allow the pinned data-slot override and global attributes" do
    message =
      render_component(&Message.message/1, %{
        :"data-slot" => "reply-message",
        :"aria-label" => "Reply from Oliver",
        id: "reply-42",
        role: "article"
      })
      |> slot("reply-message")

    assert attribute(message, "id") == "reply-42"
    assert attribute(message, "role") == "article"
    assert attribute(message, "aria-label") == "Reply from Oliver"
  end

  test "caller classes replace conflicting Message base classes" do
    message = render_component(&Message.message/1, %{class: "block"}) |> slot("message")

    assert "block" in classes(message)
    refute "flex" in classes(message)
    assert "cn-message" in classes(message)
  end
end
