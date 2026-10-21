defmodule Mix.Tasks.Ui.Verify.Plan do
  @shortdoc "Print a balanced CI verification matrix as JSON"
  @moduledoc """
  Prints source-qualified targets and estimated work for each CI runner.

      mix ui.verify.plan --source shadcn --shards 8

  The plan includes every current verification target, including documentation
  families. Each runner uses the same plan through `mix ui.verify --shard 1/8`.
  """
  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")

    {opts, names, invalid} =
      OptionParser.parse(argv, strict: [source: :string, shards: :integer, output: :string])

    source = opts[:source]

    if invalid != [] or names != [] or source not in LiveShadcnTools.sources(),
      do: Mix.raise("use ui.verify.plan --source shadcn|ai_elements --shards COUNT")

    targets = LiveShadcnTools.verification_targets(source)

    previews =
      LiveShadcnTools.registry_path(["snapshot", "index.json"]) |> File.read!() |> Jason.decode!()

    costs = LiveShadcnTools.VerificationShards.costs(previews, LiveShadcnTools.repo_root())
    shards = LiveShadcnTools.VerificationShards.plan(targets, previews, opts[:shards] || 8, costs)
    matrix = %{"include" => shards}

    if output = opts[:output],
      do: LiveShadcnTools.write_json_atomic!(Path.expand(output), matrix),
      else: IO.puts(Jason.encode!(matrix))
  end
end
