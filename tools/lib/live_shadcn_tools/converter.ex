defmodule LiveShadcnTools.Converter do
  @moduledoc """
  Synchronizes safe upstream facts into a reviewed HEEx port.

  The module updates class and CVA facts. It reports all structural or behavior
  drift for review. It returns source and contract bytes but does not write
  repository files.
  """

  import LiveShadcnTools, only: [digest: 1, repo_root: 0]

  alias LiveShadcnTools.TwMerge

  @start "# live-shadcn: upstream facts start"
  @finish "# live-shadcn: upstream facts end"

  @doc "Synchronizes one reviewed port with its upstream source files."
  def sync(%{mode: :offline} = input) do
    contract = Map.fetch!(input, :contract)
    port = Map.fetch!(input, :port)

    with {:ok, block} <- fact_block(port),
         :ok <- same_offline_facts(contract, block.facts),
         :ok <- same_fact_block(port, block, contract["facts"]),
         :ok <- same_port_body(contract, port, block) do
      {:current, artifact(contract, port)}
    end
  end

  def sync(input) do
    with {:ok, extracted} <- extract(Map.fetch!(input, :files)),
         bindings = bindings(input, extracted.facts),
         ignored = ignored(input),
         uses = uses(input),
         {:ok, facts} <- bind(extracted.facts, bindings, ignored),
         {:ok, block} <- fact_block(Map.fetch!(input, :port)),
         :ok <- same_fact_keys(block.facts, facts, Map.get(input, :contract)),
         :ok <- same_structure(Map.get(input, :contract), extracted.file_fingerprints),
         base_ui = digest_entries(Map.get(input, :base_ui, %{})),
         :ok <- same_base_ui(Map.get(input, :contract), base_ui),
         style_facts = relevant_styles(Map.get(input, :styles, %{}), facts),
         styles = digest_entries(style_facts),
         class_sources = [facts, style_facts],
         reads = state_reads(class_sources),
         :ok <- same_state_reads(Map.get(input, :contract), reads) do
      contract =
        contract(
          input,
          extracted,
          block,
          %{
            facts: facts,
            bindings: bindings,
            ignored: ignored,
            uses: uses,
            reads: reads,
            base_ui: base_ui,
            styles: styles,
            class_sources: class_sources
          }
        )

      port = replace_block(input.port, block, render_block(facts))
      artifact = artifact(contract, port)

      case Map.get(input, :contract) do
        nil ->
          {:updated, artifact,
           [%{kind: :contract, path: "registry/spec/#{input.source}/#{input.name}.json"}]}

        current when current == contract and port == input.port ->
          {:current, artifact}

        current ->
          changes =
            fact_changes(Map.get(current, "facts", %{}), facts) ++
              port_changes(current, contract)

          {:updated, artifact, changes}
      end
    end
  end

  defp bindings(%{contract: %{} = contract}, _source_facts),
    do: Map.fetch!(contract, "bindings")

  defp bindings(input, source_facts) do
    Map.get(input, :bindings) ||
      %{
        "copy" => default_copy_bindings(source_facts),
        "derived" => %{}
      }
  end

  defp default_copy_bindings(source_facts) do
    source_facts
    |> Map.keys()
    |> Enum.map(fn key ->
      case String.split(key, "/", parts: 3) do
        ["cva", binding, _rest] -> "cva/#{binding}/*"
        _other -> key
      end
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp ignored(%{contract: %{} = contract}), do: Map.get(contract, "ignored", %{})
  defp ignored(input), do: Map.get(input, :ignored, %{})

  defp uses(%{contract: %{} = contract}), do: Map.get(contract, "uses", [])
  defp uses(input), do: Map.get(input, :uses, [])

  defp bind(source, bindings, ignored) do
    copy = Map.get(bindings, "copy", [])
    derived = Map.get(bindings, "derived", %{})
    used = MapSet.new(copy ++ derived_sources(derived) ++ Map.keys(ignored))

    uncovered =
      source
      |> Map.keys()
      |> Enum.reject(&covered?(&1, used))
      |> Enum.sort()

    if uncovered == [] do
      copied =
        source
        |> Enum.filter(fn {key, _value} -> Enum.any?(copy, &matches?(&1, key)) end)
        |> Map.new()

      calculated =
        Map.new(derived, fn {key, expression} -> {key, evaluate(expression, source)} end)

      {:ok, Map.merge(copied, calculated)}
    else
      {:error,
       [
         %{
           "message" =>
             "upstream facts need a binding or ignored reason: #{Enum.join(uncovered, ", ")}"
         }
       ]}
    end
  end

  defp derived_sources(derived) do
    derived
    |> Map.values()
    |> Enum.flat_map(&expression_sources/1)
  end

  defp expression_sources(%{"fact" => key}), do: [key]
  defp expression_sources(%{"items" => items}), do: Enum.flat_map(items, &expression_sources/1)
  defp expression_sources(_expression), do: []

  defp covered?(key, patterns), do: Enum.any?(patterns, &matches?(&1, key))
  defp matches?(pattern, key) when pattern == key, do: true

  defp matches?(pattern, key) do
    if String.ends_with?(pattern, "/*") do
      String.starts_with?(key, String.trim_trailing(pattern, "*"))
    else
      false
    end
  end

  defp evaluate(%{"fact" => key}, source), do: Map.fetch!(source, key)
  defp evaluate(%{"literal" => value}, _source), do: value

  defp evaluate(%{"op" => "join", "items" => items}, source),
    do: items |> Enum.map(&evaluate(&1, source)) |> Enum.reject(&(&1 == "")) |> Enum.join(" ")

  defp evaluate(%{"op" => "tw_merge", "items" => items}, source),
    do: items |> Enum.map(&evaluate(&1, source)) |> TwMerge.merge()

  defp fact_changes(previous, current) do
    (Map.keys(previous) ++ Map.keys(current))
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.flat_map(fn key ->
      old = Map.get(previous, key)
      new = Map.get(current, key)

      if old == new,
        do: [],
        else: [%{kind: :fact, key: key, before: old, after: new}]
    end)
  end

  defp port_changes(previous, current) do
    if previous["port_body"] == current["port_body"] do
      []
    else
      [%{kind: :port_body, before: previous["port_body"], after: current["port_body"]}]
    end
  end

  defp same_offline_facts(contract, facts) do
    if Map.get(contract, "facts", %{}) == facts,
      do: :ok,
      else:
        {:error, [%{kind: :facts, message: "the port fact block does not match its contract"}]}
  end

  defp same_fact_block(port, block, facts) do
    if replace_block(port, block, render_block(facts)) == port,
      do: :ok,
      else: {:error, [%{kind: :fact_block, message: "the port fact block is not canonical"}]}
  end

  defp same_port_body(contract, port, block) do
    actual = digest(port_body(port, block))

    if contract["port_body"] == actual,
      do: :ok,
      else: {:error, [%{kind: :port_body, message: "the port body does not match its contract"}]}
  end

  defp contract(input, extracted, block, data) do
    %{
      "schema_version" => 2,
      "source" => Map.fetch!(input, :source),
      "name" => Map.fetch!(input, :name),
      "toolchain" => %{"oxc-parser" => parser_version()},
      "upstream" =>
        input.files
        |> Enum.sort()
        |> Map.new(fn {path, source} -> {path, digest(source)} end),
      "fingerprint" => extracted.fingerprint,
      "file_fingerprints" => extracted.file_fingerprints,
      "source_facts" => extracted.facts,
      "facts" => data.facts,
      "bindings" => data.bindings,
      "ignored" => data.ignored,
      "uses" => data.uses,
      "state_reads" => data.reads,
      "css_vars" => css_vars(data.class_sources),
      "base_ui" => data.base_ui,
      "styles" => data.styles,
      "port_body" => digest(port_body(input.port, block))
    }
  end

  defp artifact(contract, port) do
    %{
      contract: contract,
      contract_json: Jason.encode!(contract, pretty: true) <> "\n",
      port: port
    }
  end

  defp extract(files) do
    request = Jason.encode!(%{files: files})

    path =
      Path.join(System.tmp_dir!(), "live-shadcn-facts-#{System.unique_integer([:positive])}.json")

    script = Path.join(:code.priv_dir(:live_shadcn_tools), "facts.mjs")
    File.write!(path, request)

    try do
      case System.cmd(node!(), [script, path], stderr_to_stdout: true) do
        {json, 0} -> combine(Jason.decode!(json))
        {json, _status} -> {:error, diagnostics(json)}
      end
    after
      File.rm(path)
    end
  end

  defp combine(%{"files" => files}) do
    entries =
      for {path, result} <- Enum.sort(files),
          {key, value} <- Enum.sort(result["facts"]),
          do: {path, key, value}

    counts = Enum.frequencies_by(entries, fn {_path, key, _value} -> key end)

    facts =
      Map.new(entries, fn {path, key, value} ->
        stable_key = if counts[key] == 1, do: key, else: "file/#{path}/#{key}"
        {stable_key, value}
      end)

    fingerprints =
      files |> Enum.sort() |> Map.new(fn {path, value} -> {path, value["fingerprint"]} end)

    {:ok,
     %{
       facts: facts,
       file_fingerprints: fingerprints,
       fingerprint: digest(:erlang.term_to_binary(Enum.sort(fingerprints)))
     }}
  end

  defp same_structure(nil, _fingerprints), do: :ok

  defp same_structure(contract, fingerprints) do
    previous = Map.get(contract, "file_fingerprints", %{})

    drift =
      (Map.keys(previous) ++ Map.keys(fingerprints))
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.reject(&(Map.get(previous, &1) == Map.get(fingerprints, &1)))
      |> Enum.map(&%{kind: :structure, path: &1})

    if drift == [], do: :ok, else: {:manual, drift}
  end

  defp same_state_reads(nil, _reads), do: :ok

  defp same_state_reads(contract, reads) do
    previous = Map.get(contract, "state_reads", [])

    if previous == reads,
      do: :ok,
      else: {:manual, [%{kind: :state_reads, before: previous, after: reads}]}
  end

  defp same_base_ui(nil, _digests), do: :ok

  defp same_base_ui(contract, digests) do
    previous = Map.get(contract, "base_ui", %{})

    drift =
      (Map.keys(previous) ++ Map.keys(digests))
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.reject(&(Map.get(previous, &1) == Map.get(digests, &1)))
      |> Enum.map(&%{kind: :base_ui, path: &1})

    if drift == [], do: :ok, else: {:manual, drift}
  end

  defp digest_entries(entries) do
    entries
    |> Enum.sort()
    |> Map.new(fn {key, value} -> {key, digest(:erlang.term_to_binary(value))} end)
  end

  defp relevant_styles(styles, facts) do
    classes =
      facts
      |> Map.values()
      |> Enum.filter(&is_binary/1)
      |> Enum.flat_map(&String.split/1)
      |> Enum.filter(&String.starts_with?(&1, "cn-"))
      |> MapSet.new()
      |> MapSet.to_list()

    styles
    |> Enum.map(fn {style, rules} -> {style, Map.take(rules, classes)} end)
    |> Enum.reject(fn {_style, rules} -> rules == %{} end)
    |> Map.new()
  end

  defp state_reads(values) do
    values
    |> strings()
    |> Enum.filter(&is_binary/1)
    |> Enum.flat_map(&String.split/1)
    |> Enum.flat_map(&variant_prefixes/1)
    |> Enum.flat_map(&classify_variant/1)
    |> Enum.uniq()
    |> Enum.sort_by(&{Map.get(&1, "group"), &1["name"], &1["value"]})
  end

  defp classify_variant("group-" <> rest) do
    case String.split(rest, "/", parts: 2) do
      [attribute, group] ->
        for read <- classify_variant(attribute), do: Map.put(read, "group", group)

      _ ->
        []
    end
  end

  defp classify_variant(<<"data-[", _rest::binary>> = variant),
    do: bracket_read(variant, "data")

  defp classify_variant(<<"aria-[", _rest::binary>> = variant),
    do: bracket_read(variant, "aria")

  defp classify_variant(variant) do
    cond do
      Regex.match?(~r/^(data|aria)-[a-z][a-z0-9-]*=.+$/, variant) ->
        [name, value] = String.split(variant, "=", parts: 2)
        [read(name, value)]

      Regex.match?(~r/^(data|aria)-[a-z][a-z0-9-]*$/, variant) ->
        [read(variant)]

      true ->
        []
    end
  end

  defp bracket_read(variant, prefix) do
    case Regex.run(~r/^#{prefix}-\[([a-z][a-z0-9-]*)(?:[$^*]?=)([^\]]+)\]$/, variant) do
      [_, attribute, value] ->
        [read("#{prefix}-#{attribute}", value)]

      _ ->
        case Regex.run(~r/^#{prefix}-\[([a-z][a-z0-9-]*)\]$/, variant) do
          [_, attribute] -> [read("#{prefix}-#{attribute}")]
          _ -> []
        end
    end
  end

  defp read(name, value \\ nil), do: %{"name" => name, "value" => value}

  defp variant_prefixes(token), do: token |> split_variants(0, [], "") |> Enum.drop(-1)

  defp split_variants("", _depth, found, current), do: Enum.reverse([current | found])

  defp split_variants(<<char, rest::binary>>, depth, found, current) do
    cond do
      char == ?: and depth == 0 -> split_variants(rest, depth, [current | found], "")
      char in ~c"([{" -> split_variants(rest, depth + 1, found, current <> <<char>>)
      char in ~c")]}" -> split_variants(rest, depth - 1, found, current <> <<char>>)
      true -> split_variants(rest, depth, found, current <> <<char>>)
    end
  end

  defp css_vars(values) do
    values
    |> strings()
    |> Enum.flat_map(fn classes ->
      ~r/\(?(--[a-z][a-z0-9-]*)\)/
      |> Regex.scan(classes, capture: :all_but_first)
      |> List.flatten()
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp strings(value) when is_binary(value), do: [value]
  defp strings(value) when is_map(value), do: value |> Map.values() |> Enum.flat_map(&strings/1)
  defp strings(value) when is_list(value), do: Enum.flat_map(value, &strings/1)
  defp strings(_value), do: []

  defp diagnostics(json) do
    case Jason.decode(json) do
      {:ok, %{"diagnostics" => diagnostics, "path" => path}} ->
        Enum.map(diagnostics, &Map.put(&1, "path", path))

      _ ->
        [%{"message" => String.trim(json)}]
    end
  end

  defp fact_block(port) do
    pattern =
      ~r/(?<start>^[ \t]*#{Regex.escape(@start)}\n)(?<body>.*?)(?<finish>^[ \t]*#{Regex.escape(@finish)}$)/ms

    case Regex.named_captures(pattern, port, return: :index) do
      %{"body" => {body_start, body_length}, "start" => {start, _}, "finish" => {finish, length}} ->
        body = binary_part(port, body_start, body_length)

        with {:ok, facts} <- parse_facts(body) do
          {:ok,
           %{
             facts: facts,
             start: start,
             finish: finish + length,
             body_start: body_start,
             body_length: body_length
           }}
        end

      _ ->
        {:error, [%{"message" => "the port has no upstream fact block"}]}
    end
  end

  defp parse_facts(body) do
    with {:ok, ast} <- Code.string_to_quoted(String.trim(body)),
         {:@, _, [{:upstream_facts, _, [{:%{}, _, pairs}]}]} <- ast,
         {:ok, facts} <- literal_pairs(pairs) do
      {:ok, facts}
    else
      _ -> {:error, [%{"message" => "the upstream fact block is not a literal map"}]}
    end
  end

  defp literal_pairs(pairs) do
    Enum.reduce_while(pairs, {:ok, %{}}, fn
      {key, value}, {:ok, facts} when is_binary(key) and (is_binary(value) or is_nil(value)) ->
        {:cont, {:ok, Map.put(facts, key, value)}}

      _pair, _result ->
        {:halt, :error}
    end)
  end

  defp same_fact_keys(port, _source, nil) when map_size(port) == 0, do: :ok
  defp same_fact_keys(port, source, nil), do: compare_fact_keys(port, source, "source")

  defp same_fact_keys(port, _source, contract),
    do: compare_fact_keys(port, Map.get(contract, "facts", %{}), "contract")

  defp compare_fact_keys(port, expected, expected_name) do
    if Map.keys(port) |> Enum.sort() == Map.keys(expected) |> Enum.sort() do
      :ok
    else
      {:error,
       [
         %{
           "message" =>
             "the port fact keys do not match the #{expected_name} facts: " <>
               "port=#{inspect(Map.keys(port) |> Enum.sort())} " <>
               "#{expected_name}=#{inspect(Map.keys(expected) |> Enum.sort())}"
         }
       ]}
    end
  end

  defp replace_block(port, block, rendered) do
    prefix = binary_part(port, 0, block.start)
    suffix_start = block.finish
    suffix = binary_part(port, suffix_start, byte_size(port) - suffix_start)
    prefix <> rendered <> suffix
  end

  defp render_block(facts) do
    entries =
      facts
      |> Enum.sort()
      |> Enum.map_join(",\n", fn {key, value} -> "  #{inspect(key)} => #{inspect(value)}" end)

    "#{@start}\n@upstream_facts %{\n#{entries}\n}\n#{@finish}"
    |> Code.format_string!(line_length: 96)
    |> IO.iodata_to_binary()
    |> String.split("\n")
    |> Enum.map_join("\n", &("  " <> &1))
  end

  defp port_body(port, block) do
    prefix = binary_part(port, 0, block.start)
    suffix_start = block.finish
    suffix = binary_part(port, suffix_start, byte_size(port) - suffix_start)
    prefix <> @start <> "\n" <> @finish <> suffix
  end

  defp parser_version do
    package = Path.join([repo_root(), "tools", "package.json"])
    package |> File.read!() |> Jason.decode!() |> get_in(["dependencies", "oxc-parser"])
  end

  defp node! do
    System.find_executable("node") ||
      raise "node is not on PATH; run `mise install` before the converter"
  end
end
