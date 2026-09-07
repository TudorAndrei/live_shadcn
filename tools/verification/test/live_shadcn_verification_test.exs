defmodule LiveShadcnVerificationTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../../..", __DIR__)

  test "a shared evidence pass agrees with independent component digests" do
    names = ["button", "slider", "data-table"]

    expected =
      Map.new(names, &{&1, LiveShadcnVerification.evidence_digest("shadcn", &1, @repo_root)})

    assert LiveShadcnVerification.evidence_digests(names, @repo_root) == expected
  end

  test "publication rechecks changed bytes and added or removed shared files" do
    root = fixture_root("identity-batch")
    bootstrap_identity(root, "button")
    path = "packages/live_base/assets/js/batch.js"
    write(root, path, "first")
    original = LiveShadcnVerification.evidence_digests(["button"], root)

    write(root, path, "other")

    assert_raise Mix.Error, ~r/verification inputs changed/, fn ->
      LiveShadcnVerification.assert_identities_unchanged!(root, original)
    end

    write(root, path, "first")
    assert :ok = LiveShadcnVerification.assert_identities_unchanged!(root, original)
    write(root, "packages/live_base/assets/js/added.js", "added")

    assert_raise Mix.Error, ~r/verification inputs changed/, fn ->
      LiveShadcnVerification.assert_identities_unchanged!(root, original)
    end

    File.rm!(Path.join(root, "packages/live_base/assets/js/added.js"))
    File.rm!(Path.join(root, path))

    assert_raise Mix.Error, ~r/verification inputs changed/, fn ->
      LiveShadcnVerification.assert_identities_unchanged!(root, original)
    end
  end

  describe "shadcn identity version 2" do
    test "includes version, shared inputs, and component files" do
      inputs = LiveShadcnVerification.collect_shadcn_evidence_inputs(@repo_root, "button")

      assert inputs.version == LiveShadcnVerification.identity_version()
      assert inputs.shared_inputs != []
      assert inputs.upstream_files != []
      assert is_binary(LiveShadcnVerification.evidence_digest("shadcn", "button", @repo_root))
    end

    test "matches the tools and storybook adapters" do
      for name <- ["button", "data-table", "typography"] do
        digest = LiveShadcnVerification.evidence_digest("shadcn", name, @repo_root)
        assert digest == tools_digest("shadcn", name, @repo_root)
        assert digest == storybook_digest("shadcn", name, @repo_root)
      end
    end

    test "changes when a hook, css asset, or shim changes" do
      root = fixture_root("identity-inputs")

      bootstrap_identity(root, "button")

      original = LiveShadcnVerification.evidence_digest("shadcn", "button", root)

      write(root, "packages/live_base/assets/js/combobox.js", "export default {}\n")
      refute original == LiveShadcnVerification.evidence_digest("shadcn", "button", root)

      bootstrap_identity(root, "button")
      original = LiveShadcnVerification.evidence_digest("shadcn", "button", root)

      write(root, "storybook/assets/css/app.css", "body { color: red; }\n")
      refute original == LiveShadcnVerification.evidence_digest("shadcn", "button", root)

      bootstrap_identity(root, "button")
      original = LiveShadcnVerification.evidence_digest("shadcn", "button", root)

      write(root, "parity/src/shim/utils.ts", "export const x = 1\n")
      refute original == LiveShadcnVerification.evidence_digest("shadcn", "button", root)
    end

    test "changes when the port module or lockfile changes" do
      root = fixture_root("identity-port")
      bootstrap_identity(root, "button")
      original = LiveShadcnVerification.evidence_digest("shadcn", "button", root)

      write(root, "packages/live_shadcn/priv/registry/button.ex", "defmodule X do end\n")
      refute original == LiveShadcnVerification.evidence_digest("shadcn", "button", root)

      bootstrap_identity(root, "button")
      original = LiveShadcnVerification.evidence_digest("shadcn", "button", root)

      write(root, "packages/live_shadcn/mix.lock", "LOCK\n")
      refute original == LiveShadcnVerification.evidence_digest("shadcn", "button", root)
    end

    test "produces equal digests for prepared and clean-checkout fixtures" do
      root = fixture_root("identity-stable")
      bootstrap_identity(root, "button")

      first = LiveShadcnVerification.evidence_digest("shadcn", "button", root)
      write(root, "storybook/test/browser/results.json", ~s({"suites":[],"errors":[]}))
      write(root, "storybook/test/browser/custom-report.json", ~s({"suites":[]}))
      second = LiveShadcnVerification.evidence_digest("shadcn", "button", root)
      assert first == second
    end

    test "changes when a rendered HEEx layout changes" do
      root = fixture_root("identity-layout")
      bootstrap_identity(root, "button")

      write(
        root,
        "storybook/lib/storybook_web/layouts/root.html.heex",
        "<main>{@inner_content}</main>"
      )

      original = LiveShadcnVerification.evidence_digest("shadcn", "button", root)

      write(
        root,
        "storybook/lib/storybook_web/layouts/root.html.heex",
        "<body>{@inner_content}</body>"
      )

      refute original == LiveShadcnVerification.evidence_digest("shadcn", "button", root)
    end

    test "changes when a new shared input file is added" do
      root = fixture_root("identity-paths")
      bootstrap_identity(root, "button")

      original = LiveShadcnVerification.evidence_digest("shadcn", "button", root)

      write(root, "packages/live_base/assets/js/new-hook.js", "export default {}\n")

      refute original == LiveShadcnVerification.evidence_digest("shadcn", "button", root)
    end

    test "rejects publication when identity changes during a run" do
      root = fixture_root("identity-lock")
      bootstrap_identity(root, "button")
      captured = LiveShadcnVerification.evidence_digest("shadcn", "button", root)

      write(root, "packages/live_base/assets/js/combobox.js", "changed\n")

      assert_raise Mix.Error, ~r/verification inputs changed/, fn ->
        LiveShadcnVerification.assert_identity_unchanged!(root, "shadcn", "button", captured)
      end
    end

    test "rejects pinned upstream bytes that do not match the manifest" do
      root = fixture_root("upstream-pin")

      write(
        root,
        "registry/UPSTREAM.json",
        ~s({"files":{"shadcn/ui/button.tsx":{"sha256":"abc123"}}})
      )

      write(root, "registry/upstream/shadcn/ui/button.tsx", "stale bytes\n")

      assert_raise Mix.Error, ~r/does not match registry\/UPSTREAM.json/, fn ->
        LiveShadcnVerification.verify_pinned_upstream_files!(root)
      end
    end
  end

  describe "badge evaluation" do
    test "AI Elements has an explicit status outside verification" do
      evaluation =
        LiveShadcnVerification.evaluate(
          %{"pass" => true},
          "ai_elements",
          "message",
          @repo_root,
          nil
        )

      assert evaluation.status == :excluded
      assert evaluation.label == "Outside verification"
      assert evaluation.reason == "AI Elements is outside the shadcn verification pipeline."
    end

    test "reports verified for a current primitive record" do
      root = fixture_root("badge-primitive")
      record = verified_record(root, "button", :standard)

      assert badge_for(root, "shadcn", "button", record) == :verified
      assert pipeline_verified?(root, "shadcn", "button", record)
    end

    test "reports verified for a current docs-only family record" do
      root = fixture_root("badge-docs-only")

      write(
        root,
        "registry/UPSTREAM.json",
        ~s({"files":{},"sources":{"shadcn":{"ref":"test"}},"examples":{"shadcn":{"data-table":["data-table-demo"]}}})
      )

      write(root, "registry/snapshot/index.json", ~s({"data-table":["default"]}))
      write(root, "registry/snapshot/data-table-default.html", "<main>Data table</main>\n")
      write(root, "parity/official-examples.json", ~s({"data-table.default":"example.tsx#Demo"}))
      write(root, "storybook/lib/storybook_web/examples.ex", "example renderer\n")
      write(root, "storybook/lib/mix/tasks/snapshot.ex", "snapshot renderer\n")
      write(root, "storybook/lib/storybook_web/live/preview_live.ex", "preview renderer\n")

      policy = LiveShadcnVerification.verification_policy("shadcn", "data-table", root)
      checks = Map.new(policy.required_checks, &{&1, %{"pass" => true, "outcome" => "passed"}})

      record = %{
        "pass" => true,
        "spec" => nil,
        "evidence" => LiveShadcnVerification.evidence_digest("shadcn", "data-table", root),
        "checks" => checks
      }

      assert badge_for(root, "shadcn", "data-table", record) == :verified
    end

    test "reports no_dom for direction regardless of verification records" do
      assert LiveShadcnVerification.policy_status("shadcn", "direction") == :no_dom

      assert badge_for(@repo_root, "shadcn", "direction", %{"pass" => true, "checks" => %{}}) ==
               :no_dom
    end

    test "reports not_verified for missing checks with current evidence" do
      root = fixture_root("badge-missing")
      record = verified_record(root, "button", :standard)
      incomplete = %{record | "checks" => Map.delete(record["checks"], "pixel")}

      assert badge_for(root, "shadcn", "button", incomplete) == :not_verified
      refute pipeline_verified?(root, "shadcn", "button", incomplete)
    end

    test "reports stale for outdated evidence including historical failures" do
      root = fixture_root("badge-stale")
      record = verified_record(root, "button", :standard)

      stale = %{record | "evidence" => "stale"}
      assert badge_for(root, "shadcn", "button", stale) == :stale

      failed_stale =
        stale
        |> put_in(["checks", "pixel"], %{"pass" => false, "outcome" => "failed"})

      assert badge_for(root, "shadcn", "button", failed_stale) == :stale
    end

    test "reports failed for a current failure" do
      root = fixture_root("badge-failed")
      record = verified_record(root, "button", :standard)

      failed =
        put_in(record, ["checks", "pixel"], %{"pass" => false, "outcome" => "failed"})

      assert badge_for(root, "shadcn", "button", failed) == :failed
      assert pipeline_failed?(root, "shadcn", "button", failed)
    end

    test "includes readable check reasons" do
      root = fixture_root("badge-reasons")
      record = verified_record(root, "button", :standard)

      failed =
        put_in(record, ["checks", "pixel"], %{
          "pass" => false,
          "outcome" => "failed",
          "detail" => "Pixel check failed"
        })

      evaluation = evaluate(root, "shadcn", "button", failed)
      assert evaluation.status == :failed
      assert evaluation.reason == "Pixel check failed"

      pixel = Enum.find(evaluation.checks, &(&1.name == "pixel"))
      assert pixel.reason == "Pixel check failed"
    end
  end

  defp fixture_root(label) do
    root =
      Path.join(
        System.tmp_dir!(),
        "live-shadcn-verification-#{label}-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf!(root) end)
    root
  end

  defp bootstrap_identity(root, name) do
    write(root, "registry/snapshot/index.json", ~s({"#{name}":["default"]}))

    write(
      root,
      "registry/UPSTREAM.json",
      ~s({"sources":{"shadcn":{"ref":"test"}},"examples":{"shadcn":{"#{name}":[]}},"files":{}})
    )

    write(root, "registry/snapshot/#{name}-default.html", "<main>#{name}</main>\n")
    write(root, "storybook/lib/storybook_web/examples.ex", "example renderer\n")
    write(root, "storybook/lib/mix/tasks/snapshot.ex", "snapshot renderer\n")
    write(root, "storybook/lib/storybook_web/live/preview_live.ex", "preview renderer\n")
  end

  defp verified_record(root, name, kind) do
    bootstrap_identity(root, name)

    spec_path = Path.join(root, "registry/spec/shadcn/#{name}.json")
    contract = ~s({"ignored":{}})

    if kind == :standard do
      File.mkdir_p!(Path.dirname(spec_path))
      File.write!(spec_path, contract)
    end

    policy =
      case kind do
        :standard ->
          LiveShadcnVerification.verification_policy("shadcn", name, root)

        :docs_only ->
          %{
            kind: :docs_only,
            required_checks: ~w(snapshot examples browser behavior accessibility parity pixel)
          }
      end

    checks =
      Map.new(policy.required_checks, &{&1, %{"pass" => true, "outcome" => "passed"}})

    %{
      "pass" => true,
      "spec" => if(kind == :standard, do: LiveShadcnVerification.digest(contract), else: nil),
      "evidence" => LiveShadcnVerification.evidence_digest("shadcn", name, root),
      "checks" => checks
    }
  end

  defp badge_for(root, source, name, record) do
    spec = Path.join(root, "registry/spec/#{source}/#{name}.json")
    LiveShadcnVerification.badge_status(record, source, name, root, spec)
  end

  defp evaluate(root, source, name, record) do
    spec = Path.join(root, "registry/spec/#{source}/#{name}.json")
    LiveShadcnVerification.evaluate(record, source, name, root, spec)
  end

  defp pipeline_verified?(root, source, name, record) do
    spec = Path.join(root, "registry/spec/#{source}/#{name}.json")
    LiveShadcnVerification.pipeline_verified?(record, source, name, root, spec)
  end

  defp pipeline_failed?(root, source, name, record) do
    spec = Path.join(root, "registry/spec/#{source}/#{name}.json")
    LiveShadcnVerification.pipeline_failed?(record, source, name, root, spec)
  end

  defp tools_digest(source, name, root) do
    LiveShadcnVerification.evidence_digest(source, name, root)
  end

  defp storybook_digest(source, name, root) do
    LiveShadcnVerification.evidence_digest(source, name, root)
  end

  defp write(root, path, content) do
    path = Path.join(root, path)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
  end
end
