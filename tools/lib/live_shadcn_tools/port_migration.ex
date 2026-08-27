defmodule LiveShadcnTools.PortMigration do
  @moduledoc """
  Converts an old generated module and spec into a version 2 reviewed port.

  This module exists only for the registry migration. The final phase removes
  it with the old compiler.
  """

  import LiveShadcnTools,
    only: [module_path: 2, read_json!: 1, registry_path: 1, spec_path: 2, write!: 2]

  alias LiveShadcnTools.Converter
  alias LiveShadcnTools.Style

  @start "# live-shadcn: upstream facts start"
  @finish "# live-shadcn: upstream facts end"

  @doc "Builds and writes one checked version 2 contract and fact block."
  def migrate!(source, name, opts) do
    artifact = build!(source, name, opts)
    write!(module_path(source, name), artifact.port)
    write!(spec_path(source, name), artifact.contract_json)
    artifact
  end

  @doc "Builds one checked version 2 contract and fact block without writes."
  def build!(source, name, opts) do
    old = read_json!(spec_path(source, name))
    port = module_path(source, name) |> File.read!() |> empty_fact_block()
    files = source_files(source, name, opts)

    input = %{
      source: source,
      name: name,
      files: files,
      styles: styles(),
      base_ui: base_ui(old),
      bindings: Keyword.fetch!(opts, :bindings),
      ignored: Keyword.get(opts, :ignored, %{}),
      uses: Keyword.fetch!(opts, :uses),
      contract: nil,
      port: port
    }

    case Converter.sync(input) do
      {:updated, artifact, _changes} ->
        validate_uses!(artifact.contract["facts"], artifact.contract["uses"])
        artifact

      {:error, diagnostics} ->
        raise Enum.map_join(diagnostics, "\n", &diagnostic/1)

      {:manual, drift} ->
        raise "migration reported manual drift: #{inspect(drift)}"

      {:current, _artifact} ->
        raise "#{source}/#{name} already has a current version 2 contract"
    end
  end

  @doc "Migrates one of the three Phase 2 proof ports."
  def pilot!(name), do: pilot!(name, true)

  @doc "Previews the generic migration for one verified port."
  def preview!(source, name), do: migrate_entry!(source, name, false)

  @doc "Migrates one verified port with the generic exact-fact adapter."
  def migrate_entry!(source, name), do: migrate_entry!(source, name, true)

  @doc "Migrates all verified version 1 ports."
  def migrate_all! do
    registry_path("VERIFY.json")
    |> read_json!()
    |> Map.keys()
    |> Enum.sort()
    |> Enum.each(fn reference ->
      [source, name] = String.split(reference, "/", parts: 2)

      if read_json!(spec_path(source, name))["schema_version"] != 2 do
        migrate_entry!(source, name)
      end
    end)
  end

  @doc "Builds or writes one of the three Phase 2 proof ports."
  def pilot!("button", write?) do
    pilot_action(write?, "shadcn", "button",
      bindings: %{"copy" => ["cva/buttonVariants/*"], "derived" => %{}},
      uses: ["cva/buttonVariants/*"]
    )
  end

  def pilot!("dialog", write?) do
    pilot_action(write?, "shadcn", "dialog",
      bindings: %{"copy" => ["jsx/*"], "derived" => %{}},
      uses: ["jsx/*"]
    )
  end

  def pilot!("calendar", write?) do
    pilot_action(write?, "shadcn", "calendar",
      siblings: ["shadcn/ui/button.tsx"],
      bindings: %{"copy" => [], "derived" => calendar_bindings()},
      ignored: Map.new(calendar_ignored(), &{&1, "the reviewed month grid does not render it"}),
      uses: ["port/calendar/*"]
    )
  end

  defp pilot_action(true, source, name, opts), do: migrate!(source, name, opts)
  defp pilot_action(false, source, name, opts), do: build!(source, name, opts)

  defp migrate_entry!(source, name, write?) do
    old = read_json!(spec_path(source, name))
    original = module_path(source, name) |> File.read!()
    files = source_files(source, name, folds: Map.get(old, "folds", []))
    port = original |> reviewed_port() |> add_fact_block()

    extracted =
      converter!(%{
        source: source,
        name: name,
        files: files,
        styles: styles(),
        base_ui: base_ui(old),
        contract: nil,
        port: port
      })

    {bindings, ignored, uses, replacements} =
      binding_manifest(extracted.contract["source_facts"], original)

    migrated =
      port
      |> replace_literals(replacements)
      |> replace_variant_attrs(extracted.contract["source_facts"], bindings["copy"])
      |> replace_variant_table(bindings["copy"])
      |> preserve_empty_class_items()
      |> runtime_fact_access()
      |> add_fact_helper()
      |> format_port!()

    artifact =
      converter!(%{
        source: source,
        name: name,
        files: files,
        styles: styles(),
        base_ui: base_ui(old),
        bindings: bindings,
        ignored: ignored,
        uses: uses,
        contract: nil,
        port: migrated
      })

    validate_uses!(artifact.contract["facts"], artifact.contract["uses"])

    if write? do
      write!(module_path(source, name), artifact.port)
      write!(spec_path(source, name), artifact.contract_json)
    end

    artifact
  end

  defp converter!(input) do
    case Converter.sync(input) do
      {:updated, artifact, _changes} -> artifact
      {:current, artifact} -> artifact
      {:error, diagnostics} -> raise Enum.map_join(diagnostics, "\n", &diagnostic/1)
      {:manual, drift} -> raise "migration reported manual drift: #{inspect(drift)}"
    end
  end

  defp binding_manifest(source_facts, port) do
    variant_table? = String.contains?(port, "@variants %{")

    {bound, ignored, replacements, _values} =
      source_facts
      |> Enum.sort()
      |> Enum.reduce({[], %{}, %{}, MapSet.new()}, fn {key, value},
                                                      {bound, ignored, replacements, values} ->
        cond do
          variant_table? and cva_table_fact?(key, value, port) ->
            {[key | bound], ignored, replacements, values}

          class_fact?(key) and is_binary(value) and value != "" and quoted?(port, value) and
              not MapSet.member?(values, value) ->
            {[key | bound], ignored, Map.put(replacements, value, key), MapSet.put(values, value)}

          true ->
            reason = "the generated port does not contain this source literal"
            {bound, Map.put(ignored, key, reason), replacements, values}
        end
      end)

    bound = Enum.sort(bound)

    {derived, ignored, derived_replacements} =
      derive_composites(source_facts, ignored, port, replacements)

    uses = Enum.sort(bound ++ Map.keys(derived))

    {%{"copy" => bound, "derived" => derived}, ignored, uses,
     Map.merge(replacements, derived_replacements)}
  end

  defp derive_composites(source_facts, ignored, port, replacements) do
    candidates =
      ignored
      |> Map.keys()
      |> Enum.filter(&(class_fact?(&1) and source_facts[&1] not in [nil, ""]))
      |> Enum.uniq_by(&source_facts[&1])

    targets =
      port
      |> quoted_values()
      |> Enum.reject(&Map.has_key?(replacements, &1))
      |> Enum.filter(&(length(String.split(&1)) > 1))
      |> Enum.uniq()
      |> Enum.sort()

    {derived, used, replacements, _index} =
      Enum.reduce(targets, {%{}, MapSet.new(), %{}, 0}, fn target,
                                                           {derived, used, replacements, index} ->
        case composite_expression(target, candidates, source_facts) do
          nil ->
            {derived, used, replacements, index}

          {expression, keys} ->
            key = "port/class/#{index}"

            {
              Map.put(derived, key, expression),
              Enum.reduce(keys, used, &MapSet.put(&2, &1)),
              Map.put(replacements, target, key),
              index + 1
            }
        end
      end)

    {derived, Map.drop(ignored, MapSet.to_list(used)), replacements}
  end

  defp quoted_values(port) do
    ~r/"[^"\n]*"/
    |> Regex.scan(port)
    |> List.flatten()
    |> Enum.flat_map(fn quoted ->
      case Code.string_to_quoted(quoted) do
        {:ok, value} when is_binary(value) -> [value]
        _other -> []
      end
    end)
  end

  defp composite_expression(target, candidates, source_facts) do
    target_tokens = String.split(target)

    intervals =
      candidates
      |> Enum.flat_map(fn key ->
        tokens = source_facts[key] |> String.split()

        case subsequence_at(target_tokens, tokens) do
          nil -> []
          start -> [%{start: start, length: length(tokens), key: key}]
        end
      end)
      |> Enum.sort_by(&{-&1.length, &1.start, &1.key})
      |> take_disjoint(MapSet.new(), [])
      |> Enum.sort_by(& &1.start)

    if intervals == [] do
      nil
    else
      items = composite_items(target_tokens, intervals, 0, [])
      {%{"op" => "join", "items" => items}, Enum.map(intervals, & &1.key)}
    end
  end

  defp subsequence_at(target, source) do
    last = length(target) - length(source)

    if last < 0 do
      nil
    else
      Enum.find(0..last, fn start -> Enum.slice(target, start, length(source)) == source end)
    end
  end

  defp take_disjoint([], _occupied, selected), do: selected

  defp take_disjoint([interval | rest], occupied, selected) do
    positions = MapSet.new(interval.start..(interval.start + interval.length - 1))

    if MapSet.disjoint?(occupied, positions),
      do: take_disjoint(rest, MapSet.union(occupied, positions), [interval | selected]),
      else: take_disjoint(rest, occupied, selected)
  end

  defp composite_items(tokens, [], at, items) do
    items
    |> add_literal(Enum.slice(tokens, at, length(tokens) - at))
    |> Enum.reverse()
  end

  defp composite_items(tokens, [interval | rest], at, items) do
    items = add_literal(items, Enum.slice(tokens, at, interval.start - at))
    item = %{"fact" => interval.key}
    composite_items(tokens, rest, interval.start + interval.length, [item | items])
  end

  defp add_literal(items, []), do: items

  defp add_literal(items, tokens),
    do: [%{"literal" => Enum.join(tokens, " ")} | items]

  defp cva_table_fact?("cva/" <> rest, value, port) do
    case String.split(rest, "/") do
      [_table, "variant", _group, _choice] -> true
      [_table, "default", group] -> default_attr?(port, group, value)
      _other -> false
    end
  end

  defp cva_table_fact?(_key, _value, _port), do: false

  defp default_attr?(port, group, value) do
    Regex.match?(
      ~r/attr\(:#{Regex.escape(group)}, :string,\s*default:\s*#{Regex.escape(inspect(value))}/s,
      port
    )
  end

  defp class_fact?("jsx/" <> _rest), do: true
  defp class_fact?("cva/" <> rest), do: String.ends_with?(rest, "/base")

  defp class_fact?("file/" <> key),
    do: String.contains?(key, "/jsx/") or String.ends_with?(key, "/base")

  defp class_fact?(_key), do: false

  defp quoted?(port, value), do: String.contains?(port, inspect(value))

  defp replace_literals(port, replacements) do
    Enum.reduce(replacements, port, fn {value, key}, source ->
      quoted = inspect(value)
      access = "@upstream_facts[#{inspect(key)}]"

      source
      |> String.replace("class=#{quoted}", "class={#{access}}")
      |> String.replace(quoted, access)
    end)
  end

  defp replace_variant_attrs(port, source_facts, copied) do
    port =
      copied
      |> Enum.filter(&String.contains?(&1, "/default/"))
      |> Enum.reduce(port, fn key, source ->
        [_table, "default", group] = key |> String.trim_leading("cva/") |> String.split("/")
        value = Map.fetch!(source_facts, key)

        Regex.replace(
          ~r/(attr\(:#{Regex.escape(group)}, :string,\s*default:\s*)#{Regex.escape(inspect(value))}/s,
          source,
          "\\1@upstream_facts[#{inspect(key)}]",
          global: false
        )
      end)

    variant_groups(copied)
    |> Enum.reduce(port, fn {{table, group}, _values}, source ->
      replace_variant_values(source, table, group, copied)
    end)
  end

  defp replace_variant_values(port, table, group, copied) do
    expected =
      copied
      |> Enum.filter(&String.starts_with?(&1, "cva/#{table}/variant/#{group}/"))
      |> Enum.map(&String.replace_prefix(&1, "cva/#{table}/variant/#{group}/", ""))
      |> Enum.sort()

    pattern =
      ~r/(?<prefix>attr\(:#{Regex.escape(group)}, :string,(?:(?!\n  (?:attr|slot|def)).)*?values:\s*)(?<values>\[[^\]]*\])/s

    Regex.replace(pattern, port, fn whole, prefix, values ->
      case Code.string_to_quoted(values) do
        {:ok, ^expected} ->
          prefix <>
            "(@variant_classes |> get_in([#{inspect(table)}, #{inspect(group)}]) |> Map.keys() |> Enum.sort())"

        _other ->
          whole
      end
    end)
  end

  defp variant_groups(copied) do
    copied
    |> Enum.flat_map(fn key ->
      case String.split(key, "/") do
        ["cva", table, "variant", group, choice] -> [{{table, group}, choice}]
        _other -> []
      end
    end)
    |> Enum.group_by(&elem(&1, 0))
  end

  defp replace_variant_table(port, _copied) do
    if String.contains?(port, "@variants %{") do
      support = variant_support()

      Regex.replace(
        ~r/  # The variant tables,.*?^  defp variant_class\(table, group, value\), do: get_in\(@variants, \[table, group, value\]\)$/ms,
        port,
        "  defp variant_class(table, group, value),\n    do: get_in(@variant_classes, [table, group, value])"
      )
      |> String.replace("  #{@finish}\n", "  #{@finish}\n\n#{support}\n", global: false)
    else
      port
    end
  end

  defp variant_support do
    """
      @variant_classes (for {"cva/" <> path, value} <- @upstream_facts,
                            [table, "variant", group, choice] <- [String.split(path, "/")],
                            reduce: %{} do
        variants ->
          put_in(variants, [
            Access.key(table, %{}),
            Access.key(group, %{}),
            Access.key(choice, nil)
          ], value)
      end)

    """
    |> String.trim_trailing()
  end

  defp preserve_empty_class_items(port) do
    port
    |> String.replace(~r/(\n\s*)@class(\n\s*\])/, "\\1(@class || \"\")\\2")
    |> String.replace(", @class]", ", @class || \"\"]")
  end

  defp runtime_fact_access(port) do
    Regex.replace(~r/~H""".*?"""/s, port, fn heex ->
      Regex.replace(
        ~r/@upstream_facts\[("[^"\n]+")\]/,
        heex,
        "upstream_fact(\\1)"
      )
    end)
  end

  defp add_fact_helper(port) do
    if String.contains?(port, "upstream_fact(") and
         not String.contains?(port, "defp upstream_fact(") do
      helper = "\n  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)\n"

      String.replace(
        port,
        "  Module.get_attribute(__MODULE__, :upstream_facts)\n",
        "  Module.get_attribute(__MODULE__, :upstream_facts)\n#{helper}",
        global: false
      )
    else
      port
    end
  end

  defp reviewed_port(port) do
    Regex.replace(
      ~r/  Generated by `mix ui\.gen`.*?Change the\n  spec or the recipe, not this file\./s,
      port,
      "  Reviewed from upstream. The marked upstream fact block is synchronized.\n  The HEEx body is maintained as a LiveView port."
    )
  end

  defp add_fact_block(port) do
    block =
      "  #{@start}\n  @upstream_facts %{}\n  #{@finish}\n" <>
        "  Module.get_attribute(__MODULE__, :upstream_facts)\n"

    String.replace(port, "  use Phoenix.Component\n", "  use Phoenix.Component\n\n#{block}",
      global: false
    )
  end

  defp format_port!(port), do: port |> Code.format_string!() |> IO.iodata_to_binary()

  defp source_files(source, name, opts) do
    main = if source == "shadcn", do: "shadcn/ui/#{name}.tsx", else: "ai_elements/#{name}.tsx"

    folds =
      opts
      |> Keyword.get(:folds, [])
      |> Enum.map(fn reference ->
        [fold_source, fold_name] = String.split(reference, "/", parts: 2)
        source_path(fold_source, fold_name)
      end)

    [main | folds ++ Keyword.get(opts, :siblings, [])]
    |> Enum.uniq()
    |> relative_sources()
    |> Map.new(fn path -> {path, registry_path(["upstream", path]) |> File.read!()} end)
  end

  defp source_path("shadcn", name), do: "shadcn/ui/#{name}.tsx"
  defp source_path("ai_elements", name), do: "ai_elements/#{name}.tsx"

  defp relative_sources(paths, found \\ MapSet.new()) do
    new_paths = Enum.reject(paths, &MapSet.member?(found, &1))
    found = Enum.reduce(new_paths, found, &MapSet.put(&2, &1))

    relatives =
      Enum.flat_map(new_paths, fn path ->
        body = registry_path(["upstream", path]) |> File.read!()

        ~r|from "\./([a-z0-9-]+)"|
        |> Regex.scan(body, capture: :all_but_first)
        |> List.flatten()
        |> Enum.map(&Path.join(Path.dirname(path), "#{&1}.tsx"))
        |> Enum.filter(&(registry_path(["upstream", &1]) |> File.exists?()))
      end)

    if relatives == [], do: MapSet.to_list(found), else: relative_sources(relatives, found)
  end

  defp base_ui(old) do
    keys =
      cond do
        old["schema_version"] == 2 -> Map.get(old, "base_ui", %{})
        is_map(old["upstream"]) -> get_in(old, ["upstream", "base_ui"]) || %{}
        true -> %{}
      end

    keys
    |> Map.keys()
    |> Map.new(fn name ->
      path = registry_path(["upstream", "base_ui", "#{name}.md"])
      {name, File.read!(path)}
    end)
  end

  defp styles do
    registry_path(["upstream", "shadcn", "styles", "*.css"])
    |> Path.wildcard()
    |> Map.new(fn path ->
      {Path.basename(path, ".css"), path |> File.read!() |> Style.rules()}
    end)
  end

  defp empty_fact_block(port) do
    pattern =
      ~r/(^[ \t]*#{Regex.escape(@start)}\n).*?(^[ \t]*#{Regex.escape(@finish)}$)/ms

    Regex.replace(pattern, port, "\\1  @upstream_facts %{}\n\\2")
  end

  defp validate_uses!(facts, uses) do
    unused = facts |> Map.keys() |> Enum.reject(&covered?(&1, uses)) |> Enum.sort()

    if unused != [] do
      raise "port facts need a declared use: #{Enum.join(unused, ", ")}"
    end
  end

  defp calendar_bindings do
    %{
      "port/calendar/root" =>
        join([
          fact("jsx/Calendar/class/3"),
          literal("rdp-root"),
          fact("jsx/Calendar/class/0"),
          fact("jsx/Calendar/class/1"),
          fact("jsx/Calendar/class/2")
        ]),
      "port/calendar/months" => join([fact("jsx/Calendar/class/4"), literal("rdp-months")]),
      "port/calendar/month" => join([fact("jsx/Calendar/class/5"), literal("rdp-month")]),
      "port/calendar/nav" => join([fact("jsx/Calendar/class/6"), literal("rdp-nav")]),
      "port/calendar/button_previous" =>
        tw_merge([
          fact("cva/buttonVariants/base"),
          fact("cva/buttonVariants/variant/size/default"),
          fact("cva/buttonVariants/variant/variant/ghost"),
          fact("jsx/Calendar/class/7"),
          literal("rdp-button_previous")
        ]),
      "port/calendar/button_next" =>
        tw_merge([
          fact("cva/buttonVariants/base"),
          fact("cva/buttonVariants/variant/size/default"),
          fact("cva/buttonVariants/variant/variant/ghost"),
          fact("jsx/Calendar/class/8"),
          literal("rdp-button_next")
        ]),
      "port/calendar/month_caption" =>
        join([fact("jsx/Calendar/class/9"), literal("rdp-month_caption")]),
      "port/calendar/caption_label" =>
        join([
          fact("jsx/Calendar/class/13"),
          fact("jsx/Calendar/class/14"),
          literal("rdp-caption_label")
        ]),
      "port/calendar/month_grid" =>
        join([fact("jsx/Calendar/class/16"), literal("rdp-month_grid")]),
      "port/calendar/weekdays" => join([fact("jsx/Calendar/class/17"), literal("rdp-weekdays")]),
      "port/calendar/weekday" => join([fact("jsx/Calendar/class/18"), literal("rdp-weekday")]),
      "port/calendar/week" => join([fact("jsx/Calendar/class/19"), literal("rdp-week")]),
      "port/calendar/day" =>
        join([
          fact("jsx/Calendar/class/22"),
          fact("jsx/Calendar/class/24"),
          literal("rdp-day")
        ]),
      "port/calendar/outside" => join([fact("jsx/Calendar/class/29"), literal("rdp-outside")]),
      "port/calendar/chevron_left" =>
        join([fact("jsx/Calendar/class/32"), literal("rdp-chevron")]),
      "port/calendar/chevron_right" =>
        join([fact("jsx/Calendar/class/33"), literal("rdp-chevron")]),
      "port/calendar/day_button" =>
        tw_merge([
          fact("cva/buttonVariants/base"),
          fact("cva/buttonVariants/variant/size/icon"),
          fact("cva/buttonVariants/variant/variant/ghost"),
          fact("jsx/CalendarDayButton/class/0"),
          literal("rdp-day_button")
        ])
    }
  end

  defp calendar_ignored do
    ~w(
      cva/buttonVariants/default/size
      cva/buttonVariants/default/variant
      cva/buttonVariants/variant/size/icon-lg
      cva/buttonVariants/variant/size/icon-sm
      cva/buttonVariants/variant/size/icon-xs
      cva/buttonVariants/variant/size/lg
      cva/buttonVariants/variant/size/sm
      cva/buttonVariants/variant/size/xs
      cva/buttonVariants/variant/variant/default
      cva/buttonVariants/variant/variant/destructive
      cva/buttonVariants/variant/variant/link
      cva/buttonVariants/variant/variant/outline
      cva/buttonVariants/variant/variant/secondary
      jsx/Calendar/class/10
      jsx/Calendar/class/11
      jsx/Calendar/class/12
      jsx/Calendar/class/15
      jsx/Calendar/class/20
      jsx/Calendar/class/21
      jsx/Calendar/class/23
      jsx/Calendar/class/25
      jsx/Calendar/class/26
      jsx/Calendar/class/27
      jsx/Calendar/class/28
      jsx/Calendar/class/30
      jsx/Calendar/class/31
      jsx/Calendar/class/34
      jsx/Calendar/class/35
    )
  end

  defp fact(key), do: %{"fact" => key}
  defp literal(value), do: %{"literal" => value}
  defp join(items), do: %{"op" => "join", "items" => items}
  defp tw_merge(items), do: %{"op" => "tw_merge", "items" => items}

  defp covered?(key, patterns), do: Enum.any?(patterns, &matches?(&1, key))
  defp matches?(pattern, key) when pattern == key, do: true

  defp matches?(pattern, key) do
    String.ends_with?(pattern, "/*") and
      String.starts_with?(key, String.trim_trailing(pattern, "*"))
  end

  defp diagnostic(%{"path" => path, "message" => message}), do: "#{path}: #{message}"
  defp diagnostic(%{"message" => message}), do: message
  defp diagnostic(diagnostic), do: inspect(diagnostic)
end
