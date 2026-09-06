defmodule LiveShadcn.UI.BubbleTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Bubble

  test "a bubble emits its base class before its selected variant" do
    html =
      render_component(&Bubble.bubble/1, %{
        variant: "muted",
        inner_block: [slot(:inner_block, "Message")]
      })

    [bubble] = Floki.find(Floki.parse_fragment!(html), "[data-slot='bubble']")

    assert Floki.attribute([bubble], "class") == [
             "cn-bubble group/bubble relative flex w-fit min-w-0 flex-col cn-bubble-variant-muted"
           ]
  end

  defp slot(name, text) do
    %{__slot__: name, inner_block: fn _, _ -> text end}
  end
end
