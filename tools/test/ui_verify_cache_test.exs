defmodule Mix.Tasks.Ui.VerifyCacheTest do
  use ExUnit.Case, async: false

  alias LiveShadcnTools, as: Tools
  alias LiveShadcnTools.VerificationCache
  alias Mix.Tasks.Ui.Verify
  alias Mix.Tasks.Ui.Verify.Cache

  setup do
    root = Path.join(System.tmp_dir!(), "verify-cache-#{System.unique_integer([:positive])}")

    for directory <-
          ~w(registry/spec/shadcn registry/snapshot packages/live_shadcn/priv/registry parity tools storybook) do
      File.mkdir_p!(Path.join(root, directory))
    end

    Tools.write_json!(Path.join(root, "registry/UPSTREAM.json"), %{
      "files" => %{"shadcn/ui/button.tsx" => %{"sha256" => "pinned"}},
      "examples" => %{"shadcn" => %{"button" => ["button-demo"]}}
    })

    Tools.write_json!(Path.join(root, "registry/spec/shadcn/button.json"), %{"ignored" => %{}})
    Tools.write_json!(Path.join(root, "registry/snapshot/index.json"), %{"button" => ["default"]})
    File.write!(Path.join(root, "packages/live_shadcn/priv/registry/button.ex"), "reviewed port")
    File.write!(Path.join(root, "registry/snapshot/button-default.html"), "<button>Save</button>")

    Tools.write_json!(Path.join(root, "registry/VERIFY.json"), %{
      "ai_elements/message" => %{"pass" => false}
    })

    on_exit(fn -> File.rm_rf!(root) end)
    %{root: root, cache: Path.join(root, "cache.json"), output: Path.join(root, "output.json")}
  end

  test "the public planner and verifier reuse complete evidence without source or server setup",
       ctx do
    File.cd!(ctx.root, fn ->
      record = passing_record(ctx.root)
      write_cache(ctx.cache, record)
      {:ok, socket} = :gen_tcp.listen(0, [:binary, active: false, ip: {127, 0, 0, 1}])
      {:ok, {_, port}} = :inet.sockname(socket)
      previous = System.get_env("STORYBOOK_PORT")
      System.put_env("STORYBOOK_PORT", Integer.to_string(port))

      try do
        before = File.read!("registry/VERIFY.json")
        cached = File.read!(ctx.cache)
        Cache.run(arguments(ctx))

        assert Tools.read_json!(ctx.output) == %{
                 "browser_needed" => false,
                 "components" => ["shadcn/button"],
                 "reused" => ["shadcn/button"],
                 "run" => []
               }

        assert File.read!("registry/VERIFY.json") == before
        assert File.read!(ctx.cache) == cached

        Verify.run(arguments(ctx) ++ ["--artifacts", Path.join(ctx.root, "artifacts")])

        assert Tools.read_json!(ctx.output) == %{
                 "source" => "shadcn",
                 "shard" => "1/1",
                 "components" => ["shadcn/button"],
                 "results" => %{"shadcn/button" => record}
               }

        assert Tools.read_json!("registry/VERIFY.json")["shadcn/button"] == record
        assert Tools.read_json!(ctx.cache)["results"] == %{"shadcn/button" => record}

        assert Tools.read_json!(ctx.cache)["runtime"]["utc_date"] ==
                 Date.to_iso8601(Date.utc_today())
      after
        :gen_tcp.close(socket)

        if previous,
          do: System.put_env("STORYBOOK_PORT", previous),
          else: System.delete_env("STORYBOOK_PORT")
      end
    end)
  end

  test "a public all-hit run rejects a changed fetched source and force clears its prior cache",
       ctx do
    File.cd!(ctx.root, fn ->
      manifest = Tools.read_json!("registry/UPSTREAM.json")

      Tools.write_json!(
        "registry/UPSTREAM.json",
        put_in(manifest, ["files", "shadcn/ui/dialog.tsx"], %{
          "sha256" => Tools.digest("pinned dialog")
        })
      )

      record = passing_record(ctx.root)
      Tools.write!("registry/upstream/shadcn/ui/dialog.tsx", "changed local bytes")
      before = File.read!("registry/VERIFY.json")

      for force? <- [false, true] do
        write_cache(ctx.cache, record)
        Cache.run(arguments(ctx))
        assert Tools.read_json!(ctx.output)["reused"] == ["shadcn/button"]
        args = if force?, do: arguments(ctx) ++ ["--force"], else: arguments(ctx)

        assert_raise Mix.Error,
                     ~r/pinned upstream file shadcn\/ui\/dialog.tsx does not match/,
                     fn ->
                       Verify.run(args)
                     end

        assert File.read!("registry/VERIFY.json") == before
        if force?, do: assert(Tools.read_json!(ctx.cache)["results"] == %{})
      end
    end)
  end

  test "the public planner rejects unusable cache evidence and force bypasses a valid result",
       ctx do
    File.cd!(ctx.root, fn ->
      record = passing_record(ctx.root)

      valid = %{
        "version" => 1,
        "runtime" => VerificationCache.runtime(),
        "results" => %{"shadcn/button" => record}
      }

      cases =
        [
          nil,
          "broken JSON",
          [],
          Map.put(valid, "version", 2),
          Map.put(valid, "runtime", %{}),
          Map.put(valid, "results", nil),
          put_in(valid, ["results", "shadcn/button"], []),
          put_in(valid, ["results", "shadcn/button", "evidence"], "stale"),
          put_in(valid, ["results", "shadcn/button", "spec"], "stale"),
          put_in(valid, ["results", "shadcn/button", "pass"], false),
          put_in(valid, ["results", "shadcn/button", "checks"], %{}),
          put_in(valid, ["results", "shadcn/button", "checks", "pixel"], %{
            "pass" => true,
            "gated" => false
          }),
          put_in(valid, ["results", "shadcn/button", "checks", "browser"], %{"pass" => false})
        ] ++
          Enum.map(
            ~w(os arch otp elixir node image browser_image utc_date),
            &put_in(valid, ["runtime", &1], "other-runtime")
          )

      for candidate <- cases do
        case candidate do
          nil -> File.rm(ctx.cache)
          "broken JSON" -> File.write!(ctx.cache, candidate)
          _ -> Tools.write_json!(ctx.cache, candidate)
        end

        Cache.run(arguments(ctx))

        assert Tools.read_json!(ctx.output) == %{
                 "browser_needed" => true,
                 "components" => ["shadcn/button"],
                 "reused" => [],
                 "run" => ["shadcn/button"]
               }
      end

      Tools.write_json!(ctx.cache, valid)
      Cache.run(arguments(ctx) ++ ["--force"])
      assert Tools.read_json!(ctx.output)["run"] == ["shadcn/button"]
    end)
  end

  test "the public planner binds the browser image and the UTC date", ctx do
    File.cd!(ctx.root, fn ->
      previous = System.get_env("CI_BROWSER_IMAGE")
      image = "mcr.microsoft.com/playwright:v1.62.1-noble@sha256:fixture"
      System.put_env("CI_BROWSER_IMAGE", image)

      try do
        write_cache(ctx.cache, passing_record(ctx.root))
        cache = Tools.read_json!(ctx.cache)
        assert cache["runtime"]["browser_image"] == image
        assert cache["runtime"]["utc_date"] == Date.to_iso8601(Date.utc_today())
        Cache.run(arguments(ctx))
        assert Tools.read_json!(ctx.output)["browser_needed"] == false

        System.put_env("CI_BROWSER_IMAGE", image <> "-changed")
        Cache.run(arguments(ctx))
        assert Tools.read_json!(ctx.output)["run"] == ["shadcn/button"]

        System.put_env("CI_BROWSER_IMAGE", image)
        yesterday = Date.utc_today() |> Date.add(-1) |> Date.to_iso8601()
        Tools.write_json!(ctx.cache, put_in(cache, ["runtime", "utc_date"], yesterday))
        Cache.run(arguments(ctx))
        assert Tools.read_json!(ctx.output)["run"] == ["shadcn/button"]
      after
        if previous,
          do: System.put_env("CI_BROWSER_IMAGE", previous),
          else: System.delete_env("CI_BROWSER_IMAGE")
      end
    end)
  end

  test "a mixed public run publishes the full scope and keeps only current passed cache records",
       ctx do
    File.cd!(ctx.root, fn ->
      Tools.write_json!("registry/spec/shadcn/dialog.json", %{
        "ignored" => %{
          "unreviewed" => "the generated port does not contain this source literal"
        }
      })

      Tools.write!("packages/live_shadcn/priv/registry/dialog.ex", "reviewed port")
      button = passing_record(ctx.root)

      incomplete =
        passing_record(ctx.root, "shadcn", "dialog")
        |> update_in(["checks"], &Map.delete(&1, "browser"))

      write_cache(ctx.cache, button)
      cache = Tools.read_json!(ctx.cache)
      Tools.write_json!(ctx.cache, put_in(cache, ["results", "shadcn/dialog"], incomplete))

      Cache.run(arguments(ctx))

      assert Tools.read_json!(ctx.output) == %{
               "browser_needed" => true,
               "components" => ["shadcn/button", "shadcn/dialog"],
               "reused" => ["shadcn/button"],
               "run" => ["shadcn/dialog"]
             }

      assert_raise Mix.Error, ~r/not verified: shadcn\/dialog/, fn ->
        Verify.run(arguments(ctx))
      end

      report = Tools.read_json!(ctx.output)
      assert report["components"] == ["shadcn/button", "shadcn/dialog"]
      assert report["results"]["shadcn/button"] == button
      assert report["results"]["shadcn/dialog"]["pass"] == false
      assert Tools.read_json!(ctx.cache)["results"] == %{"shadcn/button" => button}
      assert Tools.read_json!("registry/VERIFY.json")["ai_elements/message"] == %{"pass" => false}
    end)
  end

  test "AI cache evidence is reusable before and after pinned source restoration", ctx do
    File.cd!(ctx.root, fn ->
      manifest = Tools.read_json!("registry/UPSTREAM.json")

      Tools.write_json!(
        "registry/UPSTREAM.json",
        put_in(manifest, ["files", "ai_elements/code-block.tsx"], %{
          "sha256" => Tools.digest("pinned AI source")
        })
      )

      Tools.write_json!("registry/spec/ai_elements/code-block.json", %{"ignored" => %{}})

      Tools.write!(
        "packages/live_ai_elements/lib/live_ai_elements/components/code_block.ex",
        "authored port"
      )

      record = passing_record(ctx.root, "ai_elements", "code-block")

      Tools.write_json!(ctx.cache, %{
        "version" => 1,
        "runtime" => VerificationCache.runtime(),
        "results" => %{"ai_elements/code-block" => record}
      })

      args = List.replace_at(arguments(ctx), 1, "ai_elements")

      for restored? <- [false, true] do
        if restored?,
          do: Tools.write!("registry/upstream/ai_elements/code-block.tsx", "pinned AI source")

        Cache.run(args)
        assert Tools.read_json!(ctx.output)["reused"] == ["ai_elements/code-block"]
        assert Tools.read_json!(ctx.output)["browser_needed"] == false
        Verify.run(args)
        assert Tools.read_json!(ctx.output)["results"] == %{"ai_elements/code-block" => record}
      end
    end)
  end

  test "a forced failed run removes a prior pass before the task raises and writes its report",
       ctx do
    File.cd!(ctx.root, fn ->
      Tools.write_json!("registry/snapshot/index.json", %{})
      write_cache(ctx.cache, passing_record(ctx.root))

      assert_raise Mix.Error, ~r/not verified: shadcn\/button/, fn ->
        Verify.run(arguments(ctx) ++ ["--force"])
      end

      assert Tools.read_json!(ctx.cache)["results"] == %{}
      report = Tools.read_json!(ctx.output)
      assert report["components"] == ["shadcn/button"]
      assert report["results"]["shadcn/button"]["pass"] == false
    end)
  end

  test "cache CLI options are strict and cannot import or bypass browser evidence", ctx do
    File.cd!(ctx.root, fn ->
      for extra <- [
            ["--record", "pixel=x"],
            ["--no-browser"],
            ["--unknown"],
            ["--force", "extra"]
          ] do
        assert_raise Mix.Error, fn -> Verify.run(arguments(ctx) ++ extra) end
      end

      for extra <- [["--browser"], ["--record", "pixel=x"], ["extra"]] do
        assert_raise Mix.Error, fn -> Cache.run(arguments(ctx) ++ extra) end
      end
    end)
  end

  defp arguments(ctx),
    do: ["--source", "shadcn", "--shard", "1/1", "--reuse", ctx.cache, "--output", ctx.output]

  defp passing_record(root, source \\ "shadcn", name \\ "button") do
    policy = Tools.verification_policy(source, name, root)

    %{
      "pass" => true,
      "spec" => Tools.digest(File.read!(Path.join(root, "registry/spec/#{source}/#{name}.json"))),
      "evidence" => LiveShadcnVerification.evidence_digest(source, name, root),
      "checks" =>
        Map.new(
          Tools.required_verification_checks(source, policy),
          &{&1, %{"pass" => true, "outcome" => "passed"}}
        )
    }
  end

  defp write_cache(path, record),
    do:
      Tools.write_json!(path, %{
        "version" => 1,
        "runtime" => VerificationCache.runtime(),
        "results" => %{"shadcn/button" => record}
      })
end
