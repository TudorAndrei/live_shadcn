defmodule LiveShadcn.UI.TraceTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  alias LiveShadcn.UI.Trace

  test "a trace disclosure trigger connects its open state to the content panel" do
    trigger =
      render_component(&Trace.trace_collapsible_trigger/1,
        for: "command",
        open: true,
        inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Run command" end}]
      )

    content =
      render_component(&Trace.trace_collapsible_content/1,
        for: "command",
        open: true,
        class: "font-mono",
        inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Done" end}]
      )

    trigger_tree = Floki.parse_fragment!(trigger)
    content_tree = Floki.parse_fragment!(content)
    assert Floki.attribute(trigger_tree, "aria-expanded") == ["true"]
    assert Floki.attribute(trigger_tree, "aria-controls") == Floki.attribute(content_tree, "id")
    assert Floki.attribute(content_tree, "aria-labelledby") == Floki.attribute(trigger_tree, "id")
    assert Floki.find(content_tree, "[data-slot=trace-collapsible-content-inner].font-mono") != []
  end
end
