defmodule Mix.Tasks.Ui.VerifyStatusTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 180_000

  alias LiveShadcnTools
  alias LiveShadcnVerification
  alias Mix.Tasks.Ui.Verify

  setup do
    working_directory = File.cwd!()
    original = LiveShadcnTools.repo_root()
    root = Path.join(System.tmp_dir!(), "verify-status-#{System.unique_integer([:positive])}")

    on_exit(fn ->
      File.cd!(working_directory)
      File.rm_rf!(root)
    end)

    File.mkdir_p!(Path.join(root, "registry"))
    File.mkdir_p!(Path.join(root, "parity"))

    for directory <- ~w(packages tools storybook) do
      File.ln_s!(Path.join(original, directory), Path.join(root, directory))
    end

    for name <- File.ls!(Path.join(original, "parity")),
        not String.starts_with?(name, ".source-") do
      File.ln_s!(Path.join([original, "parity", name]), Path.join([root, "parity", name]))
    end

    for name <- ~w(spec snapshot upstream) do
      File.ln_s!(Path.join([original, "registry", name]), Path.join([root, "registry", name]))
    end

    for name <- ~w(UPSTREAM.json VERIFICATION_POLICY.json INVENTORY.json) do
      File.cp!(Path.join([original, "registry", name]), Path.join([root, "registry", name]))
    end

    ai_identity = "ai_elements/message"

    ai_record =
      LiveShadcnTools.read_json!(Path.join(original, "registry/VERIFY.json"))[ai_identity]

    assert is_map(ai_record)
    path = Path.join(root, "registry/VERIFY.json")
    LiveShadcnTools.write_json_atomic!(path, %{ai_identity => ai_record})

    %{root: root, path: path, ai_identity: ai_identity, ai_record: ai_record}
  end

  test "a persisted no-browser run remains incomplete with successful static checks", context do
    {record, evaluation} = run_and_read(context, ["shadcn/button", "--no-browser"])

    assert record["pass"] == false

    for name <- ~w(generated snapshot examples) do
      assert record["checks"][name]["pass"] == true
    end

    assert evaluation.status == :not_verified
    assert evaluation.label == "Not verified"
    assert Enum.all?(evaluation.checks, &(&1.outcome in [:passed, :incomplete, :not_run]))
    assert evaluation.reason =~ "browser"
  end

  test "a persisted preparation failure has a failed required check and its reason", context do
    {:ok, listener} = :gen_tcp.listen(0, [:binary, active: false, ip: {127, 0, 0, 1}])
    {:ok, {{127, 0, 0, 1}, port}} = :inet.sockname(listener)
    prior_port = System.get_env("STORYBOOK_PORT")
    System.put_env("STORYBOOK_PORT", Integer.to_string(port))

    on_exit(fn ->
      :gen_tcp.close(listener)

      if prior_port,
        do: System.put_env("STORYBOOK_PORT", prior_port),
        else: System.delete_env("STORYBOOK_PORT")
    end)

    {record, evaluation} = run_and_read(context, ["shadcn/button"])
    browser = Enum.find(evaluation.checks, &(&1.name == "browser"))

    assert browser.outcome == :failed
    assert record["checks"]["browser"]["outcome"] == "failed"
    assert evaluation.status == :failed
    assert evaluation.label == "Failed"
    assert evaluation.reason =~ "browser preparation failed"
    assert evaluation.reason =~ "storybook port #{port} is already occupied"
  end

  defp run_and_read(context, arguments) do
    File.cd!(context.root, fn ->
      assert_raise Mix.Error, ~r/not verified: shadcn\/button/, fn -> Verify.run(arguments) end
      persisted = LiveShadcnTools.read_json!(context.path)
      assert persisted[context.ai_identity] == context.ai_record
      record = persisted["shadcn/button"]

      evaluation =
        LiveShadcnVerification.evaluate(
          record,
          "shadcn",
          "button",
          context.root,
          Path.join(context.root, "registry/spec/shadcn/button.json")
        )

      {record, evaluation}
    end)
  end
end
