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

    test "component documentation is reachable from the index", %{conn: conn} do
      {:ok, _view, index} = live(conn, "/")

      for component <- Examples.components() do
        assert index =~ "/docs/#{component}"
      end
    end
  end

  describe "a component's documentation page" do
    test "does not accept verification without current reference evidence", %{conn: conn} do
      {:ok, _view, shadcn} = live(conn, "/docs/badge")
      {:ok, _view, ai_elements} = live(conn, "/docs/audio-player")

      assert shadcn =~ ~s(data-component-status="unverified")
      assert ai_elements =~ ~s(data-component-status="unverified")
    end

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

  describe "the navigation" do
    test "puts every documented component in exactly one group" do
      grouped = StorybookWeb.Docs.groups() |> Enum.flat_map(& &1.components)

      assert Enum.sort(grouped) == Enum.sort(Examples.components())
      assert Enum.uniq(grouped) == grouped
    end

    test "groups them by the section their own documentation files them under", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/docs/badge")

      # Read from the manifest `mix ui.fetch` writes, not typed here: the
      # sections are upstream's, and a test that named them would be a second
      # copy of the thing being checked.
      #
      # A section may name a component this repository does not build —
      # `canvas` is `unsupported`, see ROADMAP.md — and one that has a page is
      # in its own section.
      for %{"title" => title, "components" => components} <- sections() do
        assert html =~ title

        for name <- components, documented?(name) do
          assert html =~ ~s(/docs/#{name}") or html =~ "-#{name}\""
        end
      end
    end

    defp documented?(name) do
      components = Examples.components()
      name in components or "ai_elements-#{name}" in components
    end

    test "names each package once, on the first group that ships in it" do
      # A group says the package in its title or beside it, and a package that
      # draws components is said once — not on all five of its sections.
      said =
        StorybookWeb.Docs.groups()
        |> Enum.flat_map(&[&1.package, &1.title])
        |> Enum.reject(&is_nil/1)

      for library <- StorybookWeb.Docs.libraries(), library.components != [] do
        assert Enum.count(said, &(&1 == library.package)) == 1
      end
    end

    defp sections do
      "../../../registry/UPSTREAM.json"
      |> Path.expand(__DIR__)
      |> File.read!()
      |> Jason.decode!()
      |> get_in(["groups", "ai_elements"])
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
