defmodule LiveShadcnTools.BrowserServer do
  @moduledoc "Readiness checks and bounded startup diagnostics for owned browser servers."

  @output_limit 32_768
  @request_timeout 1_000
  @sensitive_line ~r/token|authorization|cookie|password|secret|credential|api.?key|signature|session[_-]|[?&]sig=/i

  def await_ready!(server, deadline, opts \\ []) do
    Application.ensure_all_started(:inets)
    await(server, deadline, opts, "")
  end

  defp await(server, deadline, opts, output) do
    {output, status} = collect_output(server.process, output)
    remaining = deadline - System.monotonic_time(:millisecond)

    cond do
      is_integer(status) ->
        fail!(server, "stopped before it became ready (exit #{status})", output, opts)

      Port.info(server.process) == nil ->
        fail!(server, "stopped before it became ready", output, opts)

      remaining <= 0 ->
        fail!(server, "did not become ready before the timeout", output, opts)

      ready?(server, min(remaining, @request_timeout)) ->
        :ok

      true ->
        process = server.process

        receive do
          {^process, {:data, data}} ->
            await(server, deadline, opts, append_output(output, data))

          {^process, {:exit_status, status}} ->
            fail!(server, "stopped before it became ready (exit #{status})", output, opts)
        after
          min(50, remaining) -> await(server, deadline, opts, output)
        end
    end
  end

  defp ready?(server, timeout) do
    url = String.to_charlist("http://127.0.0.1:#{server.port}#{server.path}")

    case :httpc.request(:get, {url, []}, [timeout: timeout, connect_timeout: timeout],
           body_format: :binary
         ) do
      {:ok, {{_version, 200, _reason}, _headers, body}} -> Regex.match?(server.expected, body)
      _ -> false
    end
  end

  defp collect_output(process, output) do
    receive do
      {^process, {:data, data}} -> collect_output(process, append_output(output, data))
      {^process, {:exit_status, status}} -> {output, status}
    after
      0 -> {output, nil}
    end
  end

  # Keep the prefix so a partial final line cannot lose its sensitive-field label.
  defp append_output(output, data) do
    binary_part(output <> data, 0, min(byte_size(output) + byte_size(data), @output_limit))
  end

  defp fail!(server, reason, output, opts) do
    diagnostic =
      output
      |> String.chunk(:valid)
      |> Enum.filter(&String.valid?/1)
      |> Enum.join()
      |> String.split("\n")
      |> Enum.map(fn line ->
        if Regex.match?(@sensitive_line, line), do: "<REDACTED>", else: line
      end)
      |> Enum.take(-16)
      |> Enum.join("\n")
      |> String.trim()

    message = "#{server.name} browser server #{reason}"

    message =
      if diagnostic == "", do: message, else: message <> "\nStartup output:\n" <> diagnostic

    if directory = Keyword.get(opts, :artifacts) do
      File.mkdir_p!(directory)
      File.write!(Path.join(directory, "startup-#{server.name}.log"), message <> "\n")
    end

    Mix.raise(message)
  end
end
