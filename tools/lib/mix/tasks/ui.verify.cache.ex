defmodule Mix.Tasks.Ui.Verify.Cache do
  @shortdoc "Plan verification cache reuse without running verification"
  @moduledoc """
  Writes the assigned scope and cache misses for a CI shard.

      mix ui.verify.cache --source shadcn --shard 1/8 --reuse cache.json --output plan.json

  `--force` assigns every component to a fresh run. The planner does not fetch
  sources, start browsers or servers, or write registry verification records.
  """
  use Mix.Task

  alias LiveShadcnTools.VerificationCache

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")

    {opts, names, invalid} =
      OptionParser.parse(argv,
        strict: [
          source: :string,
          shard: :string,
          reuse: :string,
          output: :string,
          force: :boolean
        ]
      )

    if invalid != [],
      do: Mix.raise("invalid cache option(s): #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")

    components = VerificationCache.scope!(opts, names)

    selection =
      VerificationCache.select(
        components,
        opts[:reuse],
        opts[:force] || false,
        LiveShadcnTools.repo_root()
      )

    LiveShadcnTools.write_json_atomic!(
      Path.expand(opts[:output]),
      VerificationCache.plan(components, selection)
    )
  end
end
