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

  defp source_files(source, name, opts) do
    main = if source == "shadcn", do: "shadcn/ui/#{name}.tsx", else: "ai_elements/#{name}.tsx"

    [main | Keyword.get(opts, :siblings, [])]
    |> Enum.uniq()
    |> Map.new(fn path -> {path, registry_path(["upstream", path]) |> File.read!()} end)
  end

  defp base_ui(old) do
    keys =
      if old["schema_version"] == 2,
        do: Map.get(old, "base_ui", %{}),
        else: get_in(old, ["upstream", "base_ui"]) || %{}

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
