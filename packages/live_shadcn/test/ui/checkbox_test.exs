defmodule LiveShadcn.UI.CheckboxTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Checkbox

  test "a toggle updates the client state before it pushes the caller event" do
    html =
      render_component(&Checkbox.checkbox/1, %{
        id: "notifications",
        name: "notifications",
        on_toggle: "toggle_notifications"
      })

    document = Floki.parse_fragment!(html)
    [control] = Floki.find(document, "#notifications-control")
    [input] = Floki.find(document, "#notifications")

    assert Floki.attribute([control], "role") == ["checkbox"]
    assert Floki.attribute([control], "aria-checked") == ["false"]
    assert Floki.attribute([input], "type") == ["checkbox"]

    for attribute <- ["phx-click", "phx-keydown"] do
      command = Floki.attribute([control], attribute) |> hd()

      assert command =~ "toggle_attr"
      assert command =~ "aria-checked"
      assert command =~ "dispatch"
      assert command =~ "change"
      assert command =~ "push"
      assert command =~ "toggle_notifications"

      assert position(command, "push") > position(command, "dispatch")
    end
  end

  test "accessible names use an explicit relation before the generated fallback" do
    default = render_checkbox(%{})
    direct_name = render_checkbox(%{rest: %{"aria-label" => "Enable notifications"}})
    direct_atom_name = render_checkbox(%{rest: %{:"aria-label" => "Enable notifications"}})

    explicit_relation =
      render_checkbox(%{
        rest: %{
          "aria-label" => "Enable notifications",
          "aria-labelledby" => "notification-setting-label"
        }
      })

    explicit_atom_relation =
      render_checkbox(%{
        rest: %{
          :"aria-label" => "Enable notifications",
          :"aria-labelledby" => "notification-setting-label"
        }
      })

    assert attribute(default, "aria-labelledby") == ["notifications-label"]
    assert attribute(direct_name, "aria-label") == ["Enable notifications"]
    assert attribute(direct_name, "aria-labelledby") == []
    assert attribute(direct_atom_name, "aria-label") == ["Enable notifications"]
    assert attribute(direct_atom_name, "aria-labelledby") == []

    assert attribute(explicit_relation, "aria-label") == ["Enable notifications"]
    assert attribute(explicit_relation, "aria-labelledby") == ["notification-setting-label"]
    assert attribute(explicit_atom_relation, "aria-label") == ["Enable notifications"]
    assert attribute(explicit_atom_relation, "aria-labelledby") == ["notification-setting-label"]
  end

  test "an indeterminate checkbox exposes the mixed state and indicator" do
    document =
      render_component(&Checkbox.checkbox/1, %{id: "select-all", indeterminate: true})
      |> Floki.parse_fragment!()

    [control] = Floki.find(document, "#select-all-control")
    [indicator] = Floki.find(document, "[data-slot='checkbox-indicator']")

    assert Floki.attribute([control], "aria-checked") == ["mixed"]
    assert Floki.attribute([control], "data-indeterminate") == [""]
    assert Floki.attribute([indicator], "hidden") == []
  end

  defp render_checkbox(overrides) do
    assigns =
      Map.merge(
        %{id: "notifications", name: "notifications"},
        overrides
      )

    render_component(&Checkbox.checkbox/1, assigns)
    |> Floki.parse_fragment!()
    |> Floki.find("#notifications-control")
  end

  defp attribute(elements, name), do: Floki.attribute(elements, name)
  defp position(value, needle), do: value |> :binary.match(needle) |> elem(0)
end
