defmodule LiveShadcnVerification do
  @moduledoc false

  @docs_only_required_checks ~w(snapshot examples browser behavior accessibility parity pixel)

  @verification_rule_globs [
    "tools/lib/mix/tasks/ui.verify.ex",
    "tools/lib/live_shadcn_tools.ex",
    "tools/lib/live_shadcn_tools/browser_verification.ex",
    "tools/lib/live_shadcn_tools/incremental_verification.ex",
    "tools/lib/live_shadcn_tools/playwright_report.ex",
    "tools/lib/live_shadcn_tools/ai_elements_examples.ex",
    "tools/lib/live_shadcn_tools/shadcn_examples.ex",
    "tools/lib/live_shadcn_tools/verification_policy.ex",
    "registry/VERIFICATION_POLICY.json",
    "storybook/test/browser/*.mjs",
    "storybook/test/browser/ai-component-audit.json",
    "storybook/test/browser/parity-divergence.json",
    "storybook/test/browser/pixel-budget.json",
    "storybook/test/browser/package-lock.json",
    "parity/package-lock.json",
    "parity/src/main.tsx",
    "parity/src/official-ai-elements.mjs",
    "parity/src/official-shadcn.mjs",
    "parity/source-lease.mjs",
    "parity/upstream.mjs",
    "parity/vite.config.mjs"
  ]

  @unresolved_reason "the generated port does not contain this source literal"

  @storybook_renderer_paths [
    "storybook/lib/storybook_web/examples.ex",
    "storybook/lib/mix/tasks/snapshot.ex",
    "storybook/lib/storybook_web/live/preview_live.ex"
  ]

  @policy_path Path.expand("../../../registry/VERIFICATION_POLICY.json", __DIR__)
  @external_resource @policy_path
  @policy_data @policy_path |> File.read!() |> Jason.decode!()
  @standard_required_checks get_in(@policy_data, ["_standard", "required_checks"])
  @policies @policy_data
            |> Map.delete("_standard")
            |> Map.new(fn {reference, %{"kind" => kind, "reason" => reason} = entry} ->
              kind =
                case kind do
                  "local_only" -> :local_only
                  "no_dom" -> :no_dom
                  "standard" -> :standard
                end

              required_checks =
                Map.get(
                  entry,
                  "required_checks",
                  if(kind == :standard, do: @standard_required_checks, else: [])
                )

              {reference,
               %{
                 kind: kind,
                 reason: reason,
                 required_checks: required_checks
               }}
            end)

  def verification_rule_globs, do: @verification_rule_globs

  def docs_only_shadcn_families(root) do
    manifest = root |> registry_path(["UPSTREAM.json"]) |> read_json!()

    primitives =
      manifest
      |> Map.get("files", %{})
      |> Map.keys()
      |> Enum.filter(&(String.starts_with?(&1, "shadcn/ui/") and String.ends_with?(&1, ".tsx")))
      |> MapSet.new(fn path -> path |> Path.basename(".tsx") end)

    manifest
    |> get_in(["examples", "shadcn"])
    |> Kernel.||(%{})
    |> Enum.filter(fn {name, examples} ->
      is_list(examples) and examples != [] and name not in primitives
    end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.sort()
  end

  def verification_policy("shadcn", name, root) do
    policy = policy_entry("shadcn", name)

    if name in docs_only_shadcn_families(root) do
      %{policy | kind: :docs_only, required_checks: @docs_only_required_checks}
    else
      policy
    end
  end

  def policy_status(source, name) do
    case policy_entry(source, name).kind do
      :local_only -> :local_only
      :no_dom -> :no_dom
      _ -> nil
    end
  end

  def policy_status_overrides do
    @policies
    |> Enum.flat_map(fn
      {reference, %{kind: kind}} when kind in [:local_only, :no_dom] ->
        status = if kind == :local_only, do: :local_only, else: :no_dom
        [{reference, status}]

      _ ->
        []
    end)
    |> Map.new()
  end

  def required_verification_checks(_source, %{required_checks: checks}) when is_list(checks),
    do: checks

  def required_verification_checks(_source, %{kind: :standard}),
    do: ~w(generated snapshot examples browser behavior accessibility parity pixel)

  def required_verification_checks(_source, _policy), do: []

  def reviewed_contract?(contract), do: unresolved_facts(contract) == []

  def unresolved_facts(contract) when is_map(contract) do
    contract
    |> Map.get("ignored", %{})
    |> Enum.filter(fn {_fact, reason} -> reason == @unresolved_reason end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.sort()
  end

  def unresolved_facts(_contract), do: []

  def policy_checks_complete?(source, policy, checks) when is_map(checks) do
    Enum.all?(required_verification_checks(source, policy), fn name ->
      case Map.get(checks, name) do
        %{"pass" => true, "gated" => false} when policy.kind in [:standard, :docs_only] -> false
        %{"pass" => true} -> true
        _ -> false
      end
    end)
  end

  def policy_checks_complete?(_source, _policy, _checks), do: false

  def verification_failed?(%{"pass" => false}, _current?), do: true

  def verification_failed?(%{"checks" => checks}, true) when is_map(checks) do
    Enum.any?(checks, fn
      {_name, %{"pass" => false}} -> true
      _check -> false
    end)
  end

  def verification_failed?(_result, _current?), do: false

  def verified_checks?(source, policy, checks) when is_map(checks) do
    policy.kind in [:standard, :docs_only] and policy_checks_complete?(source, policy, checks)
  end

  def verified_checks?(_source, _policy, _checks), do: false

  def evidence_digest("shadcn", name, root) do
    root
    |> collect_shadcn_evidence_inputs(name)
    |> evidence_digest_from_inputs()
  end

  def evidence_digest("ai_elements", name, root) do
    snapshot_index = root |> registry_path(["snapshot", "index.json"]) |> read_json!()
    key = preview_key(snapshot_index, "ai_elements", name)
    local_examples = Map.get(snapshot_index, key, [])
    manifest = root |> registry_path(["UPSTREAM.json"]) |> read_json!()

    {
      get_in(manifest, ["sources", "ai_elements", "ref"]),
      get_in(manifest, ["examples", "ai_elements", name]) || [],
      collect_fixtures(root, key),
      collect_snapshots(root, key, local_examples),
      {local_examples, manifest, collect_pinned_ai_sources(root)},
      collect_storybook_renderers(root),
      collect_verification_rules(root)
    }
    |> :erlang.term_to_binary()
    |> digest()
  end

  def collect_shadcn_evidence_inputs(root, name) do
    snapshot_index = root |> registry_path(["snapshot", "index.json"]) |> read_json!()
    key = preview_key(snapshot_index, "shadcn", name)
    local_examples = Map.get(snapshot_index, key, [])
    manifest = root |> registry_path(["UPSTREAM.json"]) |> read_json!()

    %{
      upstream_ref: get_in(manifest, ["sources", "shadcn", "ref"]),
      documented: get_in(manifest, ["examples", "shadcn", name]) || [],
      fixtures: collect_fixtures(root, key),
      snapshots: collect_snapshots(root, key, local_examples),
      evidence_inputs: collect_official_examples(root, key),
      storybook_renderers: collect_storybook_renderers(root),
      verification_rules: collect_verification_rules(root)
    }
  end

  def evidence_digest_from_inputs(%{} = inputs) do
    {
      inputs.upstream_ref,
      inputs.documented,
      inputs.fixtures,
      inputs.snapshots,
      inputs.evidence_inputs,
      inputs.storybook_renderers,
      inputs.verification_rules
    }
    |> :erlang.term_to_binary()
    |> digest()
  end

  def preview_key(snapshot_index, source, name) do
    cond do
      Map.has_key?(snapshot_index, "#{source}-#{name}") -> "#{source}-#{name}"
      Map.has_key?(snapshot_index, name) -> name
      true -> name
    end
  end

  def collect_verification_rules(root) do
    @verification_rule_globs
    |> Enum.flat_map(fn pattern -> Path.wildcard(Path.join(root, pattern)) end)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.map(&{Path.relative_to(&1, root), File.read!(&1)})
  end

  def collect_storybook_renderers(root) do
    @storybook_renderer_paths
    |> Enum.map(&Path.join(root, &1))
    |> Enum.filter(&File.regular?/1)
    |> Enum.sort()
    |> Enum.map(&{Path.relative_to(&1, root), File.read!(&1)})
  end

  def collect_fixtures(root, key) do
    root
    |> Path.join("parity/src/examples/#{key}.*.tsx")
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.map(&{Path.basename(&1), File.read!(&1)})
  end

  def collect_snapshots(root, key, local_examples) do
    local_examples
    |> Enum.map(fn example ->
      path = Path.join([root, "registry", "snapshot", "#{key}-#{example}.html"])

      {Path.relative_to(path, root),
       if(File.regular?(path), do: File.read!(path), else: :missing)}
    end)
    |> Enum.sort_by(&elem(&1, 0))
  end

  def collect_official_examples(root, key) do
    official_path = Path.join(root, "parity/official-examples.json")

    if File.exists?(official_path) do
      official_path
      |> read_json!()
      |> Enum.filter(fn {example, _path} -> String.starts_with?(example, key <> ".") end)
      |> Enum.sort()
    else
      []
    end
  end

  def collect_pinned_ai_sources(root) do
    ["registry/upstream/ai_elements/*.tsx", "registry/upstream/ai_examples/*.tsx"]
    |> Enum.flat_map(&Path.wildcard(Path.join(root, &1)))
    |> Enum.sort()
    |> Enum.map(&{Path.relative_to(&1, root), File.read!(&1)})
  end

  def evidence_current?(result, source, name, root, spec_path)
      when source in ["shadcn", "ai_elements"] do
    policy = effective_policy(source, name, root)

    current_target =
      if policy.kind == :docs_only do
        is_nil(result["spec"])
      else
        File.exists?(spec_path) and result["spec"] == digest(File.read!(spec_path)) and
          reviewed_contract?(read_json!(spec_path))
      end

    current_target and result["evidence"] == evidence_digest(source, name, root)
  end

  def pipeline_verified?(result, source, name, root, spec_path) do
    policy = verification_policy(source, name, root)

    with true <- is_map(result),
         true <- evidence_current?(result, source, name, root, spec_path),
         true <- result["pass"] == true,
         %{"checks" => checks} <- result,
         true <- verified_checks?(source, policy, checks) do
      true
    else
      _ -> false
    end
  end

  def pipeline_failed?(result, source, name, root, spec_path) do
    with true <- is_map(result),
         true <- evidence_current?(result, source, name, root, spec_path) do
      verification_failed?(result, true)
    else
      _ -> false
    end
  end

  def badge_status(result, source, name, root, spec_path) do
    with nil <- policy_status(source, name),
         true <- is_map(result) do
      policy = effective_policy(source, name, root)
      required_checks = required_verification_checks(source, policy)

      checks_complete =
        Enum.all?(required_checks, fn check ->
          case get_in(result, ["checks", check]) do
            %{"pass" => true, "gated" => false} -> false
            %{"pass" => true} -> true
            _ -> false
          end
        end)

      checks_failed =
        Enum.any?(result["checks"] || %{}, fn
          {_check, %{"pass" => false}} -> true
          _check -> false
        end)

      current_evidence = evidence_current?(result, source, name, root, spec_path)

      cond do
        result["pass"] == true and current_evidence and checks_complete -> :verified
        result["pass"] == false or (current_evidence and checks_failed) -> :failed
        true -> :unverified
      end
    else
      status when status in [:local_only, :no_dom] -> status
      _ -> :unverified
    end
  end

  def digest(binary), do: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)

  defp effective_policy("shadcn", name, root), do: verification_policy("shadcn", name, root)
  defp effective_policy(source, name, _root), do: policy_entry(source, name)

  defp policy_entry(source, name) do
    Map.get(@policies, source <> "/" <> name, %{
      kind: :standard,
      reason: nil,
      required_checks: @standard_required_checks
    })
  end

  defp registry_path(root, parts), do: Path.join([root, "registry" | List.wrap(parts)])

  defp read_json!(path), do: path |> File.read!() |> Jason.decode!()
end
