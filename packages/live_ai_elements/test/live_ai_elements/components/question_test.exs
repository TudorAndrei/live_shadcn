defmodule LiveAiElements.Components.QuestionTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveAiElements.Components.Question

  @button_base "inline-flex items-center justify-center gap-2 rounded-md text-sm font-medium disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4 shrink-0 [&_svg]:shrink-0 outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive"
  @button_size "px-4 py-2 has-[>svg]:px-3 h-auto whitespace-normal transition-[box-shadow]"
  @default_variant "bg-primary text-primary-foreground hover:bg-primary/90"
  @outline_variant "border bg-background shadow-xs hover:bg-accent hover:text-accent-foreground dark:bg-input/30 dark:border-input dark:hover:bg-input/50"

  test "QuestionOption renders exactly one pinned button variant for each initial state" do
    assert option_class(true) == expected_class(@default_variant)
    assert option_class(false) == expected_class(@outline_variant)
  end

  test "Question parts do not render trailing class whitespace when no caller class exists" do
    option = render_component(&Question.question_option/1, option_assigns(false))

    question =
      render_component(&Question.question/1, %{id: "question", inner_block: []})

    prompt = render_component(&Question.question_prompt/1, %{inner_block: []})
    description = render_component(&Question.question_description/1, %{inner_block: []})
    options = render_component(&Question.question_options/1, %{inner_block: []})
    input = render_component(&Question.question_input/1, %{inner_block: []})
    actions = render_component(&Question.question_actions/1, %{inner_block: []})
    submit = render_component(&Question.question_submit/1, %{inner_block: []})

    for html <- [option, question, prompt, description, options, input, actions, submit] do
      refute html =~ ~r/class="[^"]* "/
    end
  end

  defp option_class(selected?) do
    html = render_component(&Question.question_option/1, option_assigns(selected?))
    [_, class] = Regex.run(~r/class="([^"]+)"/, html)
    class
  end

  defp expected_class(variant) do
    [@button_base, variant, @button_size]
    |> Enum.join(" ")
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end

  defp option_assigns(selected?) do
    %{
      is_selected: to_string(selected?),
      role: "radio",
      value: "Nuxt",
      inner_block: []
    }
  end
end
