defmodule LiveShadcnTools.VerificationCache do
  @moduledoc "Bounded, runtime-specific storage of complete verification records."

  alias LiveShadcnTools, as: Tools
  alias LiveShadcnTools.VerificationShards

  @version 1

  def scope!(opts, names \\ []) do
    if names != [] or opts[:source] not in Tools.sources() or
         Enum.any?([:shard, :reuse, :output], &(not nonempty?(opts[&1]))) do
      Mix.raise(
        "cache use requires --source shadcn|ai_elements --shard N/T --reuse PATH --output PATH and no component names"
      )
    end

    root = Tools.repo_root()
    previews = Tools.read_json!(Path.join(root, "registry/snapshot/index.json"))

    VerificationShards.select(
      Tools.verification_targets(opts[:source], root),
      previews,
      opts[:shard],
      VerificationShards.costs(previews, root)
    )
  end

  def select(components, path, force?, root) do
    runtime = runtime()
    records = if force?, do: %{}, else: read(path, runtime)
    references = Enum.map(components, fn {source, name} -> Tools.ref(source, name) end)

    records =
      records
      |> Map.take(references)
      |> Map.filter(fn {_reference, record} ->
        is_map(record) and record["pass"] == true and is_map(record["checks"])
      end)

    evaluations =
      LiveShadcnVerification.evaluate_many(records, root, Path.join(root, "registry/spec"))

    reused =
      Map.filter(records, fn {reference, _} -> evaluations[reference].status == :verified end)

    run =
      Enum.reject(components, fn {source, name} ->
        Map.has_key?(reused, Tools.ref(source, name))
      end)

    %{runtime: runtime, reused: reused, run: run}
  end

  def plan(components, selection) do
    %{
      "browser_needed" => selection.run != [],
      "reused" => selection.reused |> Map.keys() |> Enum.sort(),
      "run" => references(selection.run),
      "components" => references(components)
    }
  end

  def write!(path, runtime, records, root) do
    # Each file contains only its assigned scope, with one record per component.
    # Recheck policy and identity before a record enters persistent storage.
    candidates =
      Map.filter(records, fn {_key, record} -> is_map(record) and record["pass"] == true end)

    evaluations =
      LiveShadcnVerification.evaluate_many(candidates, root, Path.join(root, "registry/spec"))

    passed = Map.filter(candidates, fn {key, _record} -> evaluations[key].status == :verified end)

    Tools.write_json_atomic!(Path.expand(path), %{
      "version" => @version,
      "runtime" => runtime,
      "results" => passed
    })
  end

  def runtime do
    %{
      "os" => :os.type() |> Tuple.to_list() |> Enum.map_join("/", &to_string/1),
      "arch" => :erlang.system_info(:system_architecture) |> to_string(),
      "otp" => otp_version(),
      "elixir" => System.version(),
      "node" => command("node", ["--version"]),
      "image" => image(),
      "browser_image" => System.get_env("CI_BROWSER_IMAGE") || "host",
      "utc_date" => Date.utc_today() |> Date.to_iso8601()
    }
  end

  defp read(path, runtime) do
    with true <- Enum.all?(Map.values(runtime), &nonempty?/1),
         {:ok, bytes} <- File.read(path),
         {:ok, %{"version" => @version, "runtime" => ^runtime, "results" => records}} <-
           Jason.decode(bytes),
         true <- is_map(records) do
      records
    else
      _ -> %{}
    end
  end

  defp references(components),
    do: components |> Enum.map(fn {source, name} -> Tools.ref(source, name) end) |> Enum.sort()

  defp otp_version do
    release = :erlang.system_info(:otp_release) |> to_string()
    path = Path.join([to_string(:code.root_dir()), "releases", release, "OTP_VERSION"])

    case File.read(path) do
      {:ok, version} -> String.trim(version) <> "/" <> to_string(:erlang.system_info(:version))
      _ -> nil
    end
  end

  defp image do
    case {System.get_env("ImageOS"), System.get_env("ImageVersion")} do
      {os, version} when is_binary(os) and os != "" and is_binary(version) and version != "" ->
        "#{os}/#{version}"

      _ ->
        case File.read("/etc/os-release") do
          {:ok, release} -> Tools.digest(release <> (command("uname", ["-srv"]) || ""))
          _ -> command("uname", ["-srv"])
        end
    end
  end

  defp command(name, arguments) do
    case System.cmd(name, arguments, stderr_to_stdout: true) do
      {version, 0} -> String.trim(version)
      _ -> nil
    end
  rescue
    ErlangError -> nil
  end

  defp nonempty?(value), do: is_binary(value) and String.trim(value) != ""
end
