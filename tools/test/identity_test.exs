defmodule LiveShadcnTools.IdentityTest do
  use ExUnit.Case, async: true

  alias LiveShadcnVerification
  alias Mix.Tasks.Ui.Status

  # A component is identified by its source and its name, never by its name
  # alone. Upstream has a `message` in the shadcn registry and a different
  # `message` in AI Elements, and every stage that looked one up by name alone
  # reported the first one's evidence as the second one's: the inventory marked
  # the AI Elements `message` verified on the strength of a browser run against
  # shadcn's.

  describe "a reference" do
    test "joins the source to the name" do
      assert LiveShadcnTools.ref("shadcn", "message") == "shadcn/message"
      assert LiveShadcnTools.ref("ai_elements", "message") == "ai_elements/message"
    end

    test "splits back into the pair it came from" do
      for source <- LiveShadcnTools.sources(), name <- ~w(message alert-dialog) do
        assert LiveShadcnTools.parse_ref(LiveShadcnTools.ref(source, name)) == {source, name}
      end
    end

    test "refuses a source nobody publishes" do
      assert_raise Mix.Error, ~r/not a component reference/, fn ->
        LiveShadcnTools.parse_ref("radix/message")
      end
    end
  end

  describe "the path a component owns" do
    test "two components of the same name never share a spec file" do
      refute LiveShadcnTools.spec_path("shadcn", "message") ==
               LiveShadcnTools.spec_path("ai_elements", "message")
    end

    test "two components of the same name never share a module file" do
      refute LiveShadcnTools.module_path("shadcn", "message") ==
               LiveShadcnTools.module_path("ai_elements", "message")
    end

    test "each package holds the modules it ships" do
      assert LiveShadcnTools.module_path("shadcn", "message") =~ "packages/live_shadcn/"
      assert LiveShadcnTools.module_path("ai_elements", "message") =~ "packages/live_ai_elements/"
    end
  end

  describe "a name typed on the command line" do
    test "resolves while it names one component" do
      assert LiveShadcnTools.resolve("accordion") == {"shadcn", "accordion"}
    end

    test "is refused, not guessed at, when it names two" do
      assert_raise Mix.Error, ~r/names 2 components/, fn ->
        LiveShadcnTools.resolve("message")
      end
    end

    test "is accepted in full when the bare name is ambiguous" do
      assert LiveShadcnTools.resolve("ai_elements/message") == {"ai_elements", "message"}
      assert LiveShadcnTools.resolve("shadcn/message") == {"shadcn", "message"}
    end

    test "resolves an official docs-only family" do
      assert LiveShadcnTools.resolve("typography") == {"shadcn", "typography"}
    end
  end

  describe "official docs-only families" do
    test "derives families with examples and without a primitive" do
      root =
        Path.join(
          System.tmp_dir!(),
          "live-shadcn-docs-only-#{System.unique_integer([:positive])}"
        )

      on_exit(fn -> File.rm_rf!(root) end)

      write(
        root,
        "registry/UPSTREAM.json",
        ~s({"files":{"shadcn/ui/button.tsx":{}},"examples":{"shadcn":{"button":["default"],"data-table":["default"],"empty":[]}}})
      )

      assert LiveShadcnTools.docs_only_shadcn_families(root) == ["data-table"]
    end

    test "requires the full browser evidence set" do
      root =
        Path.join(
          System.tmp_dir!(),
          "live-shadcn-docs-policy-#{System.unique_integer([:positive])}"
        )

      on_exit(fn -> File.rm_rf!(root) end)

      write(
        root,
        "registry/UPSTREAM.json",
        ~s({"files":{},"examples":{"shadcn":{"typography":["default"]}}})
      )

      policy = LiveShadcnTools.verification_policy("shadcn", "typography", root)

      assert policy.kind == :docs_only

      assert policy.required_checks ==
               ~w(snapshot examples browser behavior accessibility parity pixel)

      checks = Map.new(policy.required_checks, &{&1, %{"pass" => true}})
      assert LiveShadcnTools.verified_checks?("shadcn", policy, checks)

      refute LiveShadcnTools.verified_checks?("shadcn", policy, Map.delete(checks, "pixel"))
    end

    test "current docs-only families require every snapshot and browser evidence check" do
      assert LiveShadcnTools.docs_only_shadcn_families() == ~w(data-table date-picker typography)

      for name <- ~w(data-table date-picker typography) do
        policy = LiveShadcnTools.verification_policy("shadcn", name)

        assert policy.kind == :docs_only

        assert policy.required_checks ==
                 ~w(snapshot examples browser behavior accessibility parity pixel)

        complete = Map.new(policy.required_checks, &{&1, %{"pass" => true}})

        assert LiveShadcnTools.verified_checks?("shadcn", policy, complete)

        for check <- policy.required_checks do
          refute LiveShadcnTools.verified_checks?("shadcn", policy, Map.delete(complete, check))
        end

        gated = put_in(complete, ["pixel", "gated"], false)
        refute LiveShadcnTools.verified_checks?("shadcn", policy, gated)
      end

      primitive = LiveShadcnTools.verification_policy("shadcn", "button")
      assert primitive.kind == :standard

      assert primitive.required_checks ==
               ~w(generated snapshot examples browser behavior accessibility parity pixel)
    end

    test "the status gate accepts only current complete docs-only verification" do
      root =
        Path.join(
          System.tmp_dir!(),
          "live-shadcn-docs-status-#{System.unique_integer([:positive])}"
        )

      on_exit(fn -> File.rm_rf!(root) end)

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

      evidence = LiveShadcnTools.verification_evidence_digest("shadcn", "data-table", root)
      policy = LiveShadcnTools.verification_policy("shadcn", "data-table", root)
      checks = Map.new(policy.required_checks, &{&1, %{"pass" => true}})

      record = %{
        "pass" => true,
        "spec" => nil,
        "evidence" => evidence,
        "checks" => checks
      }

      write(root, "registry/VERIFY.json", Jason.encode!(%{"shadcn/data-table" => record}))
      assert Status.docs_only_verification_gaps(root) == []

      write(root, "registry/VERIFY.json", "{}")
      assert Status.docs_only_verification_gaps(root) == ["shadcn/data-table"]

      stale = %{record | "evidence" => "stale"}
      write(root, "registry/VERIFY.json", Jason.encode!(%{"shadcn/data-table" => stale}))
      assert Status.docs_only_verification_gaps(root) == ["shadcn/data-table"]

      failed = %{record | "pass" => false}
      write(root, "registry/VERIFY.json", Jason.encode!(%{"shadcn/data-table" => failed}))
      assert Status.docs_only_verification_gaps(root) == ["shadcn/data-table"]

      incomplete = %{record | "checks" => Map.delete(checks, "pixel")}
      write(root, "registry/VERIFY.json", Jason.encode!(%{"shadcn/data-table" => incomplete}))
      assert Status.docs_only_verification_gaps(root) == ["shadcn/data-table"]
    end
  end

  describe "a reviewed contract" do
    test "is incomplete while an official fact has no port" do
      contract = %{
        "ignored" => %{
          "jsx/DropdownMenuLabel/class/0" =>
            "the generated port does not contain this source literal"
        }
      }

      refute LiveShadcnTools.reviewed_contract?(contract)

      assert LiveShadcnTools.unresolved_facts(contract) == [
               "jsx/DropdownMenuLabel/class/0"
             ]
    end

    test "permits a reviewed exception with a specific reason" do
      contract = %{"ignored" => %{"jsx/Utility/class/0" => "the utility does not render UI"}}

      assert LiveShadcnTools.reviewed_contract?(contract)
    end
  end

  describe "a verification record" do
    test "requires every current standard check" do
      policy = %{kind: :standard}

      incomplete = %{
        "generated" => %{"pass" => true},
        "snapshot" => %{"pass" => true},
        "examples" => %{"pass" => true},
        "browser" => %{"pass" => true},
        "parity" => %{"pass" => true},
        "pixel" => %{"pass" => true}
      }

      refute LiveShadcnTools.verified_checks?("shadcn", policy, incomplete)

      complete =
        Map.merge(incomplete, %{
          "behavior" => %{"pass" => true},
          "accessibility" => %{"pass" => true}
        })

      assert LiveShadcnTools.verified_checks?("shadcn", policy, complete)
    end

    test "does not verify an exceptional policy" do
      refute LiveShadcnTools.verified_checks?("shadcn", %{kind: :local_only}, %{})
    end

    test "records a complete local-only policy without calling it verified" do
      policy = %{
        kind: :local_only,
        required_checks: ~w(generated snapshot examples browser behavior accessibility)
      }

      checks = Map.new(policy.required_checks, &{&1, %{"pass" => true}})

      assert LiveShadcnTools.policy_checks_complete?("shadcn", policy, checks)
      refute LiveShadcnTools.verified_checks?("shadcn", policy, checks)
    end

    test "treats missing or stale checks as unverified, not failed" do
      incomplete = %{"pass" => true, "checks" => %{"generated" => %{"pass" => true}}}
      failed_check = put_in(incomplete, ["checks", "behavior"], %{"pass" => false})

      refute LiveShadcnTools.verification_failed?(incomplete, true)
      refute LiveShadcnTools.verification_failed?(failed_check, false)
      assert LiveShadcnTools.verification_failed?(failed_check, true)
      assert LiveShadcnTools.verification_failed?(%{"pass" => false}, false)
    end
  end

  describe "verification evidence" do
    test "changes when the selected snapshot or Storybook renderer changes" do
      root =
        Path.join(System.tmp_dir!(), "live-shadcn-evidence-#{System.unique_integer([:positive])}")

      on_exit(fn -> File.rm_rf!(root) end)

      write(root, "registry/snapshot/index.json", ~s({"button":["default"]}))

      write(
        root,
        "registry/UPSTREAM.json",
        ~s({"sources":{"shadcn":{"ref":"test"}},"examples":{"shadcn":{"button":[]}}})
      )

      write(root, "registry/snapshot/button-default.html", "<button>Before</button>\n")
      write(root, "storybook/lib/storybook_web/examples.ex", "example renderer before\n")
      write(root, "storybook/lib/mix/tasks/snapshot.ex", "snapshot renderer before\n")
      write(root, "storybook/lib/storybook_web/live/preview_live.ex", "preview renderer before\n")

      original = LiveShadcnTools.verification_evidence_digest("shadcn", "button", root)

      write(root, "registry/snapshot/button-default.html", "<button>After</button>\n")
      changed_snapshot = LiveShadcnTools.verification_evidence_digest("shadcn", "button", root)
      refute original == changed_snapshot

      write(root, "storybook/lib/storybook_web/examples.ex", "example renderer after\n")
      changed_example = LiveShadcnTools.verification_evidence_digest("shadcn", "button", root)
      refute changed_snapshot == changed_example

      write(root, "storybook/lib/mix/tasks/snapshot.ex", "snapshot renderer after\n")

      changed_snapshot_renderer =
        LiveShadcnTools.verification_evidence_digest("shadcn", "button", root)

      refute changed_example == changed_snapshot_renderer

      write(root, "storybook/lib/storybook_web/live/preview_live.ex", "preview renderer after\n")

      changed_preview_renderer =
        LiveShadcnTools.verification_evidence_digest("shadcn", "button", root)

      refute changed_snapshot_renderer == changed_preview_renderer
    end
  end

  describe "source-scoped verification workflow" do
    test "verification targets include shadcn documentation families" do
      targets = LiveShadcnTools.verification_targets("shadcn")

      assert Enum.all?(targets, fn {source, _name} -> source == "shadcn" end)
      assert {"shadcn", "typography"} in targets
      assert {"shadcn", "button"} in targets
      assert {"shadcn", "message-scroller"} in targets
    end

    test "only explicitly unsupported AI components are outside the required scope" do
      root =
        Path.join(System.tmp_dir!(), "ai-supported-scope-#{System.unique_integer([:positive])}")

      on_exit(fn -> File.rm_rf!(root) end)

      write(
        root,
        "registry/UPSTREAM.json",
        Jason.encode!(%{
          "files" =>
            Map.new(~w(canvas image new-component), &{"ai_elements/#{&1}.tsx", %{"sha256" => &1}})
        })
      )

      write(
        root,
        "registry/INVENTORY.json",
        Jason.encode!(%{
          "components" => [
            %{"source" => "ai_elements", "name" => "canvas", "recipe" => "unsupported"},
            %{"source" => "ai_elements", "name" => "image", "recipe" => "presentational"},
            %{"source" => "shadcn", "name" => "new-component", "recipe" => "unsupported"}
          ]
        })
      )

      assert LiveShadcnTools.verification_targets("ai_elements", root) == [
               {"ai_elements", "image"},
               {"ai_elements", "new-component"}
             ]

      assert LiveShadcnTools.verification_requirement_gaps("ai_elements", root) == [
               "ai_elements/image",
               "ai_elements/new-component"
             ]

      refute LiveShadcnTools.verification_requirement_met?("ai_elements/canvas", root)
    end

    test "pinned AI components stay required when their contract or port is missing" do
      root =
        Path.join(System.tmp_dir!(), "missing-ai-targets-#{System.unique_integer([:positive])}")

      on_exit(fn -> File.rm_rf!(root) end)

      write(
        root,
        "registry/UPSTREAM.json",
        Jason.encode!(%{
          "files" => %{
            "ai_elements/image.tsx" => %{"sha256" => "image"},
            "ai_elements/agent.tsx" => %{"sha256" => "agent"}
          }
        })
      )

      write(root, "registry/spec/ai_elements/image.json", ~s({"ignored":{}}))

      write(
        root,
        "packages/live_ai_elements/lib/live_ai_elements/components/agent.ex",
        "defmodule Agent do end"
      )

      assert LiveShadcnTools.verification_targets("ai_elements", root) == [
               {"ai_elements", "agent"},
               {"ai_elements", "image"}
             ]

      assert LiveShadcnTools.verification_requirement_gaps("ai_elements", root) == [
               "ai_elements/agent",
               "ai_elements/image"
             ]
    end

    test "verification requirements use the supplied repository root" do
      root =
        Path.join(System.tmp_dir!(), "verification-targets-#{System.unique_integer([:positive])}")

      on_exit(fn -> File.rm_rf!(root) end)

      write(
        root,
        "registry/UPSTREAM.json",
        ~s({"files":{},"examples":{"shadcn":{"typography":["demo"]}}})
      )

      write(root, "registry/spec/shadcn/button.json", ~s({"ignored":{}}))
      write(root, "packages/live_shadcn/priv/registry/button.ex", "defmodule Button do end")
      write(root, "registry/spec/ai_elements/image.json", ~s({"ignored":{}}))

      write(
        root,
        "packages/live_ai_elements/lib/live_ai_elements/components/image.ex",
        "defmodule Image do end"
      )

      assert LiveShadcnTools.verification_targets("ai_elements", root) == [
               {"ai_elements", "image"}
             ]

      assert {"ai_elements", "image"} in LiveShadcnTools.verification_targets(nil, root)

      assert LiveShadcnTools.verification_targets("shadcn", root) == [
               {"shadcn", "button"},
               {"shadcn", "typography"}
             ]

      assert LiveShadcnTools.verification_requirement_gaps("shadcn", root) == [
               "shadcn/button",
               "shadcn/typography"
             ]

      assert LiveShadcnTools.verification_requirement_gaps(nil, root) == [
               "ai_elements/image",
               "shadcn/button",
               "shadcn/typography"
             ]
    end

    test "require-verified rejects incomplete evidence even when a record says pass" do
      root = LiveShadcnTools.repo_root()
      policy = LiveShadcnTools.verification_policy("shadcn", "button", root)
      evidence = LiveShadcnTools.verification_evidence_digest("shadcn", "button", root)
      spec_path = Path.join([root, "registry/spec/shadcn/button.json"])

      checks =
        Map.new(policy.required_checks, fn check ->
          {check, %{"pass" => check != "pixel"}}
        end)

      result = %{
        "pass" => true,
        "evidence" => evidence,
        "checks" => checks,
        "spec" => LiveShadcnTools.digest(File.read!(spec_path))
      }

      refute LiveShadcnVerification.pipeline_verified?(
               result,
               "shadcn",
               "button",
               root,
               spec_path
             )
    end

    test "no-dom components satisfy verification requirements without browser evidence" do
      assert LiveShadcnTools.verification_requirement_met?("shadcn/direction")
    end

    test "ui.verify rejects a component from another source" do
      assert_raise Mix.Error, ~r/does not belong to source shadcn/, fn ->
        Mix.Task.run("ui.verify", ["--source", "shadcn", "ai_elements/message", "--no-browser"])
      end
    end

    test "ui.status rejects unknown options" do
      assert_raise Mix.Error, ~r/invalid option\(s\): --unknown/, fn ->
        Mix.Task.run("ui.status", ["--unknown"])
      end
    end
  end

  defp write(root, path, content) do
    path = Path.join(root, path)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
  end
end
