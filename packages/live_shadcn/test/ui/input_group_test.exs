defmodule LiveShadcn.UI.InputGroupTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.InputGroup

  test "an addon declares the shared behavior that focuses its input" do
    html =
      render_component(&InputGroup.input_group_addon/1, %{
        inner_block: [slot(:inner_block, "Search")]
      })

    [addon] = Floki.find(Floki.parse_fragment!(html), "[data-slot='input-group-addon']")

    assert Floki.attribute([addon], "data-lb-input-group-addon") == ["data-lb-input-group-addon"]
  end

  test "an autosizing group textarea declares the shared autosize behavior" do
    html =
      render_component(&InputGroup.input_group_textarea/1, %{
        autosize: true,
        placeholder: "Autoresize textarea..."
      })

    [textarea] =
      Floki.find(Floki.parse_fragment!(html), "textarea[data-slot='input-group-control']")

    assert Floki.attribute([textarea], "data-lb-autosize") == [""]
  end

  defp slot(name, text) do
    %{__slot__: name, inner_block: fn _, _ -> text end}
  end
end
