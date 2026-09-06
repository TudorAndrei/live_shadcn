defmodule LiveShadcn.UI.ButtonGroupTest do
  use ExUnit.Case, async: true

  import LiveShadcn.Test.Markup
  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.ButtonGroup

  test "the omitted orientation keeps the horizontal classes without adding a data attribute" do
    html = render_component(&ButtonGroup.button_group/1, %{})

    group = slot(html, "button-group")

    assert "cn-button-group-orientation-horizontal" in classes(group)
    assert attribute(group, "data-orientation") == nil
  end

  test "an explicit orientation is rendered as a public state attribute" do
    html = render_component(&ButtonGroup.button_group/1, %{orientation: "vertical"})

    group = slot(html, "button-group")

    assert "cn-button-group-orientation-vertical" in classes(group)
    assert attribute(group, "data-orientation") == "vertical"
  end

  test "the separator carries the independent separator contract" do
    html = render_component(&ButtonGroup.button_group_separator/1, %{})

    separator = slot(html, "button-group-separator")

    assert attribute(separator, "role") == "separator"
    assert attribute(separator, "aria-orientation") == "vertical"
    assert attribute(separator, "data-orientation") == "vertical"
    assert "shrink-0" in classes(separator)
    assert "cn-button-group-separator" in classes(separator)
  end
end
