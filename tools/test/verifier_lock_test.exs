defmodule LiveShadcnTools.VerifierLockTest do
  use ExUnit.Case, async: false

  alias LiveShadcnTools.VerifierLock

  setup do
    root =
      Path.join(
        System.tmp_dir!(),
        "live-shadcn-source-lease-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(Path.join(root, "parity"))
    on_exit(fn -> File.rm_rf!(root) end)
    {:ok, root: root}
  end

  test "a second verifier waits for the live probe owner", %{root: root} do
    parent = self()

    first =
      Task.async(fn ->
        VerifierLock.with_lock(root, fn _token ->
          send(parent, :first_has_lock)

          receive do
            :release_first -> :ok
          end
        end)
      end)

    assert_receive :first_has_lock

    second =
      Task.async(fn ->
        VerifierLock.with_lock(root, fn _token -> send(parent, :second_has_lock) end,
          wait_ms: 1_000
        )
      end)

    refute_receive :second_has_lock, 100
    send(first.pid, :release_first)
    assert_receive :second_has_lock, 1_000
    assert :ok = Task.await(first)
    assert :second_has_lock = Task.await(second)
  end

  test "the recorded nonce answers only the correct probe", %{root: root} do
    parent = self()

    owner_task =
      Task.async(fn ->
        VerifierLock.with_lock(root, fn _token ->
          owner =
            root
            |> Path.join("parity/.source-lease/owner.json")
            |> File.read!()
            |> Jason.decode!()

          send(parent, {:owner, owner})

          receive do
            :release_owner -> :ok
          end
        end)
      end)

    assert_receive {:owner, owner}
    assert probe(owner, owner["nonce"])
    assert split_probe(owner)
    refute probe(owner, "wrong-nonce")

    {:ok, silent} = :gen_tcp.connect({127, 0, 0, 1}, owner["port"], [:binary, active: false], 500)
    assert probe(owner, owner["nonce"])
    :gen_tcp.close(silent)

    send(owner_task.pid, :release_owner)
    assert :ok = Task.await(owner_task)
  end

  test "dead, stale, and corrupt owners are recovered", %{root: root} do
    lease = Path.join([root, "parity", ".source-lease"])
    File.mkdir_p!(lease)

    File.write!(
      Path.join(lease, "owner.json"),
      Jason.encode!(%{"host" => "127.0.0.1", "nonce" => "dead", "port" => 1, "token" => "dead"})
    )

    assert :ok = VerifierLock.with_lock(root, fn _token -> :ok end, wait_ms: 100)
    refute File.exists?(lease)

    File.mkdir_p!(lease)
    File.write!(Path.join(lease, "owner.json"), Jason.encode!(%{"pid" => 1, "token" => "stale"}))

    assert :ok =
             VerifierLock.with_lock(root, fn _token -> :ok end,
               wait_ms: 100,
               owner_grace_ms: 0
             )

    refute File.exists?(lease)
  end

  test "a wrong token cannot release a live lease", %{root: root} do
    lease = Path.join([root, "parity", ".source-lease"])
    File.mkdir_p!(lease)
    File.write!(Path.join(lease, "owner.json"), Jason.encode!(%{"token" => "owner"}))

    assert :ok = VerifierLock.release(lease, "other")
    assert File.exists?(lease)
  end

  test "a live handoff marker blocks recovery after its parent dies", %{root: root} do
    lease = Path.join([root, "parity", ".source-lease"])
    parent = %{"host" => "127.0.0.1", "nonce" => "dead", "port" => 1, "token" => "parent"}
    nonce = "child-handoff"
    {:ok, listener} = :gen_tcp.listen(0, [:binary, active: false, ip: {127, 0, 0, 1}])
    {:ok, {{127, 0, 0, 1}, port}} = :inet.sockname(listener)
    probe = Task.async(fn -> serve_probe(listener, nonce) end)
    marker = Path.join(lease, ".source-handoff-child")

    File.mkdir_p!(marker)
    File.write!(Path.join(lease, "owner.json"), Jason.encode!(parent))

    File.write!(
      Path.join(marker, "owner.json"),
      Jason.encode!(%{parent: parent, child: %{host: "127.0.0.1", nonce: nonce, port: port}})
    )

    test_process = self()

    waiter =
      Task.async(fn ->
        VerifierLock.with_lock(root, fn _token -> send(test_process, :waiter_has_lock) end,
          wait_ms: 1_000
        )
      end)

    refute_receive :waiter_has_lock, 100
    :gen_tcp.close(listener)
    assert_receive :waiter_has_lock, 1_000
    assert :waiter_has_lock = Task.await(waiter)
    Task.shutdown(probe, :brutal_kill)
  end

  test "a vanished stale lease path retries acquisition", %{root: root} do
    lease = Path.join([root, "parity", ".source-lease"])
    File.mkdir_p!(lease)
    File.write!(Path.join(lease, "owner.json"), Jason.encode!(%{"token" => "stale"}))

    remover = Task.async(fn -> File.rm_rf(lease) end)

    assert :ok =
             VerifierLock.with_lock(root, fn _token -> :ok end,
               wait_ms: 100,
               owner_grace_ms: 0
             )

    assert {:ok, _removed} = Task.await(remover)
  end

  defp probe(owner, nonce) do
    with {:ok, socket} <-
           :gen_tcp.connect({127, 0, 0, 1}, owner["port"], [:binary, active: false], 500),
         :ok <- :gen_tcp.send(socket, nonce <> "\n"),
         {:ok, ^nonce} <- recv_line(socket, "") do
      :gen_tcp.close(socket)
      true
    else
      _ -> false
    end
  end

  defp split_probe(owner) do
    with {:ok, socket} <-
           :gen_tcp.connect({127, 0, 0, 1}, owner["port"], [:binary, active: false], 500),
         :ok <- :gen_tcp.send(socket, binary_part(owner["nonce"], 0, 5)),
         :ok <-
           :gen_tcp.send(
             socket,
             binary_part(owner["nonce"], 5, byte_size(owner["nonce"]) - 5) <> "\n"
           ),
         {:ok, nonce} <- recv_line(socket, "") do
      :gen_tcp.close(socket)
      nonce == owner["nonce"]
    else
      _ -> false
    end
  end

  defp recv_line(socket, received) do
    case :binary.match(received, "\n") do
      {position, 1} ->
        {:ok, binary_part(received, 0, position)}

      :nomatch ->
        with {:ok, data} <- :gen_tcp.recv(socket, 0, 500) do
          recv_line(socket, received <> data)
        end
    end
  end

  defp serve_probe(listener, nonce) do
    case :gen_tcp.accept(listener) do
      {:ok, socket} ->
        Task.start(fn ->
          try do
            with {:ok, value} <- recv_line(socket, ""),
                 true <- value == nonce do
              :gen_tcp.send(socket, nonce <> "\n")
            end
          after
            :gen_tcp.close(socket)
          end
        end)

        serve_probe(listener, nonce)

      {:error, :closed} ->
        :ok
    end
  end
end
