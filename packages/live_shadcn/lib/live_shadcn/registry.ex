defmodule LiveShadcn.Registry do
  @moduledoc """
  Where the components are, and what version of them an application holds.

  `mix ui.add` copies a component's source into the application, the way the
  shadcn CLI does, so the application owns the file and can edit it. That only
  works if there is an honest answer to two questions afterwards:

    * which registry version was this copied from?
    * has anybody edited it since?

  Both are answered by the stamp `mix ui.add` writes at the top of every copy:

      # live_shadcn: accordion @ ac60ef5 (spec 4f2b1c8e9d0a) — edited: no
      # Regenerate upstream, never here. `mix ui.sync` reports what changed.

  The digest in the stamp is of the file's own body. An edited file no longer
  matches it, and `mix ui.sync` says so and leaves the file alone.
  """

  @stamp_prefix "# live_shadcn:"

  @doc "Every component the registry holds, sorted."
  def components do
    registry_path()
    |> Path.join("*.ex")
    |> Path.wildcard()
    |> Enum.map(&(&1 |> Path.basename(".ex") |> String.replace("_", "-")))
    |> Enum.sort()
  end

  @doc "The source of a registry component, or `:error`."
  def source(name) do
    path = path(name)
    if File.exists?(path), do: {:ok, File.read!(path)}, else: :error
  end

  @doc "The path a component's source lives at inside this package."
  def path(name), do: Path.join(registry_path(), "#{String.replace(name, "-", "_")}.ex")

  defp registry_path, do: Application.app_dir(:live_shadcn, "priv/registry")

  @doc """
  Rewrites a registry module under an application's own namespace and stamps it.

  The module name is the only thing changed. Everything else is the registry's
  bytes, which is what makes the digest in the stamp meaningful.
  """
  def install(source, name, opts) do
    namespace = Keyword.fetch!(opts, :namespace)
    body = String.replace(source, "defmodule LiveShadcn.UI.", "defmodule #{namespace}.")

    stamp(body, name, opts) <> body
  end

  defp stamp(body, name, opts) do
    """
    #{@stamp_prefix} #{name} @ #{Keyword.fetch!(opts, :ref)} (#{digest(body)})
    # Generated from the shadcn registry. Regenerate upstream, never here.
    # `mix ui.sync` reports what changed upstream and skips files you edited.

    """
  end

  @doc """
  What an installed file says about itself: the component, the upstream ref, the
  digest it was installed with, and whether it still matches.
  """
  def installed(path) do
    contents = File.read!(path)

    case Regex.run(~r/^#{@stamp_prefix} (\S+) @ (\S+) \(([0-9a-f]+)\)/m, contents,
           capture: :all_but_first
         ) do
      [name, ref, digest] ->
        body = body_of(contents)

        {:ok,
         %{
           name: name,
           ref: ref,
           digest: digest,
           body: body,
           edited?: digest(body) != digest,
           path: path
         }}

      nil ->
        :error
    end
  end

  @doc "An installed file with its stamp removed."
  def body_of(contents) do
    contents
    |> String.split("\n")
    |> Enum.drop_while(&(not String.starts_with?(&1, "defmodule ")))
    |> Enum.join("\n")
  end

  @doc "The digest a stamp records. Truncated, because a stamp is read by people."
  def digest(body),
    do: :crypto.hash(:sha256, body) |> Base.encode16(case: :lower) |> binary_part(0, 12)
end
