defmodule LiveShadcnVerification do
  @moduledoc false

  @identity_version 3

  @docs_only_required_checks ~w(snapshot examples browser behavior accessibility parity pixel)

  @shared_input_globs [
    "registry/UPSTREAM.json",
    "registry/VERIFICATION_POLICY.json",
    "registry/snapshot/index.json",
    "registry/spec/shadcn/*.json",
    "packages/live_shadcn/priv/registry/*.ex",
    "packages/live_shadcn/lib/**/*.ex",
    "packages/live_base/lib/**/*.ex",
    "packages/live_base/assets/js/*.js",
    "parity/official-examples.json",
    "parity/src/examples/*.tsx",
    "parity/src/shim/**/*.{ts,tsx}",
    "parity/src/reference/**/*.tsx",
    "parity/src/main.tsx",
    "parity/src/reference-server.tsx",
    "parity/src/reference-page.tsx",
    "parity/src/reference-loader.mjs",
    "parity/src/official-shadcn.mjs",
    "parity/upstream.mjs",
    "parity/upstream-directories.mjs",
    "parity/source-lease.mjs",
    "parity/vite.config.mjs",
    "parity/package.json",
    "parity/package-lock.json",
    "storybook/assets/**/*.{css,js,mjs,json}",
    "storybook/lib/**/*.{ex,heex}",
    "storybook/test/browser/*.mjs",
    "storybook/test/browser/package.json",
    "storybook/test/browser/package-lock.json",
    "tools/lib/live_shadcn_tools/**/*.ex",
    "tools/lib/mix/tasks/ui.verify.ex",
    "tools/verification/lib/**/*.ex",
    "tools/mix.lock",
    "tools/verification/mix.lock",
    "storybook/mix.lock",
    "packages/live_base/mix.lock",
    "packages/live_shadcn/mix.lock"
  ]

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

  def identity_version, do: @identity_version

  def verification_rule_globs, do: @verification_rule_globs

  def shared_input_globs, do: @shared_input_globs

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
      :standard -> nil
      kind -> kind
    end
  end

  def policy_status_overrides do
    @policies
    |> Enum.reject(fn {_reference, %{kind: kind}} -> kind == :standard end)
    |> Map.new(fn {reference, %{kind: kind}} -> {reference, kind} end)
  end

  def status_label(:verified), do: "Verified"
  def status_label(:failed), do: "Failed"
  def status_label(:stale), do: "Stale"
  def status_label(:not_verified), do: "Not verified"
  def status_label(:no_dom), do: "No DOM"
  def status_label(:local_only), do: "Local only"
  def status_label(:excluded), do: "Outside verification"

  def status_label(status) when is_atom(status),
    do: status |> to_string() |> String.replace("_", " ") |> String.capitalize()

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
      check_outcome(name, Map.get(checks, name), policy) == :passed
    end)
  end

  def policy_checks_complete?(_source, _policy, _checks), do: false

  def verification_failed?(%{"pass" => false}, _current?), do: true

  def verification_failed?(%{"checks" => checks}, true) when is_map(checks) do
    Enum.any?(checks, fn {name, check} ->
      check_outcome(name, check, %{kind: :standard}) == :failed
    end)
  end

  def verification_failed?(_result, _current?), do: false

  def verified_checks?("shadcn" = source, policy, checks) when is_map(checks) do
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
    collect_shadcn_evidence_inputs(root, name, collect_shadcn_shared_evidence_inputs(root))
  end

  # The cache belongs to this call. Publication must make a new call so that
  # changed bytes and added or removed paths are read again.
  def evidence_digests(names, root) do
    shared = collect_shadcn_shared_evidence_inputs(root)

    Map.new(names, fn name ->
      inputs = collect_shadcn_evidence_inputs(root, name, shared)
      {name, evidence_digest_from_inputs(inputs)}
    end)
  end

  def assert_identities_unchanged!(root, captured) do
    current = evidence_digests(Map.keys(captured), root)

    Enum.each(captured, fn {name, digest} ->
      if Map.fetch!(current, name) != digest do
        Mix.raise(
          "verification inputs changed during the run for shadcn/#{name}; rerun verification"
        )
      end
    end)
  end

  defp collect_shadcn_shared_evidence_inputs(root) do
    snapshot_index = root |> registry_path(["snapshot", "index.json"]) |> read_json!()
    manifest = root |> registry_path(["UPSTREAM.json"]) |> read_json!()

    %{
      snapshot_index: snapshot_index,
      manifest: manifest,
      upstream_files: collect_shadcn_upstream_digests(manifest),
      storybook_renderers: collect_storybook_renderers(root),
      verification_rules: collect_verification_rules(root),
      shared_inputs: collect_shared_inputs(root)
    }
  end

  defp collect_shadcn_evidence_inputs(root, name, shared) do
    snapshot_index = shared.snapshot_index
    key = preview_key(snapshot_index, "shadcn", name)
    local_examples = Map.get(snapshot_index, key, [])
    manifest = shared.manifest
    spec_path = Path.join(root, "registry/spec/shadcn/#{name}.json")
    port_path = Path.join(root, "packages/live_shadcn/priv/registry/#{module_file(name)}")

    %{
      version: @identity_version,
      upstream_ref: get_in(manifest, ["sources", "shadcn", "ref"]),
      upstream_files: shared.upstream_files,
      documented: get_in(manifest, ["examples", "shadcn", name]) || [],
      contract: file_digest(spec_path),
      port: file_digest(port_path),
      fixtures: collect_fixtures(root, key),
      snapshots: collect_snapshots(root, key, local_examples),
      evidence_inputs: collect_official_examples(root, key),
      storybook_renderers: shared.storybook_renderers,
      verification_rules: shared.verification_rules,
      shared_inputs: shared.shared_inputs
    }
  end

  def evidence_digest_from_inputs(%{} = inputs) do
    {
      Map.fetch!(inputs, :version),
      inputs.upstream_ref,
      inputs.upstream_files,
      inputs.contract,
      inputs.port,
      inputs.documented,
      inputs.fixtures,
      inputs.snapshots,
      inputs.evidence_inputs,
      inputs.storybook_renderers,
      inputs.verification_rules,
      inputs.shared_inputs
    }
    |> :erlang.term_to_binary()
    |> digest()
  end

  def identity_compile_paths(root) do
    root
    |> compile_path_globs()
    |> Enum.uniq()
    |> Enum.sort()
  end

  def compile_path_globs(root) do
    (@shared_input_globs ++ @verification_rule_globs)
    |> Enum.flat_map(fn pattern -> Path.wildcard(Path.join(root, pattern)) end)
    |> Enum.reject(&generated_path?/1)
  end

  def verify_pinned_upstream_files!(root) do
    manifest = root |> registry_path(["UPSTREAM.json"]) |> read_json!()

    manifest
    |> Map.get("files", %{})
    |> Enum.filter(fn {path, _meta} -> String.starts_with?(path, "shadcn/") end)
    |> Enum.each(fn {path, %{"sha256" => expected}} ->
      local = Path.join(root, "registry/upstream/#{path}")

      if File.regular?(local) do
        actual = digest(File.read!(local))

        if actual != expected do
          Mix.raise(
            "pinned upstream file #{path} does not match registry/UPSTREAM.json; run `mix ui.fetch`"
          )
        end
      end
    end)

    :ok
  end

  def assert_identity_unchanged!(root, source, name, captured_digest) do
    current = evidence_digest(source, name, root)

    if current != captured_digest do
      Mix.raise(
        "verification inputs changed during the run for #{source}/#{name}; rerun verification"
      )
    end

    :ok
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
    |> Enum.map(&file_entry(root, &1))
  end

  def collect_storybook_renderers(root) do
    @storybook_renderer_paths
    |> Enum.map(&Path.join(root, &1))
    |> Enum.filter(&File.regular?/1)
    |> Enum.sort()
    |> Enum.map(&file_entry(root, &1))
  end

  def collect_shared_inputs(root) do
    @shared_input_globs
    |> Enum.flat_map(fn pattern -> Path.wildcard(Path.join(root, pattern)) end)
    |> Enum.reject(&generated_path?/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.map(&file_entry(root, &1))
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
    |> Enum.map(&file_entry(root, &1))
  end

  def collect_shadcn_upstream_digests(manifest) do
    manifest
    |> Map.get("files", %{})
    |> Enum.filter(fn {path, _meta} -> String.starts_with?(path, "shadcn/") end)
    |> Enum.sort()
    |> Enum.map(fn {path, %{"sha256" => sha}} -> {path, sha} end)
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

  def record_stale?(result, source, name, root, spec_path) do
    is_map(result) and map_size(result) > 0 and
      not evidence_current?(result, source, name, root, spec_path)
  end

  def pipeline_verified?(result, source, name, root, spec_path) do
    evaluate(result, source, name, root, spec_path).status == :verified
  end

  def pipeline_failed?(result, source, name, root, spec_path) do
    evaluate(result, source, name, root, spec_path).status == :failed
  end

  def badge_status(result, source, name, root, spec_path) do
    evaluate(result, source, name, root, spec_path).status
  end

  def evaluate(_result, "ai_elements", _name, _root, _spec_path) do
    %{
      status: :excluded,
      label: status_label(:excluded),
      reason: "AI Elements is outside the shadcn verification pipeline.",
      checks: []
    }
  end

  def evaluate(result, source, name, root, spec_path) do
    case policy_status(source, name) do
      status when status in [:local_only, :no_dom] ->
        %{
          status: status,
          label: status_label(status),
          reason: policy_entry(source, name).reason,
          checks: []
        }

      _ ->
        evaluate_record(result, source, name, root, spec_path)
    end
  end

  def evaluate_record(result, source, name, root, spec_path) do
    policy = effective_policy(source, name, root)
    checks = evaluate_checks(source, policy, Map.get(result, "checks", %{}))

    cond do
      not record_present?(result) ->
        not_verified_result(checks, "No verification record exists")

      record_stale?(result, source, name, root, spec_path) ->
        %{
          status: :stale,
          label: status_label(:stale),
          reason: stale_reason(result, source, name, root, spec_path),
          checks: checks
        }

      result["pass"] == true and Enum.all?(checks, &(&1.outcome == :passed)) ->
        %{
          status: :verified,
          label: status_label(:verified),
          reason: nil,
          checks: checks
        }

      Enum.any?(checks, &(&1.outcome == :failed)) or result["pass"] == false ->
        %{
          status: :failed,
          label: status_label(:failed),
          reason: failed_reason(checks),
          checks: checks
        }

      true ->
        not_verified_result(checks, incomplete_reason(checks))
    end
  end

  def evaluate_checks(source, policy, checks) when is_map(checks) do
    required_verification_checks(source, policy)
    |> Enum.map(fn name ->
      check = Map.get(checks, name)
      outcome = check_outcome(name, check, policy)

      %{
        name: name,
        outcome: outcome,
        reason: check_reason(name, check, outcome)
      }
    end)
  end

  def check_outcome(_name, %{"outcome" => "passed"}, _policy), do: :passed
  def check_outcome(_name, %{"outcome" => "failed"}, _policy), do: :failed
  def check_outcome(_name, %{"outcome" => "skipped"}, _policy), do: :skipped
  def check_outcome(_name, %{"outcome" => "incomplete"}, _policy), do: :incomplete
  def check_outcome(_name, %{"outcome" => "not_run"}, _policy), do: :not_run

  def check_outcome(_name, %{"pass" => true, "gated" => false}, %{kind: kind})
      when kind in [:standard, :docs_only],
      do: :incomplete

  def check_outcome(_name, %{"pass" => true}, _policy), do: :passed
  def check_outcome(_name, %{"pass" => false}, _policy), do: :failed
  def check_outcome(_name, nil, _policy), do: :not_run
  def check_outcome(_name, _check, _policy), do: :incomplete

  def with_check_outcome(check) when is_map(check) do
    outcome =
      case check do
        %{"outcome" => outcome} when outcome in ~w(passed failed skipped incomplete not_run) ->
          outcome

        %{"pass" => true, "gated" => false} ->
          "incomplete"

        %{"pass" => true} ->
          "passed"

        %{"pass" => false} ->
          "failed"

        _ ->
          "incomplete"
      end

    Map.put(check, "outcome", outcome)
  end

  def with_check_outcome(check), do: check

  def digest(binary), do: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)

  defp not_verified_result(checks, reason) do
    %{
      status: :not_verified,
      label: status_label(:not_verified),
      reason: reason,
      checks: checks
    }
  end

  defp record_present?(result), do: map_size(result) > 0

  defp stale_reason(result, source, name, root, spec_path) do
    policy = effective_policy(source, name, root)

    cond do
      result["evidence"] != evidence_digest(source, name, root) ->
        "Source changed since verification"

      policy.kind == :docs_only and not is_nil(result["spec"]) ->
        "Documentation family record has a spec digest"

      policy.kind != :docs_only and
          (not File.exists?(spec_path) or result["spec"] != digest(File.read!(spec_path))) ->
        "Contract changed since verification"

      policy.kind != :docs_only and File.exists?(spec_path) and
          not reviewed_contract?(read_json!(spec_path)) ->
        "Contract review is incomplete"

      true ->
        "Verification inputs changed since the record was written"
    end
  end

  defp failed_reason(checks) do
    checks
    |> Enum.find(&(&1.outcome == :failed))
    |> case do
      %{name: _name, reason: reason} when is_binary(reason) and reason != "" -> reason
      %{name: name} -> "#{human_check(name)} check failed"
      _ -> "A required check failed"
    end
  end

  defp incomplete_reason(checks) do
    case Enum.find(checks, &(&1.outcome in [:incomplete, :not_run, :skipped])) do
      %{name: _name, reason: reason} when is_binary(reason) and reason != "" -> reason
      %{name: name} -> "#{human_check(name)} check is incomplete"
      _ -> "Verification is incomplete"
    end
  end

  defp check_reason(name, check, outcome) do
    detail = if is_map(check), do: Map.get(check, "detail")

    if is_binary(detail) and detail != "" and outcome != :not_run do
      detail
    else
      suffix =
        Map.get(
          %{
            passed: "passed",
            failed: "failed",
            skipped: "was skipped",
            incomplete: "did not run",
            not_run: "has no record"
          },
          outcome,
          "is incomplete"
        )

      "#{human_check(name)} check #{suffix}"
    end
  end

  defp human_check("pixel"), do: "Pixel"
  defp human_check(name), do: name |> String.replace("-", " ") |> String.capitalize()

  defp effective_policy("shadcn", name, root), do: verification_policy("shadcn", name, root)
  defp effective_policy(source, name, _root), do: policy_entry(source, name)

  defp policy_entry(source, name) do
    Map.get(@policies, source <> "/" <> name, %{
      kind: :standard,
      reason: nil,
      required_checks: @standard_required_checks
    })
  end

  defp file_entry(root, path) do
    {Path.relative_to(path, root), File.read!(path)}
  end

  defp file_digest(path) do
    if File.regular?(path), do: digest(File.read!(path)), else: :missing
  end

  defp module_file(name), do: String.replace(name, "-", "_") <> ".ex"

  defp generated_path?(path) do
    String.contains?(path, "/node_modules/") or
      String.contains?(path, "/_build/") or
      String.contains?(path, "/priv/static/assets/") or
      String.contains?(path, "/assets/css/upstream/")
  end

  defp registry_path(root, parts), do: Path.join([root, "registry" | List.wrap(parts)])

  defp read_json!(path), do: path |> File.read!() |> Jason.decode!()
end
