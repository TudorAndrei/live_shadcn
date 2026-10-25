defmodule Mix.Tasks.Ui.Hooks do
  @shortdoc "Regenerate the colocated hook blocks from the packages' assets/js/"

  @moduledoc """
  Writes every colocated hook block in `packages/live_base/lib` and
  `packages/live_ai_elements/lib` from the hook source it names. See
  `LiveShadcnTools.ColocatedHooks` for the block format.

      mix ui.hooks
      mix ui.hooks --check   # exit 1 and list stale files (for CI)

  Needs `npm ci` in `tools/` for the bundler.
  """
  use Mix.Task

  import LiveShadcnTools, only: [repo_root: 0]

  alias LiveShadcnTools.ColocatedHooks

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")

    case OptionParser.parse(argv, strict: [check: :boolean]) do
      {opts, [], []} -> generate(Keyword.get(opts, :check, false))
      _ -> Mix.raise("usage: mix ui.hooks [--check]")
    end
  end

  defp generate(check?) do
    root = repo_root()

    case {ColocatedHooks.render(root), check?} do
      {{:error, errors}, _} ->
        Mix.raise("colocated hooks cannot be generated:\n" <> Enum.join(errors, "\n"))

      {{:ok, []}, _} ->
        Mix.shell().info("colocated hooks are current")

      {{:ok, stale}, true} ->
        files = Enum.map_join(stale, "\n", fn {path, _content} -> "  " <> path end)
        Mix.raise("colocated hooks are stale. Run `mix ui.hooks`.\n" <> files)

      {{:ok, stale}, false} ->
        for {path, content} <- stale do
          File.write!(Path.join(root, path), content)
          Mix.shell().info("wrote #{path}")
        end
    end
  end
end
