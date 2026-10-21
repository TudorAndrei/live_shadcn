defmodule LiveShadcn.UI.CodeBlockTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  alias LiveShadcn.UI.CodeBlock

  test "numbered code preserves empty lines, escapes markup, and starts at the supplied line" do
    html =
      render_component(&CodeBlock.code_block_content/1,
        code: "<script>alert(1)</script>\n\n  done\n",
        line_numbers: true,
        start_line: 12,
        wrap: true
      )

    tree = Floki.parse_fragment!(html)
    assert Floki.attribute(tree, "style") == ["counter-reset:line 11;"]
    assert Floki.attribute(tree, "data-wrap") == [""]
    assert Floki.attribute(tree, "data-numbered") == [""]
    lines = Floki.find(tree, "[data-slot=code-block-line-content]")

    assert Enum.map(lines, &Floki.text(&1, sep: "")) == [
             "<script>alert(1)</script>",
             "",
             "  done"
           ]

    assert html =~ ~r/data-slot="code-block-line-content"[^>]*>\n<\/span>/
    assert Floki.find(tree, "script") == []
  end
end
