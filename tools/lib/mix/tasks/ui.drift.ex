defmodule Mix.Tasks.Ui.Drift do
  @shortdoc "Summarise what moved upstream, in words rather than file statistics"

  @moduledoc """
  Reads the working tree against the last commit and says what upstream changed.

      mix ui.drift              # a summary a person can read
      mix ui.drift --title      # one line, for a pull request title

  The weekly sync opens a pull request, and this is what it puts in it:

      sync shadcn — 3 class strings, 1 new attribute, 1 new component

  The comparison is of specs, not of files. See `LiveShadcnTools.Drift` for why
  that is the trustworthy thing to compare.
  """
  use Mix.Task

  import LiveShadcnTools

  alias LiveShadcnTools.Drift

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")
    {opts, _, _} = OptionParser.parse(argv, strict: [title: :boolean])

    drift = drift()

    if Keyword.get(opts, :title, false),
      do: Mix.shell().info(Drift.title(drift)),
      else: Mix.shell().info(Drift.report(drift))
  end

  @doc "What changed, per component, between the last commit and the working tree."
  def drift do
    registry_path("spec")
    |> Path.join("*/*.json")
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.map(&compare/1)
    |> Enum.reject(&(&1.changes == [] and not &1.new?))
  end

  defp compare(path) do
    reference = ref(Path.basename(Path.dirname(path)), Path.basename(path, ".json"))
    current = read_json!(path)

    case committed(path) do
      :error ->
        %{name: reference, new?: true, changes: []}

      {:ok, previous} ->
        %{name: reference, new?: false, changes: Drift.between(previous, current)}
    end
  end

  # What the last commit holds, which is what a reviewer is comparing against.
  defp committed(path) do
    relative = Path.relative_to(path, repo_root())

    case System.cmd("git", ["show", "HEAD:#{relative}"], cd: repo_root(), stderr_to_stdout: true) do
      {contents, 0} -> {:ok, Jason.decode!(contents)}
      _ -> :error
    end
  end
end
