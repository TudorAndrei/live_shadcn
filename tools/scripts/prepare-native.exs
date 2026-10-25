defmodule NativeArtifacts do
  @moduledoc false

  def run(projects) do
    if projects == [], do: raise("usage: elixir prepare-native.exs PROJECT [PROJECT ...]")
    Enum.each(projects, &prepare/1)
  end

  defp prepare(project) do
    lock_path = Path.join(project, "mix.lock")

    lock_ast =
      Code.string_to_quoted!(File.read!(lock_path), file: lock_path, emit_warnings: false)

    {lock, _} = Code.eval_quoted(lock_ast, [], file: lock_path)
    config_path = Path.join(project, "config/config.exs")
    env = System.get_env("MIX_ENV", "dev") |> String.to_existing_atom()

    config =
      if File.exists?(config_path),
        do: Config.Reader.read!(config_path, env: env, target: :host),
        else: []

    for dependency <- [:lazy_html, :mdex_native], Map.has_key?(lock, dependency) do
      {:hex, ^dependency, version, _, _, _, _, _} = Map.fetch!(lock, dependency)
      directory = Path.join([project, "deps", Atom.to_string(dependency)])
      {filename, checksum_file, cache, url} = artifact(dependency, version, config)
      {checksums, _} = Code.eval_file(Path.join(directory, checksum_file))
      "sha256:" <> expected = Map.fetch!(checksums, filename)
      unless Regex.match?(~r/\A[0-9a-f]{64}\z/, expected), do: raise("invalid pinned checksum")
      File.mkdir_p!(cache)
      destination = Path.join(cache, filename)

      if valid?(destination, expected) do
        IO.puts("Verified cached #{filename} sha256:#{expected}")
      else
        File.rm(destination)
        download(url, destination, expected)
        IO.puts("Verified downloaded #{filename} sha256:#{expected}")
      end
    end
  end

  defp artifact(:lazy_html, version, _config) do
    target = target("linux-gnu", "apple-darwin")
    filename = "lazy_html-nif-2.16-#{target}-#{version}.tar.gz"
    cache = System.get_env("ELIXIR_MAKE_CACHE_DIR") || cache_dir("elixir_make")

    {filename, "checksum.exs", cache,
     "https://github.com/dashbitco/lazy_html/releases/download/v#{version}/#{filename}"}
  end

  defp artifact(:mdex_native, version, config) do
    if System.get_env("MDEX_NATIVE_BUILD") in ["true", "1"],
      do: raise("native archive preparation requires MDEX_NATIVE_BUILD to be disabled")

    options = Keyword.get(config, :mdex_native, [])
    highlighter = Keyword.get(options, :syntax_highlighter)
    unless highlighter in [nil, :lumis, :syntect], do: raise("unsupported MDEx highlighter")

    legacy =
      Keyword.get(
        options,
        :use_legacy_artifacts,
        System.get_env("MDEX_NATIVE_USE_LEGACY_ARTIFACTS") in ["true", "1"]
      )

    # The dependency permits nil for CPU auto-detection. Do not guess its result.
    unless is_boolean(legacy), do: raise("set an explicit MDEx CPU variant before preparation")
    target = target("unknown-linux-gnu", "apple-darwin")
    legacy = legacy and String.starts_with?(target, "x86_64-unknown-linux")
    suffix = [if(legacy, do: "legacy_cpu"), highlighter] |> Enum.reject(&is_nil/1)
    variant = if suffix == [], do: "", else: "--" <> Enum.join(suffix, "_")
    filename = "libmdex_native_nif-v#{version}-nif-2.15-#{target}#{variant}.so.tar.gz"

    cache =
      System.get_env("RUSTLER_PRECOMPILED_GLOBAL_CACHE_PATH") ||
        cache_dir("rustler_precompiled/precompiled_nifs")

    {filename, "checksum-Elixir.MDExNative.Native.exs", cache,
     "https://artifacts.mdelixir.dev/releases/download/v#{version}/#{filename}"}
  end

  defp target(linux, darwin) do
    architecture = :erlang.system_info(:system_architecture) |> to_string()

    cpu =
      cond do
        String.starts_with?(architecture, "x86_64") -> "x86_64"
        String.starts_with?(architecture, "aarch64") -> "aarch64"
        true -> raise("unsupported native architecture: #{architecture}")
      end

    case :os.type() do
      {:unix, :linux} -> "#{cpu}-#{linux}"
      {:unix, :darwin} -> "#{cpu}-#{darwin}"
      other -> raise("unsupported native OS: #{inspect(other)}")
    end
  end

  defp cache_dir(name) do
    options = if System.get_env("MIX_XDG"), do: %{os: :linux}, else: %{}
    :filename.basedir(:user_cache, name, options) |> to_string()
  end

  defp valid?(path, expected) do
    case File.read(path) do
      {:ok, bytes} -> Base.encode16(:crypto.hash(:sha256, bytes), case: :lower) == expected
      {:error, _} -> false
    end
  end

  defp download(url, destination, expected) do
    temporary = destination <> ".#{System.pid()}.#{System.unique_integer([:positive])}.partial"

    try do
      {_, status} =
        System.cmd(
          "curl",
          [
            "--fail",
            "--location",
            "--silent",
            "--show-error",
            "--proto",
            "=https",
            "--proto-redir",
            "=https",
            "--retry",
            "3",
            "--connect-timeout",
            "15",
            "--max-time",
            "120",
            "--output",
            temporary,
            url
          ],
          stderr_to_stdout: true
        )

      # Do not print curl output. It can contain a signed redirect URL.
      unless status == 0, do: raise("native archive download failed with curl exit #{status}")

      unless valid?(temporary, expected),
        do: raise("native archive does not match its pinned SHA-256")

      File.rename!(temporary, destination)
    after
      File.rm(temporary)
    end
  end
end

NativeArtifacts.run(System.argv())
