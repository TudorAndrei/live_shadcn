defmodule LiveShadcnTools do
  @moduledoc """
  Shared helpers for the maintainer codegen pipeline.

  The pipeline is `ui.fetch -> ui.spec -> ui.gen -> ui.verify`. Every stage is
  deterministic and reads only from `registry/`, so a rerun on the same pinned
  upstream commit must produce a byte-identical result.
  """

  @doc "Absolute path of the monorepo root, found by walking up from the cwd."
  def repo_root do
    File.cwd!()
    |> Path.expand()
    |> walk_up()
    |> case do
      nil ->
        Mix.raise("cannot find repo root: no parent directory holds both registry/ and packages/")

      root ->
        root
    end
  end

  defp walk_up("/"), do: nil

  defp walk_up(dir) do
    if File.dir?(Path.join(dir, "registry")) and File.dir?(Path.join(dir, "packages")) do
      dir
    else
      walk_up(Path.dirname(dir))
    end
  end

  def registry_path(parts), do: Path.join([repo_root(), "registry" | List.wrap(parts)])

  @doc "SHA-256 of a binary, hex encoded. Used to detect upstream drift."
  def digest(binary), do: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)

  def write!(path, content) do
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
    path
  end

  def read_json!(path), do: path |> File.read!() |> Jason.decode!()

  def write_json!(path, term) do
    write!(
      path,
      Jason.encode_to_iodata!(term, pretty: true) |> IO.iodata_to_binary() |> Kernel.<>("\n")
    )
  end
end
