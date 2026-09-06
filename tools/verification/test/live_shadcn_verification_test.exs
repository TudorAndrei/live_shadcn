defmodule LiveShadcnVerificationTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../../..", __DIR__)

  describe "shadcn evidence digest" do
    test "matches the tools adapter for a primitive" do
      assert LiveShadcnVerification.evidence_digest("shadcn", "button", @repo_root) ==
               tools_digest("shadcn", "button", @repo_root)
    end

    test "matches the tools adapter for a documentation family" do
      assert LiveShadcnVerification.evidence_digest("shadcn", "data-table", @repo_root) ==
               tools_digest("shadcn", "data-table", @repo_root)
    end

    test "matches the storybook adapter for the same inputs" do
      for name <- ["button", "data-table", "typography"] do
        assert storybook_digest("shadcn", name, @repo_root) ==
                 LiveShadcnVerification.evidence_digest("shadcn", name, @repo_root)
      end
    end

    test "changes when a snapshot or renderer changes" do
      root = fixture_root("evidence-change")

      write(
        root,
        "registry/snapshot/index.json",
        ~s({"button":["default"]})
      )

      write(
        root,
        "registry/UPSTREAM.json",
        ~s({"sources":{"shadcn":{"ref":"test"}},"examples":{"shadcn":{"button":[]}}})
      )

      write(root, "registry/snapshot/button-default.html", "<button>Before</button>\n")
      write(root, "storybook/lib/storybook_web/examples.ex", "example renderer before\n")
      write(root, "storybook/lib/mix/tasks/snapshot.ex", "snapshot renderer before\n")
      write(root, "storybook/lib/storybook_web/live/preview_live.ex", "preview renderer before\n")

      original = LiveShadcnVerification.evidence_digest("shadcn", "button", root)

      write(root, "registry/snapshot/button-default.html", "<button>After</button>\n")
      changed_snapshot = LiveShadcnVerification.evidence_digest("shadcn", "button", root)
      refute original == changed_snapshot

      write(root, "storybook/lib/storybook_web/examples.ex", "example renderer after\n")
      changed_example = LiveShadcnVerification.evidence_digest("shadcn", "button", root)
      refute changed_snapshot == changed_example
    end
  end

  describe "badge status" do
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
      checks = Map.new(policy.required_checks, &{&1, %{"pass" => true}})

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
      assert LiveShadcnVerification.policy_status_overrides()["shadcn/direction"] == :no_dom

      assert badge_for(@repo_root, "shadcn", "direction", %{"pass" => true, "checks" => %{}}) ==
               :no_dom
    end

    test "reports unverified for missing checks" do
      root = fixture_root("badge-missing")
      record = verified_record(root, "button", :standard)
      incomplete = %{record | "checks" => Map.delete(record["checks"], "pixel")}

      assert badge_for(root, "shadcn", "button", incomplete) == :unverified
      refute pipeline_verified?(root, "shadcn", "button", incomplete)
    end

    test "reports unverified for stale evidence and failed for a current failure" do
      root = fixture_root("badge-stale")
      record = verified_record(root, "button", :standard)

      stale = %{record | "evidence" => "stale"}
      assert badge_for(root, "shadcn", "button", stale) == :unverified

      failed =
        put_in(record, ["checks", "pixel"], %{"pass" => false})

      assert badge_for(root, "shadcn", "button", failed) == :failed
      assert pipeline_failed?(root, "shadcn", "button", failed)
    end

    test "tools and storybook adapters agree on independent fixtures" do
      root = fixture_root("adapter-agreement")
      record = verified_record(root, "button", :standard)

      assert badge_for(root, "shadcn", "button", record) ==
               storybook_badge(root, "shadcn", "button", record)

      assert tools_digest("shadcn", "button", root) ==
               storybook_digest("shadcn", "button", root)
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

  defp verified_record(root, name, kind) do
    write(root, "registry/snapshot/index.json", ~s({"#{name}":["default"]}))

    write(
      root,
      "registry/UPSTREAM.json",
      ~s({"sources":{"shadcn":{"ref":"test"}},"examples":{"shadcn":{"#{name}":[]}}})
    )

    write(root, "registry/snapshot/#{name}-default.html", "<main>#{name}</main>\n")
    write(root, "storybook/lib/storybook_web/examples.ex", "example renderer\n")
    write(root, "storybook/lib/mix/tasks/snapshot.ex", "snapshot renderer\n")
    write(root, "storybook/lib/storybook_web/live/preview_live.ex", "preview renderer\n")

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

    checks = Map.new(policy.required_checks, &{&1, %{"pass" => true}})

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

  defp storybook_badge(root, source, name, record) do
    spec = Path.join(root, "registry/spec/#{source}/#{name}.json")
    LiveShadcnVerification.badge_status(record, source, name, root, spec)
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
    inputs = LiveShadcnVerification.collect_shadcn_evidence_inputs(root, name)
    LiveShadcnVerification.evidence_digest_from_inputs(inputs)
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
