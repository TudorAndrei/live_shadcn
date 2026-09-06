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

  @reference_dates %{
    "calendar" => ~D[2025-06-01],
    "date-picker" => ~D[2025-06-01]
  }

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")
    {opts, names, invalid} = OptionParser.parse(argv, strict: [check: :boolean, source: :string])
    if invalid != [], do: Mix.raise("invalid snapshot options: #{inspect(invalid)}")
    check? = Keyword.get(opts, :check, false)
    source = Keyword.get(opts, :source)

    components =
      scoped_components(if(names == [], do: Examples.components(), else: names), source)

    if components == [], do: Mix.raise("no snapshot components match this source")

    results =
      for component <- components,
          example <- Examples.all(component),
          do: one(component, example, check?)

    unless check?, do: write_index()

    outdated = for {:outdated, name} <- results, do: name
    expected = Enum.map(results, fn {_status, name} -> name end)

    unexpected =
      if check? and names == [] do
        unexpected_snapshot_names(snapshot_dir(), expected, if(source, do: components))
      else
        []
      end

    cond do
      check? and (outdated != [] or unexpected != []) ->
        Mix.raise("""
        snapshot files do not match the current example index.

        Outdated or missing:
          #{format_names(outdated)}

        Not in the index:
          #{format_names(unexpected)}

        Run `mix snapshot` and review the diff. A diff here is a change a reader
        would see.
        """)

      check? ->
        Mix.shell().info("every snapshot is current (#{length(results)})")

      true ->
        Mix.shell().info("wrote #{length(results)} snapshot(s)")
    end
  end

  @doc false
  def scoped_components(components, nil), do: components

  def scoped_components(components, "shadcn") do
    root = Path.expand("../../../..", __DIR__)
    docs_only = LiveShadcnVerification.docs_only_shadcn_families(root)

    Enum.filter(components, fn component ->
      component in docs_only or
        String.starts_with?(to_string(StorybookWeb.Docs.module(component)), "Elixir.LiveShadcn.")
    end)
  end

  def scoped_components(_components, source),
    do: Mix.raise("snapshot source filter supports only shadcn; received #{source}")

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

  defp sorted_attributes({tag, attrs, children}) do
    attrs =
      attrs
      |> Enum.map(&canonicalize_json_attribute/1)
      |> Enum.sort_by(&rank/1)

    {tag, attrs, sorted_attributes(children)}
  end

  defp sorted_attributes(node), do: node

  defp rank({name, _value}) do
    cond do
      name in @first -> {0, name}
      name in @last -> {2, name}
      true -> {1, name}
    end
  end

  # LiveView command attributes contain JSON. Phoenix serializes command maps
  # in VM map order, which is not stable between runs. The browser reads these
  # values as JSON objects, so their key order has no runtime meaning. A
  # snapshot must record that stable meaning instead of the VM iteration order.
  @doc false
  def canonicalize_json_attribute({name, value} = attribute)
      when is_binary(name) and is_binary(value) do
    if String.starts_with?(name, "phx-") do
      case Jason.decode(value) do
        {:ok, json} -> {name, json |> ordered_json() |> Jason.encode!()}
        {:error, _reason} -> attribute
      end
    else
      attribute
    end
  end

  def canonicalize_json_attribute(attribute), do: attribute

  defp ordered_json(value) when is_map(value) do
    value
    |> Enum.map(fn {key, nested_value} -> {key, ordered_json(nested_value)} end)
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Jason.OrderedObject.new()
  end

  defp ordered_json(value) when is_list(value), do: Enum.map(value, &ordered_json/1)
  defp ordered_json(value), do: value

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
      |> Map.merge(Examples.page_assigns(reference_date: reference_date(component)))
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

  @doc false
  def unexpected_snapshot_names(directory, expected, components \\ nil) do
    actual =
      directory
      |> Path.join("*.html")
      |> Path.wildcard()
      |> Enum.map(&Path.basename(&1, ".html"))

    actual
    |> Enum.filter(fn name ->
      is_nil(components) or Enum.any?(components, &String.starts_with?(name, &1 <> "-"))
    end)
    |> Kernel.--(expected)
    |> Enum.sort()
  end

  defp format_names([]), do: "(none)"
  defp format_names(names), do: Enum.join(names, "\n  ")

  defp reference_date(component), do: Map.get(@reference_dates, component, Date.utc_today())
end
