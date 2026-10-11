defmodule Mix.Tasks.Verification.Identity do
  @shortdoc "Export verification identity JSON for browser reports"

  @moduledoc false

  use Mix.Task

  alias LiveShadcnVerification

  import LiveShadcnTools

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")

    {opts, args, _} =
      OptionParser.parse(argv,
        strict: [source: :string, layer: :string, examples: :string, preview_key: :string]
      )

    {source, name} =
      case args do
        [reference] ->
          LiveShadcnTools.parse_ref(reference)

        [] ->
          Mix.raise(
            "usage: mix verification.identity [--layer LAYER] [--examples a,b] <source/name>"
          )
      end

    root = repo_root()
    layer = Keyword.get(opts, :layer)
    preview_key = Keyword.get(opts, :preview_key) || preview_key(source, name, root)

    examples =
      case Keyword.get(opts, :examples) do
        nil ->
          []

        value ->
          value
          |> String.split(",", trim: true)
          |> Enum.sort()
      end

    envelope =
      LiveShadcnVerification.Report.envelope(
        source,
        name,
        layer,
        preview_key,
        examples,
        LiveShadcnVerification.evidence_digest(source, name, root),
        completed: not is_nil(layer)
      )

    Mix.shell().info(Jason.encode!(envelope))
  end

  defp preview_key(source, name, root) do
    snapshot_index =
      Path.join(root, "registry/snapshot/index.json") |> File.read!() |> Jason.decode!()

    LiveShadcnVerification.preview_key(snapshot_index, source, name)
  end
end
