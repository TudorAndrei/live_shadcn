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
    record = verified_record(root, "button", :standard)
    path = "packages/live_base/assets/js/batch.js"
    write(root, path, "first")
    original = LiveShadcnVerification.evidence_digests(["button"], root)
    record = Map.put(record, "evidence", Map.fetch!(original, "button"))

    evaluate_badge = fn ->
      LiveShadcnVerification.evaluate_many(
        %{"shadcn/button" => record},
        root,
        Path.join(root, "registry/spec")
      )
      |> Map.fetch!("shadcn/button")
    end

    assert evaluate_badge.().status == :verified

    write(root, path, "other")
    assert evaluate_badge.().status == :stale

    assert_raise Mix.Error, ~r/verification inputs changed/, fn ->
      LiveShadcnVerification.assert_identities_unchanged!(root, original)
    end

    write(root, path, "first")
    assert :ok = LiveShadcnVerification.assert_identities_unchanged!(root, original)
    assert evaluate_badge.().status == :verified
    write(root, "packages/live_base/assets/js/added.js", "added")
    assert evaluate_badge.().status == :stale

    assert_raise Mix.Error, ~r/verification inputs changed/, fn ->
      LiveShadcnVerification.assert_identities_unchanged!(root, original)
    end

    File.rm!(Path.join(root, "packages/live_base/assets/js/added.js"))
    assert evaluate_badge.().status == :verified
    File.rm!(Path.join(root, path))
    assert evaluate_badge.().status == :stale

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

    test "shared build, preview, and stylesheet source mutations invalidate evidence" do
      for path <-
            ~w(tools/mix.exs tools/verification/mix.exs storybook/mix.exs storybook/config/config.exs packages/live_base/mix.exs packages/live_shadcn/mix.exs packages/live_ai_elements/mix.exs packages/live_base/package.json packages/live_base/package-lock.json packages/live_ai_elements/lib/component.ex parity/src/official-ai-elements.mjs storybook/priv/static/previews/release.html) do
        root = fixture_root("build-input-#{Path.basename(path)}")
        bootstrap_identity(root, "button")
        write(root, path, "original")
        original = LiveShadcnVerification.evidence_digest("shadcn", "button", root)
        assert Path.join(root, path) in LiveShadcnVerification.identity_compile_paths(root)
        write(root, path, "changed")
        refute original == LiveShadcnVerification.evidence_digest("shadcn", "button", root), path
        File.rm!(Path.join(root, path))
        refute original == LiveShadcnVerification.evidence_digest("shadcn", "button", root), path
      end
    end

    test "shared fetched stylesheet sources are pinned without depending on preparation" do
      for family <- ~w(ai_elements ai_shadcn ai_examples) do
        root = fixture_root("shared-fetched-#{family}")
        bootstrap_identity(root, "button")
        path = "#{family}/example.tsx"

        manifest = %{
          "files" => %{path => %{"sha256" => LiveShadcnVerification.digest("original")}}
        }

        write(root, "registry/UPSTREAM.json", Jason.encode!(manifest))
        original = LiveShadcnVerification.evidence_digest("shadcn", "button", root)
        write(root, "registry/upstream/#{path}", "original")
        assert original == LiveShadcnVerification.evidence_digest("shadcn", "button", root)
        assert :ok == LiveShadcnVerification.verify_pinned_upstream_files!(root)
        write(root, "registry/upstream/#{path}", "corrupt")

        assert_raise Mix.Error, ~r/pinned upstream file/, fn ->
          LiveShadcnVerification.verify_pinned_upstream_files!(root)
        end
      end
    end

    test "changes when a hook, css asset, static image, or shim changes" do
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
      write(root, "storybook/priv/static/avatars/shadcn.jpg", "first image")
      original = LiveShadcnVerification.evidence_digest("shadcn", "button", root)

      write(root, "storybook/priv/static/avatars/shadcn.jpg", "other image")
      refute original == LiveShadcnVerification.evidence_digest("shadcn", "button", root)

      bootstrap_identity(root, "button")
      original = LiveShadcnVerification.evidence_digest("shadcn", "button", root)

      write(root, "parity/src/shim/utils.ts", "export const x = 1\n")
      refute original == LiveShadcnVerification.evidence_digest("shadcn", "button", root)
    end

    test "Phoenix digest copies preserve identity without hiding changed source or derivative bytes" do
      root = fixture_root("digested-avatar")
      bootstrap_identity(root, "button")
      source = "storybook/priv/static/avatars/shadcn.jpg"
      bytes = "avatar source bytes"
      md5 = :crypto.hash(:md5, bytes) |> Base.encode16(case: :lower)
      copy = "storybook/priv/static/avatars/shadcn-#{md5}.jpg"
      write(root, source, bytes)
      original = LiveShadcnVerification.evidence_digest("shadcn", "button", root)
      original_paths = LiveShadcnVerification.identity_compile_paths(root)

      write(root, copy, bytes)
      assert LiveShadcnVerification.evidence_digest("shadcn", "button", root) == original
      assert LiveShadcnVerification.identity_compile_paths(root) == original_paths

      write(root, copy, "unexpected derivative bytes")
      refute LiveShadcnVerification.evidence_digest("shadcn", "button", root) == original

      write(root, copy, bytes)
      write(root, source, "changed source bytes")
      refute LiveShadcnVerification.evidence_digest("shadcn", "button", root) == original
    end

    test "nested static asset directories contribute files, not unreadable directory entries" do
      root = fixture_root("nested-avatar")
      bootstrap_identity(root, "button")
      original = LiveShadcnVerification.evidence_digest("shadcn", "button", root)
      write(root, "storybook/priv/static/avatars/team/person.png", "new avatar")
      refute LiveShadcnVerification.evidence_digest("shadcn", "button", root) == original
      assert Enum.all?(LiveShadcnVerification.identity_compile_paths(root), &File.regular?/1)
    end

    test "identity paths keep native hidden-root and symlink behavior" do
      root = Path.join(fixture_root("wildcard-contract"), ".root")
      bootstrap_identity(root, "button")

      for path <- [
            "storybook/assets/root.css",
            "storybook/assets/nested/café.mjs",
            "storybook/assets/node_modules-note/kept.js",
            "storybook/assets/_build-note/kept.json",
            "storybook/assets/css/upstream-note/kept.css",
            "storybook/priv/static/avatars/node_modules",
            "storybook/assets/.hidden.js",
            "storybook/assets/.hidden/nested.css",
            "external/target/linked.js"
          ] do
        write(root, path, path)
      end

      excluded = [
        "storybook/assets/node_modules/excluded.js",
        "storybook/assets/_build/excluded.json",
        "storybook/assets/nested/priv/static/assets/excluded.js",
        "storybook/assets/css/upstream/excluded.css",
        "storybook/assets/generated-alias/node_modules/linked.js"
      ]

      Enum.each(excluded |> Enum.take(4), &write(root, &1, &1))

      File.ln_s!(
        Path.join(root, "external/target"),
        Path.join(root, "storybook/assets/source-link")
      )

      File.ln_s!(
        Path.join(root, "external/target/linked.js"),
        Path.join(root, "storybook/assets/file-link.js")
      )

      File.ln_s!(
        Path.join(root, "storybook/assets/node_modules"),
        Path.join(root, "storybook/assets/source-alias")
      )

      File.mkdir_p!(Path.join(root, "storybook/assets/generated-alias"))

      File.ln_s!(
        Path.join(root, "external/target"),
        Path.join(root, "storybook/assets/generated-alias/node_modules")
      )

      File.ln_s!(
        Path.join(root, "external/missing.js"),
        Path.join(root, "storybook/assets/broken.js")
      )

      native_paths = fn globs ->
        globs
        |> Enum.flat_map(&Path.wildcard(Path.join(root, &1)))
        |> Enum.filter(&File.regular?/1)
        |> Enum.reject(&(Path.relative_to(&1, root) in excluded))
      end

      shared_paths = native_paths.(LiveShadcnVerification.shared_input_globs())

      expected =
        shared_paths
        |> Enum.uniq()
        |> Enum.sort()
        |> Enum.map(&{Path.relative_to(&1, root), File.read!(&1)})

      assert LiveShadcnVerification.collect_shared_inputs(root) == expected

      globs =
        LiveShadcnVerification.shared_input_globs() ++
          LiveShadcnVerification.verification_rule_globs()

      expected_compile = native_paths.(globs)
      assert LiveShadcnVerification.compile_path_globs(root) == expected_compile

      assert LiveShadcnVerification.identity_compile_paths(root) ==
               Enum.sort(Enum.uniq(expected_compile))

      for path <- [
            "storybook/assets/root.css",
            "storybook/assets/nested/café.mjs",
            "storybook/assets/source-link/linked.js",
            "storybook/assets/file-link.js",
            "storybook/assets/source-alias/excluded.js",
            "storybook/priv/static/avatars/node_modules"
          ] do
        assert {path, File.read!(Path.join(root, path))} in expected
      end
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

    test "AI restored source identities match clean checkouts and reject changed bytes" do
      root = fixture_root("ai-upstream-inputs")
      bootstrap_identity(root, "image")

      sources = %{
        "ai_elements/image.tsx" => "component",
        "ai_examples/image.tsx" => "example",
        "ai_shadcn/button.tsx" => "dependency"
      }

      files =
        Map.new(sources, fn {path, bytes} ->
          {path, %{"sha256" => LiveShadcnVerification.digest(bytes)}}
        end)

      write(root, "registry/UPSTREAM.json", Jason.encode!(%{"files" => files}))
      clean = LiveShadcnVerification.evidence_digest("ai_elements", "image", root)
      for {path, bytes} <- sources, do: write(root, "registry/upstream/" <> path, bytes)
      assert clean == LiveShadcnVerification.evidence_digest("ai_elements", "image", root)

      for {path, bytes} <- sources do
        write(root, "registry/upstream/" <> path, bytes <> "changed")
        refute clean == LiveShadcnVerification.evidence_digest("ai_elements", "image", root)

        assert_raise Mix.Error, ~r/verification inputs changed/, fn ->
          LiveShadcnVerification.assert_identity_unchanged!(root, "ai_elements", "image", clean)
        end

        write(root, "registry/upstream/" <> path, bytes)
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
    test "AI authored checks require complete current local evidence" do
      root = fixture_root("ai-authored-status")
      bootstrap_identity(root, "message")
      contract = ~s({"ignored":{}})
      write(root, "registry/spec/ai_elements/message.json", contract)

      checks =
        Map.new(
          ~w(generated snapshot examples browser behavior accessibility),
          &{&1, %{"pass" => true, "outcome" => "passed"}}
        )

      checks =
        Map.merge(
          checks,
          Map.new(
            ~w(parity pixel),
            &{&1, %{"pass" => false, "outcome" => "not_applicable", "gated" => false}}
          )
        )

      record = %{
        "pass" => true,
        "spec" => LiveShadcnVerification.digest(contract),
        "evidence" => LiveShadcnVerification.evidence_digest("ai_elements", "message", root),
        "checks" => checks
      }

      assert badge_for(root, "ai_elements", "message", record) == :verified

      for name <- ~w(generated snapshot examples browser behavior accessibility),
          outcome <- ~w(skipped incomplete not_run) do
        incomplete = put_in(record, ["checks", name], %{"pass" => true, "outcome" => outcome})
        assert badge_for(root, "ai_elements", "message", incomplete) == :not_verified
      end

      write(root, "packages/live_ai_elements/assets/js/prompt_input.js", "changed")
      assert badge_for(root, "ai_elements", "message", record) == :stale
    end

    test "explicit passing outcomes cannot override required gating or contradictory pass flags" do
      for {name, kind} <- [{"button", :standard}, {"data-table", :docs_only}],
          bad_check <- [
            %{"pass" => true, "gated" => false, "outcome" => "passed"},
            %{"pass" => false, "gated" => true, "outcome" => "passed"},
            %{"gated" => true, "outcome" => "passed"},
            %{"pass" => true, "gated" => true, "outcome" => "unknown"}
          ] do
        root = fixture_root("badge-contradiction-#{name}")
        record = verified_record(root, name, kind)
        record = put_in(record, ["checks", "pixel"], bad_check)

        assert badge_for(root, "shadcn", name, record) == :not_verified
        refute pipeline_verified?(root, "shadcn", name, record)
      end
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

    if kind == :docs_only do
      write(
        root,
        "registry/UPSTREAM.json",
        Jason.encode!(%{"examples" => %{"shadcn" => %{name => ["demo"]}}, "files" => %{}})
      )
    end

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
