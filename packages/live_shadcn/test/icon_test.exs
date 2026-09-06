defmodule LiveShadcn.IconTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveShadcn.Icon

  test "an SVG has no exterior whitespace" do
    html = render_component(&Icon.icon/1, %{name: "git-commit-horizontal"})

    assert html == String.trim(html)
  end

  test "a false Boolean SVG attribute is absent" do
    html = render_component(&Icon.icon/1, %{name: "folder-open", rest: %{hidden: false}})

    assert Floki.attribute(Floki.parse_fragment!(html), "svg", "hidden") == []
  end

  test "a true Boolean SVG attribute is present" do
    html = render_component(&Icon.icon/1, %{name: "folder-open", rest: %{hidden: true}})

    assert Floki.attribute(Floki.parse_fragment!(html), "svg", "hidden") != []
  end

  test "an explicitly labelled SVG is not hidden from assistive technology" do
    html =
      render_component(&Icon.icon/1, %{
        name: "loader-2",
        rest: %{role: "status", "aria-label": "Loading"}
      })

    document = Floki.parse_fragment!(html)

    assert Floki.attribute(document, "svg", "role") == ["status"]
    assert Floki.attribute(document, "svg", "aria-label") == ["Loading"]
    assert Floki.attribute(document, "svg", "aria-hidden") == []
  end
end
