defmodule LiveShadcnTools.BrowserServerTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.BrowserServer

  @moduletag :tmp_dir

  test "an early exit reports the status and saves redacted startup output", %{tmp_dir: dir} do
    process =
      Port.open({:spawn_executable, System.find_executable("sh")}, [
        :binary,
        :exit_status,
        args: [~c"-c", ~c"printf 'boot error\nSESSION_TOKEN=private-value\n'; exit 7"]
      ])

    server = %{name: :storybook, process: process, port: 0, path: "/", expected: ~r/ready/}

    error =
      assert_raise Mix.Error, fn ->
        BrowserServer.await_ready!(server, deadline(), artifacts: dir)
      end

    message = Exception.message(error)
    assert message =~ "exit 7"
    assert message =~ "boot error"
    assert message =~ "<REDACTED>"
    refute message =~ "private-value"
    assert File.read!(Path.join(dir, "startup-storybook.log")) == message <> "\n"
  end

  test "HTTP 200 with the wrong body times out and retains bounded output", %{tmp_dir: dir} do
    server = http_server("wrong body", String.duplicate("x", 40_000) <> "\n")

    error =
      assert_raise Mix.Error, fn ->
        BrowserServer.await_ready!(server, deadline(), artifacts: dir)
      end

    assert Exception.message(error) =~ "did not become ready before the timeout"
    assert Exception.message(error) =~ String.duplicate("x", 100)
    assert byte_size(File.read!(Path.join(dir, "startup-storybook.log"))) < 33_000
  end

  test "the expected HTTP response makes the server ready" do
    server = http_server("ready", "")
    assert :ok = BrowserServer.await_ready!(server, deadline())
  end

  defp deadline, do: System.monotonic_time(:millisecond) + 1_000

  defp http_server(body, output) do
    script = """
    const http = require('node:http');
    const server = http.createServer((_req, res) => res.end(#{Jason.encode!(body)}));
    server.listen(0, '127.0.0.1', () => {
      console.log(server.address().port);
      process.stdout.write(#{Jason.encode!(output)});
    });
    """

    process =
      Port.open({:spawn_executable, System.find_executable("node")}, [
        :binary,
        :exit_status,
        :stderr_to_stdout,
        args: [~c"-e", String.to_charlist(script)]
      ])

    assert_receive {^process, {:data, startup}}, 5_000
    [port, output] = String.split(startup, "\n", parts: 2)
    if output != "", do: send(self(), {process, {:data, output}})

    on_exit(fn ->
      if Port.info(process), do: Port.close(process)
    end)

    %{
      name: :storybook,
      process: process,
      port: String.to_integer(port),
      path: "/",
      expected: ~r/^ready$/
    }
  end
end
