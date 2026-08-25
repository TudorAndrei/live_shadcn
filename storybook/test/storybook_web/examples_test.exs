defmodule StorybookWeb.ExamplesTest do
  use StorybookWeb.ConnCase, async: true

  alias StorybookWeb.Examples

  describe "every example" do
    test "renders on a page of its own", %{conn: conn} do
      for component <- Examples.components(), example <- Examples.all(component) do
        {:ok, _view, html} = live(conn, "/preview/#{component}/#{example.id}")

        assert html =~ ~s(data-preview="#{component}")
      end
    end

    # Two hops now rather than one. The index used to render every example on a
    # single page; it lists the components, and a component's own page lists its
    # examples. The contract is the same one: nothing is documented that a
    # reader cannot get to.
    test "is reachable from the index", %{conn: conn} do
      {:ok, _view, index} = live(conn, "/")

      for component <- Examples.components() do
        assert index =~ "/docs/#{component}"

        {:ok, _view, page} = live(conn, "/docs/#{component}")

        for example <- Examples.all(component) do
          assert page =~ "/preview/#{component}/#{example.id}"
        end
      end
    end
  end

  describe "a component's documentation page" do
    test "shows the markup each example is written with", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/docs/badge")

      # Read out of `examples.ex` rather than typed here, so this checks that
      # the source reached the page and not that somebody kept two copies of it.
      [example] = Examples.all("badge")
      source = StorybookWeb.Docs.source(example)

      assert source =~ "<.badge"
      assert html =~ Phoenix.HTML.html_escape(source) |> Phoenix.HTML.safe_to_string()
    end

    test "shows every attribute the component declares", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/docs/badge")

      for %{attrs: attrs} <- StorybookWeb.Docs.api("badge"), attr <- attrs do
        assert html =~ to_string(attr.name)
      end
    end

    test "is a 404 for a component nobody documented", %{conn: conn} do
      assert_raise StorybookWeb.DocsLive.NotFound, fn ->
        live(conn, "/docs/nothing-by-that-name")
      end
    end
  end

  describe "an example that does not exist" do
    test "is a 404, not a blank page", %{conn: conn} do
      assert_raise StorybookWeb.PreviewLive.NotFound, fn ->
        live(conn, "/preview/accordion/nothing-by-that-name")
      end
    end
  end

  describe "the page around the component" do
    test "supplies the heading levels above the component's own", %{conn: conn} do
      # The accordion's headings are `h3`, which Base UI documents. A page that
      # jumps from `h1` to `h3` fails axe-core, and the component is not the
      # place to fix it.
      {:ok, _view, html} = live(conn, "/preview/accordion/default")
      document = Floki.parse_fragment!(html)

      assert [_] = Floki.find(document, "h1")
      assert [_] = Floki.find(document, "h2")
      assert Floki.find(document, "h3") != []
    end
  end
end
