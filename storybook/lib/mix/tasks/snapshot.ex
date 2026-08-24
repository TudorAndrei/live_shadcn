defmodule Mix.Tasks.Snapshot do
  @shortdoc "Render every example to registry/snapshot"

  @moduledoc """
  The markup snapshot half of `mix ui.verify`.

  Renders each example in `StorybookWeb.Examples` and writes the result to
  `registry/snapshot/<component>-<example>.html`.

      mix snapshot
      mix snapshot accordion
      mix snapshot --check    # exit 1 if a snapshot on disk is out of date

  The snapshots are committed. That is the whole point: a change to a spec, a
  recipe or a class string upstream shows up in a pull request as a diff of the
  markup a reader actually gets, rather than as a diff of the generator that
  produced it.

  The markup is pretty-printed before it is written, because a golden file
  nobody can read is a golden file nobody reviews.

  Attributes are sorted by name. HEEx writes a `:global` attribute in whatever
  order the map holding it iterates, and a map keyed by atoms does not iterate
  in the same order between runs. `pagination` passes two of them, so its
  snapshot flipped between two spellings of the same element and `mix ui.verify`
  failed on about half the runs. An element is the set of its attributes, so a
  file that records them in one order records the same fact every time.
  """
  use Mix.Task

  alias StorybookWeb.Examples

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")
    {opts, names, _} = OptionParser.parse(argv, strict: [check: :boolean])
    check? = Keyword.get(opts, :check, false)
    components = if names == [], do: Examples.components(), else: names

    results =
      for component <- components,
          example <- Examples.all(component),
          do: one(component, example, check?)

    unless check?, do: write_index()

    outdated = for {:outdated, name} <- results, do: name

    cond do
      check? and outdated != [] ->
        Mix.raise("""
        these snapshots no longer match what the components render:

          #{Enum.join(outdated, "\n  ")}

        Run `mix snapshot` and review the diff. A diff here is a change a reader
        would see.
        """)

      check? ->
        Mix.shell().info("every snapshot is current (#{length(results)})")

      true ->
        Mix.shell().info("wrote #{length(results)} snapshot(s)")
    end
  end

  # Which preview pages exist. The browser suite reads this at collection time,
  # before any server is running, so it cannot ask the application.
  defp write_index do
    index =
      Map.new(Examples.components(), fn component ->
        {component, Enum.map(Examples.all(component), & &1.id)}
      end)

    File.mkdir_p!(snapshot_dir())

    File.write!(
      Path.join(snapshot_dir(), "index.json"),
      (index |> Jason.encode_to_iodata!(pretty: true) |> IO.iodata_to_binary()) <> "\n"
    )
  end

  defp one(component, example, check?) do
    name = "#{component}-#{example.id}"
    path = Path.join(snapshot_dir(), "#{name}.html")
    rendered = render(component, example)

    cond do
      not check? ->
        File.mkdir_p!(Path.dirname(path))
        File.write!(path, rendered)
        {:wrote, name}

      File.exists?(path) and File.read!(path) == rendered ->
        {:current, name}

      true ->
        {:outdated, name}
    end
  end

  # What an element is called comes first and what it looks like comes last,
  # because a reader scanning a diff is looking for the element. Everything
  # between is alphabetical, which is an order and not a preference.
  @first ~w(data-slot id name role type)
  @last ~w(class style)

  defp sorted_attributes(nodes) when is_list(nodes), do: Enum.map(nodes, &sorted_attributes/1)

  defp sorted_attributes({tag, attrs, children}),
    do: {tag, Enum.sort_by(attrs, &rank/1), sorted_attributes(children)}

  defp sorted_attributes(node), do: node

  defp rank({name, _value}) do
    cond do
      name in @first -> {0, name}
      name in @last -> {2, name}
      true -> {1, name}
    end
  end

  defp render(component, example) do
    # A function component is called with change tracking. Rendering one by
    # hand still has to hand it the same marker.
    #
    # And the same page assigns. An example may read one — the toaster takes
    # its list from the page, because the server owns it — so the three places
    # that render an example ask `Examples` for them rather than each seeding
    # its own and drifting.
    html =
      %{__changed__: nil}
      |> Map.merge(Examples.page_assigns())
      |> example.render.()
      |> Phoenix.LiveViewTest.rendered_to_string()
      |> Floki.parse_fragment!()
      |> sorted_attributes()
      |> Floki.raw_html(pretty: true)

    # Floki already ends its pretty output with a newline, and the heredoc adds
    # one of its own. Trimming leaves exactly one, which is what every other
    # text file in the tree has: a generated file that breaks the convention
    # invites a whitespace fixer to edit it, and a generated file must never be
    # edited.
    """
    <!-- #{component} / #{example.id} — generated by `mix snapshot`. Do not edit. -->
    #{String.trim_trailing(html)}
    """
  end

  defp snapshot_dir do
    Path.expand("../../../../registry/snapshot", __DIR__)
  end
end
