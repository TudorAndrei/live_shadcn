defmodule LiveShadcn.UI.ToggleTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Toggle

  test "does not add a form value unless the caller supplies one" do
    plain = render_toggle(%{})
    explicit = render_toggle(%{value: "bookmark"})

    assert Floki.attribute(Floki.find(Floki.parse_fragment!(plain), "button"), "value") == []

    assert Floki.attribute(Floki.find(Floki.parse_fragment!(explicit), "button"), "value") == [
             "bookmark"
           ]
  end

  test "caller layout classes replace the default display and alignment" do
    html = render_toggle(%{class: "flex items-start justify-end"})

    classes =
      html
      |> Floki.parse_fragment!()
      |> Floki.find("button")
      |> Floki.attribute("class")
      |> hd()
      |> String.split()

    assert "flex" in classes
    assert "items-start" in classes
    assert "justify-end" in classes
    refute "inline-flex" in classes
    refute "items-center" in classes
    refute "justify-center" in classes
  end

  defp render_toggle(overrides) do
    assigns =
      Map.merge(
        %{
          id: "bookmark",
          inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Bookmark" end}]
        },
        overrides
      )

    render_component(&Toggle.toggle/1, assigns)
  end
end
