defmodule StorybookWeb.ProductionImageTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../../..", __DIR__)

  test "the clean builder installs the locked asset dependencies before bundling assets" do
    dockerfile = File.read!(Path.join(@repo_root, "storybook/Dockerfile"))

    assert [_, after_install] = String.split(dockerfile, "RUN cd assets && npm ci", parts: 2)
    assert after_install =~ "RUN mix assets.deploy"
  end

  test "compiled badge evaluation matches the shared pipeline evaluator" do
    verify_path = Path.join(@repo_root, "registry/VERIFY.json")
    verify = verify_path |> File.read!() |> Jason.decode!()

    for {identity, record} <- verify, String.starts_with?(identity, "shadcn/") do
      [source, name] = String.split(identity, "/", parts: 2)
      spec = Path.join(@repo_root, "registry/spec/#{source}/#{name}.json")

      pipeline =
        LiveShadcnVerification.evaluate(record, source, name, @repo_root, spec)

      compiled = StorybookWeb.Docs.evaluation("#{source}-#{name}")

      assert compiled == pipeline, identity
    end
  end
end
