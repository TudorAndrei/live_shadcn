defmodule LiveAiElements.MarkdownTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  import Phoenix.Component, only: [sigil_H: 2]

  alias LiveAiElements.Markdown

  setup do
    before = Application.get_env(:live_ai_elements, :markdown)

    on_exit(fn ->
      if before,
        do: Application.put_env(:live_ai_elements, :markdown, before),
        else: Application.delete_env(:live_ai_elements, :markdown)
    end)
  end

  defp render(content, streaming \\ false) do
    assigns = %{content: content, streaming: streaming}

    rendered_to_string(~H"<Markdown.markdown content={@content} streaming={@streaming} />")
  end

  test "renders markdown with no configuration, because the dependency is the choice" do
    Application.delete_env(:live_ai_elements, :markdown)

    assert Markdown.renderer() == Markdown.Streamdown
    assert render("**bold**") =~ "<strong>bold</strong>"
  end

  test "renders the text when the renderer is turned off" do
    Application.put_env(:live_ai_elements, :markdown, nil)

    assert Markdown.renderer() == nil
    assert render("**bold**") =~ "**bold**"
  end

  test "a renderer that is configured but not loaded degrades rather than raising" do
    # An optional dependency the application did not install. A conversation
    # that renders its markdown as text is worse than one that renders it; an
    # application that will not boot is worse than both.
    Application.put_env(:live_ai_elements, :markdown, ThisRendererWasNeverCompiled)

    assert Markdown.renderer() == nil
    assert render("**bold**") =~ "**bold**"
  end

  test "renders a code block without a syntax highlighter installed" do
    # `phoenix_streamdown` always asks MDEx for highlighting, and MDEx raises
    # without a highlighter. It catches that and renders the block as escaped
    # text — every block, not only the code ones — so a conversation shows
    # `**bold**` and nothing says why. The adapter asks for no highlighting
    # rather than walking into it.
    refute Application.get_env(:mdex_native, :syntax_highlighter)

    html = render("Here:\n\n```elixir\nx = 1\n```\n")

    assert html =~ "<pre"
    assert html =~ "x = 1"
  end

  test "tells the renderer whether more is still arriving" do
    # `phoenix_streamdown` closes syntax a half-finished message left open, so a
    # lone `**` does not turn the rest of the conversation bold. That only works
    # if it is told the message is not finished.
    assert render("**half a bold", true) =~ "<strong>half a bold</strong>"
    refute render("**half a bold", false) =~ "<strong>"
  end
end
