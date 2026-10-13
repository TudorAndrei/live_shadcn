defmodule StorybookWeb.AiDocsTest do
  use StorybookWeb.ConnCase, async: true

  for component <- StorybookWeb.Examples.components(),
      String.starts_with?(
        to_string(StorybookWeb.Docs.module(component)),
        "Elixir.LiveAiElements."
      ) do
    @component component

    test "#{component} documentation renders all examples together", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/docs/#{@component}")

      assert has_element?(view, "h1", StorybookWeb.Docs.title(@component))

      for example <- StorybookWeb.Examples.all(@component) do
        assert has_element?(view, "#example-#{example.id}-panel-preview")
      end
    end
  end
end
