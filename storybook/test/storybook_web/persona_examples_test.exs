defmodule StorybookWeb.PersonaExamplesTest do
  use StorybookWeb.ConnCase, async: true

  test "Persona documentation keeps each variant's animation state separate", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/docs/persona")

    for variant <- ~w(command glint halo mana obsidian opal) do
      assert has_element?(
               view,
               "#example-#{variant}-panel-preview [data-persona-variant='#{variant}'][data-persona-state='idle']"
             )
    end

    view
    |> element("#example-command-panel-preview button[aria-label='Listening']")
    |> render_click()

    assert has_element?(
             view,
             "#example-command-panel-preview [data-persona-state='listening']"
           )

    for variant <- ~w(glint halo mana obsidian opal) do
      assert has_element?(view, "#example-#{variant}-panel-preview [data-persona-state='idle']")
    end

    view
    |> element("#example-opal-panel-preview button[aria-label='Speaking']")
    |> render_click()

    assert has_element?(view, "#example-opal-panel-preview [data-persona-state='speaking']")
    assert has_element?(view, "#example-command-panel-preview [data-persona-state='listening']")
  end
end
