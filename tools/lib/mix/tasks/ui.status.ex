defmodule Mix.Tasks.Ui.Status do
  @shortdoc "Regenerate docs/INVENTORY.md from what is actually on disk"

  @moduledoc """
  The inventory tracker.

  Status is never typed by hand. This task derives it from the files each
  pipeline stage leaves behind, so the tracker cannot drift from reality:

  | Status | Evidence on disk |
  |---|---|
  | `planned` | listed in `registry/INVENTORY.json`, nothing else |
  | `fetched` | a digest in `registry/UPSTREAM.json` |
  | `spec` | `registry/spec/<source>/<name>.json` |
  | `generated` | a module in the owning package |
  | `verified` | a passing entry in `registry/VERIFY.json`, for this spec |

  Every one of those is looked up by source *and* name. A name is not an
  identity: upstream has a `message` in the shadcn registry and a different
  `message` in AI Elements, and looking either up by name alone reports one
  component's evidence as the other's.

  `registry/INVENTORY.json` holds only the two decisions a person makes: which
  behavior recipe a component uses, and which tier it ships in.

  A component that appears upstream and is missing from the inventory is
  appended with tier 2 and recipe `unassigned`, then reported. New shadcn
  components therefore show up in the tracker on their own.

      mix ui.status
      mix ui.status --check   # exit 1 if docs/INVENTORY.md is stale (for CI)

  """
  use Mix.Task

  import LiveShadcnTools

  @statuses [:planned, :fetched, :spec, :generated, :verified]

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")
    {opts, _, _} = OptionParser.parse(argv, strict: [check: :boolean])
    check? = Keyword.get(opts, :check, false)

    inventory = read_json!(registry_path("INVENTORY.json"))
    {components, added} = merge_upstream(inventory["components"])

    if added != [] do
      Mix.shell().info(
        "new upstream components added to the inventory: #{Enum.join(added, ", ")}"
      )

      write_json!(registry_path("INVENTORY.json"), %{inventory | "components" => components})
    end

    rendered = render(inventory, Enum.map(components, &with_status/1))
    path = Path.join([repo_root(), "docs", "INVENTORY.md"])

    cond do
      not check? ->
        write!(path, rendered)
        Mix.shell().info("wrote docs/INVENTORY.md (#{length(components)} components)")

      File.exists?(path) and File.read!(path) == rendered ->
        Mix.shell().info("docs/INVENTORY.md is current")

      true ->
        Mix.raise("docs/INVENTORY.md is stale. Run `mix ui.status`.")
    end
  end

  # A component upstream that nobody has triaged yet must still be visible.
  defp merge_upstream(components) do
    known = MapSet.new(components, &{&1["source"], &1["name"]})

    upstream =
      case File.exists?(registry_path("UPSTREAM.json")) do
        false ->
          []

        true ->
          registry_path("UPSTREAM.json")
          |> read_json!()
          |> Map.get("files", %{})
          |> Map.keys()
          |> Enum.flat_map(&upstream_entry/1)
          |> Enum.uniq_by(&{&1["source"], &1["name"]})
      end

    added = Enum.reject(upstream, &MapSet.member?(known, {&1["source"], &1["name"]}))

    {Enum.sort_by(components ++ added, &{&1["source"], &1["name"]}),
     Enum.map(added, &ref(&1["source"], &1["name"]))}
  end

  defp upstream_entry("shadcn/ui/" <> file), do: entry("shadcn", file)
  defp upstream_entry("ai_elements/" <> file), do: entry("ai_elements", file)
  defp upstream_entry(_), do: []

  # What makes a fetched file a component is that it is a source file. The fetch
  # stores other things beside them — the documentation index is one — and none
  # of those is a component to triage.
  defp entry(source, file) do
    if Path.extname(file) == ".tsx" do
      [
        %{
          "name" => Path.basename(file, ".tsx"),
          "source" => source,
          "recipe" => "unassigned",
          "tier" => 2
        }
      ]
    else
      []
    end
  end

  defp with_status(component) do
    Map.put(component, "status", status_of(component))
  end

  defp status_of(%{"name" => name, "source" => source}) do
    cond do
      verified?(source, name) -> :verified
      generated?(source, name) -> :generated
      File.exists?(spec_path(source, name)) -> :spec
      fetched?(source, name) -> :fetched
      true -> :planned
    end
  end

  defp fetched?(source, name) do
    path = if source == "shadcn", do: "shadcn/ui/#{name}.tsx", else: "ai_elements/#{name}.tsx"

    case File.exists?(registry_path("UPSTREAM.json")) do
      false -> false
      true -> registry_path("UPSTREAM.json") |> read_json!() |> get_in(["files", path]) != nil
    end
  end

  defp generated?(source, name), do: File.exists?(module_path(source, name))

  # A pass counts only while it is a pass about the spec on disk. `mix ui.verify`
  # records the digest it verified, so a spec that moved on since demotes the
  # component instead of leaving a green mark nobody earned.
  defp verified?(source, name) do
    verify = registry_path("VERIFY.json")
    spec = spec_path(source, name)

    with true <- File.exists?(verify) and File.exists?(spec),
         result when is_map(result) <- get_in(read_json!(verify), [ref(source, name)]) do
      result["pass"] == true and result["spec"] == digest(File.read!(spec)) and
        result["evidence"] == verification_evidence_digest(source, name) and
        Enum.all?(result["checks"] || %{}, fn {_name, check} ->
          check["pass"] == true and check["gated"] != false
        end)
    else
      _ -> false
    end
  end

  defp render(inventory, components) do
    counts = Enum.frequencies_by(components, & &1["status"])
    total = length(components)

    """
    # Inventory

    <!-- Generated by `mix ui.status`. Do not edit by hand. -->

    #{total} components. Status is derived from the files on disk, never typed in.

    #{progress_table(counts, total)}

    ## Recipes

    Eight core recipes cover #{core_coverage(inventory, components)} of #{total} components.
    Only the recipes are written by hand; every component is data.

    #{recipe_table(components)}

    ## shadcn/ui

    #{component_table(components, "shadcn")}

    ## AI Elements

    #{component_table(components, "ai_elements")}
    """
  end

  defp progress_table(counts, total) do
    rows =
      Enum.map_join(@statuses, "\n", fn status ->
        n = Map.get(counts, status, 0)
        "| `#{status}` | #{n} | #{bar(n, total)} |"
      end)

    "| Stage | Components | |\n|---|---:|---|\n" <> rows
  end

  defp bar(n, total) do
    filled = if total == 0, do: 0, else: round(n / total * 24)
    String.duplicate("█", filled) <> String.duplicate("·", 24 - filled)
  end

  defp core_coverage(inventory, components) do
    core = MapSet.new(get_in(inventory, ["recipes", "core"]) || [])
    Enum.count(components, &MapSet.member?(core, &1["recipe"]))
  end

  defp recipe_table(components) do
    core = ~w(disclosure dialog popover listbox menu tabs form-control presentational)

    # `utility` and `unsupported` are not ways of building a component: one says
    # the file draws nothing, the other that what it draws belongs to a library.
    kind = fn
      recipe when recipe in ~w(utility unsupported) -> "not built"
      recipe -> if recipe in core, do: "core", else: "specialist"
    end

    rows =
      components
      |> Enum.group_by(& &1["recipe"])
      |> Enum.sort_by(fn {recipe, group} -> {recipe not in core, -length(group), recipe} end)
      |> Enum.map_join("\n", fn {recipe, group} ->
        "| `#{recipe}` | #{kind.(recipe)} | #{length(group)} |"
      end)

    "| Recipe | Kind | Components |\n|---|---|---:|\n" <> rows
  end

  defp component_table(components, source) do
    rows =
      components
      |> Enum.filter(&(&1["source"] == source))
      |> Enum.sort_by(&{&1["tier"], &1["name"]})
      |> Enum.map_join("\n", fn c ->
        "| `#{c["name"]}` | #{c["tier"]} | `#{c["recipe"]}` | #{mark(c["status"])} #{c["status"]} |"
      end)

    "| Component | Tier | Recipe | Status |\n|---|---:|---|---|\n" <> rows
  end

  defp mark(:verified), do: "✅"
  defp mark(:generated), do: "🟩"
  defp mark(:spec), do: "🟨"
  defp mark(:fetched), do: "🟦"
  defp mark(:planned), do: "⬜"
end
