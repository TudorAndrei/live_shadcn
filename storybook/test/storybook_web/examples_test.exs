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

    test "is reachable from the index", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      for component <- Examples.components(), example <- Examples.all(component) do
        assert html =~ "/preview/#{component}/#{example.id}"
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
