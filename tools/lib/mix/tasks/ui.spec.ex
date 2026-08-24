defmodule Mix.Tasks.Ui.Spec do
  @shortdoc "Turn the fetched upstream sources into registry/spec/<source>/<name>.json"

  @moduledoc """
  Stage 2 of the codegen pipeline.

  Reads the shadcn `.tsx` and the Base UI `.md` that `mix ui.fetch` downloaded
  and writes one JSON document per component into `registry/spec/<source>/`.

      mix ui.spec                     # every component that has both sources
      mix ui.spec accordion           # one component
      mix ui.spec shadcn/message      # one component, said unambiguously
      mix ui.spec --check             # exit 1 if any spec on disk is stale

  The directory is per source because a name is not an identity: upstream has a
  `message` in the shadcn registry and a different `message` in AI Elements.

  The spec is committed and the upstream sources are not, so the spec is the
  reviewable record of what upstream says. Each spec carries the SHA-256 of the
  two files it was built from: if a digest in the spec and the digest in
  `registry/UPSTREAM.json` disagree, the spec is stale and `--check` fails.

  A component with no Base UI page is skipped, not guessed at. The Base UI page
  is where the data-attribute contract comes from, and a component generated
  without it would emit attributes nobody promised.
  """
  use Mix.Task

  import LiveShadcnTools

  alias LiveShadcnTools.Spec
  alias LiveShadcnTools.Style

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")
    {opts, names, _} = OptionParser.parse(argv, strict: [check: :boolean])
    check? = Keyword.get(opts, :check, false)

    manifest = read_json!(registry_path("UPSTREAM.json"))
    inventory = read_json!(registry_path("INVENTORY.json"))
    recipes = Map.new(inventory["components"], &{{&1["source"], &1["name"]}, &1["recipe"]})
    styles = styles(manifest)

    components = if names == [], do: fetched(manifest), else: Enum.map(names, &resolve/1)
    if names == [], do: inventoried!(recipes, manifest)
    results = settle(components, manifest, recipes, styles, check?)

    report(results, check?)
  end

  # The inventory names components; the manifest records what was fetched. A
  # name in one and not the other is a disagreement nobody would see: this task
  # walks what was fetched, so an inventory entry with no source is never
  # mentioned at all, and it still counts toward "63 components" wherever
  # somebody adds the list up.
  #
  # `form` was one. shadcn publishes a `form` in its Radix base and not in the
  # Base UI one this project reads, so a recipe and a tier had been decided for
  # a file that does not exist.
  defp inventoried!(recipes, manifest) do
    fetched = MapSet.new(fetched(manifest))

    case for(
           name <- Map.keys(recipes),
           not MapSet.member?(fetched, name),
           do: ref(elem(name, 0), elem(name, 1))
         ) do
      [] ->
        :ok

      missing ->
        Mix.raise("""
        the inventory names #{length(missing)} component(s) that were never fetched: \
        #{Enum.join(Enum.sort(missing), ", ")}

        Either the registry stopped publishing them, or the name is wrong. \
        Remove the entry or run `mix ui.fetch`.
        """)
    end
  end

  # A spec that reads another spec is a fixpoint, not a sequence.
  #
  # `combobox` renders shadcn's input group and records the element that ends up
  # as, and it reads that off the input group's spec. Whether that spec was
  # current when combobox was built depends on the order the two were built in,
  # which is alphabetical and means nothing. So the run repeats until no file
  # moves, and one extra pass is what it costs to stop caring about the order.
  #
  # Two passes always settle it today: a reference is one deep. The cap is
  # three, because a run that has not settled by then has a cycle in it, and a
  # cycle is a thing to hear about rather than to loop on.
  @passes 3

  defp settle(components, manifest, recipes, styles, check?, pass \\ 1, written \\ []) do
    results = Enum.map(components, &one(&1, manifest, recipes, styles, check?))
    written = written ++ for {:wrote, reference} <- results, do: reference

    if not check? and pass < @passes and Enum.any?(results, &match?({:wrote, _}, &1)) do
      settle(components, manifest, recipes, styles, check?, pass + 1, written)
    else
      # What the run wrote, not what its last pass wrote. By the last pass every
      # file is already what it should be, which is the point of the pass and
      # not something to report as having done nothing.
      Enum.map(results, fn
        {:current, reference} ->
          if reference in written, do: {:wrote, reference}, else: {:current, reference}

        result ->
          result
      end)
    end
  end

  # A component in one registry may be built out of a component in the other,
  # and the reader folds that one's markup in rather than calling it. So the
  # spec it folds has to be on disk, which is why this reads the file rather
  # than a half-built map, and why `settle/6` runs until the files stop moving.
  defp resolve_spec(source, name) do
    path = spec_path(source, name)
    if File.exists?(path), do: read_json!(path)
  end

  # The `cn-` rules, one map per shadcn style. A missing sheet is reported once
  # here rather than per component.
  defp styles(manifest) do
    manifest
    |> Map.get("files", %{})
    |> Map.keys()
    |> Enum.filter(&String.starts_with?(&1, "shadcn/styles/"))
    |> Enum.sort()
    |> Enum.flat_map(fn file ->
      path = registry_path(["upstream", file])

      if File.exists?(path) do
        [{Path.basename(file, ".css"), path |> File.read!() |> Style.rules()}]
      else
        Mix.shell().error("  skip #{file}: not fetched. Run `mix ui.fetch`.")
        []
      end
    end)
    |> Map.new()
  end

  # Both registries. AI Elements has no Base UI page of its own: it is built out
  # of shadcn components, which have one each, so its contract arrives through
  # the components it renders rather than through a page named after it.
  defp fetched(manifest) do
    files = Map.keys(manifest["files"] || %{})

    shadcn = for "shadcn/ui/" <> file <- files, do: {"shadcn", Path.basename(file, ".tsx")}
    ai = for "ai_elements/" <> file <- files, do: {"ai_elements", Path.basename(file, ".tsx")}

    # shadcn first, and not sorted together. An AI Elements component folds in
    # the markup of the shadcn component it renders, and it reads that spec off
    # disk, so the shadcn spec has to have been written this run.
    Enum.sort(shadcn) ++ Enum.sort(ai)
  end

  # One component that the reader cannot understand is a gap in the reader, not
  # a reason to leave the other sixty unspecced. It is reported by name and the
  # run continues, so the gaps are a list somebody can work through.
  defp one({source, name}, manifest, recipes, styles, check?) do
    tsx_file = tsx_file(source, name)
    md_file = "base_ui/#{name}.md"
    recipe = Map.get(recipes, {source, name}, "unassigned")

    with :component <- utility(recipe),
         {:ok, tsx} <- source(manifest, tsx_file),
         {:ok, pages} <- extra_pages(tsx, manifest, name) do
      # A component with no Base UI page is a component with no behaviour: a
      # card is a `<div>` with a class string. It specs from the `.tsx` alone.
      pages =
        case source(manifest, md_file) do
          {:ok, markdown} -> Map.put(pages, name, markdown)
          _absent -> pages
        end

      spec =
        Spec.build(name,
          tsx: tsx,
          module: name,
          markdown: pages,
          styles: styles,
          source: source,
          resolve: &resolve_spec/2,
          recipe: recipe,
          upstream: %{
            "shadcn" => %{"file" => tsx_file, "sha256" => digest(tsx)},
            "base_ui" => Map.new(pages, fn {mod, md} -> {mod, digest(md)} end)
          }
        )

      write_or_check(source, name, spec, check?)
    end
  rescue
    error ->
      {:unreadable, ref(source, name), Exception.message(error) |> String.split("\n") |> hd()}
  end

  # Not every file in the registry is a component. `direction` re-exports Base
  # UI's `DirectionProvider` and a hook, and renders nothing at all: what it
  # provides, HTML already has as `dir`. The inventory says so with the
  # `utility` recipe, and a component with nothing to read is not a component
  # the reader failed on.
  defp utility("utility"), do: :utility
  defp utility(_recipe), do: :component

  defp tsx_file("shadcn", name), do: "shadcn/ui/#{name}.tsx"
  defp tsx_file("ai_elements", name), do: "ai_elements/#{name}.tsx"

  # menubar is built from `@base-ui/react/menubar` and `@base-ui/react/menu`.
  # Both pages are its contract, so both are read.
  defp extra_pages(tsx, manifest, name) do
    ~r|from "@base-ui/react/([a-z0-9-]+)"|
    |> Regex.scan(tsx, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.reject(&(&1 == name))
    |> Enum.reduce_while({:ok, %{}}, fn module, {:ok, pages} ->
      case source(manifest, "base_ui/#{module}.md") do
        {:ok, markdown} -> {:cont, {:ok, Map.put(pages, module, markdown)}}
        # A module with no page of its own is not a component module: Base UI
        # publishes utilities under the same namespace.
        _missing -> {:cont, {:ok, pages}}
      end
    end)
  end

  defp source(manifest, file) do
    path = registry_path(["upstream", file])

    cond do
      not File.exists?(path) ->
        {:missing, file}

      manifest["files"][file]["sha256"] != digest(File.read!(path)) ->
        {:stale, file}

      true ->
        {:ok, File.read!(path)}
    end
  end

  defp write_or_check(source, name, spec, check?) do
    path = spec_path(source, name)
    rendered = spec |> preserve_recipe_facts(path) |> json()

    unchanged? = File.exists?(path) and File.read!(path) == rendered

    cond do
      check? and unchanged? ->
        {:current, ref(source, name)}

      check? ->
        {:outdated, ref(source, name)}

      # Already what it should be. Saying so rather than "wrote" is what lets
      # `settle/6` know the run has stopped moving.
      unchanged? ->
        {:current, ref(source, name)}

      true ->
        write!(path, rendered)
        {:wrote, ref(source, name)}
    end
  end

  # A specialist recipe can need a server-only class that does not exist in a
  # readable JSX part. Such facts live in the component spec, next to the
  # parsed facts, and must survive a later reader run.
  defp preserve_recipe_facts(spec, path) do
    with true <- File.exists?(path),
         {:ok, existing} <- path |> File.read!() |> Jason.decode(),
         %{} = classes <- existing["classes"] do
      Map.put(spec, "classes", classes)
    else
      _ -> spec
    end
  end

  defp json(spec),
    do: (spec |> Jason.encode_to_iodata!(pretty: true) |> IO.iodata_to_binary()) <> "\n"

  defp report(results, check?) do
    for {:missing, file} <- results,
        do: Mix.shell().error("  skip: #{file} is not fetched. Run `mix ui.fetch`.")

    for {:stale, file} <- results,
        do: Mix.shell().error("  skip: #{file} does not match its digest. Run `mix ui.fetch`.")

    utilities = for :utility <- results, do: :utility
    unreadable = for {:unreadable, name, why} <- results, do: "#{name}: #{why}"
    outdated = for {:outdated, name} <- results, do: name
    wrote = for {:wrote, name} <- results, do: name

    if unreadable != [] do
      Mix.shell().error("""

      #{length(unreadable)} component(s) the reader cannot understand yet:

        #{Enum.join(unreadable, "\n  ")}
      """)
    end

    cond do
      check? and outdated != [] ->
        Mix.raise("stale specs: #{Enum.join(outdated, ", ")}. Run `mix ui.spec`.")

      check? ->
        Mix.shell().info(
          "every spec is current (#{length(results) - length(unreadable) - length(utilities)})"
        )

      true ->
        Mix.shell().info("wrote #{length(wrote)} spec(s)")
    end
  end
end
