defmodule Mix.Tasks.Ui.FetchLockedTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Ui.Fetch

  setup do
    root = Path.join(System.tmp_dir!(), "fetch-locked-#{System.unique_integer([:positive])}")
    File.mkdir_p!(Path.join(root, "packages"))
    File.mkdir_p!(Path.join(root, "registry/upstream"))
    on_exit(fn -> File.rm_rf!(root) end)
    %{root: root}
  end

  test "restores the recorded source and keeps the manifest byte for byte", %{root: root} do
    source = "export const version = 'pinned';\n"
    url = serve(source)
    manifest = manifest(root, url, source)
    path = Path.join(root, "registry/upstream/shadcn/ui/button.tsx")
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, "local source from another revision")

    File.cd!(root, fn -> Fetch.run(["--locked"]) end)

    assert File.read!(path) == source
    assert File.read!(Path.join(root, "registry/UPSTREAM.json")) == manifest

    # The one-request server is closed. A valid local digest permits an
    # offline repeat, without resolving the current upstream branch.
    File.cd!(root, fn -> Fetch.run(["--locked"]) end)
    assert File.read!(path) == source
  end

  test "rejects changed remote bytes before replacing the local source", %{root: root} do
    url = serve("unexpected source")
    manifest = manifest(root, url, "reviewed source")
    path = Path.join(root, "registry/upstream/shadcn/ui/button.tsx")
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, "existing local source")

    File.cd!(root, fn ->
      assert_raise Mix.Error, ~r/does not match the pinned digest/, fn ->
        Fetch.run(["--locked"])
      end
    end)

    assert File.read!(path) == "existing local source"
    assert File.read!(Path.join(root, "registry/UPSTREAM.json")) == manifest
  end

  defp manifest(root, url, source) do
    body =
      Jason.encode!(
        %{
          "files" => %{
            "shadcn/ui/button.tsx" => %{
              "url" => url,
              "sha256" => LiveShadcnTools.digest(source)
            }
          }
        },
        pretty: true
      ) <> "\n"

    File.write!(Path.join(root, "registry/UPSTREAM.json"), body)
    body
  end

  defp serve(body) do
    {:ok, listener} = :gen_tcp.listen(0, [:binary, active: false, ip: {127, 0, 0, 1}])
    {:ok, {{127, 0, 0, 1}, port}} = :inet.sockname(listener)

    server =
      Task.async(fn ->
        {:ok, socket} = :gen_tcp.accept(listener, 5_000)
        {:ok, _request} = :gen_tcp.recv(socket, 0, 5_000)

        :ok =
          :gen_tcp.send(socket, [
            "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: ",
            Integer.to_string(byte_size(body)),
            "\r\nConnection: close\r\n\r\n",
            body
          ])

        :gen_tcp.close(socket)
        :gen_tcp.close(listener)
      end)

    on_exit(fn ->
      :gen_tcp.close(listener)
      if Process.alive?(server.pid), do: Process.exit(server.pid, :kill)
    end)

    "http://127.0.0.1:#{port}/pinned/button.tsx"
  end
end
