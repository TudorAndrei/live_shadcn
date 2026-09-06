defmodule LiveShadcnTools.VerifierLock do
  @moduledoc false

  @wait_ms 120_000
  @poll_ms 50
  @owner_grace_ms 1_000
  @loopback {127, 0, 0, 1}
  @probe_frame_max 512
  @handoff_prefix ".source-handoff-"
  @transition_suffix "-transition"

  def with_lock(root, fun, opts \\ []) when is_function(fun, 1) do
    path = Path.join([root, "parity", ".source-lease"])
    token = "#{System.unique_integer([:positive])}-#{nonce()}"
    {:ok, listener} = :gen_tcp.listen(0, [:binary, active: false, ip: @loopback])
    {:ok, {@loopback, port}} = :inet.sockname(listener)
    nonce = nonce()
    probe = Task.async(fn -> serve_probe(listener, nonce) end)
    owner = %{host: "127.0.0.1", nonce: nonce, port: port, token: token}

    try do
      acquire!(
        path,
        owner,
        Keyword.get(opts, :wait_ms, @wait_ms),
        Keyword.get(opts, :owner_grace_ms, @owner_grace_ms)
      )

      try do
        fun.(token)
      after
        release(path, token)
      end
    after
      :gen_tcp.close(listener)
      Task.shutdown(probe, :brutal_kill)
    end
  end

  @doc false
  def release(path, token) do
    if get_in(read_owner(path), ["token"]) == token, do: File.rm_rf(path)
    :ok
  end

  defp acquire!(path, owner, wait_ms, owner_grace_ms) do
    deadline = System.monotonic_time(:millisecond) + wait_ms

    case File.mkdir(path) do
      :ok ->
        write_owner!(path, owner)

      {:error, :eexist} ->
        if recover_dead_owner(path, owner_grace_ms) do
          acquire!(path, owner, wait_ms, owner_grace_ms)
        else
          wait_for_lock!(path, owner, deadline, wait_ms, owner_grace_ms)
        end

      {:error, reason} ->
        Mix.raise("cannot create source lease #{path}: #{:file.format_error(reason)}")
    end
  end

  defp wait_for_lock!(path, owner, deadline, wait_ms, owner_grace_ms) do
    if System.monotonic_time(:millisecond) >= deadline do
      Mix.raise(
        "timed out after #{wait_ms} ms waiting for source lease #{path}; " <>
          "stop the other verifier or remove a dead-owner lease"
      )
    end

    Process.sleep(@poll_ms)

    acquire!(
      path,
      owner,
      max(deadline - System.monotonic_time(:millisecond), 0),
      owner_grace_ms
    )
  end

  defp recover_dead_owner(path, owner_grace_ms) do
    case read_owner(path) do
      %{"host" => "127.0.0.1", "nonce" => nonce, "port" => port} = owner
      when is_binary(nonce) and is_integer(port) and port > 0 ->
        cond do
          probe_owner?(port, nonce) ->
            false

          handoff_protects_owner?(path, owner, owner_grace_ms) ->
            false

          true ->
            with_transition_lock(path, owner_grace_ms, fn ->
              remove_dead_owner(path, owner, port, nonce, owner_grace_ms)
            end)
        end

      _ ->
        if older_than?(path, owner_grace_ms) do
          with_transition_lock(path, owner_grace_ms, fn ->
            remove_if_stale(path, owner_grace_ms)
          end)
        else
          false
        end
    end
  end

  defp with_transition_lock(path, owner_grace_ms, fun) do
    transition_path = path <> @transition_suffix
    token = "transition-#{System.unique_integer([:positive])}-#{nonce()}"
    {:ok, listener} = :gen_tcp.listen(0, [:binary, active: false, ip: @loopback])
    {:ok, {@loopback, port}} = :inet.sockname(listener)
    nonce = nonce()
    probe = Task.async(fn -> serve_probe(listener, nonce) end)
    owner = %{host: "127.0.0.1", nonce: nonce, port: port, token: token}

    try do
      acquire_transition!(transition_path, owner, @wait_ms, owner_grace_ms)

      try do
        fun.()
      after
        release(transition_path, token)
      end
    after
      :gen_tcp.close(listener)
      Task.shutdown(probe, :brutal_kill)
    end
  end

  defp acquire_transition!(path, owner, wait_ms, owner_grace_ms) do
    deadline = System.monotonic_time(:millisecond) + wait_ms

    case File.mkdir(path) do
      :ok ->
        write_owner!(path, owner)

      {:error, :eexist} ->
        if recover_dead_transition(path, owner_grace_ms) do
          acquire_transition!(path, owner, wait_ms, owner_grace_ms)
        else
          wait_for_transition!(path, owner, deadline, wait_ms, owner_grace_ms)
        end

      {:error, reason} ->
        Mix.raise("cannot create verifier transition #{path}: #{:file.format_error(reason)}")
    end
  end

  defp wait_for_transition!(path, owner, deadline, wait_ms, owner_grace_ms) do
    if System.monotonic_time(:millisecond) >= deadline do
      Mix.raise("timed out after #{wait_ms} ms waiting for verifier transition #{path}")
    end

    Process.sleep(@poll_ms)

    acquire_transition!(
      path,
      owner,
      max(deadline - System.monotonic_time(:millisecond), 0),
      owner_grace_ms
    )
  end

  defp recover_dead_transition(path, owner_grace_ms) do
    case read_owner(path) do
      %{"host" => "127.0.0.1", "nonce" => nonce, "port" => port} = owner
      when is_binary(nonce) and is_integer(port) and port > 0 ->
        if probe_owner?(port, nonce) do
          false
        else
          remove_dead_transition(path, owner, port, nonce)
        end

      _ ->
        if older_than?(path, owner_grace_ms) do
          if older_than?(path, owner_grace_ms), do: remove_path(path), else: false
        else
          false
        end
    end
  end

  defp probe_owner?(port, nonce) do
    case :gen_tcp.connect(@loopback, port, [:binary, active: false], 500) do
      {:ok, socket} ->
        try do
          with :ok <- :gen_tcp.send(socket, nonce <> "\n"),
               {:ok, ^nonce} <- recv_probe_line(socket, "", 500) do
            true
          else
            _ -> false
          end
        after
          :gen_tcp.close(socket)
        end

      _ ->
        false
    end
  end

  defp remove_dead_owner(path, owner, port, nonce, owner_grace_ms) do
    case read_owner(path) do
      ^owner ->
        if probe_owner?(port, nonce) or
             handoff_protects_owner?(path, owner, owner_grace_ms) do
          false
        else
          remove_path(path)
        end

      _ ->
        false
    end
  end

  defp remove_dead_transition(path, owner, port, nonce) do
    case read_owner(path) do
      ^owner -> if probe_owner?(port, nonce), do: false, else: remove_path(path)
      _ -> false
    end
  end

  defp remove_if_stale(path, owner_grace_ms) do
    if older_than?(path, owner_grace_ms), do: remove_path(path), else: false
  end

  defp handoff_protects_owner?(path, owner, grace_ms) do
    case File.ls(path) do
      {:ok, entries} ->
        Enum.any?(entries, fn entry ->
          if String.starts_with?(entry, @handoff_prefix) do
            handoff_protects?(Path.join(path, entry), owner, grace_ms)
          else
            false
          end
        end)

      _ ->
        false
    end
  end

  defp handoff_protects?(marker, owner, grace_ms) do
    case read_owner(marker) do
      %{
        "parent" => parent,
        "child" => %{"host" => "127.0.0.1", "nonce" => nonce, "port" => port}
      }
      when is_map(parent) and is_binary(nonce) and is_integer(port) and port > 0 ->
        same_owner?(parent, owner) and probe_owner?(port, nonce)

      _ ->
        not older_than?(marker, grace_ms)
    end
  end

  defp same_owner?(left, right) do
    Map.take(left, ["host", "nonce", "port", "token"]) ==
      Map.take(right, ["host", "nonce", "port", "token"])
  end

  defp remove_path(path) do
    case File.rm_rf(path) do
      {:ok, _} -> true
      {:error, _, _} -> false
    end
  end

  defp serve_probe(listener, nonce) do
    case :gen_tcp.accept(listener) do
      {:ok, socket} ->
        Task.start(fn -> answer_probe(socket, nonce) end)
        serve_probe(listener, nonce)

      {:error, :closed} ->
        :ok

      {:error, _reason} ->
        serve_probe(listener, nonce)
    end
  end

  defp answer_probe(socket, nonce) do
    result =
      case recv_probe_line(socket, "", 1_000) do
        {:ok, ^nonce} -> :gen_tcp.send(socket, nonce <> "\n")
        _ -> :ok
      end

    :gen_tcp.close(socket)
    result
  end

  defp recv_probe_line(_socket, received, _timeout) when byte_size(received) > @probe_frame_max,
    do: {:error, :frame_too_large}

  defp recv_probe_line(socket, received, timeout) do
    case :binary.match(received, "\n") do
      {position, 1} ->
        {:ok, binary_part(received, 0, position)}

      :nomatch ->
        case :gen_tcp.recv(socket, 0, timeout) do
          {:ok, data} -> recv_probe_line(socket, received <> data, timeout)
          error -> error
        end
    end
  end

  defp read_owner(path) do
    with {:ok, contents} <- File.read(Path.join(path, "owner.json")),
         {:ok, owner} <- Jason.decode(contents) do
      owner
    end
  end

  defp write_owner!(path, owner) do
    temporary = Path.join(path, "owner-#{owner.token}.json")
    owner_path = Path.join(path, "owner.json")

    File.write!(temporary, Jason.encode!(owner))
    File.rename!(temporary, owner_path)
  rescue
    error ->
      File.rm_rf(path)
      reraise error, __STACKTRACE__
  end

  defp older_than?(path, milliseconds) do
    case File.stat(path) do
      {:ok, stat} ->
        modified_at =
          stat.mtime
          |> :calendar.datetime_to_gregorian_seconds()
          |> Kernel.-(:calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}}))
          |> Kernel.*(1_000)

        System.system_time(:millisecond) - modified_at >= milliseconds

      _ ->
        false
    end
  end

  defp nonce do
    24
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
