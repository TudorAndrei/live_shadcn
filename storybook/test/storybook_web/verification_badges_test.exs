defmodule StorybookWeb.VerificationBadgesTest do
  use StorybookWeb.ConnCase, async: false

  @root Path.expand("../../..", __DIR__)

  test "compiled records render each verification state on the index and documentation", %{
    conn: conn
  } do
    fixture = Path.join(System.tmp_dir!(), "badge-pages-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(fixture) end)
    fixture_inputs(fixture)
    records = fixture_records(fixture)
    File.write!(Path.join(fixture, "registry/VERIFY.json"), Jason.encode!(records))

    module = StorybookWeb.Docs
    {^module, binary, filename} = :code.get_object_code(module)
    compiler_options = Code.compiler_options()
    Code.compiler_options(ignore_module_conflict: true)

    try do
      source = File.read!(Path.join(@root, "storybook/lib/storybook_web/docs.ex"))
      Code.compile_string(source, Path.join(fixture, "storybook/lib/storybook_web/docs.ex"))
      index_html = conn |> get("/") |> html_response(200)

      for {component, status, label} <- [
            {"button", "not_verified", "Not verified"},
            {"label", "not_verified", "Not verified"},
            {"dialog", "failed", "Failed"},
            {"accordion", "stale", "Stale"},
            {"aspect-ratio", "verified", "Verified"},
            {"data-table", "verified", "Verified"},
            {"direction", "no_dom", "No DOM"},
            {"attachments", "stale", "Stale"}
          ] do
        docs_html = assert_badges(index_html, component, status, label)

        if component == "dialog", do: assert(docs_html =~ "browser preparation failed")
        if component == "button", do: assert(docs_html =~ "--no-browser was used")
      end

      recovered = %{
        records["shadcn/button"]
        | "pass" => true,
          "checks" => records["shadcn/aspect-ratio"]["checks"]
      }

      File.write!(
        Path.join(fixture, "registry/VERIFY.json"),
        Jason.encode!(Map.put(records, "shadcn/button", recovered))
      )

      prior_html = build_conn() |> get("/") |> html_response(200)
      assert_badges(prior_html, "button", "not_verified", "Not verified")
      :code.soft_purge(module)
      Code.compile_string(source, Path.join(fixture, "storybook/lib/storybook_web/docs.ex"))
      recovered_html = build_conn() |> get("/") |> html_response(200)
      assert_badges(recovered_html, "button", "verified", "Verified")
    after
      Code.compiler_options(compiler_options)
      :code.soft_purge(module)
      assert {:module, ^module} = :code.load_binary(module, filename, binary)
      :code.soft_purge(module)
    end
  end

  defp assert_badges(index_html, component, status, label) do
    row =
      index_html
      |> Floki.parse_fragment!()
      |> Floki.find("li")
      |> Enum.find(fn row ->
        Floki.attribute(Floki.find([row], "a"), "href") == ["/docs/#{component}"] and
          Floki.find([row], "[data-component-status]") != []
      end)

    assert row, "missing index badge for #{component}"
    [index_badge] = Floki.find([row], "[data-component-status]")
    assert Floki.attribute([index_badge], "data-component-status") == [status]
    assert String.trim(Floki.text(index_badge)) == label

    docs_html = build_conn() |> get("/docs/#{component}") |> html_response(200)
    [docs_badge] = Floki.find(Floki.parse_fragment!(docs_html), "[data-component-status]")
    assert Floki.attribute([docs_badge], "data-component-status") == [status]
    assert String.trim(Floki.text(docs_badge)) == label
    docs_html
  end

  defp fixture_inputs(root) do
    File.mkdir_p!(Path.join(root, "registry"))

    for directory <- ~w(packages tools storybook parity) do
      File.ln_s!(Path.join(@root, directory), Path.join(root, directory))
    end

    for name <- ~w(spec snapshot upstream) do
      File.ln_s!(Path.join([@root, "registry", name]), Path.join([root, "registry", name]))
    end

    for name <- ~w(UPSTREAM.json VERIFICATION_POLICY.json) do
      File.cp!(Path.join([@root, "registry", name]), Path.join([root, "registry", name]))
    end
  end

  defp fixture_records(root) do
    template =
      @root
      |> Path.join("registry/VERIFY.json")
      |> File.read!()
      |> Jason.decode!()
      |> Map.fetch!("shadcn/button")

    names = ~w(button label dialog accordion aspect-ratio data-table)
    identities = LiveShadcnVerification.evidence_digests(names, root)

    records =
      Map.new(names, fn name ->
        spec = Path.join([root, "registry/spec/shadcn", "#{name}.json"])

        record =
          template
          |> Map.put("evidence", Map.fetch!(identities, name))
          |> Map.put(
            "spec",
            if(File.exists?(spec), do: LiveShadcnVerification.digest(File.read!(spec)))
          )

        {"shadcn/#{name}", record}
      end)

    incomplete = not_run_record(records["shadcn/button"], "--no-browser was used")
    preparation = "browser preparation failed: storybook port is already occupied"
    failure = %{"pass" => false, "outcome" => "failed", "detail" => preparation}

    failed =
      records["shadcn/dialog"]
      |> not_run_record(preparation)
      |> put_in(["checks", "browser"], failure)

    stale =
      records["shadcn/accordion"]
      |> not_run_record(preparation)
      |> put_in(["checks", "browser"], failure)
      |> Map.put("evidence", "prior-source-identity")

    missing = records["shadcn/label"] |> incomplete_policy()
    missing = update_in(missing, ["checks"], &Map.delete(&1, "pixel"))

    records
    |> Map.put("shadcn/button", incomplete)
    |> Map.put("shadcn/dialog", failed)
    |> Map.put("shadcn/accordion", stale)
    |> Map.put("shadcn/label", missing)
    |> Map.put("ai_elements/attachments", %{"pass" => false, "evidence" => "historical-ai-input"})
  end

  defp not_run_record(record, reason) do
    Enum.reduce(~w(browser behavior accessibility parity pixel), record, fn name, record ->
      put_in(record, ["checks", name], %{
        "pass" => false,
        "gated" => false,
        "outcome" => "not_run",
        "detail" => "not run because #{reason}"
      })
    end)
    |> incomplete_policy()
  end

  defp incomplete_policy(record) do
    record
    |> Map.put("pass", false)
    |> put_in(["checks", "policy"], %{
      "pass" => false,
      "outcome" => "incomplete",
      "detail" => "required checks for standard policy"
    })
  end
end
