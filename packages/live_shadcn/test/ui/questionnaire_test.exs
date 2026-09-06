defmodule LiveShadcn.UI.QuestionnaireTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Questionnaire

  test "the root declares the client controller and item navigation contract" do
    html =
      render_component(&Questionnaire.questionnaire/1, %{
        id: "questionnaire-contract",
        default_item: "scope",
        item: "scope",
        items: [%{name: "scope", required: true}],
        shortcuts: "numbers",
        on_item_change: "questionnaire_item",
        on_submit: "save_questionnaire",
        on_reset: "reset_questionnaire",
        inner_block: [slot(:inner_block, "content")]
      })

    [root] = Floki.find(Floki.parse_fragment!(html), "[data-slot='questionnaire']")
    assert Floki.attribute([root], "id") == ["questionnaire-contract"]
    assert Floki.attribute([root], "phx-hook") == ["LiveBase.Questionnaire"]
    assert Floki.attribute([root], "data-default-item") == ["scope"]
    assert Floki.attribute([root], "data-item") == ["scope"]
    assert Floki.attribute([root], "data-controlled") == [""]
    assert Floki.attribute([root], "data-shortcuts") == ["numbers"]
    assert Floki.attribute([root], "data-lb-item-change-event") == ["questionnaire_item"]
    assert Floki.attribute([root], "phx-submit") == ["save_questionnaire"]
    assert Floki.attribute([root], "phx-reset") == ["reset_questionnaire"]
  end

  test "the root can close and reset its containing dialog after a valid submission" do
    html =
      render_component(&Questionnaire.questionnaire/1, %{
        id: "questionnaire-dialog-form",
        rest: %{
          "data-lb-close-dialog-on-submit" => "questionnaire-dialog",
          "data-lb-reset-on-dialog-close" => true
        },
        inner_block: [slot(:inner_block, "content")]
      })

    [root] = Floki.find(Floki.parse_fragment!(html), "[data-slot='questionnaire']")

    assert Floki.attribute([root], "data-lb-close-dialog-on-submit") == ["questionnaire-dialog"]
    assert Floki.attribute([root], "data-lb-reset-on-dialog-close") != []
  end

  test "declared items select the first enabled initial item and configure the hook" do
    html =
      render_component(&Questionnaire.questionnaire/1, %{
        id: "questionnaire-enabled-item",
        default_item: "disabled",
        items: [%{name: "disabled", disabled: true}, %{name: "scope", required: true}],
        inner_block: [slot(:inner_block, "content")]
      })

    [root] = Floki.find(Floki.parse_fragment!(html), "[data-slot='questionnaire']")
    assert Floki.attribute([root], "data-default-item") == ["scope"]
    [declared_items] = Floki.attribute([root], "data-lb-items")

    assert Jason.decode!(declared_items) == [
             %{"disabled" => true, "name" => "disabled"},
             %{"name" => "scope", "required" => true}
           ]
  end

  test "a choice keeps the official native control contract" do
    html =
      render_component(&Questionnaire.questionnaire_choice/1, %{
        value: "tests",
        type: "checkbox",
        checked: false,
        default_checked: true,
        disabled: true,
        rest: %{name: "checks"}
      })

    [input] = Floki.find(Floki.parse_fragment!(html), "[data-slot='questionnaire-choice-input']")
    [choice] = Floki.find(Floki.parse_fragment!(html), "[data-slot='questionnaire-choice']")
    assert Floki.attribute([input], "type") == ["checkbox"]
    assert Floki.attribute([input], "value") == ["tests"]
    assert Floki.attribute([input], "name") == ["checks"]
    assert Floki.attribute([input], "checked") == []
    assert Floki.attribute([choice], "data-type") == ["checkbox"]
    assert Floki.attribute([choice], "data-disabled") == [""]

    assert Floki.find(Floki.parse_fragment!(html), "[data-slot='questionnaire-choice-shortcut']") !=
             []
  end

  test "an invalid item exposes its state and the error can be described" do
    html =
      render_component(&Questionnaire.questionnaire_item/1, %{
        name: "scope",
        required: true,
        invalid: true,
        on_status_change: "scope_status",
        rest: %{"aria-describedby": "scope-error"},
        inner_block: [slot(:inner_block, "content")]
      })

    [item] = Floki.find(Floki.parse_fragment!(html), "[data-slot='questionnaire-item']")
    assert Floki.attribute([item], "data-required") == [""]
    assert Floki.attribute([item], "data-invalid") == [""]
    assert Floki.attribute([item], "aria-invalid") == ["true"]
    assert Floki.attribute([item], "data-lb-status-change-event") == ["scope_status"]
  end

  test "an item accepts the external label relation" do
    html =
      render_component(&Questionnaire.questionnaire_item/1, %{
        name: "scope",
        rest: %{"aria-labelledby" => "scope-title"},
        inner_block: [slot(:inner_block, "content")]
      })

    [item] = Floki.find(Floki.parse_fragment!(html), "[data-slot='questionnaire-item']")
    assert Floki.attribute([item], "aria-labelledby") == ["scope-title"]
  end

  test "every action merges the pinned button variant and size classes" do
    for {action, variant, layout} <- [
          {&Questionnaire.questionnaire_previous/1, "outline", "cn-questionnaire-previous"},
          {&Questionnaire.questionnaire_skip/1, "outline", "cn-questionnaire-skip"},
          {&Questionnaire.questionnaire_next/1, "default", "cn-questionnaire-next"},
          {&Questionnaire.questionnaire_submit/1, "default", "cn-questionnaire-submit"}
        ] do
      html = render_component(action, %{inner_block: []})
      [button] = Floki.find(Floki.parse_fragment!(html), "button")
      [class] = Floki.attribute([button], "class")

      assert class =~ "cn-button"
      assert class =~ "cn-button-variant-#{variant}"
      assert class =~ "cn-button-size-default"
      assert class =~ layout
    end
  end

  test "a progress part starts at one and visible parts do not hide themselves" do
    progress_html = render_component(&Questionnaire.questionnaire_progress/1, %{inner_block: []})

    item_html =
      render_component(&Questionnaire.questionnaire_item/1, %{name: "scope", inner_block: []})

    action_html = render_component(&Questionnaire.questionnaire_next/1, %{inner_block: []})

    [progress] =
      Floki.find(Floki.parse_fragment!(progress_html), "[data-slot='questionnaire-progress']")

    [item] = Floki.find(Floki.parse_fragment!(item_html), "[data-slot='questionnaire-item']")
    [action] = Floki.find(Floki.parse_fragment!(action_html), "[data-slot='questionnaire-next']")

    assert Floki.attribute([progress], "aria-valuemin") == ["1"]
    assert Floki.attribute([item], "aria-hidden") == []
    assert Floki.attribute([action], "aria-hidden") == []
  end

  test "a fraction progress part preserves the pinned compact format" do
    html =
      render_component(&Questionnaire.questionnaire_progress/1, %{
        format: "fraction",
        current: 1,
        total: 2,
        inner_block: []
      })

    [progress] = Floki.find(Floki.parse_fragment!(html), "[data-slot='questionnaire-progress']")

    assert progress |> Floki.text() |> String.trim() == "1 / 2"
  end

  defp slot(name, text), do: %{__slot__: name, inner_block: fn _, _ -> text end}
end
