defmodule StorybookWeb.SearchTest do
  use StorybookWeb.ConnCase, async: true

  alias StorybookWeb.Search

  # The sidebar lists every component whatever the query, so a search is only
  # visible inside the palette's own list. Asserting against the whole page
  # would pass on the navigation and say nothing about the search.
  defp palette(html) do
    html
    |> Floki.parse_fragment!()
    |> Floki.find("[data-slot='command-list']")
    |> Floki.raw_html()
  end

  defp searched(view, query) do
    view
    |> element("form[phx-change='search']")
    |> render_change(%{"query" => query})
    |> palette()
  end

  describe "the ⌘K palette" do
    test "filters the component list as you type", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/docs/badge")
      results = searched(view, "accord")

      assert results =~ "/docs/accordion"
      refute results =~ "/docs/badge"
    end

    test "answers on the index too, not only on a component page", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      assert searched(view, "slid") =~ "/docs/slider"
    end

    test "says so when nothing matches", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      assert searched(view, "nothing-by-that-name") =~ "Nothing by that name."
    end

    test "opening it costs no round trip", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/docs/badge")

      # ⌘K carries a `JS` command rather than an event name. A `phx-window-keydown`
      # holding a bare string would be a push, and the palette would wait on the
      # server to appear.
      [shortcut] =
        html
        |> Floki.parse_fragment!()
        |> Floki.find("##{Search.id()}-shortcut")
        |> Floki.attribute("phx-window-keydown")

      assert shortcut =~ "set_attr"
      refute shortcut == "search"
    end
  end

  describe "matches/1" do
    test "is the components whose name contains the query" do
      assert "accordion" in Search.matches("accord")
      refute "badge" in Search.matches("accord")
    end

    test "an empty query is every component" do
      assert length(Search.matches("")) == length(StorybookWeb.Examples.components())
    end
  end
end
