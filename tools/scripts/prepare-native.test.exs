ExUnit.start()

defmodule NativeArtifactsTest do
  use ExUnit.Case, async: false

  @script Path.expand("prepare-native.exs", __DIR__)

  setup do
    root = Path.join(System.tmp_dir!(), "native-artifacts-#{System.unique_integer([:positive])}")
    File.mkdir_p!(Path.join(root, "bin"))
    on_exit(fn -> File.rm_rf!(root) end)
    payload = "a checksum-protected native archive"
    File.write!(Path.join(root, "payload"), payload)
    checksum = "sha256:" <> Base.encode16(:crypto.hash(:sha256, payload), case: :lower)

    curl = Path.join(root, "bin/curl")

    File.write!(curl, """
    #!/bin/sh
    while [ "$#" -gt 0 ]; do
      if [ "$1" = "--output" ]; then shift; output="$1"; fi
      shift
    done
    cp "$NATIVE_TEST_PAYLOAD" "$output"
    exit 0
    """)

    File.chmod!(curl, 0o755)
    %{root: root, checksum: checksum, curl: curl}
  end

  test "the CLI downloads a verified archive and reuses it without a download", context do
    filename = fixture(context)
    assert {output, 0} = run(context)
    assert output =~ "Verified downloaded #{filename}"
    File.write!(context.curl, "#!/bin/sh\nexit 99\n")
    assert {output, 0} = run(context)
    assert output =~ "Verified cached #{filename}"
  end

  test "a corrupt cached archive is replaced with verified bytes", context do
    filename = fixture(context)
    cache = Path.join(context.root, "cache")
    File.mkdir_p!(cache)
    File.write!(Path.join(cache, filename), "corrupt cache")
    assert {_, 0} = run(context)

    assert File.read!(Path.join(cache, filename)) ==
             File.read!(Path.join(context.root, "payload"))
  end

  test "a checksum mismatch cannot enter the compiler cache", context do
    filename = fixture(context)
    File.write!(Path.join(context.root, "payload"), "untrusted archive")
    assert {output, status} = run(context)
    assert status != 0
    assert output =~ "does not match its pinned SHA-256"
    refute File.exists?(Path.join(context.root, "cache/#{filename}"))
    assert Path.wildcard(Path.join(context.root, "cache/*.partial")) == []
  end

  test "a failed partial download leaves no archive and does not print signed URLs", context do
    filename = fixture(context)

    File.write!(
      context.curl,
      String.replace(
        File.read!(context.curl),
        "exit 0",
        "echo 'https://private.invalid/?signature=secret'\nexit 23"
      )
    )

    assert {output, status} = run(context)
    assert status != 0
    assert output =~ "curl exit 23"
    refute output =~ "signature=secret"
    refute File.exists?(Path.join(context.root, "cache/#{filename}"))
    assert Path.wildcard(Path.join(context.root, "cache/*.partial")) == []
  end

  test "a locked version without a pinned checksum fails before cache publication", context do
    fixture(context)
    File.write!(Path.join(context.root, "deps/lazy_html/checksum.exs"), "%{}")
    assert {_, status} = run(context)
    assert status != 0
    assert Path.wildcard(Path.join(context.root, "cache/*")) == []
  end

  test "MDEx selects the configured highlighter and CPU variant", context do
    architecture = :erlang.system_info(:system_architecture) |> to_string()
    cpu = if String.starts_with?(architecture, "x86_64"), do: "x86_64", else: "aarch64"
    os = if :os.type() == {:unix, :linux}, do: "unknown-linux-gnu", else: "apple-darwin"
    legacy = cpu == "x86_64" and os == "unknown-linux-gnu"
    suffix = if legacy, do: "legacy_cpu_syntect", else: "syntect"
    filename = "libmdex_native_nif-v0.2.8-nif-2.15-#{cpu}-#{os}--#{suffix}.so.tar.gz"
    File.mkdir_p!(Path.join(context.root, "deps/mdex_native"))
    File.mkdir_p!(Path.join(context.root, "config"))

    File.write!(
      Path.join(context.root, "config/config.exs"),
      "import Config\nconfig :mdex_native, syntax_highlighter: :syntect, use_legacy_artifacts: #{legacy}\n"
    )

    File.write!(
      Path.join(context.root, "mix.lock"),
      inspect(%{mdex_native: {:hex, :mdex_native, "0.2.8", nil, [], [], "hexpm", nil}})
    )

    File.write!(
      Path.join(context.root, "deps/mdex_native/checksum-Elixir.MDExNative.Native.exs"),
      inspect(%{filename => context.checksum})
    )

    assert {output, 0} = run(context)
    assert output =~ "Verified downloaded #{filename}"
  end

  defp fixture(context) do
    architecture = :erlang.system_info(:system_architecture) |> to_string()
    cpu = if String.starts_with?(architecture, "x86_64"), do: "x86_64", else: "aarch64"
    os = if :os.type() == {:unix, :linux}, do: "linux-gnu", else: "apple-darwin"
    filename = "lazy_html-nif-2.16-#{cpu}-#{os}-0.1.12.tar.gz"
    File.mkdir_p!(Path.join(context.root, "deps/lazy_html"))

    File.write!(
      Path.join(context.root, "mix.lock"),
      inspect(%{lazy_html: {:hex, :lazy_html, "0.1.12", nil, [], [], "hexpm", nil}})
    )

    File.write!(
      Path.join(context.root, "deps/lazy_html/checksum.exs"),
      inspect(%{filename => context.checksum})
    )

    filename
  end

  defp run(context) do
    System.cmd(System.find_executable("elixir"), [@script, context.root],
      stderr_to_stdout: true,
      env: [
        {"PATH", Path.join(context.root, "bin") <> ":" <> System.get_env("PATH")},
        {"MIX_ENV", "dev"},
        {"ELIXIR_MAKE_CACHE_DIR", Path.join(context.root, "cache")},
        {"RUSTLER_PRECOMPILED_GLOBAL_CACHE_PATH", Path.join(context.root, "cache")},
        {"MDEX_NATIVE_BUILD", nil},
        {"NATIVE_TEST_PAYLOAD", Path.join(context.root, "payload")}
      ]
    )
  end
end
