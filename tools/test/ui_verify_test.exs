defmodule Mix.Tasks.Ui.VerifyTest do
  use ExUnit.Case, async: false

  alias LiveShadcnTools.VerificationPolicy
  alias LiveShadcnVerification
  alias Mix.Tasks.Ui.Verify

  test "shadcn publication preserves out-of-scope records, even without a generated port" do
    ai_record = %{
      "pass" => true,
      "evidence" => "historical-ai-identity",
      "checks" => %{"pixel" => %{"pass" => false, "gated" => false}},
      "time" => "2025-01-01T00:00:00Z"
    }

    existing = %{
      "ai_elements/open-in-chat" => ai_record,
      "ai_elements/message" => Map.put(ai_record, "pass", false),
      "shadcn/button" => %{"pass" => false},
      "shadcn/dialog" => %{"pass" => true},
      "shadcn/removed-test-component" => %{"pass" => true}
    }

    results = %{"shadcn/button" => %{"pass" => true, "evidence" => "current"}}

    assert Verify.merge_results(existing, results) ==
             existing
             |> Map.delete("shadcn/removed-test-component")
             |> Map.merge(results)
  end

  test "incremental report validation waits for the verifier lock" do
    root = LiveShadcnTools.repo_root()

    report =
      Path.join(System.tmp_dir!(), "missing-report-#{System.unique_integer([:positive])}.json")

    task =
      LiveShadcnTools.VerifierLock.with_lock(root, fn _token ->
        task =
          Task.async(fn ->
            try do
              Verify.run([
                "shadcn/button",
                "--examples",
                "default",
                "--record",
                "parity=#{report}"
              ])
            rescue
              error in Mix.Error -> {:error, Exception.message(error)}
            end
          end)

        assert Task.yield(task, 5_000) == nil
        task
      end)

    assert {:error, message} = Task.await(task, 5_000)
    assert message =~ "cannot import"
  end

  test "browser preparation updates pinned parity sources once" do
    test_pid = self()

    runner = fn dir, command, arguments, env ->
      send(test_pid, {:command, dir, command, arguments, env})
      %{"pass" => true}
    end

    assert :ok = Verify.prepare_browser!(runner)

    assert_receive {:command, parity_dir, "npm", ["run", "upstream"], %{}}
    assert Path.basename(parity_dir) == "parity"

    refute_receive {:command, ^parity_dir, "npm", ["run", "upstream"], %{}}
  end

  test "browser preparation forwards the owning source lease token" do
    test_pid = self()
    Process.put(:live_shadcn_source_lease_token, "source-lease-token")

    on_exit(fn -> Process.delete(:live_shadcn_source_lease_token) end)

    runner = fn dir, command, arguments, env ->
      send(test_pid, {:command, dir, command, arguments, env})
      %{"pass" => true}
    end

    assert :ok = Verify.prepare_browser!(runner)

    assert_receive {
      :command,
      _parity_dir,
      "npm",
      ["run", "upstream"],
      %{"PARITY_SOURCE_LEASE_TOKEN" => "source-lease-token"}
    }
  end

  test "managed browser servers set the reuse lease only while checks run" do
    test_pid = self()

    result =
      Verify.with_managed_browser_servers(
        fn ->
          send(test_pid, :started)
          [:phoenix, :vite]
        end,
        fn servers -> send(test_pid, {:stopped, servers}) end,
        fn ->
          assert %{"LIVE_SHADCN_MANAGED_SERVERS" => "1"} =
                   Verify.managed_browser_environment(%{})

          :checked
        end
      )

    assert result == :checked
    assert_received :started
    assert_received {:stopped, [:phoenix, :vite]}
    assert Verify.managed_browser_environment(%{}) == %{}
  end

  test "managed browser servers stop after a browser batch raises" do
    test_pid = self()

    assert_raise RuntimeError, "browser batch failed", fn ->
      Verify.with_managed_browser_servers(
        fn -> [:phoenix, :vite] end,
        fn servers -> send(test_pid, {:stopped_after_error, servers}) end,
        fn -> raise "browser batch failed" end
      )
    end

    assert_received {:stopped_after_error, [:phoenix, :vite]}
    assert Verify.managed_browser_environment(%{}) == %{}
  end

  test "a ready browser server port keeps draining output while browser work runs" do
    executable = System.find_executable("sh")

    port =
      Port.open(
        {:spawn_executable, executable},
        [
          :binary,
          :exit_status,
          args: [~c"-c", ~c"printf ready; sleep 0.1; printf after-ready; sleep 1"]
        ]
      )

    assert_receive {^port, {:data, "ready"}}
    drain = Verify.drain_browser_port(port, self())

    work = Task.async(fn -> Process.sleep(150) end)

    assert_receive {:browser_port_output, ^port, "after-ready"}, 500
    assert Task.await(work) == :ok
    assert Process.alive?(drain)

    assert :ok = Verify.stop_browser_port_drain(drain)
    refute Process.alive?(drain)
  end

  test "managed server cleanup terminates its direct processes and releases their ports" do
    servers =
      [start_test_server(), start_test_server(release_port_on_term: true)]
      |> Enum.map(fn server ->
        Map.put(server, :drain, Verify.drain_browser_port(server.process))
      end)

    on_exit(fn ->
      Enum.each(servers, &stop_test_server/1)
    end)

    assert Enum.all?(servers, &listening?/1)
    assert :ok = Verify.stop_browser_servers(servers)

    for server <- servers do
      refute process_alive?(server.os_pid)
      assert port_free?(server.port)
    end
  end

  test "managed server cleanup terminates a listening descendant of its wrapper" do
    server = start_wrapped_test_server()

    on_exit(fn ->
      stop_test_server(server)
      stop_test_server(%{server | os_pid: server.descendant_pid})
    end)

    assert listening?(server)
    assert :ok = Verify.stop_browser_servers([server])
    assert port_free?(server.port)
    refute process_alive?(server.descendant_pid)
  end

  test "managed server cleanup does not wait on a stale process id after closing its Port" do
    server = start_test_server(release_port_on_term: true, exit_on_port_close: true)
    unrelated_server = start_test_server()
    stale_server = %{server | os_pid: unrelated_server.os_pid}

    on_exit(fn ->
      stop_test_server(server)
      stop_test_server(unrelated_server)
    end)

    {_output, 0} = System.cmd("kill", ["-TERM", Integer.to_string(server.os_pid)])
    assert eventually(fn -> process_alive?(server.os_pid) and port_free?(server.port) end)

    assert :ok = Verify.stop_browser_servers([stale_server])
    assert eventually(fn -> Port.info(server.process) == nil end)
    assert port_free?(server.port)
  end

  test "closing a managed Port reaps a child that stays alive after TERM" do
    server = start_test_server(release_port_on_term: true, exit_on_port_close: true)

    on_exit(fn -> stop_test_server(server) end)

    {_output, 0} = System.cmd("kill", ["-TERM", Integer.to_string(server.os_pid)])

    assert eventually(fn -> process_alive?(server.os_pid) and port_free?(server.port) end)
    assert Port.info(server.process) != nil

    Port.close(server.process)

    assert eventually(fn -> not process_alive?(server.os_pid) end)
    assert port_free?(server.port)
  end

  test "occupied browser ports fail before source preparation" do
    {:ok, socket} = :gen_tcp.listen(0, [:binary, active: false, reuseaddr: true])
    {:ok, {_address, port}} = :inet.sockname(socket)

    on_exit(fn -> :gen_tcp.close(socket) end)

    assert_raise Mix.Error,
                 ~r/cannot prepare browser sources: storybook port #{port} is already occupied/,
                 fn ->
                   Verify.ensure_browser_ports_free!(storybook: port)
                 end
  end

  test "released browser ports can be reserved after a TCP connection closes" do
    {:ok, listener} =
      :gen_tcp.listen(0, [:binary, active: false, reuseaddr: true, ip: {127, 0, 0, 1}])

    {:ok, {{127, 0, 0, 1}, port}} = :inet.sockname(listener)
    accept = Task.async(fn -> :gen_tcp.accept(listener) end)
    {:ok, client} = :gen_tcp.connect({127, 0, 0, 1}, port, [:binary, active: false])
    {:ok, server} = Task.await(accept)

    :ok = :gen_tcp.close(server)
    assert {:error, :closed} = :gen_tcp.recv(client, 0, 500)
    :ok = :gen_tcp.close(client)
    :ok = :gen_tcp.close(listener)

    assert :ok = Verify.ensure_browser_ports_free!(storybook: port)
  end

  test "Message Scroller behavior commands use one title per sequential batch" do
    commands =
      Verify.behavior_batch_arguments("shadcn", "message-scroller", "message-scroller.spec.mjs")

    assert Enum.count(commands) == 11

    assert Enum.all?(commands, fn command ->
             assert [
                      "playwright",
                      "test",
                      "message-scroller.spec.mjs",
                      "--workers",
                      "1",
                      "--grep",
                      pattern
                    ] = command

             assert String.starts_with?(pattern, "(?:")

             title_count =
               pattern
               |> String.trim_leading("(?:")
               |> String.trim_trailing(")$")
               |> String.split("|")
               |> length()

             title_count == 1
           end)
  end

  test "a standard shadcn component without a named suite uses generic interaction parity" do
    policy = VerificationPolicy.get("shadcn", "native-select")

    assert {:suites, ["interaction-parity.spec.mjs"]} =
             Verify.behavior_suites("shadcn", "native-select", "native-select", policy)

    commands =
      Verify.behavior_batch_arguments("shadcn", "native-select", "interaction-parity.spec.mjs")

    assert [_, _, _] = commands

    assert Enum.all?(commands, fn
             [
               "playwright",
               "test",
               "interaction-parity.spec.mjs",
               "--workers",
               "1",
               "--grep",
               pattern
             ] ->
               title_count =
                 pattern
                 |> String.trim_leading("(?:")
                 |> String.trim_trailing(")$")
                 |> String.split("|")
                 |> length()

               String.starts_with?(pattern, "(?:") and title_count in 1..2

             _ ->
               false
           end)
  end

  test "a named shadcn suite runs after generic interaction parity" do
    policy = VerificationPolicy.get("shadcn", "select")

    assert {:suites, ["interaction-parity.spec.mjs", "select.spec.mjs"]} =
             Verify.behavior_suites("shadcn", "select", "select", policy)

    assert {:commands, commands} =
             Verify.behavior_commands("shadcn", "select", "select", policy)

    assert List.last(commands) == ["playwright", "test", "select.spec.mjs", "--workers", "1"]
    assert Enum.any?(commands, &(Enum.at(&1, 2) == "interaction-parity.spec.mjs"))
  end

  test "generic interaction commands select each pinned official example" do
    commands =
      Verify.behavior_batch_arguments(
        "shadcn",
        "select",
        "select",
        "interaction-parity.spec.mjs"
      )

    patterns = Enum.map(commands, &Enum.at(&1, 6))

    for example <- ~w(align-item default disabled groups invalid rtl scrollable) do
      title = "select / #{example} keeps inferred interaction semantics"
      assert Enum.any?(patterns, &Regex.match?(Regex.compile!(&1), title))
    end
  end

  test "parity command selects only the parity spec path" do
    assert ["playwright", "test", path_filter, "--grep", "draws what React draws"] =
             Verify.parity_batch_arguments()

    assert path_filter == "(?:^|/)parity\\.spec\\.mjs$"
    assert Regex.match?(Regex.compile!(path_filter), "parity.spec.mjs")
    assert Regex.match?(Regex.compile!(path_filter), "test/browser/parity.spec.mjs")
  end

  test "named suite commands select only their exact spec paths" do
    for {name, suite} <- [{"dialog", "dialog.spec.mjs"}, {"input", "input.spec.mjs"}] do
      assert [["playwright", "test", path_filter, "--workers", "1"]] =
               Verify.behavior_batch_arguments("shadcn", name, name, suite)

      assert path_filter == "(?:^|/)#{Regex.escape(suite)}$"
      assert Regex.match?(Regex.compile!(path_filter), suite)
      assert Regex.match?(Regex.compile!(path_filter), "test/browser/#{suite}")
    end
  end

  test "a docs-only family uses the same generic interaction suite" do
    policy = LiveShadcnTools.verification_policy("shadcn", "typography")

    assert policy.kind == :docs_only

    assert {:suites, ["interaction-parity.spec.mjs"]} =
             Verify.behavior_suites("shadcn", "typography", "typography", policy)
  end

  test "semantic parity and pixel batches preserve every example in bounded groups" do
    examples = ["default", "anchoring", "streaming"]

    for kind <- ["parity", "pixel"] do
      assert Verify.example_batches("message-scroller", kind, examples) == [
               ["default", "anchoring"],
               ["streaming"]
             ]
    end

    assert Verify.example_batches("data-table", "pixel", ["default", "rtl"]) == [
             ["default", "rtl"]
           ]
  end

  test "interaction and accessibility batches contain at most two examples" do
    examples = ["default", "disabled", "rtl", "scrollable", "invalid"]

    for kind <- ["interaction", "accessibility"] do
      assert Verify.example_batches("select", kind, examples) == [
               ["default", "disabled"],
               ["rtl", "scrollable"],
               ["invalid"]
             ]
    end
  end

  defp start_test_server(options \\ []) do
    port = free_port()
    assert executable = System.find_executable("node")

    script =
      cond do
        Keyword.get(options, :release_port_on_term, false) and
            Keyword.get(options, :exit_on_port_close, false) ->
          ~c"const server = require('node:net').createServer(() => {}); server.listen(Number(process.argv[1]), '127.0.0.1'); process.on('SIGTERM', () => server.close()); process.stdin.resume(); process.stdin.on('end', () => process.exit(0)); setInterval(() => {}, 1000);"

        Keyword.get(options, :release_port_on_term, false) ->
          ~c"const server = require('node:net').createServer(() => {}); server.listen(Number(process.argv[1]), '127.0.0.1'); process.on('SIGTERM', () => server.close()); setInterval(() => {}, 1000);"

        true ->
          ~c"require('node:net').createServer(() => {}).listen(Number(process.argv[1]), '127.0.0.1')"
      end

    process =
      Port.open(
        {:spawn_executable, executable},
        [
          :binary,
          :exit_status,
          args: [
            ~c"-e",
            script,
            Integer.to_charlist(port)
          ]
        ]
      )

    {:os_pid, os_pid} = Port.info(process, :os_pid)
    server = %{name: :test, process: process, os_pid: os_pid, port: port}

    assert eventually(fn -> listening?(server) end)
    server
  end

  defp start_wrapped_test_server do
    port = free_port()
    assert executable = System.find_executable("sh")

    script =
      ~c"node -e \"require('node:net').createServer(() => {}).listen(Number(process.argv[1]), '127.0.0.1')\" \"$1\" & echo $!; wait"

    process =
      Port.open(
        {:spawn_executable, executable},
        [
          :binary,
          :exit_status,
          args: [~c"-c", script, ~c"wrapped-test-server", Integer.to_charlist(port)]
        ]
      )

    {:os_pid, os_pid} = Port.info(process, :os_pid)

    assert_receive {^process, {:data, child_pid}}
    {descendant_pid, _} = Integer.parse(String.trim(child_pid))

    server = %{
      name: :wrapped_test,
      process: process,
      os_pid: os_pid,
      descendant_pid: descendant_pid,
      port: port
    }

    assert eventually(fn -> listening?(server) end)
    server
  end

  defp stop_test_server(server) do
    if process_alive?(server.os_pid) do
      _ = System.cmd("kill", ["-KILL", Integer.to_string(server.os_pid)], stderr_to_stdout: true)
    end
  end

  defp free_port do
    {:ok, socket} = :gen_tcp.listen(0, [:binary, active: false, ip: {127, 0, 0, 1}])
    {:ok, {{127, 0, 0, 1}, port}} = :inet.sockname(socket)
    :ok = :gen_tcp.close(socket)
    port
  end

  defp listening?(%{port: port}) do
    case :gen_tcp.connect({127, 0, 0, 1}, port, [], 50) do
      {:ok, socket} ->
        :ok = :gen_tcp.close(socket)
        true

      _ ->
        false
    end
  end

  defp port_free?(port) do
    case :gen_tcp.listen(port, [:binary, active: false, ip: {127, 0, 0, 1}]) do
      {:ok, socket} ->
        :ok = :gen_tcp.close(socket)
        true

      _ ->
        false
    end
  end

  defp process_alive?(pid) do
    match?(
      {_output, 0},
      System.cmd("kill", ["-0", Integer.to_string(pid)], stderr_to_stdout: true)
    )
  end

  test "browser report envelopes bind the current shadcn identity and scope" do
    envelope =
      Verify.browser_report_envelope("shadcn", "button", "parity", "button", ["default", "rtl"])

    assert envelope["source"] == "shadcn"
    assert envelope["name"] == "button"
    assert envelope["layer"] == "parity"
    assert envelope["preview_key"] == "button"
    assert envelope["examples"] == ["default", "rtl"]
    assert is_binary(envelope["identity"])
    assert envelope["completed"]

    assert envelope["identity"] ==
             LiveShadcnVerification.evidence_digest(
               "shadcn",
               "button",
               LiveShadcnTools.repo_root()
             )
  end

  defp eventually(fun, attempts \\ 50)
  defp eventually(fun, 0), do: fun.()

  defp eventually(fun, attempts) do
    if fun.() do
      true
    else
      Process.sleep(20)
      eventually(fun, attempts - 1)
    end
  end
end
