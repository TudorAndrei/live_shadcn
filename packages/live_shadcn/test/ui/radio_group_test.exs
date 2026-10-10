defmodule LiveShadcn.UI.RadioGroupTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.RadioGroup

  test "optional identities render independent items with their submitted values" do
    for identity <- [%{}, %{name: "choice"}, %{id: "first"}] do
      document = render_item(Map.merge(%{value: "first"}, identity))
      [control] = Floki.find(document, "[role='radio']")
      [input] = Floki.find(document, "input[type='radio']")

      assert Floki.attribute([control], "aria-checked") == ["false"]
      assert Floki.attribute([input], "value") == ["first"]
      assert Floki.attribute([input], "name") == [Map.get(identity, :name, "choices")]
    end
  end

  test "a shared field selects its matching value and gives each item its own identity" do
    field = Phoenix.Component.to_form(%{"choice" => "second"}, as: "settings")[:choice]

    documents =
      for value <- ["first", "second", "a b", "a-b", "a_b", "a.b", "a/b"] do
        checked = value == "second"
        document = render_item(%{field: field, value: value})
        [control] = Floki.find(document, "[role='radio']")
        [input] = Floki.find(document, "input[type='radio']")

        assert Floki.attribute([control], "aria-checked") == [to_string(checked)]
        assert Floki.attribute([input], "checked") != [] == checked
        assert Floki.attribute([input], "name") == ["settings[choice]"]
        assert Floki.attribute([input], "value") == [value]
        document
      end

    ids = Enum.flat_map(documents, &Floki.attribute(Floki.find(&1, "[id]"), "id"))
    assert Enum.uniq(ids) == ids

    for {value, checked} <- [{"first", true}, {"second", false}] do
      document = render_item(%{field: field, value: value, checked: checked, id: "explicit"})

      assert Floki.attribute(Floki.find(document, "[role='radio']"), "aria-checked") == [
               to_string(checked)
             ]

      assert Floki.attribute(Floki.find(document, "input"), "id") == ["explicit"]
    end
  end

  defp render_item(overrides) do
    render_component(
      &RadioGroup.radio_group_item/1,
      Map.merge(%{group: "choices", rest: %{"aria-label" => "Choice"}}, overrides)
    )
    |> Floki.parse_fragment!()
  end
end
