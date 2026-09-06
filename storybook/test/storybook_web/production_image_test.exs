defmodule StorybookWeb.ProductionImageTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../../..", __DIR__)

  test "compiled badge evaluation matches the shared pipeline evaluator" do
    verify_path = Path.join(@repo_root, "registry/VERIFY.json")
    verify = verify_path |> File.read!() |> Jason.decode!()

    for {identity, record} <- verify, String.starts_with?(identity, "shadcn/") do
      [source, name] = String.split(identity, "/", parts: 2)
      spec = Path.join(@repo_root, "registry/spec/#{source}/#{name}.json")

      pipeline =
        LiveShadcnVerification.evaluate(record, source, name, @repo_root, spec)

      compiled = StorybookWeb.Docs.evaluation(name)

      assert compiled.status == pipeline.status
      assert compiled.label == pipeline.label
      assert compiled.reason == pipeline.reason

      assert Enum.map(compiled.checks, & &1.name) ==
               Enum.map(pipeline.checks, & &1.name)

      assert Enum.map(compiled.checks, & &1.outcome) ==
               Enum.map(pipeline.checks, & &1.outcome)
    end
  end
end
